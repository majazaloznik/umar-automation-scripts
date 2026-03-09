library(UMARaccessR)
library(dplyr)
library(tidyr)
library(openxlsx2)

message("Running gt & eo grafi update on ", Sys.Date(), "\n")

con <- DBI::dbConnect(RPostgres::Postgres(),
                      dbname = "platform",
                      host = "192.168.38.21",
                      port = 5432,
                      user = "majaz",
                      password = Sys.getenv("PG_MZ_PSW"),
                      client_encoding = "utf8")


load_wb <- function(filename){
  path <- paste0("\\\\192.168.38.7\\data$\\",
                 "GT\\SLIKE\\GT slike avtomatizirane\\",
                 filename)

  openxlsx2::wb_load(path)
}

load_wb_eo <- function(filename){
  path <- paste0("\\\\192.168.38.7\\data$\\",
                 "EO\\EO slike avtomatizirane\\",
                 filename)

  openxlsx2::wb_load(path)
}

write_wb <- function(wb, raw){
  message("Data available up to ", tail(raw$period_id, 1))
wb |>
  openxlsx2::wb_remove_tables(sheet = "podatki", table = "datatable") |>
  openxlsx2::wb_add_data_table(x = raw, table_name = "datatable") |>
  openxlsx2::wb_set_col_widths(sheet = "podatki", cols = 1, widths = 10) |>  # period_id
  openxlsx2::wb_set_col_widths(sheet = "podatki", cols = 2:ncol(raw), widths = 15) |>
  openxlsx2::wb_add_numfmt(sheet = "podatki", dims = "A2:A1000", numfmt = "MMM-YY") # Generous range
}

try_save <- function(filename){
  timestamp <- format(Sys.time(), "%Y-%m-%d_%H-%M-%S")
  original_path <- paste0("\\\\192.168.38.7\\data$\\",
                          "GT\\SLIKE\\GT slike avtomatizirane\\",
                          filename)

  backup_path <- sub("\\.xlsx$", paste0("_", timestamp, ".xlsx"), original_path)

  # Try to save, if fails, use backup path
  tryCatch({
    wb_save(wb, original_path)
    message(filename, " saved successfully to original location")
  }, error = function(e) {
    message("Could not save to original file, likely opened by another user")
    message("Error was: ", e$message)
    message("Saving to backup location: ", backup_path)
    wb_save(wb, backup_path)
    message(filename, " File saved successfully to backup location")
  })
}

try_save_eo <- function(filename){
  timestamp <- format(Sys.time(), "%Y-%m-%d_%H-%M-%S")
  original_path <- paste0("\\\\192.168.38.7\\data$\\",
                          "EO\\EO slike avtomatizirane\\",
                          filename)

  backup_path <- sub("\\.xlsx$", paste0("_", timestamp, ".xlsx"), original_path)

  # Try to save, if fails, use backup path
  tryCatch({
    wb_save(wb, original_path)
    message(filename, " saved successfully to original location")
  }, error = function(e) {
    message("Could not save to original file, likely opened by another user")
    message("Error was: ", e$message)
    message("Saving to backup location: ", backup_path)
    wb_save(wb, backup_path)
    message(filename, " File saved successfully to backup location")
  })
}

process_codes_vectorized <- function(codes, con, schema = "platform") {
  codes |>
    purrr::map(\(code) {
      vin <- sql_get_vintage_from_series_code(con, code, schema = schema)
      sql_get_data_points_from_vintage(con, vin, schema) |>
        dplyr::rename(!!code := value)
    }) |>
    purrr::reduce(dplyr::full_join, by = "period_id")
}

rebase_multiple <- function(data, value_cols, period_col = "period_id", base_year) {
  data <- data |>
    dplyr::mutate(year = as.integer(substr(!!rlang::sym(period_col), 1, 4)))

  data |>
    dplyr::mutate(dplyr::across(
      dplyr::all_of(value_cols),
      \(x) {
        base_mean <- mean(x[data$year == base_year], na.rm = TRUE)
        (x / base_mean) * 100
      }
    )) |>
    dplyr::select(-year)
}

rebase_multiple_m <- function(data, value_cols, period_col = "period_id", base_month) {
  data |>
    dplyr::mutate(dplyr::across(
      dplyr::all_of(value_cols),
      \(x) {
        base_value <- x[data[[period_col]] == base_month]
        if (length(base_value) == 0 || is.na(base_value)) {
          return(rep(NA_real_, length(x)))
        }
        (x / base_value) * 100
      }
    ))
}

rolling_mean <- function(data, value_cols, period_col = "period_id", k = 3,
                         fill = NA, align = "right") {
  data |>
    dplyr::mutate(dplyr::across(
      dplyr::all_of(value_cols),
      \(x) zoo::rollmean(x, k = k, fill = fill, align = align)
    ))
}

rolling_mean_m100 <- function(data, value_cols, period_col = "period_id", k = 3,
                              fill = NA, align = "right") {
  data |>
    dplyr::mutate(dplyr::across(
      dplyr::all_of(value_cols),
      \(x) zoo::rollmean(x, k = k, fill = fill, align = align) * 100 - 100
    ))
}

m100 <- function(data, value_cols) {
  data |>
    dplyr::mutate(dplyr::across(
      dplyr::all_of(value_cols),
      \(x)  x * 100 - 100
    ))
}


rolling_sum <- function(data, value_cols, period_col = "period_id", k = 12,
                        fill = NA, align = "right") {
  data |>
    dplyr::mutate(dplyr::across(
      dplyr::all_of(value_cols),
      \(x) zoo::rollsum(x, k = k, fill = fill, align = align)
    ))
}



deflate <- function(data, value_cols, inflation = "SURS--0400608S--TOT--2--M") {
  data |>
    dplyr::mutate(dplyr::across(
      dplyr::all_of(value_cols),
      \(x) x / .data[[inflation]]
    ))
}

aggregate_to_quarters <- function(data, value_cols, period_col = "period_id", aggr_func = mean) {
  data <- data |>
    dplyr::mutate(
      year = as.integer(substr(!!rlang::sym(period_col), 1, 4)),
      month = as.integer(substr(!!rlang::sym(period_col), 6, 7)),
      quarter = paste0(year, "Q", ceiling(month / 3))
    )

  data |>
    dplyr::group_by(quarter) |>
    dplyr::summarise(dplyr::across(
      dplyr::all_of(value_cols),
      \(x) aggr_func(x, na.rm = TRUE)
    )) |>
    dplyr::ungroup() |>
    dplyr::rename(!!period_col := quarter)
}
incomplete_quarters_note <- function(data, value_cols, period_col = "period_id", lang = "sl") {
  month_names_sl <- c("januar", "februar", "marec", "april", "maj", "junij",
                      "julij", "avgust", "september", "oktober", "november", "december")
  month_names_en <- c("January", "February", "March", "April", "May", "June",
                      "July", "August", "September", "October", "November", "December")

  month_names <- if (lang == "sl") month_names_sl else month_names_en

  data <- data |>
    dplyr::mutate(
      year = as.integer(substr(!!rlang::sym(period_col), 1, 4)),
      month = as.integer(substr(!!rlang::sym(period_col), 6, 7)),
      quarter = paste0(year, "Q", ceiling(month / 3))
    )

  purrr::map(value_cols, \(col) {
    incomplete <- data |>
      dplyr::filter(!is.na(!!rlang::sym(col))) |>
      dplyr::group_by(quarter) |>
      dplyr::summarise(
        months = list(month),
        n_months = dplyr::n(),
        .groups = "drop"
      ) |>
      dplyr::filter(n_months < 3) |>
      dplyr::pull(months) |>
      unlist()

    if (length(incomplete) == 0) NA_character_ else month_names[incomplete]
  })
}


yoy_growth <- function(data, value_cols, period_col = "period_id", n = 12) {
  data |>
    dplyr::mutate(dplyr::across(
      dplyr::all_of(value_cols),
      \(x) (x / dplyr::lag(x, n = n) - 1) * 100
    ))
}

filter_ten_years <- function(df, period_col = "period_id") {
  max_date <- max(df[[period_col]], na.rm = TRUE)
  max_year <- lubridate::year(max_date)
  start_date <- lubridate::make_date(max_year - 10, 1, 1)

  dplyr::filter(df,
                .data[[period_col]] >= start_date,
                .data[[period_col]] <= max_date)
}
