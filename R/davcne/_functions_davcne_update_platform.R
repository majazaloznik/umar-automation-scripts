################################################################################
# Functions for davcne-platform-update.R
# Monthly aggregates of the davcne tax register (davcni_racuni) -> platform
################################################################################

# one definition of the 6 tables, shared by registration and import
davcne_tables <- tibble::tribble(
  ~level,    ~table_name,                                                 ~dimensions,
  "agregat", "Dav\u010dne blagajne - znesek, skupaj",                     "agregat",
  "L1",      "Dav\u010dne blagajne - znesek po SKD, L1 podro\u010dja",    "SKD",
  "L2",      "Dav\u010dne blagajne - znesek po SKD, L2 oddelki",          "SKD",
  "L3",      "Dav\u010dne blagajne - znesek po SKD, L3 skupine",          "SKD",
  "L4",      "Dav\u010dne blagajne - znesek po SKD, L4 razredi",          "SKD",
  "L5",      "Dav\u010dne blagajne - znesek po SKD, L5 podrazredi",       "SKD"
)

#' Read davcni_racuni and aggregate to complete months, long format
#'
#' Complete month = every calendar day present. Totals from 2019, SKD levels
#' from 2025 (SKD 2025 classification).
#'
#' @return data frame: period (Date), level, code, text, value
read_davcne_long <- function(con_d) {
  months_ok <- DBI::dbGetQuery(con_d, "
    SELECT date_trunc('month', datum)::date AS period
    FROM public.davcni_racuni
    GROUP BY 1
    HAVING count(DISTINCT datum) =
           extract(day FROM date_trunc('month', min(datum)) + interval '1 month - 1 day')")$period

  agg <- DBI::dbGetQuery(con_d, "
    SELECT date_trunc('month', datum)::date AS period, skd_alpha, skd_5,
           coalesce(\"filter\" = '1', false) AS filt, sum(znesek)::float8 AS znesek
    FROM public.davcni_racuni
    GROUP BY 1, 2, 3, 4")
  agg <- agg[agg$period %in% months_ok, ]
  if (nrow(agg) == 0) stop("No complete months in davcni_racuni")

  totals <- agg |>
    dplyr::summarise(TOT = sum(znesek), FILT = sum(znesek[filt]), .by = period) |>
    tidyr::pivot_longer(-period, names_to = "code", values_to = "value") |>
    dplyr::mutate(level = "agregat", text = code)

  skd <- agg |>
    dplyr::filter(period >= as.Date("2025-01-01")) |>
    dplyr::mutate(L1 = skd_alpha,
                  L2 = substr(skd_5, 1, 2), L3 = substr(skd_5, 1, 4),
                  L4 = substr(skd_5, 1, 5), L5 = skd_5) |>
    dplyr::mutate(dplyr::across(L2:L5, \(x) ifelse(skd_alpha == "0", "0", x))) |>
    tidyr::pivot_longer(L1:L5, names_to = "level", values_to = "text") |>
    dplyr::summarise(value = sum(znesek), .by = c(period, level, text)) |>
    dplyr::mutate(code = gsub(".", "", text, fixed = TRUE))

  dplyr::bind_rows(totals, skd)
}

#' Metadata rows for every (level, code) present in `long`
davcne_metadata_rows <- function(long, tables = davcne_tables,
                                 author = "Umar Data Bot",
                                 source = "FURS, UMAR", unit = "eur") {
  long |>
    dplyr::distinct(level, code, text) |>
    dplyr::mutate(text = dplyr::case_when(
      code == "TOT"  ~ "skupaj",
      code == "FILT" ~ "skupaj, filtrirano",
      code == "0"    ~ "0 - neopredeljeno",
      .default = text)) |>
    dplyr::inner_join(tables, by = "level") |>
    dplyr::arrange(match(level, tables$level), code) |>
    dplyr::transmute(
      source, author, table_name, dimensions,
      dimension_levels_text = text,
      dimension_levels_code = code,
      unit, interval = "M",
      series_name = ifelse(dimensions == "SKD",
                           paste("Dav\u010dne blagajne - znesek, SKD", text), NA_character_),
      table_code  = NA_character_,
      series_code = NA_character_)
}

#' Append unregistered (table, code) rows to the metadata file and register them
#'
#' @return codes of newly registered series (empty most months)
register_new_davcne_series <- function(long, meta_file, con, schema = "platform") {
  existing <- openxlsx::read.xlsx(meta_file, sheet = "timeseries")
  new_rows <- davcne_metadata_rows(long) |>
    dplyr::anti_join(existing, by = c("table_name", "dimension_levels_code"))
  if (nrow(new_rows) == 0) return(invisible(character(0)))

  UMARbotR::log_msg("Registering %d new series: %s", nrow(new_rows),
                    toString(paste(new_rows$table_name, new_rows$dimension_levels_code, sep = " / ")))
  existing[] <- lapply(existing, \(x) if (is.logical(x)) as.character(x) else x)  # all-NA cols read as logical
  UMARfetchR::update_structure_excel(meta_file, dplyr::bind_rows(existing, new_rows))
  UMARfetchR::main_structure(meta_file, con, schema, keep_vintage = FALSE)
  invisible(new_rows$dimension_levels_code)
}

#' (level, code) -> series_code and table_code, from the metadata file
davcne_code_map <- function(meta_file, tables = davcne_tables) {
  openxlsx::read.xlsx(meta_file, sheet = "timeseries") |>
    dplyr::inner_join(tables, by = c("table_name", "dimensions")) |>
    dplyr::select(level, code = dimension_levels_code, series_code, table_code)
}

#' Wide data frame per level, ready for import_data_df()
davcne_wide_tables <- function(long, code_map) {
  joined <- long |>
    dplyr::left_join(code_map, by = c("level", "code"))
  if (anyNA(joined$series_code))
    stop("Unregistered series: ",
         toString(unique(paste(joined$level, joined$code)[is.na(joined$series_code)])))
  joined |>
    dplyr::select(period, level, series_code, value) |>
    (\(d) split(d, d$level))() |>
    purrr::map(\(x) x |>
                 dplyr::select(-level) |>
                 tidyr::pivot_wider(names_from = series_code, values_from = value) |>
                 dplyr::arrange(period) |>
                 as.data.frame())
}
