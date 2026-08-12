################################################################################
#'
#'  REPLICATING LEJLA'S TROŠARINE CALCULATIONS (well, kinda)
#'
#'  This script takes the excise data from the UMAR platform database
#'  (where it is ingested monthly using the data/trosarine.R script)
#'
#'
################################################################################
library(dplyr)
con <- DBI::dbConnect(RPostgres::Postgres(),
                      dbname = "platform",
                      host = "localhost",
                      port = 5432,
                      user = "postgres",
                      password = Sys.getenv("PG_PG_PSW"),
                      client_encoding = "utf8")

lookup_path <- "\\\\192.168.38.7\\public$\\Avtomatizacija\\umar-automation-scripts\\data\\trosarine\\sifranti\\trosarine_lookup.xlsx"
final_path <- "\\\\192.168.38.7\\public$\\Users\\LFajic\\trošarine\\trošarine_preračuni.xlsx"

################################################################################
#'   RAW DATA EXTRACTION
#'
#'   get raw data from the database and clean up minimally
#'
#'   results in 4 tables:
#'    - Količine and zneski old series up to aug. 2025 (16 cats) K_raw_old Z_raw_old
#'    - Količine and zneski new series from sept. 2025 (40 cats) K_codes_new Z_raw_new
#'
################################################################################
lookup <- openxlsx2::read_xlsx(lookup_path, sheet = 1L)

# 1. old data up to august 2025 with 16 categories
# get codes for old data
old_codes <- unique(lookup$kratice_stare)
K_codes_old <- paste("MF-UMAR", "LF001", "K", old_codes, "M", sep = "--")
Z_codes_old <- paste("MF-UMAR", "LF001", "Z", old_codes, "M", sep = "--")

# get raw old data - quantities
K_raw_old <- tbl(con, dbplyr::in_schema("views", "latest_data_points_view")) |>
  filter(series_code %in% c(K_codes_old)) |>
  select(series_code, period_id, date, value) |>
  collect() |>
  mutate(code = sub("^.*--([A-Z0-9]{3,4})--M$", "\\1", series_code), .keep = "unused")

# get raw old data - amounts of excise duty
Z_raw_old <- tbl(con, dbplyr::in_schema("views", "latest_data_points_view")) |>
  filter(series_code %in% c(Z_codes_old)) |>
  select(series_code, period_id, date, value) |>
  collect() |>
  mutate(code = sub("^.*--([A-Z0-9]{3,4})--M$", "\\1", series_code), .keep = "unused")

#' why the difference of 77 rows between kolicine and zneski?
#' ZPPV have 198 rows of 0 zneski with no kolicine (2005-junij 2021)
#' BDIZ has 121 rows of kolicine with no zneski.
#' these are all artefacts of the original data source, double sanity checked, so all is good.


# 2. new data from september 2025 with 40 categories
# get codes for old data
new_codes <- unique(lookup$kratice_nove)
K_codes_new <- paste("MF-UMAR", "LF002", "K", new_codes, "M", sep = "--")
Z_codes_new <- paste("MF-UMAR", "LF002", "Z", new_codes, "M", sep = "--")

# get raw old data - quantities
K_raw_new <- tbl(con, dbplyr::in_schema("views", "latest_data_points_view")) |>
  filter(series_code %in% c(K_codes_new)) |>
  select(series_code, period_id, date, value) |>
  collect() |>
  mutate(code = sub("^.*--([A-Z0-9]{2,4})--M$", "\\1", series_code), .keep = "unused")

# get raw old data - amounts of excise duty
Z_raw_new <- tbl(con, dbplyr::in_schema("views", "latest_data_points_view")) |>
  filter(series_code %in% c(Z_codes_new)) |>
  select(series_code, period_id, date, value) |>
  collect() |>
  mutate(code = sub("^.*--([A-Z0-9]{2,4})--M$", "\\1", series_code), .keep = "unused")

library(dplyr)

## ---- original code -> consolidated (kontinuiteta) -> nad maps ----
map_old <- lookup |>
  select(koda_orig = kratice_stare, code = kontinuiteta, nad) |>
  distinct() |> tidyr::drop_na(koda_orig, code)

map_new <- lookup |>
  select(koda_orig = kratice_nove, code = kontinuiteta, nad) |>
  distinct() |> tidyr::drop_na(koda_orig, code)

## ---- monthly, ORIGINAL-code grain (K + Z joined before consolidation) ----
raw_old <- full_join(K_raw_old |> rename(kolicina = value),
                     Z_raw_old |> rename(znesek   = value),
                     by = c("period_id", "date", "code")) |>
  rename(koda_orig = code) |> left_join(map_old, by = "koda_orig")

raw_new <- full_join(K_raw_new |> rename(kolicina = value),
                     Z_raw_new |> rename(znesek   = value),
                     by = c("period_id", "date", "code")) |>
  rename(koda_orig = code) |> left_join(map_new, by = "koda_orig")

used <- c("alkohol", "pivo", "vmesne_pijace",
          "cigarete", "cigare", "tobak", "elektronske_cigarete",
          "bencin", "dizel", "kurilno_olje")

monthly_orig <- bind_rows(raw_old, raw_new) |>
  filter(code %in% used) |>
  mutate(year    = lubridate::year(date),
         month   = lubridate::month(date),
         quarter = lubridate::quarter(date),
         imputed = FALSE)

## ---- consolidated monthly (needed for imputation, structures, YoY) ----
consolidated_monthly <- monthly_orig |>
  summarise(kolicina = sum(kolicina, na.rm = TRUE),
            znesek   = sum(znesek,   na.rm = TRUE),
            .by = c(period_id, date, code, nad))

################################################################################
#'   OK, now the problematic part.. imputing the 3rd month of the
#'   quarter if it is missing..
#'
##############################################################################
impute_monthly <- function(data, n_months = NULL) {
  monthly <- data |>
    mutate(year    = lubridate::year(date),
           month   = lubridate::month(date),
           quarter = lubridate::quarter(date),
           imputed = FALSE)

  last_month <- max(monthly$date)
  last_y     <- lubridate::year(last_month)
  last_m     <- lubridate::month(last_month)
  last_q     <- lubridate::quarter(last_month)
  q_months   <- (last_q - 1L) * 3L + 1:3

  # codes with exactly 2 of 3 months in current quarter
  to_impute <- monthly |>
    filter(year == last_y, quarter == last_q, !is.na(kolicina)) |>
    summarise(n_present      = dplyr::n(),
              months_present = list(sort(month)),
              .by = c(code, nad)) |>
    filter(n_present == 2L) |>
    mutate(missing_month = purrr::map_int(months_present,
                                          \(x) setdiff(q_months, x)))

  if (nrow(to_impute) == 0L) return(monthly)

  # ytd reference window
  ref <- monthly |>
    filter(year == last_y, month <= last_m, !is.na(kolicina))

  if (!is.null(n_months)) ref <- ref |> filter(month > (last_m - n_months))

  ref_means <- ref |>
    summarise(kolicina = mean(kolicina, na.rm = TRUE),
              znesek   = mean(znesek,   na.rm = TRUE),
              .by = code)

  imputed_rows <- to_impute |>
    left_join(ref_means, by = "code") |>
    mutate(
      month     = missing_month,
      year      = last_y,
      quarter   = last_q,
      date      = lubridate::make_date(last_y, missing_month, 1L),
      period_id = paste0(last_y, "M", sprintf("%02d", missing_month)),
      imputed   = TRUE
    ) |>
    select(period_id, date, code, nad, kolicina, znesek, year, month, quarter, imputed)

  dplyr::bind_rows(monthly, imputed_rows) |>
    arrange(code, date)
}

## impute on the CONSOLIDATED series (this is what fixes the PQ brez-nikotina bug)
consolidated_imputed <- impute_monthly(consolidated_monthly)

imputed_rows <- consolidated_imputed |>
  filter(imputed) |> mutate(koda_orig = NA_character_)

## ---- structures (annual x code) ----
structures <- consolidated_imputed |>
  mutate(year = lubridate::year(date)) |>
  summarise(znesek_annual = sum(znesek, na.rm = TRUE), .by = c(year, code, nad)) |>
  mutate(znesek_aggr  = sum(znesek_annual, na.rm = TRUE), .by = c(year, nad)) |>
  mutate(znesek_total = sum(znesek_annual, na.rm = TRUE), .by = year) |>
  mutate(str_within_aggr = znesek_annual / znesek_aggr,
         str_aggr_total  = znesek_aggr    / znesek_total,
         str_total       = znesek_annual / znesek_total)

## ---- quarterly YoY: self-join on year-1 instead of lag(4) ----
q <- consolidated_imputed |>
  mutate(year = lubridate::year(date), quarter = lubridate::quarter(date)) |>
  summarise(kolicina_q = sum(kolicina, na.rm = TRUE), .by = c(year, quarter, code, nad))

yoy <- q |>
  left_join(q |> select(year, quarter, code, kolicina_q_ly = kolicina_q) |>
              mutate(year = year + 1L),
            by = c("year", "quarter", "code")) |>
  mutate(yoy = (kolicina_q / kolicina_q_ly - 1) * 100)

## ---- weighted YoY + coefficient, PRIOR-year weights (year + 1L join) ----
coeff <- yoy |>
  left_join(structures |> select(year, code, str_within_aggr, str_aggr_total, str_total) |>
              mutate(year = year + 1L),
            by = c("year", "code")) |>
  mutate(yoy_weighted_code = yoy * str_total) |>
  mutate(stopnja_rasti_nad = sum(yoy_weighted_code, na.rm = TRUE), .by = c(year, quarter, nad)) |>
  mutate(stopnja_rasti     = sum(yoy_weighted_code, na.rm = TRUE), .by = c(year, quarter)) |>
  mutate(koeficient = 1 + stopnja_rasti / 100)

## ---- assemble: original rows + imputed synthetic rows, broadcast analytics ----
final_table <- bind_rows(monthly_orig, imputed_rows) |>
  left_join(coeff |> select(year, quarter, code,
                            kolicina_q, kolicina_q_ly,
                            str_within_aggr, str_aggr_total, str_total,
                            yoy, yoy_weighted_code,
                            stopnja_rasti_nad, stopnja_rasti, koeficient),
            by = c("year", "quarter", "code")) |>
  relocate(period_id, date, year, month, quarter, koda_orig, code, nad,
           imputed, kolicina, znesek) |>
  arrange(date, nad, code)




wb <- openxlsx2::wb_load(final_path) |>
  # register the named style ONCE on the workbook
  openxlsx2::wb_add_dxfs_style(
    name     = "pinkRow",
    bg_fill  = openxlsx2::wb_color(hex = "FFFFC0CB")
  )

# preserve original sheet position
sheet_pos <- match("raw", wb$get_sheet_names())

# remove old sheet (also clears its CF rules)
if (!is.na(sheet_pos)) {
  wb <- openxlsx2::wb_remove_worksheet(wb, sheet = "raw")
}

wb <- wb |>
  openxlsx2::wb_add_worksheet("raw") |>
  openxlsx2::wb_add_data_table(
    sheet = "raw",
    x     = final_table,
    table_name = "datatable",
    start_col = 1,
    start_row = 1,
    table_style = "TableStyleMedium2") |>
  openxlsx2::wb_add_conditional_formatting(
    sheet = "raw",
    dims  = openxlsx2::wb_dims(rows = 2:(nrow(final_table) + 1), cols = 1:ncol(final_table)),
    rule  = "$I2",
    style = "pinkRow"          # <- string name, not a style object
  )

# test next time for july!!!
# # after wb_load(), before wb_save()
# wb$pivotDefinitions <- vapply(wb$pivotDefinitions, function(xml) {
#   if (grepl("refreshOnLoad=", xml, fixed = TRUE)) {
#     sub('refreshOnLoad="[^"]*"', 'refreshOnLoad="1"', xml)
#   } else {
#     sub("(<pivotCacheDefinition\\b)", '\\1 refreshOnLoad="1"', xml)
#   }
# }, character(1))

# save final
openxlsx2::wb_save(wb, final_path, overwrite = TRUE)


