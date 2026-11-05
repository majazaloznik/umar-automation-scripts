################################################################################
# setup for reading the bloomberg data from the MF excel dump
################################################################################
con <- DBI::dbConnect(RPostgres::Postgres(),
                      dbname = "platform",
                      host = "localhost",
                      port = 5432,
                      user = "postgres",
                      password = Sys.getenv("PG_PG_PSW"),
                      client_encoding = "utf8")

send_status_email <- function(subject, body, recipients) {
  setwd("\\\\192.168.38.7\\public$\\Avtomatizacija\\umar-automation-scripts\\")
  gmailr::gm_auth_configure(path = "data/gmailr/credentials.json")
  gmailr::gm_auth(email = "umar.data.bot@gmail.com", cache = ".secret")
  gmailr::gm_mime() |>
    gmailr::gm_bcc(recipients) |>
    gmailr::gm_subject(subject) |>
    gmailr::gm_html_body(body) |>
    gmailr::gm_send_message()
}

email_list_failure <- "maja.zaloznik@gmail.com"

table_id <- function(code) {
  id <- UMARaccessR::sql_get_table_id_from_table_code(con, code)
  if (is.na(id)) stop("Table ", code, " not found", call. = FALSE)
  id
}

#' Read Bloomberg 10Y yields from the weekly MF Excel dump
#'
#' reads data from the excel that Marjan updates once weekly with daily
#' data from Bloomberg and writes to the database. currently no exception
#' handling or email logs
#'
#'
#'
#'
#' Read Bloomberg 10Y yields from the weekly MF Excel dump
#'
#' Finds series blocks by their "Date" header label (no hardcoded cell
#' positions) and returns each series as its own table. Stops with an error
#' on any structural change.
#'
#' @return list(meta = data.frame, series = named list of tibbles(date, value))
read_bbg_10y <- function(path,
                         sheet = "RAW DATA",
                         value_header = "YLD_YTM_MID",
                         expected_countries = c("Avstrija", "Belgija", "Francija", "Irska",
                                                "Italija", "Nemčija", "Portugalska",
                                                "Slovaška", "Slovenija", "Španija"),
                         valid_range = c(-5, 50)) {
  if (!file.exists(path)) stop("File not found: ", path)
  if (!sheet %in% readxl::excel_sheets(path)) stop("Sheet '", sheet, "' not found in ", path)

  # read a local copy so a save in progress on the share can't give a half-written file
  tmp <- tempfile(fileext = paste0(".", tools::file_ext(path)))
  if (!file.copy(path, tmp)) stop("Could not copy ", path)
  on.exit(unlink(tmp), add = TRUE)

  # every cell keeps its own type: date-formatted -> POSIXct, number -> dbl, text -> chr
  raw <- readxl::read_excel(tmp, sheet = sheet, col_names = FALSE,
                            col_types = "list", .name_repair = "minimal")

  is_blank <- function(v) is.null(v) || length(v) == 0 || (length(v) == 1 && is.na(v))
  chr <- vapply(raw, \(col) vapply(col, \(v) if (is_blank(v)) NA_character_ else trimws(format(v)),
                                   character(1)),
                character(nrow(raw)))

  # ---- locate blocks --------------------------------------------------------
  n_date <- rowSums(chr == "Date", na.rm = TRUE)
  if (max(n_date) == 0) stop("No 'Date' header labels found")
  hdr <- which.max(n_date)
  if (hdr < 3) stop("Header row ", hdr, " leaves no room for country/ticker rows above it")

  date_cols <- which(chr[hdr, ] == "Date")
  val_cols  <- date_cols + 1L
  if (any(val_cols > ncol(chr))) stop("Last 'Date' column has no value column next to it")
  bad_hdr <- !(chr[hdr, val_cols] %in% value_header)
  if (any(bad_hdr)) stop("Expected '", value_header, "' next to 'Date' in column(s) ",
                         paste(val_cols[bad_hdr], collapse = ", "))

  meta <- data.frame(country  = chr[hdr - 2L, date_cols],
                     ticker   = chr[hdr - 1L, date_cols],
                     date_col = date_cols)
  if (anyNA(meta$country) || anyNA(meta$ticker))
    stop("Missing country/ticker label above column(s) ",
         paste(date_cols[is.na(meta$country) | is.na(meta$ticker)], collapse = ", "))
  if (anyDuplicated(meta$country)) stop("Duplicate country labels: ",
                                        paste(meta$country[duplicated(meta$country)], collapse = ", "))
  missing <- setdiff(expected_countries, meta$country)
  extra   <- setdiff(meta$country, expected_countries)
  if (length(c(missing, extra)))
    stop("Country set changed. Missing: ", toString(missing), "; unexpected: ", toString(extra))

  # ---- cell parsers ---------------------------------------------------------
  parse_date <- function(v) {
    if (is_blank(v)) return(NA_real_)
    if (inherits(v, c("POSIXt", "Date"))) return(as.numeric(as.Date(v)))
    if (is.numeric(v)) return(as.numeric(as.Date(v, origin = "1899-12-30")))  # unformatted Excel serial
    if (is.character(v)) return(as.numeric(as.Date(v, tryFormats = c("%d/%m/%Y", "%d.%m.%Y", "%Y-%m-%d"),
                                                   optional = TRUE)))
    NA_real_
  }
  parse_value <- function(v) {
    if (is_blank(v)) return(NA_real_)
    if (is.numeric(v)) return(as.numeric(v))
    if (is.character(v) && grepl("^#N/A", v)) return(NA_real_)  # Bloomberg missing marker
    NaN                                                          # sentinel: unparseable
  }

  rows <- seq.int(hdr + 1L, nrow(raw))

  read_block <- function(country, ticker, date_col) {
    d_raw <- raw[[date_col]][rows]
    v_raw <- raw[[date_col + 1L]][rows]
    d <- as.Date(vapply(d_raw, parse_date, numeric(1)), origin = "1970-01-01")
    v <- vapply(v_raw, parse_value, numeric(1))
    d_blank <- vapply(d_raw, is_blank, logical(1))
    v_blank <- vapply(v_raw, is_blank, logical(1))
    fail <- \(msg, i) stop(country, " (", ticker, "): ", msg, " at sheet row(s) ",
                           toString(utils::head(rows[i], 5)), call. = FALSE)

    if (any(i <- !d_blank & is.na(d))) fail("unparseable date", i)
    if (any(i <- is.nan(v)))           fail("unparseable value", i)
    if (any(i <- d_blank & !v_blank))  fail("value without date", i)
    if (all(d_blank)) fail("no observations", TRUE)
    last <- max(which(!d_blank))
    if (any(i <- d_blank[seq_len(last)])) fail("blank row inside series", i)

    d <- d[seq_len(last)]; v <- v[seq_len(last)]
    if (any(i <- duplicated(d)))            fail("duplicate date", i)
    if (is.unsorted(d, strictly = TRUE))    fail("dates not strictly increasing", which(diff(d) <= 0) + 1L)
    if (any(i <- d > Sys.Date()))           fail("future date", i)
    if (any(i <- !is.na(v) & (v < valid_range[1] | v > valid_range[2])))
      fail("value outside plausible range", i)

    out <- tibble::tibble(date = d, value = v)[!is.na(v), ]
    attr(out, "n_missing") <- sum(is.na(v))
    out
  }

  series <- purrr::pmap(meta, read_block) |> purrr::set_names(meta$country)

  meta$n_obs     <- purrr::map_int(series, nrow)
  meta$n_missing <- purrr::map_int(series, \(x) attr(x, "n_missing"))
  meta$first     <- purrr::map_vec(series, \(x) min(x$date))
  meta$last      <- purrr::map_vec(series, \(x) max(x$date))

  list(meta = meta, series = series)
}

################################################################################
# run
################################################################################
cat("Start donosnosti run\n")
result <- tryCatch({
  bbg_file <-  "\\\\192.168.38.7\\public$\\Avtomatizacija\\umar-automation-scripts\\data\\donosnosti\\Donosnosti_10Ya.xlsx"
  meta_file <-  "\\\\192.168.38.7\\public$\\Avtomatizacija\\umar-data\\UDB\\umar_serije_metadata_UDB.xlsx"

  struct_all <- openxlsx::read.xlsx(meta_file, sheet = "timeseries")
  struct_d <- struct_all[struct_all$interval == "D" & grepl("^BLOOMBERG", struct_all$series_code), ]

  bbg <- read_bbg_10y(bbg_file, expected_countries = struct_d$dimension_levels_text)
  code_map <- stats::setNames(struct_d$series_code, struct_d$dimension_levels_text)
  unmapped <- setdiff(names(bbg$series), names(code_map))

    if (length(unmapped)) stop("No series code for: ", toString(unmapped))

  wide <- bbg$series |>
    purrr::imap(\(x, country) stats::setNames(x, c("period", code_map[[country]]))) |>
    purrr::reduce(dplyr::full_join, by = "period") |>
    dplyr::arrange(period) |>
    as.data.frame()

  struct_m  <- struct_all[struct_all$interval == "M" & grepl("^BLOOMBERG", struct_all$series_code), ]
  d_to_dim  <- stats::setNames(struct_d$dimension_levels_code, struct_d$series_code)      # D code -> AT
  dim_to_m  <- stats::setNames(struct_m$series_code, struct_m$dimension_levels_code)  # AT -> M code

  monthly <- wide |>
    tidyr::pivot_longer(-period, names_to = "code", values_to = "value", values_drop_na = TRUE) |>
    dplyr::mutate(month = lubridate::floor_date(period, "month")) |>
    dplyr::filter(month < lubridate::floor_date(max(period), "month"),      # complete months only
                  month > lubridate::floor_date(min(period), "month")) |>   # drop partial first month
    dplyr::summarise(value = mean(value), .by = c(code, month)) |>
    dplyr::mutate(code = unname(dim_to_m[d_to_dim[code]])) |>
    tidyr::pivot_wider(names_from = code, values_from = value) |>
    dplyr::rename(period = month) |>
    dplyr::arrange(period) |>
    as.data.frame()



  n <- UMARfetchR::import_data_df(wide, "D", unname(code_map), con, "platform")
  if (n == 0) warning("No new data points: has the MF file been refreshed?")

  if (anyNA(names(monthly))) stop("Unmapped D -> M series")
  m <- UMARfetchR::import_data_df(monthly, "M", unname(dim_to_m), con, "platform")

  # refresh views only if something was inserted
  if (n > 0 | m > 0)
    DBI::dbExecute(con, "REFRESH MATERIALIZED VIEW views.mat_latest_data_points")

  last_date <- DBI::dbGetQuery(con, sprintf(
    "SELECT max(dp.period_id) AS last
       FROM platform.data_points dp
       JOIN platform.vintage v ON dp.vintage_id = v.id
       JOIN platform.series s  ON v.series_id = s.id
      WHERE s.table_id = %s", table_id("GASOIL_RAW")))$last

  "ok"
}, error = function(e) e)

DBI::dbDisconnect(con)

if (inherits(result, "error")) {
  cat("Run FAILED:", conditionMessage(result), "\n")
  send_status_email(
    "NAPAKA: Posodobitev donosnosti na bazi ni uspela",
    paste0("Avtomatska posodobitev Bloomberg donosnosti je spodletela.",
           "<br><br>Napaka: ", conditionMessage(result),
           "<br><br>Tvoj Umar Data Bot &#129302;"),
    recipients = email_list_failure)
  quit(save = "no", status = 1)
} else {
  cat("Run OK, latest data:", last_date,
      if (n == 0) "(no new data)" else "(new data imported)", "\n")
}




