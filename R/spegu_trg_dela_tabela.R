library(dplyr)
library(purrr)
library(lubridate)
library(UMARaccessR)
library(openxlsx2)

# connect to database čžš
con <- DBI::dbConnect(RPostgres::Postgres(),
                      dbname = "platform",
                      host = "192.168.38.21",
                      port = 5432,
                      user = "majaz",
                      password = Sys.getenv("PG_MZ_PSW"),
                      client_encoding = "utf8")

# Configuration
series_config <- list(
  da_bp_group = list(
    da = list(
      codes = c(orig = "DESEZ--DA--VSI--N--M", seas = "DESEZ--DA--VSI--Y--M"),
      label = "Delovno aktivni (rast, v %) opomba 2"
    ),
    bp_skupaj = list(
      codes = c(orig = "DESEZ--BP--SK--N--M", seas = "DESEZ--BP--SK--Y--M"),
      label = "Povprečna nominalna bruto plača (rast, v %)"
    ),
    bp_zasebni = list(
      codes = c(orig = "DESEZ--BP--ZS--N--M", seas = "DESEZ--BP--ZS--Y--M"),
      label = "- zasebni sektor"
    ),
    bp_javni = list(
      codes = c(orig = "DESEZ--BP--JS--N--M", seas = "DESEZ--BP--JS--Y--M"),
      label = "- javni sektor"
    ),
    bp_drzava = list(
      codes = c(orig = "DESEZ--BP--SD--N--M", seas = "DESEZ--BP--SD--Y--M"),
      label = "  - v tem sektor država"
    ),
    bp_javne_sluzbe = list(
      codes = c(orig = "DESEZ--BP--JD--N--M", seas = "DESEZ--BP--JD--Y--M"),
      label = "  - v tem javne družbe"
    )
  ),
  rb_rate = list(
    codes = c(orig = "DESEZ--RB--ST--Y--M"),
    label = "Stopnja registrirane brezposelnosti (v %), desezonirano"
  ),
  rb_count = list(
    codes = c(orig = "DESEZ--RB--BP--N--M", seas = "DESEZ--RB--BP--Y--M"),
    label = "Registrirani brezposelni (v %)"
  )
)

# Helper: Parse period_id to date
parse_period_id <- function(period_id) {
  year <- as.integer(stringr::str_sub(period_id, 1, 4))
  month <- as.integer(stringr::str_sub(period_id, 6, 7))
  lubridate::make_date(year, month, 1)
}

# Helper: Convert month number to Roman numeral
month_to_roman <- function(month) {
  c("I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X", "XI", "XII")[month]
}

# Fetch all data
fetch_series_data <- function(code, con, schema = "platform") {
  vin <- sql_get_vintage_from_series_code(con, code, NULL, schema)
  data <- sql_get_data_points_from_vintage(con, vin, schema) %>%
    dplyr::mutate(period = parse_period_id(period_id))
  last_period_id <- sql_get_last_period_from_vintage(con, vin, schema)
  last_period <- parse_period_id(last_period_id)
  list(data = data, last_period = last_period, code = code)
}

fetch_all_data <- function(config, con, schema = "platform") {
  # Extract codes from nested da_bp_group
  da_bp_codes <- config$da_bp_group %>%
    purrr::map(~unname(.x$codes)) %>%
    unlist()

  # Extract codes from rb_rate and rb_count
  rb_rate_codes <- unname(config$rb_rate$codes)
  rb_count_codes <- unname(config$rb_count$codes)

  # Combine all codes
  all_codes <- c(da_bp_codes, rb_rate_codes, rb_count_codes) %>%
    unique()

  purrr::map(all_codes, ~fetch_series_data(.x, con, schema)) %>%
    purrr::set_names(all_codes)
}

# Calculate functions
calc_annual_growth <- function(data, year) {
  current <- data %>%
    dplyr::filter(lubridate::year(period) == year) %>%
    dplyr::pull(value) %>%
    mean(na.rm = TRUE)

  previous <- data %>%
    dplyr::filter(lubridate::year(period) == year - 1) %>%
    dplyr::pull(value) %>%
    mean(na.rm = TRUE)

  ((current - previous) / previous) * 100
}

calc_monthly_growth <- function(data, target_period) {
  current <- data %>%
    dplyr::filter(period == target_period) %>%
    dplyr::pull(value)

  prev_month <- target_period %m-% months(1)
  previous <- data %>%
    dplyr::filter(period == prev_month) %>%
    dplyr::pull(value)

  if (length(current) == 0 || length(previous) == 0) return(NA)
  ((current - previous) / previous) * 100
}

calc_yoy_growth <- function(data, target_period) {
  current <- data %>%
    dplyr::filter(period == target_period) %>%
    dplyr::pull(value)

  prev_year <- target_period %m-% years(1)
  previous <- data %>%
    dplyr::filter(period == prev_year) %>%
    dplyr::pull(value)

  if (length(current) == 0 || length(previous) == 0) return(NA)
  ((current - previous) / previous) * 100
}

calc_cumulative_yoy_growth <- function(data, target_period) {
  target_year <- lubridate::year(target_period)
  target_month <- lubridate::month(target_period)

  current <- data %>%
    dplyr::filter(lubridate::year(period) == target_year,
                  lubridate::month(period) <= target_month) %>%
    dplyr::pull(value) %>%
    mean(na.rm = TRUE)

  previous <- data %>%
    dplyr::filter(lubridate::year(period) == target_year - 1,
                  lubridate::month(period) <= target_month) %>%
    dplyr::pull(value) %>%
    mean(na.rm = TRUE)

  ((current - previous) / previous) * 100
}

# Build DA/BP table
build_da_bp_table <- function(config, all_data, con, schema = "platform") {
  # Find common last period across all orig series in this group
  orig_codes <- config %>%
    purrr::map(~.x$codes["orig"]) %>%
    unlist()

  last_periods <- orig_codes %>%
    purrr::map(~all_data[[.x]]$last_period)

  common_period <- purrr::reduce(last_periods, min)
  current_year <- lubridate::year(common_period)
  prev_year <- current_year - 1
  current_month <- lubridate::month(common_period)
  prev_month <- lubridate::month(common_period %m-% months(1))
  yoy_month <- lubridate::month(common_period %m-% years(1))

  # Dynamic column names
  col_annual <- ifelse(current_month == 12, as.character(current_year),
                       as.character(prev_year))
  col_monthly <- sprintf("%s %02d/%s %02d",
                         month_to_roman(current_month), current_year %% 100,
                         month_to_roman(prev_month),
                         lubridate::year(common_period %m-% months(1)) %% 100)
  col_yoy <- sprintf("%s %02d/%s %02d",
                     month_to_roman(current_month), current_year %% 100,
                     month_to_roman(yoy_month), (current_year - 1) %% 100)
  col_cumulative <- sprintf("I-%s %02d/I-%s %02d",
                            month_to_roman(current_month), current_year %% 100,
                            month_to_roman(current_month), (current_year - 1) %% 100)

  # Build table
  results <- config %>%
    purrr::imap_dfr(function(item, name) {
      orig_data <- all_data[[item$codes["orig"]]]$data
      seas_data <- all_data[[item$codes["seas"]]]$data

      row_data <- list(
        item$label,
        ifelse(current_month == 12, calc_annual_growth(orig_data, current_year),
               calc_annual_growth(orig_data, prev_year)),
        calc_monthly_growth(seas_data, common_period),
        calc_yoy_growth(orig_data, common_period),
        calc_cumulative_yoy_growth(orig_data, common_period)
      )

      names(row_data) <- c(" ", col_annual, col_monthly, col_yoy, col_cumulative)
      tibble::as_tibble(row_data)
    })

  results
}


# Build RB rate table
build_rb_rate_table <- function(config, all_data, con, schema = "platform") {
  data <- all_data[[config$codes["orig"]]]$data
  last_period <- all_data[[config$codes["orig"]]]$last_period

  current_year <- lubridate::year(last_period)
  prev_year <- current_year - 1
  current_month <- lubridate::month(last_period)
  prev_month <- lubridate::month(last_period %m-% months(1))
  yoy_month <- lubridate::month(last_period %m-% years(1))

  # Dynamic column names
  col_annual <- ifelse(current_month == 12, as.character(current_year),
                       as.character(prev_year))
  col_last_year_m <- sprintf("%s %02d", month_to_roman(current_month),
                            lubridate::year(last_period %m-% months(12)) %% 100)
  col_prev_month <- sprintf("%s %02d", month_to_roman(prev_month),
                            lubridate::year(last_period %m-% months(1)) %% 100)
  col_current <- sprintf("%s %02d", month_to_roman(current_month), current_year %% 100)

  # Get actual values
  year_avg <- data %>%
    dplyr::filter(lubridate::year(period) == ifelse(current_month == 12,
                                                    current_year,
                                                    prev_year)) %>%
    dplyr::pull(value) %>%
    mean(na.rm = TRUE)

  prev_last_year_m <- data %>%
    dplyr::filter(period == last_period %m-% months(12)) %>%
    dplyr::pull(value)

  prev_month_val <- data %>%
    dplyr::filter(period == last_period %m-% months(1)) %>%
    dplyr::pull(value)

  current_val <- data %>%
    dplyr::filter(period == last_period) %>%
    dplyr::pull(value)

  row_data <- list(config$label, year_avg, prev_last_year_m, prev_month_val, current_val)
  names(row_data) <- c(" ", col_annual, col_last_year_m, col_prev_month, col_current)
  tibble::as_tibble(row_data)
}

# Build count table for DA
build_count_table_da <- function(config, all_data, con, schema = "platform") {
  orig_data <- all_data[[config$codes["orig"]]]$data
  seas_data <- all_data[[config$codes["seas"]]]$data
  last_period <- all_data[[config$codes["orig"]]]$last_period

  current_year <- lubridate::year(last_period)
  prev_year <- current_year - 1
  current_month <- lubridate::month(last_period)
  prev_month <- lubridate::month(last_period %m-% months(1))
  yoy_month <- lubridate::month(last_period %m-% years(1))

  # Dynamic column names
  col_annual <- ifelse(current_month == 12, as.character(current_year),
                       as.character(prev_year))
  col_monthly <- sprintf("%s %02d/%s %02d",
                         month_to_roman(current_month), current_year %% 100,
                         month_to_roman(prev_month),
                         lubridate::year(last_period %m-% months(1)) %% 100)
  col_yoy <- sprintf("%s %02d/%s %02d",
                     month_to_roman(current_month), current_year %% 100,
                     month_to_roman(yoy_month), prev_year %% 100)
  col_cumulative <- sprintf("I-%s %02d/I-%s %02d",
                            month_to_roman(current_month), current_year %% 100,
                            month_to_roman(current_month), prev_year %% 100)

  row_data <- list(
    config$label,
    ifelse(current_month == 12, calc_annual_growth(orig_data, current_year),
           calc_annual_growth(orig_data, prev_year)),
    calc_monthly_growth(seas_data, last_period),
    calc_yoy_growth(orig_data, last_period),
    calc_cumulative_yoy_growth(orig_data, last_period)
  )

  names(row_data) <- c(" ", col_annual, col_monthly, col_yoy, col_cumulative)
  tibble::as_tibble(row_data)
}

# Build count table for DA
build_count_table_rb <- function(config, all_data, con, schema = "platform") {
  orig_data <- all_data[[config$codes["orig"]]]$data
  seas_data <- all_data[[config$codes["seas"]]]$data
  last_period <- all_data[[config$codes["orig"]]]$last_period

  current_year <- lubridate::year(last_period)
  prev_year <- current_year - 1
  current_month <- lubridate::month(last_period)
  prev_month <- lubridate::month(last_period %m-% months(1))
  yoy_month <- lubridate::month(last_period %m-% years(1))

  # Dynamic column names
  col_annual <- ifelse(current_month == 12, as.character(current_year),
                       as.character(prev_year))
  col_monthly <- sprintf("%s %02d/%s %02d",
                         month_to_roman(current_month), current_year %% 100,
                         month_to_roman(prev_month),
                         lubridate::year(last_period %m-% months(1)) %% 100)
  col_yoy <- sprintf("%s %02d/%s %02d",
                     month_to_roman(current_month), current_year %% 100,
                     month_to_roman(yoy_month), prev_year %% 100)
  col_cumulative <- sprintf("I-%s %02d/I-%s %02d",
                            month_to_roman(current_month), current_year %% 100,
                            month_to_roman(current_month), prev_year %% 100)

  row_data <- list(
    config$label,
    ifelse(current_month == 12, calc_annual_growth(orig_data, current_year),
           calc_annual_growth(orig_data, prev_year)),
    calc_monthly_growth(orig_data, last_period),
    calc_yoy_growth(orig_data, last_period),
    calc_cumulative_yoy_growth(orig_data, last_period)
  )

  names(row_data) <- c(" ", col_annual, col_monthly, col_yoy, col_cumulative)
  tibble::as_tibble(row_data)
}

# Main execution
create_tables <- function(con, schema = "platform") {
  all_data <- fetch_all_data(series_config, con, schema)

  list(
    da = build_count_table_da(series_config$da_bp_group[[1]], all_data, con, schema),
    bp = build_da_bp_table(series_config$da_bp_group[2:6], all_data, con, schema),
    da_bp = build_da_bp_table(series_config$da_bp_group, all_data, con, schema),
    rb_rate = build_rb_rate_table(series_config$rb_rate, all_data, con, schema),
    rb_count = build_count_table_rb(series_config$rb_count, all_data, con, schema)
  )
}


################################################################################
# RUN whole bloody thing
################################################################################
tables <- create_tables(con)


################################################################################
# write to excel table
################################################################################
# Function to remove illegal XML characters
sanitize_xml <- function(x) {
  if (is.character(x)) {
    # Remove illegal XML chars (control chars except tab, newline, carriage return)
    stringr::str_replace_all(x, "[^\u0009\u000A\u000D\u0020-\uD7FF\uE000-\uFFFD]", "")
  } else {
    x
  }
}

original_path <- "\\\\192.168.38.7\\data$\\EO/AVTOMATIZIRANE STANDARDNE TABELE/trg dela.xlsx"

# Apply to all tables before writing
tables_clean <- purrr::map(tables, ~dplyr::mutate(.x, dplyr::across(dplyr::where(is.character), sanitize_xml)))
wb <- openxlsx2::wb_load(original_path)

template_sheet <- if(all(names(tables$da) == names(tables$bp))) "da=bp" else "da!=bp"

# Clone template to position 1, remove old sheet 1
wb$remove_worksheet(1)
wb$clone_worksheet(old = template_sheet, new = "Kaz. trga dela")
wb$set_order(c("Kaz. trga dela", "da=bp", "da!=bp"))

if(all(names(tables$da) == names(tables$bp))){
wb$add_data(sheet = "Kaz. trga dela", x = tables_clean[[3]], dims = "A3")
wb$add_data(sheet = "Kaz. trga dela", x = tables_clean[[4]], dims = "A10")
wb$add_data(sheet = "Kaz. trga dela", x = tables_clean[[5]], dims = "A12")} else {
  wb$add_data(sheet = "Kaz. trga dela", x = tables_clean[[1]], dims = "A3")
  wb$add_data(sheet = "Kaz. trga dela", x = tables_clean[[2]], dims = "A5")
  wb$add_data(sheet = "Kaz. trga dela", x = tables_clean[[4]], dims = "A11")
  wb$add_data(sheet = "Kaz. trga dela", x = tables_clean[[5]], dims = "A13")
}

# First create fallback filename with timestamp
timestamp <- format(Sys.time(), "%Y-%m-%d_%H-%M-%S")
backup_path <- sub("\\.xlsx$", paste0("_", timestamp, ".xlsx"), original_path)
final_path <- NULL
# Try to save, if fails, use backup path
final_path <- tryCatch({
  openxlsx2::wb_save(wb, original_path)
  base::message("File saved successfully to original location")
  original_path  # Return this value
}, error = function(e) {
  base::message("Could not save to original file, likely opened by another user")
  base::message("Error was: ", e$message)
  base::message("Saving to backup location: ", backup_path)
  openxlsx2::wb_save(wb, backup_path)
  base::message("File saved successfully to backup location")
  backup_path  # Return this value
})
#
#
################################################################################
# email success
################################################################################

setwd("\\\\192.168.38.7\\public$\\Avtomatizacija\\umar-automation-scripts\\")
library(gmailr)
gm_auth_configure(path ="data/gmailr/credentials.json")
gm_auth(email = "umar.data.bot@gmail.com", cache = ".secret")

email_list <- c("maja.zaloznik@gmail.com",
                "maja.zaloznik@gov.si",
                "urska.brodar@gov.si",
                "Tina.Nenadic-Senica@gov.si",
                "Barbara.Bratuz-Ferk@gov.si",
                "Denis.rogan@gov.si")

email_body <- paste("To je avtomatsko generirano sporo\u010dilo o posodobitvi podatkov v tabeli kazalniki gibanj na trgu dela za \u0161pegu.<br><br>",
"Fajl se nahaja tukajle:", final_path,"<br><br>",
"Tvoj Umar Data Bot &#129302;")

text_msg <- gmailr::gm_mime() %>% gmailr::gm_bcc(email_list) %>%
  gmailr::gm_subject("Posodobitev EO tabele za trg dela") %>%
  gmailr::gm_html_body(email_body)
gmailr::gm_send_message(text_msg)

