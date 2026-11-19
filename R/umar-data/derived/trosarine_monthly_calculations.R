################################################################################
#'
#'  REPLICATING LEJLA'S TROŠARINE CALCULATIONS (well, kinda)
#'
#'  This script takes the excise data from the UMAR platform database
#'  (where it is ingested monthly using the data/trosarine.R script)
#'
#'
################################################################################
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
K_raw_old <- dplyr::tbl(con, dbplyr::in_schema("views", "latest_data_points_view")) |>
  dplyr::filter(series_code %in% c(K_codes_old)) |>
  dplyr::select(series_code, period_id, date, value) |>
  dplyr::collect() |>
  dplyr::mutate(code = sub("^.*--([A-Z0-9]{3,4})--M$", "\\1", series_code), .keep = "unused")

# get raw old data - amounts of excise duty
Z_raw_old <- dplyr::tbl(con, dbplyr::in_schema("views", "latest_data_points_view")) |>
  dplyr::filter(series_code %in% c(Z_codes_old)) |>
  dplyr::select(series_code, period_id, date, value) |>
  dplyr::collect() |>
  dplyr::mutate(code = sub("^.*--([A-Z0-9]{3,4})--M$", "\\1", series_code), .keep = "unused")

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
K_raw_new <- dplyr::tbl(con, dbplyr::in_schema("views", "latest_data_points_view")) |>
  dplyr::filter(series_code %in% c(K_codes_new)) |>
  dplyr::select(series_code, period_id, date, value) |>
  dplyr::collect() |>
  dplyr::mutate(code = sub("^.*--([A-Z0-9]{2,4})--M$", "\\1", series_code), .keep = "unused")

# get raw old data - amounts of excise duty
Z_raw_new <- dplyr::tbl(con, dbplyr::in_schema("views", "latest_data_points_view")) |>
  dplyr::filter(series_code %in% c(Z_codes_new)) |>
  dplyr::select(series_code, period_id, date, value) |>
  dplyr::collect() |>
  dplyr::mutate(code = sub("^.*--([A-Z0-9]{2,4})--M$", "\\1", series_code), .keep = "unused")


## ---- original code -> consolidated (kontinuiteta) -> nad maps ----
map_old <- lookup |>
  dplyr::select(koda_orig = kratice_stare, code = kontinuiteta, nad) |>
  dplyr::distinct() |> tidyr::drop_na(koda_orig, code)

map_new <- lookup |>
  dplyr::select(koda_orig = kratice_nove, code = kontinuiteta, nad) |>
  dplyr::distinct() |> tidyr::drop_na(koda_orig, code)

## ---- monthly, ORIGINAL-code grain (K + Z joined before consolidation) ----
raw_old <- dplyr::full_join(K_raw_old |> dplyr::rename(kolicina = value),
                            Z_raw_old |> dplyr::rename(znesek   = value),
                            by = c("period_id", "date", "code")) |>
  dplyr::rename(koda_orig = code) |>
  dplyr::left_join(map_old, by = "koda_orig")

raw_new <- dplyr::full_join(K_raw_new |> dplyr::rename(kolicina = value),
                            Z_raw_new |> dplyr::rename(znesek   = value),
                            by = c("period_id", "date", "code")) |>
  dplyr::rename(koda_orig = code) |>
  dplyr::left_join(map_new, by = "koda_orig")

used <- c("alkohol", "pivo", "vmesne_pijace",
          "cigarete", "cigare", "tobak", "elektronske_cigarete",
          "bencin", "dizel", "kurilno_olje")

monthly_orig <- dplyr::bind_rows(raw_old, raw_new) |>
  dplyr::filter(code %in% used) |>
  dplyr::mutate(year    = lubridate::year(date),
                month   = lubridate::month(date),
                quarter = lubridate::quarter(date),
                imputed = FALSE)

## ---- consolidated monthly (needed for imputation, structures, YoY) ----
consolidated_monthly <- monthly_orig |>
  dplyr::summarise(kolicina = sum(kolicina, na.rm = TRUE),
                   znesek   = sum(znesek,   na.rm = TRUE),
                   .by = c(period_id, date, code, nad))

################################################################################
#'   OK, now the problematic part.. imputing the 3rd month of the
#'   quarter if it is missing..
#'
##############################################################################
impute_monthly <- function(data, n_months = NULL) {
  monthly <- data |>
    dplyr::mutate(year    = lubridate::year(date),
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
    dplyr::filter(year == last_y, quarter == last_q, !is.na(kolicina)) |>
    dplyr::summarise(n_present      = dplyr::n(),
                     months_present = list(sort(month)),
                     .by = c(code, nad)) |>
    dplyr::filter(n_present == 2L) |>
    dplyr::mutate(missing_month = purrr::map_int(months_present,
                                                 \(x) setdiff(q_months, x)))

  if (nrow(to_impute) == 0L) return(monthly)

  # ytd reference window
  ref <- monthly |>
    dplyr::filter(year == last_y, month <= last_m, !is.na(kolicina))

  if (!is.null(n_months)) ref <- ref |> dplyr::filter(month > (last_m - n_months))

  ref_means <- ref |>
    dplyr::summarise(kolicina = mean(kolicina, na.rm = TRUE),
                     znesek   = mean(znesek,   na.rm = TRUE),
                     .by = code)

  imputed_rows <- to_impute |>
    dplyr::left_join(ref_means, by = "code") |>
    dplyr::mutate(
      month     = missing_month,
      year      = last_y,
      quarter   = last_q,
      date      = lubridate::make_date(last_y, missing_month, 1L),
      period_id = paste0(last_y, "M", sprintf("%02d", missing_month)),
      imputed   = TRUE
    ) |>
    dplyr::select(period_id, date, code, nad, kolicina, znesek, year, month, quarter, imputed)

  dplyr::bind_rows(monthly, imputed_rows) |>
    dplyr::arrange(code, date)
}

## impute on the CONSOLIDATED series (this is what fixes the PQ brez-nikotina bug)
consolidated_imputed <- impute_monthly(consolidated_monthly)

imputed_rows <- consolidated_imputed |>
  dplyr::filter(imputed) |> dplyr::mutate(koda_orig = NA_character_)

## ---- structures (annual x code) ----
structures <- consolidated_imputed |>
  dplyr::mutate(year = lubridate::year(date)) |>
  dplyr::summarise(znesek_annual = sum(znesek, na.rm = TRUE), .by = c(year, code, nad)) |>
  dplyr::mutate(znesek_aggr  = sum(znesek_annual, na.rm = TRUE), .by = c(year, nad)) |>
  dplyr::mutate(znesek_total = sum(znesek_annual, na.rm = TRUE), .by = year) |>
  dplyr::mutate(str_within_aggr = znesek_annual / znesek_aggr,
                str_aggr_total  = znesek_aggr    / znesek_total,
                str_total       = znesek_annual / znesek_total)

## ---- quarterly YoY: self-join on year-1 instead of lag(4) ----
q <- consolidated_imputed |>
  dplyr::mutate(year = lubridate::year(date), quarter = lubridate::quarter(date)) |>
  dplyr::summarise(kolicina_q = sum(kolicina, na.rm = TRUE), .by = c(year, quarter, code, nad))

yoy <- q |>
  dplyr::left_join(q |> dplyr::select(year, quarter, code, kolicina_q_ly = kolicina_q) |>
                     dplyr::mutate(year = year + 1L),
            by = c("year", "quarter", "code")) |>
  dplyr::mutate(yoy = (kolicina_q / kolicina_q_ly - 1) * 100)

## ---- weighted YoY + coefficient, PRIOR-year weights (year + 1L join) ----
coeff <- yoy |>
  dplyr::left_join(structures |> dplyr::select(year, code, str_within_aggr, str_aggr_total, str_total) |>
                     dplyr::mutate(year = year + 1L),
            by = c("year", "code")) |>
  dplyr::mutate(yoy_weighted_code = yoy * str_total) |>
  dplyr::mutate(stopnja_rasti_nad = sum(yoy_weighted_code, na.rm = TRUE), .by = c(year, quarter, nad)) |>
  dplyr::mutate(stopnja_rasti     = sum(yoy_weighted_code, na.rm = TRUE), .by = c(year, quarter)) |>
  dplyr::mutate(koeficient = 1 + stopnja_rasti / 100)

## ---- assemble: original rows + imputed synthetic rows, broadcast analytics ----
final_table <- dplyr::bind_rows(monthly_orig, imputed_rows) |>
  dplyr::left_join(coeff |> dplyr::select(year, quarter, code,
                                          kolicina_q, kolicina_q_ly,
                                          str_within_aggr, str_aggr_total, str_total,
                                          yoy, yoy_weighted_code,
                                          stopnja_rasti_nad, stopnja_rasti, koeficient),
                   by = c("year", "quarter", "code")) |>
  dplyr::relocate(period_id, date, year, month, quarter, koda_orig, code, nad,
                  imputed, kolicina, znesek) |>
  dplyr::arrange(date, nad, code) |>
  dplyr::mutate(quarter_id = paste0(year, "Q", quarter)) |>
  dplyr::relocate(quarter_id, .after = date)

kolone <- tibble::tribble(
  ~staro,              ~novo,                              ~entiteta,     ~cas, ~leto_ref,  ~aditivnost,  ~opis,
  "period_id",         "obdobje",                          "-",           "M",  "-",        "-",          "Mesečna oznaka obdobja (npr. 2025M09).",
  "date",              "datum",                            "-",           "M",  "-",        "-",          "Datum (prvi dan v mesecu).",
  "quarter_id",        "kvartal_oznaka",                   "-",           "Q",  "-",        "-",          "Oznaka četrtletja (npr. 2026Q3) za vrtilne tabele — preprečuje napačno seštevanje po letu.",
  "year",              "leto",                             "-",           "-",  "-",        "-",          "Leto.",
  "month",             "mesec",                            "-",           "M",  "-",        "-",          "Mesec (1-12).",
  "quarter",           "kvartal",                          "-",           "Q",  "-",        "-",          "Četrtletje (1-4).",
  "koda_orig",         "izdelek",                          "izdelek",     "-",  "-",        "-",          "Šifra izvornega izdelka (najnižja raven). Pri imputiranih vrsticah NA.",
  "code",              "skupina",                          "skupina",     "-",  "-",        "-",          "Konsolidirana skupina (10 skupin v izračunu, npr. cigarete, bencin).",
  "nad",               "nadskupina",                       "nadskupina",  "-",  "-",        "-",          "Raven agregacije: Alkohol, Tobak ali Energent.",
  "imputed",           "imputirano",                       "-",           "M",  "-",        "-",          "TRUE = imputirana vrstica (manjkajoči 3. mesec četrtletja).",
  "kolicina",          "kolicina_m",                       "izdelek",     "M",  "tekoče",   "aditivno",   "Mesečna količina izvornega izdelka (surova). Pri imputiranih vrsticah imputirana količina skupine.",
  "znesek",            "znesek_m",                         "izdelek",     "M",  "tekoče",   "aditivno",   "Mesečni znesek trošarine izvornega izdelka (surov).",
  "kolicina_q",        "kolicina_q",                       "skupina",     "Q",  "tekoče",   "neaditivno", "Četrtletna količina skupine (vsota mesecev). Ponovljena po vrsticah skupine.",
  "kolicina_q_ly",     "kolicina_q_lani",                  "skupina",     "Q",  "prejšnje", "neaditivno", "Četrtletna količina skupine, isto četrtletje lani.",
  "str_within_aggr",   "delez_skupina_v_nadskupini_lani",  "skupina",     "L",  "prejšnje", "neaditivno", "Delež skupine znotraj nadskupine po znesku, lani (letno).",
  "str_aggr_total",    "delez_nadskupina_v_skupaj_lani",   "nadskupina",  "L",  "prejšnje", "neaditivno", "Delež nadskupine v celotnem znesku, lani (letno).",
  "str_total",         "utez_skupina_lani",                "skupina",     "L",  "prejšnje", "neaditivno", "Delež skupine v celotnem znesku, lani (letno) = utež za ponderiranje.",
  "yoy",               "medletna_rast_skupina_q",          "skupina",     "Q",  "tekoče",   "neaditivno", "Medletna stopnja rasti količine skupine za četrtletje (%), NEponderirana.",
  "yoy_weighted_code", "ponderirani_prispevek_skupina_q",  "skupina",     "Q",  "tekoče",   "neaditivno", "Ponderirani prispevek skupine = medletna_rast_skupina_q x utez_skupina_lani.",
  "stopnja_rasti_nad", "ponderirana_medletna_rast_nadskupina_q", "nadskupina", "Q", "tekoče", "neaditivno", "Ponderirana medletna rast nadskupine (vsota prispevkov skupin), %.",
  "stopnja_rasti",     "ponderirana_medletna_rast_skupaj_q", "skupaj",    "Q",  "tekoče",   "neaditivno", "Skupna ponderirana medletna rast (vsota vseh prispevkov), %.",
  "koeficient",        "koeficient_q",                     "skupaj",      "Q",  "tekoče",   "neaditivno", "Končni koeficient = 1 + ponderirana_medletna_rast_skupaj_q / 100 (ena vrednost na četrtletje)."
)
## ---- preimenovanje + vrstni red ----
final_table_named <- final_table |>
  dplyr::rename(dplyr::all_of(stats::setNames(kolone$staro, kolone$novo))) |>
  dplyr::select(dplyr::all_of(kolone$novo))

## ---- list metapodatkov ----
metapodatki <- kolone |>
  dplyr::select(kolona = novo, entiteta, cas, leto_ref, aditivnost, opis)

to_utf8 <- function(df) {
  df[] <- lapply(df, \(x) if (is.character(x)) iconv(x, "windows-1250", "UTF-8") else x)
  df
}
metapodatki       <- to_utf8(metapodatki)
final_table_named <- to_utf8(final_table_named)

# --------  WRITING TO EXCEL ---------------------------------------------------
wb <- openxlsx2::wb_load(final_path)

n <- nrow(final_table_named)
k <- ncol(final_table_named)

# 1. capture per-column cell styles (number formats etc.) from the old first data row
sty <- openxlsx2::wb_get_cell_style(
  wb, sheet = "raw",
  dims = openxlsx2::wb_dims(rows = 2, cols = seq_len(k))
)

# 2. keep the sheet (widths, position, pivot source link survive); replace table + CF only
wb <- wb |>
  openxlsx2::wb_remove_tables(sheet = "raw", table = "datatable", remove_data = TRUE) |>
  openxlsx2::wb_remove_conditional_formatting(sheet = "raw") |>
  openxlsx2::wb_add_data_table(
    sheet = "raw", x = final_table_named, table_name = "datatable",
    start_col = 1, start_row = 1, table_style = "TableStyleMedium2"
  )

# 3. re-apply captured styles down the (possibly longer/shorter) data range
cols <- which(!is.na(sty) & nzchar(sty))
wb <- Reduce(
  \(w, j) openxlsx2::wb_set_cell_style(
    w, sheet = "raw",
    dims  = openxlsx2::wb_dims(rows = 2:(n + 1), cols = j),
    style = sty[[j]]
  ),
  cols, init = wb
)

# 4. conditional formatting on the new range
wb <- wb |>
  openxlsx2::wb_add_dxfs_style(name = "pinkRow",
                               bg_fill = openxlsx2::wb_color(hex = "FFFFC0CB")) |>
  openxlsx2::wb_add_conditional_formatting(
    sheet = "raw",
    dims  = openxlsx2::wb_dims(rows = 2:(n + 1), cols = seq_len(k)),
    rule  = "$I2", style = "pinkRow"
  )

# 5. metadata only if missing
if (!"metapodatki" %in% openxlsx2::wb_get_sheet_names(wb)) {
  wb <- wb |>
    openxlsx2::wb_add_worksheet("metapodatki") |>
    openxlsx2::wb_add_data(sheet = "metapodatki", x = metapodatki)
}

openxlsx2::wb_save(wb, final_path, overwrite = TRUE)

#
# wb <- openxlsx2::wb_load(final_path) |>
#   # register the named style ONCE on the workbook
#   openxlsx2::wb_add_dxfs_style(
#     name     = "pinkRow",
#     bg_fill  = openxlsx2::wb_color(hex = "FFFFC0CB")
#   )
#
# # preserve original sheet position
# sheet_pos <- match("raw", wb$get_sheet_names())
#
# # remove old sheet (also clears its CF rules)
# if (!is.na(sheet_pos)) {
#   wb <- openxlsx2::wb_remove_worksheet(wb, sheet = "raw")
# }
#
# wb <- wb |>
#   openxlsx2::wb_add_worksheet("raw") |>
#   openxlsx2::wb_add_data_table(
#     sheet = "raw",
#     x     = final_table_named,
#     table_name = "datatable",
#     start_col = 1,
#     start_row = 1,
#     table_style = "TableStyleMedium2") |>
#   openxlsx2::wb_add_conditional_formatting(
#     sheet = "raw",
#     dims  = openxlsx2::wb_dims(rows = 2:(nrow(final_table) + 1), cols = 1:ncol(final_table)),
#     rule  = "$I2",
#     style = "pinkRow"          # <- string name, not a style object
#   ) |>
#   openxlsx2::wb_add_data(sheet = "metapodatki", x = metapodatki)
#
# # test next time for july!!!
# # # after wb_load(), before wb_save()
# # wb$pivotDefinitions <- vapply(wb$pivotDefinitions, function(xml) {
# #   if (grepl("refreshOnLoad=", xml, fixed = TRUE)) {
# #     sub('refreshOnLoad="[^"]*"', 'refreshOnLoad="1"', xml)
# #   } else {
# #     sub("(<pivotCacheDefinition\\b)", '\\1 refreshOnLoad="1"', xml)
# #   }
# # }, character(1))
#
# # save final
# openxlsx2::wb_save(wb, final_path, overwrite = TRUE)
#
