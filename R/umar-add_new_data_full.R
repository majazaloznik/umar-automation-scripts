################################################################################
# setup packages and connections
home <- "\\\\192.168.38.7\\public$\\Avtomatizacija\\furs-surs-soap\\"
setwd(home)
Sys.setenv(http_proxy="http://proxy.gov.si:80")
Sys.setenv(https_proxy="http://proxy.gov.si:80")

# devtools::install_github("majazaloznik/UMARfetchR")
# devtools::install_github("majazaloznik/UMARimportR")
# devtools::install_github("majazaloznik/UMARaccessR", dependencies = FALSE,  INSTALL_opts=c("--no-multiarch"))


library(gmailr)
gm_auth_configure(path ="data/credentials.json")
gm_auth(email = "umar.data.bot@gmail.com", cache = ".secret")

# package
library(UMARfetchR)
library(UMARaccessR)
# database connection
con <- DBI::dbConnect(RPostgres::Postgres(),
                      dbname = "platform",
                      host = "localhost",
                      port = 5432,
                      user = "postgres",
                      password = Sys.getenv("PG_PG_PSW"),
                      client_encoding = "utf8")
DBI::dbExecute(con, "set search_path to platform")
schema <- "platform"

dir_path <- "\\\\192.168.38.7\\public$\\Avtomatizacija\\umar-data"
log_path <- "\\\\192.168.38.7\\public$\\Avtomatizacija\\umar-automation-scripts\\logs\\UMARfetchR\\"

meta_filenames <- rev(list.files(path = dir_path, pattern = "^umar_serije_metadata_",
                                 recursive = TRUE, full.names = TRUE))
data_filenames <- rev(list.files(path = dir_path, pattern = "^umar_serije_podatki_",
                                 recursive = TRUE, full.names = TRUE))

for (i in seq(length(meta_filenames))){
  update_data(meta_filenames[i], data_filenames[i], con, schema,
                           path = log_path)
}

# cleanup hashes for all tables.
table_ids <- c(57:63, 74, 80, 226:228, 232, 260, 261:265, 306, 308, 309, 313)
# clean up vintages and add new hashes
purrr::map(table_ids, ~UMARimportR::vintage_cleanup(con, .x,
                                                   schema = "platform"))


# # update materialised views
DBI::dbExecute(con, "set search_path to views")
DBI::dbExecute(con, "REFRESH MATERIALIZED VIEW mat_latest_series_insolvency_skd21")
DBI::dbExecute(con, "REFRESH MATERIALIZED VIEW mat_latest_series_stecaji_skd21")


# # run over single data file
# initials <- "AJPES"
# meta_filename <- paste0(dir_path, "\\", initials, "\\umar_serije_metadata_", initials, ".xlsx")
# data_filename <- paste0(dir_path, "\\", initials,"\\umar_serije_podatki_", initials, ".xlsx")
# update_data(meta_filename, data_filename, con, schema, path = log_path)
# DBI::dbExecute(con, "set search_path to views")
# DBI::dbExecute(con, "REFRESH MATERIALIZED VIEW mat_latest_series_insolvency_skd21")
# DBI::dbExecute(con, "REFRESH MATERIALIZED VIEW mat_latest_series_stecaji_skd21")
# DBI::dbExecute(con, "REFRESH MATERIALIZED VIEW latest_data_points")
