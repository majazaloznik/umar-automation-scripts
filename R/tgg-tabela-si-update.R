library(UMARaccessR)
library(purrr)
library(dplyr)
library(lubridate)
library(tidyr)
library(openxlsx2)

################################################################################
# Data series from the platform database
################################################################################
# connect to database
con <- DBI::dbConnect(RPostgres::Postgres(),
                      dbname = "platform",
                      host = "192.168.38.21",
                      port = 5432,
                      user = "majaz",
                      password = Sys.getenv("PG_MZ_PSW"),
                      client_encoding = "utf8")
# set schema search path
DBI::dbExecute(con, "set search_path to platform")



process_codes_vectorized <- function(codes, con, schema = "platform", stotka = FALSE) {
  # Process all codes at once using map
  results <- codes %>%
    map(~{
      vin <- sql_get_vintage_from_series_code(con, .x, schema = schema)
      list(
        df = sql_get_data_points_from_vintage(con, vin, schema) %>%
          rename(!!.x := value),
        date = sql_get_date_published_from_vintage(vin, con, schema)
      )
    })
  # Extract all dates
  dates <- map(results, "date") |>
    unlist() |>
    as_datetime(tz = "CET") |>
    as_date()

  # Extract and combine all dataframes
  combined_df <- results |>
    map("df") |>
    reduce(full_join, by = "period_id") |>
    slice_tail(n = 6) |>
    mutate(period_id = sub("Q", " Q", period_id),
           period_id = sub("M0", "M", period_id),
           period_id = sub("M", " m ", period_id)) |>
    pivot_longer(-period_id, names_to = "code", values_to = "value") |>
    ({if(stotka) \(x) x |> mutate(value = value - 100) else \(x) x})() |>
    pivot_wider(names_from = "period_id", values_from = "value") |>
    mutate(Zadnja = as.Date(dates)) |>
    relocate(Zadnja, .after = code)

}

process_codes_rates <- function(codes, con, schema = "platform", stotka = FALSE) {
  # Process all codes at once using map
  results <- codes %>%
    map(~{
      vin <- sql_get_vintage_from_series_code(con, .x, schema = schema)
      list(
        df = sql_get_data_points_from_vintage(con, vin, schema) %>%
          rename(!!.x := value),
        date = as_date(lubridate::with_tz(sql_get_date_published_from_vintage(vin, con, schema)), "CET")
      )
    })
  # Extract all dates
  dates <- map(results, "date") |>
    unlist() |>
    as_date()

  # Extract and combine all dataframes
  combined_df <- results |>
    map("df") |>
    reduce(full_join, by = "period_id") |>
    mutate(
      across(
        where(is.numeric),
        list(
          # Monthly growth rate
          mgr = ~(. / lag(.) - 1) * 100,
          # Year-over-year growth rate (lag of 12 months)
          yoy = ~(. / lag(., 12) - 1) * 100
        ),
        .names = "{.col}_{.fn}"
      )
    ) |>
    slice_tail(n = 6) |>
    select(period_id,
           "SURS--1701111S--sa--C[skd]--M_mgr",
           "SURS--1701111S--orig--C[skd]--M_yoy",
           "SURS--1957408S--SA--CC--M_mgr",
           "SURS--1957408S--O--CC--M_yoy",
           "SURS--2001303S--2--2--G--M_mgr",
           "SURS--2001303S--2--1--G--M_yoy",
           "SURS--2080006S--2--H+I+J+L+M+N--M_mgr",
           "SURS--2080006S--1--H+I+J+L+M+N--M_yoy") |>
  mutate(period_id = sub("M0", "M", period_id),
         period_id = sub("M", " m ", period_id)) |>
    pivot_longer(-period_id, names_to = "code", values_to = "value") |>
    pivot_wider(names_from = "period_id", values_from = "value") |>
    mutate(Zadnja = as.Date(dates)) |>
    relocate(Zadnja, .after = code)
}

print("start preparing SURS data from the database")

# setup series that we need for different sections
makro_slo <-  c("SURS--0300230S--B1GQ--G1--Y--Q",
                "SURS--0300230S--B1GQ--GO4--N--Q",
                "SURS--0300230S--P31_S14_D--G1--Y--Q",
                "SURS--0300230S--P31_S14_D--G4--N--Q",
                "SURS--0300230S--P3_S13--G1--Y--Q",
                "SURS--0300230S--P3_S13--G4--N--Q",
                "SURS--0300230S--P5--G1--Y--Q",
                "SURS--0300230S--P5--G4--N--Q",
                "SURS--0300230S--P6--G1--Y--Q",
                "SURS--0300230S--P6--G4--N--Q",
                "SURS--0300230S--P7--G1--Y--Q",
                "SURS--0300230S--P7--G4--N--Q")

inflacija_slo <- c("SURS--H281S--1--M",
                   "SURS--H281S--2--M")

indpro_slo <- c("SURS--0457201S--B_TO_E--01--M",
                "SURS--0457201S--B_TO_E--02--M")

za_rast_slo <-  c("SURS--1701111S--sa--C[skd]--M",
                  "SURS--1701111S--orig--C[skd]--M",
                  "SURS--1957408S--SA--CC--M",
                  "SURS--1957408S--O--CC--M",
                  "SURS--2001303S--2--2--G--M",
                  "SURS--2001303S--2--1--G--M",
                  "SURS--2080006S--2--H+I+J+L+M+N--M",
                  "SURS--2080006S--1--H+I+J+L+M+N--M")

dolg_slo <- c("SURS--0314905S--B9--XDC_R_B1GQ--A",
              "SURS--0314905S--GD--XDC_R_B1GQ--A")

klima_slo <- "SURS--2855901S--1--2--M"

makro <- process_codes_vectorized(makro_slo, con)

inflacija <- process_codes_vectorized(inflacija_slo, stotka = TRUE,con)

indpro <- process_codes_vectorized(indpro_slo, stotka = TRUE, con)

rast <- process_codes_rates(za_rast_slo, con)

dolg <- process_codes_vectorized(dolg_slo, con)

klima <- process_codes_vectorized(klima_slo, con)

inflacija <- klima[0,] |>
  bind_rows(inflacija) |>
  select(any_of(names(klima)))

indpro <- klima[0,] |>
  bind_rows(indpro) |>
  select(any_of(names(klima)))

rast <- klima[0,] |>
  bind_rows(rast) |>
  select(any_of(names(klima)))

indpro <-  indpro |>
  bind_rows(rast)

print("SURS data from the database ready")


print("start preparing BS data from the database")

pl_b_slo <- c("BS--i_32_6ms--3--M",
              "BS--i_32_6ms--0--M")
pl_b <- process_codes_vectorized(pl_b_slo, con)

pl_b <- klima[0,] |>
  bind_rows(pl_b) |>
  select(any_of(names(klima)))

print("start preparing Eurostat data from the database")
money_slo <- c("EUROSTAT--teimf200--USD--M")

money <- process_codes_vectorized(money_slo, con)

money <- klima[0,] |>
  bind_rows(money) |>
  select(any_of(names(klima)))

################################################################################
# Data series from Excel files on the network drives
################################################################################

rates_from_excel <-  function(path, code, month = TRUE){
  da_sa <- readxl::read_xls(path, sheet = "SA", col_names = c("period_id", "value_sa")) |>
    filter(!is.na(period_id)) |>
    mutate(value_sa = as.numeric(value_sa)) |>
    mutate(mgr = (value_sa / lag(value_sa) - 1) * 100) |>
    slice_tail(n = 6) |>
    select(period_id, mgr) |>
    mutate(period_id = paste(year(period_id), "m", month(period_id))) |>
    pivot_wider(names_from = "period_id", values_from = "mgr") |>
    mutate(code = paste0(code, "_mgr")) |>
    relocate(code)
  if(month) lag = 12 else lag = 4
  da_orig <- readxl::read_xls(path, sheet = "Orig", col_names = c("period_id", "value_orig")) |>
    filter(!is.na(period_id)) |>
    mutate(value_orig = as.numeric(value_orig)) |>
    mutate(yoy = (value_orig / lag(value_orig, lag) - 1) * 100) |>
    slice_tail(n = 6) |>
    select(period_id, yoy) |>
    mutate(period_id = paste(year(period_id), "m", month(period_id))) |>
    pivot_wider(names_from = "period_id", values_from = "yoy") |>
    mutate(code = paste0(code, "_yoy")) |>
    relocate(code)
  da_sa |>
    bind_rows(da_orig)
}

month_to_quarter <- function(month_str) {
  # Extract year and month
  year <- stringr::str_extract(month_str, "\\d{4}")
  month_num <- as.numeric(stringr::str_extract(month_str, "\\d+$"))

  # Calculate quarter
  quarter <- ceiling(month_num / 3)

  # Format output
  paste(year, " Q", quarter, sep = "")
}

print("start preparing data from local drives")
# delovno aktivni   ############################################################
path <- "\\\\192.168.38.7\\public$\\DESEZONIRANJE/Trg dela/Delovno aktivni/Vsi/"

# Get most recent folder
most_recent_year <- list.dirs(path = path, full.names = TRUE, recursive = FALSE) %>%
  basename() %>%
  .[grep("^Leto ", .)] %>%
  .[which.max(as.numeric(stringr::str_extract(., "\\d{4}")))]

most_recent_month <- list.dirs(path = paste(path, most_recent_year, sep = "/"), full.names = TRUE, recursive = FALSE) %>%
  basename() %>%
  .[which.max(as.numeric(stringr::str_extract(., "\\d{2}")))]
path <- paste(path, most_recent_year, most_recent_month, "DA - vsi.xls", sep = "/")

da <- rates_from_excel(path, "da")

da <- klima[0,] |>
  bind_rows(da) |>
  select(any_of(names(klima)))


# brezposelni   ################################################################
path <- "\\\\192.168.38.7\\public$\\DESEZONIRANJE/Trg dela/Registrirani brezposelni/Stevilo/"

# Get most recent folder
most_recent_year <- list.dirs(path = path, full.names = TRUE, recursive = FALSE) %>%
  basename() %>%
  .[grep("^Leto ", .)] %>%
  .[which.max(as.numeric(stringr::str_extract(., "\\d{4}")))]

most_recent_month <- list.dirs(path = paste(path, most_recent_year, sep = "/"), full.names = TRUE, recursive = FALSE) %>%
  basename() %>%
  .[which.max(as.numeric(stringr::str_extract(., "\\d{2}")))]
path <- paste(path, most_recent_year, most_recent_month, "Stevilo reg brezposelnih zadnji.xls", sep = "/")

bp <- rates_from_excel(path, "bp")

da_bp <- da |>
  bind_rows(bp) |>
  select(any_of(names(da)))

# brezposelni   ################################################################
path <- "\\\\192.168.38.7\\public$\\DESEZONIRANJE/Trg dela/Registrirani brezposelni/Stopnje/Skupaj/"

# Get most recent folder
most_recent_year <- list.dirs(path = path, full.names = TRUE, recursive = FALSE) %>%
  basename() %>%
  .[grep("^Leto ", .)] %>%
  .[which.max(as.numeric(stringr::str_extract(., "\\d{4}")))]

most_recent_month <- list.dirs(path = paste(path, most_recent_year, sep = "/"), full.names = TRUE, recursive = FALSE) %>%
  basename() %>%
  .[which.max(as.numeric(stringr::str_extract(., "\\d{2}")))]
path <- paste(path, most_recent_year, most_recent_month, "Stopnja reg brezposelnih.xls", sep = "/")

st <- readxl::read_xls(path, sheet = "Orig", col_names = c("period_id", "value_orig")) |>
  filter(!is.na(period_id)) |>
  mutate(value_orig = as.numeric(value_orig)) |>
  slice_tail(n = 6) |>mutate(period_id = paste(year(period_id), "m", month(period_id))) |>
  pivot_wider(names_from = "period_id", values_from = "value_orig")


da_bp_st <- da_bp |>
  bind_rows(st) |>
  select(any_of(names(da_bp)))


# ILO   ################################################################
path <- "\\\\192.168.38.7\\public$\\DESEZONIRANJE/Trg dela/ILO/Zaposleni/"

# Get most recent folder
most_recent_year <- list.dirs(path = path, full.names = TRUE, recursive = FALSE) %>%
  basename() %>%
  .[grep("^Leto ", .)] %>%
  .[which.max(as.numeric(stringr::str_extract(., "\\d{4}")))]

most_recent_Q <- list.dirs(path = paste(path, most_recent_year, sep = "/"), full.names = TRUE, recursive = FALSE) %>%
  basename() %>%
  .[which.max(as.numeric(stringr::str_extract(., "\\d{1}")))]
most_recent_file <-list.files(path = paste(path, most_recent_year, most_recent_Q, sep = "/"),
                              full.names = TRUE,
                              recursive = FALSE) %>%
  basename() %>%
  .[grep("^ILO zaposleni", ., ignore.case = TRUE)]
path <- paste(path, most_recent_year, most_recent_Q, most_recent_file, sep = "/")


ilo <- rates_from_excel(path, "ilo", month = FALSE)

colnames(ilo)[2:7] <- month_to_quarter(colnames(ilo)[2:7])

ilo <- makro[0,] |>
  bind_rows(ilo) |>
  select(any_of(names(makro)))

# ILO stopnja  ################################################################
path <- "\\\\192.168.38.7\\public$\\DESEZONIRANJE/Trg dela/ILO/Stopnja brezposelnosti/"

# Get most recent folder
most_recent_year <- list.dirs(path = path, full.names = TRUE, recursive = FALSE) %>%
  basename() %>%
  .[grep("^Leto ", .)] %>%
  .[which.max(as.numeric(stringr::str_extract(., "\\d{4}")))]

most_recent_Q <- list.dirs(path = paste(path, most_recent_year, sep = "/"), full.names = TRUE, recursive = FALSE) %>%
  basename() %>%
  .[which.max(as.numeric(stringr::str_extract(., "\\d{1}")))]
most_recent_file <-list.files(path = paste(path, most_recent_year, most_recent_Q, sep = "/"),
                              full.names = TRUE,
                              recursive = FALSE) %>%
  basename() %>%
  .[grep("^Stopnja ILO brezposelnih", ., ignore.case = TRUE)]
path <- paste(path, most_recent_year, most_recent_Q, most_recent_file, sep = "/")


ilo_st <- readxl::read_xls(path, sheet = "Orig", col_names = c("period_id", "value_orig")) |>
  filter(!is.na(period_id)) |>
  mutate(value_orig = as.numeric(value_orig)) |>
  slice_tail(n = 6) |>mutate(period_id = paste(year(period_id), "m", month(period_id))) |>
  pivot_wider(names_from = "period_id", values_from = "value_orig")


colnames(ilo_st)[2:7] <- month_to_quarter(colnames(ilo_st)[2:7])

ilo_both <- ilo |>
  bind_rows(ilo_st) |>
  select(any_of(names(ilo)))
# uvoz izvoz   ################################################################
path <- "\\\\192.168.38.7\\public$\\DESEZONIRANJE/Zunanja trgovina/Realni izvoz blaga/"

# Get most recent folder
most_recent_year <- list.dirs(path = path, full.names = TRUE, recursive = FALSE) %>%
  basename() %>%
  .[grep("^Leto ", .)] %>%
  .[which.max(as.numeric(stringr::str_extract(., "\\d{4}")))]

most_recent_month <- list.dirs(path = paste(path, most_recent_year, sep = "/"), full.names = TRUE, recursive = FALSE) %>%
  basename() %>%
  .[which.max(as.numeric(stringr::str_extract(., "\\d{2}")))]
path <- paste(path, most_recent_year, most_recent_month, "Izvoz blaga - real.xls", sep = "/")

ex <- rates_from_excel(path, "ex")

ex <- pl_b |>
  bind_rows(ex) |>
  select(any_of(names(klima)))

path <- "\\\\192.168.38.7\\public$\\DESEZONIRANJE/Zunanja trgovina/Realni uvoz blaga/"

# Get most recent folder
most_recent_year <- list.dirs(path = path, full.names = TRUE, recursive = FALSE) %>%
  basename() %>%
  .[grep("^Leto ", .)] %>%
  .[which.max(as.numeric(stringr::str_extract(., "\\d{4}")))]

most_recent_month <- list.dirs(path = paste(path, most_recent_year, sep = "/"), full.names = TRUE, recursive = FALSE) %>%
  basename() %>%
  .[which.max(as.numeric(stringr::str_extract(., "\\d{2}")))]
path <- paste(path, most_recent_year, most_recent_month, "Uvoz blaga - real.xls", sep = "/")

im <- rates_from_excel(path, "im")

im_ex <- ex |>
  bind_rows(im) |>
  select(any_of(names(ex)))

# plače   ################################################################

path <- "\\\\192.168.38.7\\public$\\Users/DRogan/GT/GT-place (REK).xlsx"

raw <- read_xlsx(path, sheet = "tgg - tabela", rows = 25:33)
place <- raw[, (ncol(raw)-6):ncol(raw)]

place <- klima[0,] |>
  bind_rows(place) |>
  select(any_of(names(klima)))

print("Local data ready")

################################################################################
# release dates from ZRSZ website - manual
# this needs to be updated manually from their website once a year!
# https://www.ess.gov.si/partnerji/trg-dela/koledar-objav/
################################################################################
zrsz_days <- c(8, 5, 5, 3, 7, 4, 3, 5, 3, 3, 5, 3) # update this for next year
reg_bp_datumi <- data.frame(datum = as.Date(paste0("2025-", 1:12, "-", zrsz_days))) |>
  bind_rows(data.frame(datum = as.Date("2024-12-04"))) |>
  filter(datum <= Sys.Date() |
                        datum == min(datum[datum > Sys.Date()])) |>
  filter(datum >= max(datum[datum <= Sys.Date()]) |
           datum > Sys.Date()) %>%
  arrange(datum) |>
  pull(datum)

################################################################################
# release dates from SURS website
################################################################################
print("start getting release calendar dates")
library(httr)
library(readr)
library(stringr)
# Make the POST request to download the CSV
response <- POST(
  url = "https://www.stat.si/statweb/File/ReleaseCalendarCsv",
  # You might need to add some headers to mimic the browser request
  add_headers(
    "Accept-Language" = "en-GB,en-US;q=0.9",
    "Content-Type" = "text/csv"
  )
)
temp_file <- tempfile(fileext = ".csv")
writeBin(content(response, "raw"), temp_file)

# Get content as text with proper encoding
raw_text <- rawToChar(content(response, "raw"))
raw_text <- iconv(raw_text, from = "windows-1250", to = "UTF-8", sub = "")

# Split into initial lines
lines <- str_split(raw_text, "\r\n|\n")[[1]]
lines <- c(lines[1], lines[9001:length(lines)])

# Function to count semicolons in a line
count_semicolons <- function(line) {
  str_count(line, ";")
}

# Function to combine broken lines
combine_broken_lines <- function(lines) {
  combined <- character(0)
  current <- ""
  for (line in lines) {
    if (current == "") {
      current <- line
    } else {
      current <- paste0(current, " ", line)
    }

    # If we have the right number of semicolons (4), save and reset
    if (count_semicolons(current) == 4) {
      combined <- c(combined, current)
      current <- ""
    }
  }
  # Handle any remaining content
  if (current != "" && count_semicolons(current) == 4) {
    combined <- c(combined, current)
  }
  return(combined)
}

# Combine broken lines first
combined_lines <- combine_broken_lines(lines)

# Now clean each line
clean_line <- function(text) {
  parts <- str_split(text, ";")[[1]]
  if(length(parts) != 4) return(NULL)

  # Clean semicolons in title and note
  parts[2] <- str_replace_all(parts[2], ";", "-")
  parts[4] <- str_replace_all(parts[4], ";", "-")

  # Remove any trailing semicolon in the last part
  parts[4] <- str_replace(parts[4], ";$", "")

  paste(parts, collapse = ";")
}

# Process lines
cleaned_lines <- sapply(combined_lines, clean_line)
cleaned_lines <- names(cleaned_lines)

# Remove the last semicolon from each line
cleaned_lines <- str_replace_all(cleaned_lines, ";$", "")

# Make sure we have the header
header <- str_replace(lines[1], ";$", "")
cleaned_text <- paste(c(header, cleaned_lines), collapse = "\n")

# Read the cleaned data
df <- read_delim(
  I(cleaned_text),
  delim = ";",
  show_col_types = FALSE) |>
   mutate(`Datum objave` = as.Date(`Datum objave`, format = "%d. %m. %Y")) |>
   rename(datum = `Datum objave`, naslov = `Naslov objave`)

# BDP
makro_datumi <- df |>
  dplyr::filter(grepl("^Bruto doma\u010di proizvod, [1-4]+. \u010detrtletje [0-9]{4}", `naslov`)) |>
  dplyr::filter(datum <= Sys.Date() |
           datum == min(datum[datum > Sys.Date()])) |>
  dplyr::filter(datum >= max(datum[datum <= Sys.Date()]) |
           datum > Sys.Date()) %>%
  dplyr::arrange(datum) |>
  dplyr::pull(datum)

im_ex_datumi <- df |>
  filter(grepl("^Izvoz in uvoz blaga, [a-z]+ [0-9]{4}", `naslov`)) |>
  filter(datum <= Sys.Date() |
           datum == min(datum[datum > Sys.Date()])) |>
  filter(datum >= max(datum[datum <= Sys.Date()]) |
           datum > Sys.Date()) %>%
  arrange(datum) |>
  pull(datum)

inflacija_datumi <- df |>
  filter(grepl("^Indeksi cen .ivljenjskih potreb..in, [a-z]+ [0-9]{4}", `naslov`)) |>
  filter(datum <= Sys.Date() |
           datum == min(datum[datum > Sys.Date()])) |>
  filter(datum >= max(datum[datum <= Sys.Date()]) |
           datum > Sys.Date()) %>%
  arrange(datum) |>
  pull(datum)

place_datumi <- df |>
  filter(grepl("^Pla.e zaposlenih pri pravnih osebah, [a-z]+ [0-9]{4}", `naslov`)) |>
  filter(datum <= Sys.Date() |
           datum == min(datum[datum > Sys.Date()])) |>
  filter(datum >= max(datum[datum <= Sys.Date()]) |
           datum > Sys.Date()) %>%
  arrange(datum) |>
  pull(datum)

da_datumi <- df |>
  filter(grepl("^Delovno aktivno prebivalstvo, [a-z]+ [0-9]{4}", `naslov`)) |>
  filter(datum <= Sys.Date() |
           datum == min(datum[datum > Sys.Date()])) |>
  filter(datum >= max(datum[datum <= Sys.Date()]) |
           datum > Sys.Date()) %>%
  arrange(datum) |>
  pull(datum)

ilo_datumi <- df |>
  filter(grepl("^Aktivno in neaktivno prebivalstvo, [1-4]+. .etrtletje [0-9]{4}", `naslov`)) |>
  filter(datum <= Sys.Date() |
           datum == min(datum[datum > Sys.Date()])) |>
  filter(datum >= max(datum[datum <= Sys.Date()]) |
           datum > Sys.Date()) %>%
  arrange(datum) |>
  pull(datum)

indpro_datumi <- df |>
  filter(grepl("^Indeksi cen industrijskih proizvodov pri proizvajalcih, [a-z]+ [0-9]{4}", `naslov`)) |>
  filter(datum <= Sys.Date() |
           datum == min(datum[datum > Sys.Date()])) |>
  filter(datum >= max(datum[datum <= Sys.Date()]) |
           datum > Sys.Date()) %>%
  arrange(datum) |>
  pull(datum)

pred_datumi <- df |>
  filter(grepl("^Indeksi industrijske proizvodnje, [a-z]+ [0-9]{4}", `naslov`)) |>
  filter(datum <= Sys.Date() |
           datum == min(datum[datum > Sys.Date()])) |>
  filter(datum >= max(datum[datum <= Sys.Date()]) |
           datum > Sys.Date()) %>%
  arrange(datum) |>
  pull(datum)

gradb_datumi <- df |>
  filter(grepl("^Indeksi vrednosti opravljenih gradbenih del, [a-z]+ [0-9]{4}", `naslov`)) |>
  filter(datum <= Sys.Date() |
           datum == min(datum[datum > Sys.Date()])) |>
  filter(datum >= max(datum[datum <= Sys.Date()]) |
           datum > Sys.Date()) %>%
  arrange(datum) |>
  pull(datum)

trg_datumi <- df |>
  filter(grepl("^Prihodek od prodaje v trgovini na drobno, [a-z]+ [0-9]{4}", `naslov`)) |>
  filter(datum <= Sys.Date() |
           datum == min(datum[datum > Sys.Date()])) |>
  filter(datum >= max(datum[datum <= Sys.Date()]) |
           datum > Sys.Date()) %>%
  arrange(datum) |>
  pull(datum)

trzna_datumi <- df |>
  filter(grepl("^Indeks obsega v storitvenih dejavnostih in trgovini, [a-z]+ [0-9]{4}", `naslov`)) |>
  filter(datum <= Sys.Date() |
           datum == min(datum[datum > Sys.Date()])) |>
  filter(datum >= max(datum[datum <= Sys.Date()]) |
           datum > Sys.Date()) %>%
  arrange(datum) |>
  pull(datum)

drzava_datumi <- df |>
  filter(grepl("^Temeljni agregati sektorja .+[0-9]{4}.+[0-9]{4}$", naslov)) |>
  filter(datum <= Sys.Date() |
           datum == min(datum[datum > Sys.Date()])) |>
  filter(datum >= max(datum[datum <= Sys.Date()]) |
           datum > Sys.Date()) %>%
  arrange(datum) |>
  pull(datum)

klima_datumi <- df |>
  filter(grepl("^Gospodarska klima, [a-z]+ [0-9]{4}$", naslov)) |>
  filter(datum <= Sys.Date() |
           datum == min(datum[datum > Sys.Date()])) |>
  filter(datum >= max(datum[datum <= Sys.Date()]) |
           datum > Sys.Date()) %>%
  arrange(datum) |>
  pull(datum)

print("Release dates ready, start writing to file")
################################################################################
# write tto excel table
################################################################################
# load file
wb <- wb_load("\\\\192.168.38.7\\data$\\GT/GT_tabela_slovenska_auto_update.xlsx")
# clear cells to be updated
wb$clean_sheet(sheet = 1, dims = "B3:C59", styles = FALSE)
wb$clean_sheet(sheet = 1, dims = "E3:J59", styles = FALSE)


# makro
wb$add_data(sheet = "tabela",  x = makro[2],  dims = "B2")
wb$add_data(sheet = "tabela",  x = makro[3:8],  dims = "E2",  na.strings = ":")
wb$add_data(sheet = "tabela",  x = data.frame(datum = rep(makro_datumi[2],12)),
            colNames = FALSE,dims = "C3")

# uvozizvoz
wb$add_data(sheet = "tabela",  x = im_ex[2],  dims = "B16", colNames = FALSE)
wb$add_data(sheet = "tabela",  x = im_ex[3:8],  dims = "E15",
            na.strings = ":")
wb$add_data(sheet = "tabela",  x = data.frame(datum1 = rep(im_ex_datumi[1],4),
                                              datum2 = rep(im_ex_datumi[2],4)),
            colNames = FALSE,dims = "B18")

# inflacija
wb$add_data(sheet = "tabela",  colNames = FALSE,  x = inflacija[2],  dims = "B23")
wb$add_data(sheet = "tabela",  x = inflacija[3:8],
            dims = "E22",  na.strings = ":")
wb$add_data(sheet = "tabela",  x = data.frame(datum = rep(inflacija_datumi[2],2)),
            colNames = FALSE,dims = "C23")

# plače
wb$add_data(sheet = "tabela",  x = place[3:8],
            dims = "E25",  na.strings = ":")
wb$add_data(sheet = "tabela",  x = data.frame(datum1 = rep(place_datumi[1],8),
                                              datum2 = rep(place_datumi[2],8)),
            colNames = FALSE,dims = "B26")

# delovno aktivi, reg brezposelni
wb$add_data(sheet = "tabela",  x = da_bp_st[3:8],
            dims = "E34",  na.strings = ":")
wb$add_data(sheet = "tabela",  x = data.frame(datum1 = rep(da_datumi[1],5),
                                              datum2 = rep(da_datumi[2],5)),
            colNames = FALSE,dims = "B35")
wb$add_data(sheet = "tabela",  x = data.frame(datum1 = rep(reg_bp_datumi[1],2),
                                              datum2 = rep(reg_bp_datumi[2],2)),
            colNames = FALSE,dims = "B37")

# ILO
wb$add_data(sheet = "tabela",  x = ilo_both[3:8],
            dims = "E40",  na.strings = ":")
wb$add_data(sheet = "tabela",  x = data.frame(datum1 = rep(ilo_datumi[1],3),
                                              datum2 = rep(ilo_datumi[2],3)),
            colNames = FALSE,dims = "B41")

# indpro
wb$add_data(sheet = "tabela",  colNames = FALSE,
            x = indpro[2],  dims = "B45")
wb$add_data(sheet = "tabela",  x = indpro[3:8],  dims = "E44", na.strings = ":")
wb$add_data(sheet = "tabela",  x = data.frame(datum = rep(indpro_datumi[2],2)),
            colNames = FALSE,dims = "C45")
wb$add_data(sheet = "tabela",  x = data.frame(datum = rep(pred_datumi[2],2)),
            colNames = FALSE,dims = "C47")
wb$add_data(sheet = "tabela",  x = data.frame(datum = rep(gradb_datumi[2], 2)),
            colNames = FALSE,dims = "C49")
wb$add_data(sheet = "tabela",  x = data.frame(datum = rep(trg_datumi[2], 2)),
            colNames = FALSE,dims = "C51")
wb$add_data(sheet = "tabela",  x = data.frame(datum = rep(trzna_datumi[2], 2)),
            colNames = FALSE,dims = "C53")

# dolg
wb$add_data(sheet = "tabela",  colNames = FALSE,
            x = dolg[2],  dims = "B56")
wb$add_data(sheet = "tabela",  x = dolg[3:8],  dims = "E55")
wb$add_data(sheet = "tabela",  x = data.frame(datum = rep(drzava_datumi[2], 2)),
            colNames = FALSE,dims = "C56")

# klima
wb$add_data(sheet = "tabela",  colNames = FALSE,
            x = klima[2],  dims = "B59")
wb$add_data(sheet = "tabela",  x = klima[3:8],  dims = "E58")
wb$add_data(sheet = "tabela",  x = data.frame(datum = klima_datumi[2], 1),
            colNames = FALSE,dims = "C59")

wb$add_data(sheet = "tabela",
            x = paste(fmt_txt("%", font = "Myriad Pro", size = 11),
                      fmt_txt("3", vert_align = "superscript", font = "Myriad Pro", size = 11)),  dims = "D59")

# meseci zadnji
wb$add_data(sheet = "tabela",  x =  klima[2:4,3:8],  dims = "E60", na.strings = ":")

wb$add_data(sheet = "tabela",  x =  money[3:8],  dims = "E63", na.strings = ":", colNames = FALSE)

# # prazne celice
# empty <- data.frame(a = NA, b = NA, c= NA, d = NA, e = NA, f = NA)
# wb$add_data(sheet = "tabela",  x = empty[1,],  dims = "E16",  col_names = FALSE, na.strings = ":")
# wb$add_data(sheet = "tabela",  x = empty[1,],  dims = "E17",  col_names = FALSE, na.strings = ":")

# write back to file
wb_save(wb, "\\\\192.168.38.7\\data$\\GT/GT_tabela_slovenska_auto_update.xlsx")

# First create fallback filename with timestamp
timestamp <- format(Sys.time(), "%Y-%m-%d_%H-%M-%S")
original_path <- "\\\\192.168.38.7\\data$\\GT/GT_tabela_slovenska_auto_update.xlsx"
backup_path <- sub("\\.xlsx$", paste0("_", timestamp, ".xlsx"), original_path)

# Try to save, if fails, use backup path
tryCatch({
  wb_save(wb, original_path)
  message("File saved successfully to original location")
}, error = function(e) {
  message("Could not save to original file, likely opened by another user")
  message("Error was: ", e$message)
  message("Saving to backup location: ", backup_path)
  wb_save(wb, backup_path)
  message("File saved successfully to backup location")
})

print("Writing to file done, now emailing everyone.")


################################################################################
# email success
################################################################################

setwd("\\\\192.168.38.7\\public$\\Avtomatizacija\\umar-automation-scripts\\")
library(gmailr)
gm_auth_configure(path ="data/credentials.json")
gm_auth(email = "umar.data.bot@gmail.com", cache = ".secret")

email_list <- c("maja.zaloznik@gmail.com",
                "maja.zaloznik@gov.si",
                "Bibijana.Cirman-Naglic@gov.si",
                "urska.brodar@gov.si",
                "Tina.Nenadic-Senica@gov.si",
                "Laura.Juznik-Rotar@gov.si",
                "Barbara.Bratuz-Ferk@gov.si")

email_body <- "To je avtomatsko generirano sporo\u010dilo o posodobitvi podatkov v tabeli GT_tabela_slovenska_auto_update.<br><br>Tvoj Umar Data Bot &#129302;"

text_msg <- gmailr::gm_mime() %>% gmailr::gm_bcc(email_list) %>%
  gmailr::gm_subject("Posodobitev slovenske GT tabele") %>%
  gmailr::gm_html_body(email_body)
gmailr::gm_send_message(text_msg)
