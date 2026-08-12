################################################################################
# GT tabele — monthly data pipeline
# Refactored for: robust file discovery (naming drift tolerant), per-block
# tryCatch so one missing/renamed file or one failed DB series doesn't kill
# the run, and a run log / email summary of what failed.
################################################################################

library(UMARaccessR)
library(purrr)
library(dplyr)
library(lubridate)
library(tidyr)
library(openxlsx2)
library(stringr)
library(httr)
library(readr)
library(gmailr)

setwd("\\\\192.168.38.7\\public$\\Avtomatizacija\\umar-automation-scripts\\")

################################################################################
# Logging + generic error-tolerance helpers
################################################################################

dir.create("logs", showWarnings = FALSE)

# Anything that fails inside safe_fetch() gets appended here for the
# end-of-run summary (printed + emailed).
issue_log <- character()

log_msg <- function(...) {
  line <- sprintf("[%s] %s", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), sprintf(...))
  base::message(line)
}

# Runs `expr`; on error, logs it, records it in issue_log, and returns
# `fallback` instead of crashing the script.
safe_fetch <- function(label, expr, fallback = NULL) {
  tryCatch({
    out <- expr
    log_msg("OK: %s", label)
    out
  }, error = function(e) {
    msg <- sprintf("%s -- %s", label, conditionMessage(e))
    log_msg("FAILED: %s", msg)
    issue_log <<- c(issue_log, msg)
    fallback
  })
}

# --- Network-drive file discovery -------------------------------------------
# Folders sometimes get named "Registrirani" vs "reg" etc. — don't hardcode
# filenames. There's one file per folder per month, so just take whatever's
# there (matching extension, optionally a keyword) and log what was used.

latest_year_dir <- function(path) {
  dirs <- list.dirs(path, full.names = FALSE, recursive = FALSE)
  dirs <- dirs[grep("^Leto ", dirs)]
  if (length(dirs) == 0) stop(sprintf("No 'Leto *' folders in: %s", path))
  dirs[which.max(as.numeric(stringr::str_extract(dirs, "\\d{4}")))]
}

latest_numeric_dir <- function(path, digits = "\\d{2}") {
  dirs <- list.dirs(path, full.names = FALSE, recursive = FALSE)
  if (length(dirs) == 0) stop(sprintf("No subfolders in: %s", path))
  dirs[which.max(as.numeric(stringr::str_extract(dirs, digits)))]
}

find_data_file <- function(folder, pattern = "\\.xlsx?$") {
  files <- list.files(folder, pattern = pattern, full.names = TRUE, ignore.case = TRUE)
  files <- files[!grepl("^~\\$", basename(files))]  # drop Excel lock files
  if (length(files) == 0) stop(sprintf("No file matching '%s' in: %s", pattern, folder))
  if (length(files) > 1) {
    log_msg("WARNING: multiple matches in %s -- using %s", folder, basename(files[1]))
  }
  log_msg("Using file: %s", files[1])
  files[1]
}

# base_path/Leto YYYY/MM/<the one file>
latest_month_file <- function(base_path, pattern = "\\.xlsx?$") {
  yr <- latest_year_dir(base_path)
  mo <- latest_numeric_dir(file.path(base_path, yr))
  find_data_file(file.path(base_path, yr, mo), pattern)
}

# base_path/Leto YYYY/Q/<file matching pattern>  (used by the ILO series,
# where a folder can contain more than one file, hence the keyword pattern)
latest_quarter_file <- function(base_path, pattern) {
  yr <- latest_year_dir(base_path)
  q  <- latest_numeric_dir(file.path(base_path, yr), digits = "\\d")
  find_data_file(file.path(base_path, yr, q), pattern)
}

# NA-filled row(s) with the same column structure as `template`, used as the
# fallback when a fetch fails, so downstream bind_rows()/cell writes keep
# their expected row count instead of silently shrinking.
na_template <- function(codes, template) {
  template[0, ] |>
    dplyr::bind_rows(tibble::tibble(code = codes)) |>
    dplyr::select(dplyr::any_of(names(template)))
}

################################################################################
# Database connection
################################################################################

con <- tryCatch(
  DBI::dbConnect(RPostgres::Postgres(),
                 dbname = "platform", host = "192.168.38.21", port = 5432,
                 user = "majaz", password = Sys.getenv("PG_MZ_PSW"),
                 client_encoding = "utf8"),
  error = function(e) {
    log_msg("FATAL: cannot connect to database -- %s", conditionMessage(e))
    stop(e)  # nothing downstream works without this, so this one stays fatal
  }
)
DBI::dbExecute(con, "set search_path to platform")

################################################################################
# Series fetch helpers (DB)
################################################################################

# Fetches one series; returns NULL (via safe_fetch) instead of throwing, so
# one bad/renamed/retired series code doesn't take out the whole group.
fetch_series <- function(code, con, schema, date_fn = identity) {
  safe_fetch(
    label = sprintf("series fetch: %s", code),
    expr = {
      vin <- UMARaccessR::sql_get_vintage_from_series_code(con, code, schema = schema)
      list(
        df = UMARaccessR::sql_get_data_points_from_vintage(con, vin, schema) |>
          dplyr::rename(!!code := value),
        date = date_fn(UMARaccessR::sql_get_date_published_from_vintage(vin, con, schema))
      )
    },
    fallback = NULL
  )
}

process_codes_vectorized <- function(codes, con, schema = "platform", stotka = FALSE) {
  results <- codes |> purrr::map(~ fetch_series(.x, con, schema))
  ok <- !purrr::map_lgl(results, is.null)
  if (!all(ok)) {
    log_msg("process_codes_vectorized: %d/%d codes failed: %s",
            sum(!ok), length(codes), paste(codes[!ok], collapse = ", "))
  }
  results_ok <- results[ok]

  if (length(results_ok) == 0) {
    return(tibble::tibble(code = codes, Zadnja = as.Date(NA)))
  }

  dates <- purrr::map(results_ok, "date") |>
    unlist() |>
    lubridate::as_datetime(tz = "CET") |>
    lubridate::as_date()

  combined_df <- results_ok |>
    purrr::map("df") |>
    purrr::reduce(dplyr::full_join, by = "period_id") |>
    dplyr::slice_tail(n = 6) |>
    dplyr::mutate(period_id = sub("Q", " Q", period_id),
                  period_id = sub("M0", "M", period_id),
                  period_id = sub("M", " m ", period_id)) |>
    tidyr::pivot_longer(-period_id, names_to = "code", values_to = "value") |>
    ({if (stotka) \(x) x |> dplyr::mutate(value = value - 100) else \(x) x})() |>
    tidyr::pivot_wider(names_from = "period_id", values_from = "value") |>
    dplyr::mutate(Zadnja = as.Date(dates))

  # pad back in any codes that failed, in their original position
  missing_codes <- setdiff(codes, combined_df$code)
  if (length(missing_codes) > 0) {
    combined_df <- combined_df |> dplyr::bind_rows(tibble::tibble(code = missing_codes))
  }

  combined_df |>
    dplyr::arrange(match(code, codes)) |>
    dplyr::relocate(Zadnja, .after = code)
}

process_codes_rates <- function(codes, con, schema = "platform") {
  results <- codes |> purrr::map(~ fetch_series(
    .x, con, schema,
    date_fn = function(d) lubridate::as_date(lubridate::with_tz(d), "CET")
  ))
  ok <- !purrr::map_lgl(results, is.null)
  if (!all(ok)) {
    log_msg("process_codes_rates: %d/%d codes failed: %s",
            sum(!ok), length(codes), paste(codes[!ok], collapse = ", "))
  }
  results_ok <- results[ok]

  # which derived series we want, and where each comes from: mgr off the
  # seasonally-adjusted series, yoy off the original series
  wanted <- tibble::tibble(
    raw_code = c("SURS--1701111S--sa--C[skd]--M",   "SURS--1701111S--orig--C[skd]--M",
                 "SURS--1957408S--SA--CC--M",        "SURS--1957408S--O--CC--M",
                 "SURS--2001303S--2--2--G--M",       "SURS--2001303S--2--1--G--M",
                 "SURS--2080006S--2--H+I+J+L+M+N--M","SURS--2080006S--1--H+I+J+L+M+N--M"),
    transform = c("mgr", "yoy", "mgr", "yoy", "mgr", "yoy", "mgr", "yoy")
  ) |>
    dplyr::mutate(out_code = paste0(raw_code, "_", transform))

  if (length(results_ok) == 0) {
    return(wanted |> dplyr::transmute(code = out_code, Zadnja = as.Date(NA)))
  }

  dates <- purrr::map(results_ok, "date") |> unlist()

  combined_df <- results_ok |>
    purrr::map("df") |>
    purrr::reduce(dplyr::full_join, by = "period_id") |>
    dplyr::mutate(
      dplyr::across(
        dplyr::where(is.numeric),
        list(mgr = ~(. / dplyr::lag(.) - 1) * 100,
             yoy = ~(. / dplyr::lag(., 12) - 1) * 100),
        .names = "{.col}_{.fn}"
      )
    ) |>
    dplyr::slice_tail(n = 6) |>
    dplyr::select(period_id, dplyr::any_of(wanted$out_code)) |>
    dplyr::mutate(period_id = sub("M0", "M", period_id),
                  period_id = sub("M", " m ", period_id)) |>
    tidyr::pivot_longer(-period_id, names_to = "code", values_to = "value") |>
    tidyr::pivot_wider(names_from = "period_id", values_from = "value") |>
    dplyr::mutate(Zadnja = if (length(dates) > 0) as.Date(max(dates, na.rm = TRUE)) else as.Date(NA))

  missing <- setdiff(wanted$out_code, combined_df$code)
  if (length(missing) > 0) {
    log_msg("process_codes_rates: output columns padded with NA: %s", paste(missing, collapse = ", "))
    combined_df <- combined_df |> dplyr::bind_rows(tibble::tibble(code = missing))
  }

  combined_df |>
    dplyr::arrange(match(code, wanted$out_code)) |>
    dplyr::relocate(Zadnja, .after = code)
}
# NOTE: Zadnja above is a single "latest publish date" for the whole table
# rather than per-row, because under partial failure the raw-code dates and
# the derived-column rows can no longer be reliably paired positionally.
# This is a deliberate behaviour change from the original (which set Zadnja
# positionally) -- flagging it since it's a business-logic-relevant choice,
# not just a style change.

################################################################################
# Series fetch helper (network-drive Excel files)
################################################################################

rates_from_excel <- function(path, code, month = TRUE) {
  da_sa <- readxl::read_excel(path, sheet = "SA", col_names = c("period_id", "value_sa")) |>
    dplyr::filter(!is.na(period_id)) |>
    dplyr::mutate(value_sa = as.numeric(value_sa),
                  mgr = (value_sa / dplyr::lag(value_sa) - 1) * 100) |>
    dplyr::slice_tail(n = 6) |>
    dplyr::select(period_id, mgr) |>
    dplyr::mutate(period_id = paste(lubridate::year(period_id), "m", lubridate::month(period_id))) |>
    tidyr::pivot_wider(names_from = "period_id", values_from = "mgr") |>
    dplyr::mutate(code = paste0(code, "_mgr")) |>
    dplyr::relocate(code)

  lag_n <- if (month) 12 else 4
  da_orig <- readxl::read_excel(path, sheet = "Orig", col_names = c("period_id", "value_orig")) |>
    dplyr::filter(!is.na(period_id)) |>
    dplyr::mutate(value_orig = as.numeric(value_orig),
                  yoy = (value_orig / dplyr::lag(value_orig, lag_n) - 1) * 100) |>
    dplyr::slice_tail(n = 6) |>
    dplyr::select(period_id, yoy) |>
    dplyr::mutate(period_id = paste(lubridate::year(period_id), "m", lubridate::month(period_id))) |>
    tidyr::pivot_wider(names_from = "period_id", values_from = "yoy") |>
    dplyr::mutate(code = paste0(code, "_yoy")) |>
    dplyr::relocate(code)

  da_sa |> dplyr::bind_rows(da_orig)
}

read_orig_only <- function(path) {
  readxl::read_excel(path, sheet = "Orig", col_names = c("period_id", "value_orig")) |>
    dplyr::filter(!is.na(period_id)) |>
    dplyr::mutate(value_orig = as.numeric(value_orig)) |>
    dplyr::slice_tail(n = 6) |>
    dplyr::mutate(period_id = paste(lubridate::year(period_id), "m", lubridate::month(period_id))) |>
    tidyr::pivot_wider(names_from = "period_id", values_from = "value_orig")
}

month_to_quarter <- function(month_str) {
  year <- stringr::str_extract(month_str, "\\d{4}")
  month_num <- as.numeric(stringr::str_extract(month_str, "\\d+$"))
  quarter <- ceiling(month_num / 3)
  paste(year, " Q", quarter, sep = "")
}

################################################################################
# Data series from the platform database
################################################################################

log_msg("start preparing SURS data from the database")

makro_slo <- c("SURS--0300230S--B1GQ--G1--Y--Q", "SURS--0300230S--B1GQ--GO4--N--Q",
               "SURS--0300230S--P31_S14_D--G1--Y--Q", "SURS--0300230S--P31_S14_D--G4--N--Q",
               "SURS--0300230S--P3_S13--G1--Y--Q", "SURS--0300230S--P3_S13--G4--N--Q",
               "SURS--0300230S--P5--G1--Y--Q", "SURS--0300230S--P5--G4--N--Q",
               "SURS--0300230S--P6--G1--Y--Q", "SURS--0300230S--P6--G4--N--Q",
               "SURS--0300230S--P7--G1--Y--Q", "SURS--0300230S--P7--G4--N--Q")

inflacija_slo <- c("SURS--H281S--1--M", "SURS--H281S--2--M")

indpro_slo <- c("SURS--0457201S--B_TO_E--01--M", "SURS--0457201S--B_TO_E--02--M")

za_rast_slo <- c("SURS--1701111S--sa--C[skd]--M", "SURS--1701111S--orig--C[skd]--M",
                 "SURS--1957408S--SA--CC--M", "SURS--1957408S--O--CC--M",
                 "SURS--2001303S--2--2--G--M", "SURS--2001303S--2--1--G--M",
                 "SURS--2080006S--2--H+I+J+L+M+N--M", "SURS--2080006S--1--H+I+J+L+M+N--M")

dolg_slo <- c("SURS--0314905S--B9--XDC_R_B1GQ--A", "SURS--0314905S--GD--XDC_R_B1GQ--A")

klima_slo <- "SURS--2855901S--1--2--M"

makro     <- process_codes_vectorized(makro_slo, con)
inflacija <- process_codes_vectorized(inflacija_slo, con, stotka = TRUE)
indpro    <- process_codes_vectorized(indpro_slo, con, stotka = TRUE)
rast      <- process_codes_rates(za_rast_slo, con)
dolg      <- process_codes_vectorized(dolg_slo, con)
klima     <- process_codes_vectorized(klima_slo, con)

inflacija <- klima[0, ] |> dplyr::bind_rows(inflacija) |> dplyr::select(dplyr::any_of(names(klima)))
indpro    <- klima[0, ] |> dplyr::bind_rows(indpro)    |> dplyr::select(dplyr::any_of(names(klima)))
rast      <- klima[0, ] |> dplyr::bind_rows(rast)      |> dplyr::select(dplyr::any_of(names(klima)))
indpro    <- indpro |> dplyr::bind_rows(rast)

log_msg("SURS data from the database ready")

log_msg("start preparing BS data from the database")
pl_b_slo <- c("BS--i_32_6ms--3--M", "BS--i_32_6ms--0--M")
pl_b <- process_codes_vectorized(pl_b_slo, con)
pl_b <- klima[0, ] |> dplyr::bind_rows(pl_b) |> dplyr::select(dplyr::any_of(names(klima)))

log_msg("start preparing Eurostat data from the database")
money_slo <- c("EUROSTAT--teimf200--USD--M")
money <- process_codes_vectorized(money_slo, con)
money <- klima[0, ] |> dplyr::bind_rows(money) |> dplyr::select(dplyr::any_of(names(klima)))

log_msg("start preparing ECB data from the database")
euribor_slo <- c("ECB--FM--U2--EUR--RT--MM--EURIBOR3MD_--HSTA--M")
euribor <- process_codes_vectorized(euribor_slo, con)
euribor <- klima[0, ] |> dplyr::bind_rows(euribor) |> dplyr::select(dplyr::any_of(names(klima)))

################################################################################
# Data series from Excel files on the network drives
################################################################################

log_msg("start preparing data from local drives")

# delovno aktivni --------------------------------------------------------
path_da <- "\\\\192.168.38.7\\public$\\DESEZONIRANJE/Trg dela/Delovno aktivni/Vsi/"
da <- safe_fetch(
  "da (Delovno aktivni)",
  { file <- latest_month_file(path_da); rates_from_excel(file, "da") },
  fallback = na_template(c("da_mgr", "da_yoy"), klima)
)
da <- klima[0, ] |> dplyr::bind_rows(da) |> dplyr::select(dplyr::any_of(names(klima)))

# brezposelni - stevilo ---------------------------------------------------
path_bp <- "\\\\192.168.38.7\\public$\\DESEZONIRANJE/Trg dela/Registrirani brezposelni/Stevilo/"
bp <- safe_fetch(
  "bp (Registrirani brezposelni - stevilo)",
  { file <- latest_month_file(path_bp); rates_from_excel(file, "bp") },
  fallback = na_template(c("bp_mgr", "bp_yoy"), klima)
)
da_bp <- da |> dplyr::bind_rows(bp) |> dplyr::select(dplyr::any_of(names(da)))

# brezposelni - stopnja ----------------------------------------------------
path_st <- "\\\\192.168.38.7\\public$\\DESEZONIRANJE/Trg dela/Registrirani brezposelni/Stopnje/Skupaj/"
st <- safe_fetch(
  "st (Registrirani brezposelni - stopnja)",
  { file <- latest_month_file(path_st); read_orig_only(file) },
  fallback = na_template(NA_character_, klima)
)
da_bp_st <- da_bp |> dplyr::bind_rows(st) |> dplyr::select(dplyr::any_of(names(da_bp)))

# ILO zaposleni -------------------------------------------------------------
path_ilo <- "\\\\192.168.38.7\\public$\\DESEZONIRANJE/Trg dela/ILO/Zaposleni/"
ilo <- safe_fetch(
  "ilo (ILO zaposleni)",
  {
    file <- latest_quarter_file(path_ilo, pattern = "^ILO zaposleni")
    out <- rates_from_excel(file, "ilo", month = FALSE)
    colnames(out)[2:7] <- month_to_quarter(colnames(out)[2:7])
    out
  },
  fallback = na_template(c("ilo_mgr", "ilo_yoy"), makro)
)
ilo <- makro[0, ] |> dplyr::bind_rows(ilo) |> dplyr::select(dplyr::any_of(names(makro)))

# ILO stopnja -----------------------------------------------------------
path_ilo_st <- "\\\\192.168.38.7\\public$\\DESEZONIRANJE/Trg dela/ILO/Stopnja brezposelnosti/"
ilo_st <- safe_fetch(
  "ilo_st (ILO stopnja brezposelnosti)",
  {
    file <- latest_quarter_file(path_ilo_st, pattern = "^Stopnja ILO brezposelnih")
    out <- read_orig_only(file)
    colnames(out)[2:7] <- month_to_quarter(colnames(out)[2:7])
    out
  },
  fallback = na_template(NA_character_, ilo)
)
ilo_both <- ilo |> dplyr::bind_rows(ilo_st) |> dplyr::select(dplyr::any_of(names(ilo)))

# uvoz izvoz --------------------------------------------------------------
path_ex <- "\\\\192.168.38.7\\public$\\DESEZONIRANJE/Zunanja trgovina/Realni izvoz blaga/"
ex <- safe_fetch(
  "ex (Realni izvoz blaga)",
  { file <- latest_month_file(path_ex); rates_from_excel(file, "ex") },
  fallback = na_template(c("ex_mgr", "ex_yoy"), klima)
)
ex <- pl_b |> dplyr::bind_rows(ex) |> dplyr::select(dplyr::any_of(names(klima)))

path_im <- "\\\\192.168.38.7\\public$\\DESEZONIRANJE/Zunanja trgovina/Realni uvoz blaga/"
im <- safe_fetch(
  "im (Realni uvoz blaga)",
  { file <- latest_month_file(path_im); rates_from_excel(file, "im") },
  fallback = na_template(c("im_mgr", "im_yoy"), klima)
)
im_ex <- ex |> dplyr::bind_rows(im) |> dplyr::select(dplyr::any_of(names(ex)))

# place -----------------------------------------------------------------
path_place <- "\\\\192.168.38.7\\public$\\Users/DRogan/GT/GT-place (REK).xlsx"
place <- safe_fetch(
  "place (GT-place REK)",
  {
    raw <- openxlsx2::read_xlsx(path_place, sheet = "tgg - tabela", rows = 25:33)
    raw[, (ncol(raw) - 6):ncol(raw)]
  },
  fallback = na_template(NA_character_, klima)
)
place <- klima[0, ] |> dplyr::bind_rows(place) |> dplyr::select(dplyr::any_of(names(klima)))

log_msg("Local data ready")

# Marjanove donosnosti ----------------------------------------------------
path_don <- "\\\\192.168.38.7\\public$\\Avtomatizacija/umar-automation-scripts/data/donosnosti/Donosnosti_10Ya.xlsx"
donosnosti <- safe_fetch(
  "donosnosti (Marjanove donosnosti)",
  {
    raw <- openxlsx2::read_xlsx(path_don, sheet = "Mesecno", start_row = 167, cols = 1:2, col_names = FALSE)
    year_rows <- which(grepl("^\\d{4}$", raw[[1]]))
    last_data_row <- max(which(!is.na(raw[[2]]) & raw[[2]] != ""))
    last_year_row <- max(year_rows[year_rows < last_data_row])
    last_year <- as.integer(raw[[1]][last_year_row])
    last_month <- last_data_row - last_year_row
    raw <- raw[-year_rows, ]
    last_6_rows <- (last_data_row - 5):last_data_row - length(year_rows)
    last_6_data <- raw[last_6_rows, 2]
    months <- (last_month - 5):last_month
    years <- ifelse(months <= 0, last_year - 1, last_year)
    months <- ifelse(months <= 0, months + 12, months)
    data.frame(period = paste(years, "m", months), value = as.numeric(last_6_data)) |>
      tidyr::pivot_wider(names_from = period, values_from = value) |>
      dplyr::mutate(code = NA, Zadnja = NA) |>
      dplyr::relocate(code, Zadnja)
  },
  fallback = na_template(NA_character_, klima)
)
donosnosti <- klima[0, ] |> dplyr::bind_rows(donosnosti) |> dplyr::select(dplyr::any_of(names(klima)))

################################################################################
# release dates - ZRSZ (manual, update zrsz_days once a year from
# https://www.ess.gov.si/partnerji/trg-dela/koledar-objav/)
################################################################################

zrsz_days <- c(8, 5, 5, 3, 7, 4, 3, 5, 3, 3, 5, 3)
reg_bp_datumi <- data.frame(datum = as.Date(paste0("2025-", 1:12, "-", zrsz_days))) |>
  dplyr::bind_rows(data.frame(datum = as.Date("2024-12-04"))) |>
  dplyr::filter(datum <= Sys.Date() | datum == min(datum[datum > Sys.Date()])) |>
  dplyr::filter(datum >= max(datum[datum <= Sys.Date()]) | datum > Sys.Date()) |>
  dplyr::arrange(datum) |>
  dplyr::pull(datum)

################################################################################
# release dates from SURS website
################################################################################

log_msg("start getting release calendar dates")

combine_broken_lines <- function(lines) {
  combined <- character(0)
  current <- ""
  for (line in lines) {
    current <- if (current == "") line else paste0(current, " ", line)
    if (stringr::str_count(current, ";") == 4) {
      combined <- c(combined, current)
      current <- ""
    }
  }
  if (current != "" && stringr::str_count(current, ";") == 4) combined <- c(combined, current)
  combined
}

clean_line <- function(text) {
  parts <- stringr::str_split(text, ";")[[1]]
  if (length(parts) != 4) return(NULL)
  parts[2] <- stringr::str_replace_all(parts[2], ";", "-")
  parts[4] <- stringr::str_replace_all(parts[4], ";", "-")
  parts[4] <- stringr::str_replace(parts[4], ";$", "")
  paste(parts, collapse = ";")
}

df <- safe_fetch(
  "SURS release calendar",
  {
    response <- httr::POST(
      url = "https://www.stat.si/statweb/File/ReleaseCalendarCsv",
      httr::add_headers("Accept-Language" = "en-GB,en-US;q=0.9", "Content-Type" = "text/csv")
    )
    raw_text <- rawToChar(httr::content(response, "raw"))
    raw_text <- iconv(raw_text, from = "windows-1250", to = "UTF-8", sub = "")
    lines <- stringr::str_split(raw_text, "\r\n|\n")[[1]]
    lines <- c(lines[1], lines[9001:length(lines)])

    combined_lines <- combine_broken_lines(lines)
    cleaned_lines <- sapply(combined_lines, clean_line)
    cleaned_lines <- names(cleaned_lines)
    cleaned_lines <- stringr::str_replace_all(cleaned_lines, ";$", "")

    header <- stringr::str_replace(lines[1], ";$", "")
    cleaned_text <- paste(c(header, cleaned_lines), collapse = "\n")

    readr::read_delim(I(cleaned_text), delim = ";", show_col_types = FALSE) |>
      dplyr::mutate(`Datum objave` = as.Date(`Datum objave`, format = "%d. %m. %Y")) |>
      dplyr::rename(datum = `Datum objave`, naslov = `Naslov objave`)
  },
  fallback = tibble::tibble(datum = as.Date(NA), naslov = NA_character_)
)

get_release_dates <- function(df, pattern) {
  df |>
    dplyr::filter(grepl(pattern, naslov)) |>
    dplyr::filter(datum <= Sys.Date() | datum == min(datum[datum > Sys.Date()])) |>
    dplyr::filter(datum >= max(datum[datum <= Sys.Date()]) | datum > Sys.Date()) |>
    dplyr::arrange(datum) |>
    dplyr::pull(datum)
}

makro_datumi     <- get_release_dates(df, "^Bruto doma\u010di proizvod, [1-4]+. \u010detrtletje [0-9]{4}")
im_ex_datumi     <- get_release_dates(df, "^Izvoz in uvoz blaga, [a-z]+ [0-9]{4}")
inflacija_datumi <- get_release_dates(df, "^Indeksi cen .ivljenjskih potreb..in, [a-z]+ [0-9]{4}")
place_datumi     <- get_release_dates(df, "^Pla.e zaposlenih pri pravnih osebah, [a-z]+ [0-9]{4}")
da_datumi        <- get_release_dates(df, "^Delovno aktivno prebivalstvo, [a-z]+ [0-9]{4}")
ilo_datumi       <- get_release_dates(df, "^Aktivno in neaktivno prebivalstvo, [1-4]+. .etrtletje [0-9]{4}")
indpro_datumi    <- get_release_dates(df, "^Indeksi cen industrijskih proizvodov pri proizvajalcih, [a-z]+ [0-9]{4}")
pred_datumi      <- get_release_dates(df, "^Indeksi industrijske proizvodnje, [a-z]+ [0-9]{4}")
gradb_datumi     <- get_release_dates(df, "^Indeksi vrednosti opravljenih gradbenih del, [a-z]+ [0-9]{4}")
trg_datumi       <- get_release_dates(df, "^Prihodek od prodaje v trgovini na drobno, [a-z]+ [0-9]{4}")
trzna_datumi     <- get_release_dates(df, "^Indeks obsega v storitvenih dejavnostih in trgovini, [a-z]+ [0-9]{4}")
drzava_datumi    <- get_release_dates(df, "^Temeljni agregati sektorja .+[0-9]{4}.+[0-9]{4}$")
klima_datumi     <- get_release_dates(df, "^Gospodarska klima, [a-z]+ [0-9]{4}$")

log_msg("Release dates ready, start writing to file")

################################################################################
# write to excel table
################################################################################

file_configs <- list(
  list(path = "\\\\192.168.38.7\\data$\\GT/GT_tabele_ZA WORD_ne spreminjaj/GT_tabela_SI_angl.xlsx",
       lang = "en", update_text = "Last updated:"),
  list(path = "\\\\192.168.38.7\\data$\\GT/GT_tabele_ZA WORD_ne spreminjaj/GT_tabela_SI_slo.xlsx",
       lang = "sl", update_text = "Zadnja posodobitev:")
)

write_ok <- purrr::map_lgl(file_configs, function(config) {
  tryCatch({
    wb <- openxlsx2::wb_load(config$path)
    wb$clean_sheet(sheet = 1, dims = "B2:B58", styles = FALSE)
    wb$clean_sheet(sheet = 1, dims = "D1:J62", styles = FALSE)

    wb$add_data(sheet = "tabela", x = makro[2], dims = "B2", colNames = FALSE)
    wb$add_data(sheet = "tabela", x = makro[3:8], dims = "D1", na.strings = ":")

    wb$add_data(sheet = "tabela", x = im_ex[2], dims = "B15", colNames = FALSE)
    wb$add_data(sheet = "tabela", x = im_ex[3:8], dims = "D14", na.strings = ":")
    wb$add_data(sheet = "tabela", x = rep(im_ex_datumi[1], 4), colNames = FALSE, dims = "B17")

    wb$add_data(sheet = "tabela", colNames = FALSE, x = inflacija[2], dims = "B22")
    wb$add_data(sheet = "tabela", x = inflacija[3:8], dims = "D21", na.strings = ":")

    wb$add_data(sheet = "tabela", x = place[3:8], dims = "D24", na.strings = ":")
    wb$add_data(sheet = "tabela", x = rep(place_datumi[1], 8), colNames = FALSE, dims = "B25")

    wb$add_data(sheet = "tabela", x = da_bp_st[3:8], dims = "D33", na.strings = ":")
    wb$add_data(sheet = "tabela", x = data.frame(datum1 = rep(da_datumi[1], 5)), colNames = FALSE, dims = "B34")
    wb$add_data(sheet = "tabela", x = data.frame(datum1 = rep(reg_bp_datumi[1], 2)), colNames = FALSE, dims = "B36")

    wb$add_data(sheet = "tabela", x = ilo_both[3:8], dims = "D39", na.strings = ":")
    wb$add_data(sheet = "tabela", x = data.frame(datum1 = rep(ilo_datumi[1], 3)), colNames = FALSE, dims = "B40")

    wb$add_data(sheet = "tabela", colNames = FALSE, x = indpro[2], dims = "B44")
    wb$add_data(sheet = "tabela", x = indpro[3:8], dims = "D43", na.strings = ":")

    wb$add_data(sheet = "tabela", colNames = FALSE, x = dolg[2], dims = "B55")
    wb$add_data(sheet = "tabela", x = dolg[3:8], dims = "D54")

    wb$add_data(sheet = "tabela", colNames = FALSE, x = klima[2], dims = "B58")
    wb$add_data(sheet = "tabela", x = klima[3:8], dims = "D57")

    wb$add_data(sheet = "tabela", x = klima[2:4, 3:8], dims = "D59", na.strings = ":")
    wb$add_data(sheet = "tabela", x = euribor[3:8], dims = "D60", na.strings = ":", colNames = FALSE)
    wb$add_data(sheet = "tabela", x = donosnosti[3:8], dims = "D61", na.strings = ":", colNames = FALSE)
    wb$add_data(sheet = "tabela", x = money[3:8], dims = "D62", na.strings = ":", colNames = FALSE)

    wb$add_data(sheet = "tabela", dims = "A63",
                x = paste(config$update_text, format(Sys.Date(), "%d/%m/%Y")))

    timestamp <- format(Sys.time(), "%Y-%m-%d_%H-%M-%S")
    backup_path <- sub("\\.xlsx$", paste0("_", timestamp, ".xlsx"), config$path)
    tryCatch({
      openxlsx2::wb_save(wb, config$path)
      log_msg("Saved (%s): %s", config$lang, config$path)
    }, error = function(e) {
      log_msg("Primary save failed (%s): %s -- saving to backup", config$lang, conditionMessage(e))
      openxlsx2::wb_save(wb, backup_path)
      log_msg("Saved backup (%s): %s", config$lang, backup_path)
    })
    TRUE
  }, error = function(e) {
    msg <- sprintf("writing %s table -- %s", config$lang, conditionMessage(e))
    log_msg("FAILED: %s", msg)
    issue_log <<- c(issue_log, msg)
    FALSE
  })
})

log_msg("Writing to file done (%d/%d succeeded), now emailing.", sum(write_ok), length(write_ok))

################################################################################
# email
################################################################################

email_list <- c("maja.zaloznik@gmail.com", "maja.zaloznik@gov.si",
                "urska.brodar@gov.si", "Tina.Nenadic-Senica@gov.si",
                "Barbara.Bratuz-Ferk@gov.si")

email_body <- "To je avtomatsko generirano sporo\u010dilo o posodobitvi podatkov v obeh tabelah GT_tabela_SI.<br><br>Tvoj Umar Data Bot &#129302;"

if (length(issue_log) > 0) {
  email_body <- paste0(
    email_body,
    "<br><br><b>Opozorila med tem tekom (", length(issue_log), "):</b><br>",
    paste(issue_log, collapse = "<br>")
  )
}

tryCatch({
  gmailr::gm_auth_configure(path = "data/gmailr/credentials.json")
  gmailr::gm_auth(email = "umar.data.bot@gmail.com", cache = ".secret")
  text_msg <- gmailr::gm_mime() |>
    gmailr::gm_bcc(email_list) |>
    gmailr::gm_subject("Posodobitev GT SI tabel") |>
    gmailr::gm_html_body(email_body)
  gmailr::gm_send_message(text_msg)
  log_msg("Email sent.")
}, error = function(e) {
  log_msg("FAILED to send email: %s", conditionMessage(e))
})

log_msg("Run finished. %d issue(s) logged.", length(issue_log))
