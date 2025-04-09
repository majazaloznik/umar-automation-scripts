###############################################################################
## MF update script + prepare Excel tables
###############################################################################
# This script is run from a batch file run by the task scheduler at the end
# of each month. it does the following:
# - checks if a new email has arrived to umar.data.bot from Lejla containing
#   xlsx files
# - if the files are there it downloads them and writes the timestamp to a log file
# - it updates the database with the parsed data
# - it prepares three Excel output tables for Lejla
###############################################################################
## Preliminaries
###############################################################################
#
library(DBI)
library(RPostgres)
library(dplyr)
library(dittodb)
# devtools::install_github("majazaloznik/UMARaccessR", dependencies = FALSE)
# devtools::install_github("majazaloznik/MFfetchR", dependencies = FALSE)
library(UMARaccessR)
library(MFfetchR)
library(gmailr)

# logging in
con <- DBI::dbConnect(RPostgres::Postgres(),
                      dbname = "sandbox",
                      host = "localhost",
                      port = 5432,
                      user = "mzaloznik",
                      password = Sys.getenv("PG_local_MAJA_PSW"),
                      client_encoding = "utf8")
DBI::dbExecute(con, "set search_path to test_platform")

###############################################################################
## Check for new data
###############################################################################
#
# check for new data
gm_auth_configure(path ="data/credentials.json")
gm_auth(email = "umar.data.bot@gmail.com", cache = ".secret")

data_path <- "data/mf_bilance/raw_data"
sender <- "lejla.fajic@gov.si"
last_run <- ceiling(as.numeric(readLines("logs/mf_last_update.txt")))

# Find the newest message
msg <- gm_messages(search = paste0("from:", sender, " after:", last_run,
                                   " has:attachment filename:xlsx"),
                   num_results = 1)

# if there is a new email with data, save the attachments overwriting existing ones.
if(!is.null(purrr::pluck(msg, 1,1,1,"id"))){
  msg_id <- purrr::pluck(msg, 1,1,1,"id")
  message <- gm_message(msg_id)
  gm_save_attachments(message, path = data_path)

  writeLines(as.character(as.numeric(Sys.time())), "logs/mf_last_update.txt")
  ###############################################################################
  ## Update database
  ###############################################################################
  #
  # get correct filenames from the folder - in case the filenames change each year
  data_path <- "data/mf_bilance/raw_data/"
  meta <- MFfetchR:::meta
  pattern <- paste0("^", meta$file_path , ".*")
  file_list <- list.files(data_path)
  matching_indices <- sapply(pattern, function(x) grep(x, file_list))
  meta$file_path  <- paste0(data_path, file_list[matching_indices])

  # update database with new data
  purrr::pmap(meta, insert_new_data, con)

  ###############################################################################
  ## Prepare excel tables for EO etc.
  ###############################################################################

  # script for EO excel
  raw_data_frame <- load_series_as_df(MFfetchR:::kbjf_series_list_eo, con)
  data_frame <- transform_series_eo(raw_data_frame)
  quarterly_list <- prepare_quarterly_eo(data_frame)
  annual_list <- prepare_annual_eo(data_frame)
  write_excel_kbjf_eo(quarterly_list, annual_list, data_frame, "data/mf_bilance/output_tables/KBJF-EO.xlsx")

  # script for 12mK excel
  raw_data_frame <- load_series_as_df(MFfetchR:::kbjf_series_list_12mK, con)
  data_frame <- transform_series_12mK(raw_data_frame)
  monthly_list <- prepare_monthly_12mK(data_frame)
  write_excel_kbjf_12mK(monthly_list, data_frame, "data/mf_bilance/output_tables/KBJF-12mK.xlsx", update = TRUE)

  # scritp for 12mK excel
  raw_data_frame <- load_series_as_df(MFfetchR:::kbjf_series_list_12mK, con)
  data_frame <- transform_series_12mK(raw_data_frame)
  stats_appendix_list <- prepare_stats_appendix(data_frame)
  write_excel_stats_appendix(stats_appendix_list, data_frame, "data/mf_bilance/output_tables/KBJF-stat-priloga.xlsx")
} else {print("There are no new emails from Lejla with excel files in them.")}
