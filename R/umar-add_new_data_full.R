################################################################################

# setup packages and connections
home <- "\\\\192.168.38.7\\public$\\Avtomatizacija\\furs-surs-soap\\"
setwd(home)
Sys.setenv(http_proxy="http://proxy.gov.si:80")
Sys.setenv(http_proxy_user="http://proxy.gov.si:80")
Sys.setenv(https_proxy="http://proxy.gov.si:80")
Sys.setenv(https_proxy_user="http://proxy.gov.si:80")

# devtools::install_github("majazaloznik/UMARfetchR")
# devtools::install_github("majazaloznik/UMARaccessR", dependencies = FALSE,  INSTALL_opts=c("--no-multiarch"))


library(gmailr)
options(gargle_oauth_email = TRUE)
gm_auth_configure(path ="data/credentials-umar.json")
gm_auth(email = TRUE, cache = ".secret")

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

# update materialised views
DBI::dbExecute(con, "set search_path to views")
DBI::dbExecute(con, "REFRESH MATERIALIZED VIEW mat_latest_series_data_table_74")
DBI::dbExecute(con, "REFRESH MATERIALIZED VIEW mat_latest_series_data_table_80")


#
# # run over single data file
# initials <- "AJPES"
# meta_filename <- paste0(dir_path, "\\", initials, "\\umar_serije_metadata_", initials, ".xlsx")
# data_filename <- paste0(dir_path, "\\", initials,"\\umar_serije_podatki_", initials, ".xlsx")
# update_data(meta_filename, data_filename, con, schema, path = log_path)
