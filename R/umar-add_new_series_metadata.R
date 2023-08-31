################################################################################
# setup packages and connections
home <- "\\\\192.168.38.7\\public$\\Avtomatizacija\\furs-surs-soap\\"
setwd(home)
Sys.setenv(http_proxy="http://proxy.gov.si:80")
Sys.setenv(http_proxy_user="http://proxy.gov.si:80")
Sys.setenv(https_proxy="http://proxy.gov.si:80")
Sys.setenv(https_proxy_user="http://proxy.gov.si:80")

library(gmailr)
options(gargle_oauth_email = TRUE)
gm_auth_configure(path ="data/credentials-umar.json")
gm_auth(email = TRUE, cache = ".secret")

# package
# devtools::install_github("majazaloznik/UMARfetchR", dependencies = FALSE)
# devtools::install_github("majazaloznik/UMARaccessR", dependencies = FALSE,  INSTALL_opts=c("--no-multiarch"))
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


dir_path <- "\\\\192.168.38.7\\public$\\Avtomatizacija\\umar-data"
log_path <- "\\\\192.168.38.7\\public$\\Avtomatizacija\\umar-automation-scripts\\logs\\UMARfetchR\\"

# # run over all metadata files
# meta_filenames <- list.files(path = dir_path, pattern = "^umar_serije_metadata_",
#                     recursive = TRUE, full.names = TRUE)
#
# for (meta_filename in meta_filenames){
#   update_metadata(meta_filename, con, schema = "platform",
#                            path = log_path)
# }

# run over single metadata file
args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 1) {
  stop("No initials provided.")
}

initials <- args[1]

meta_filename <- paste0(dir_path, "\\", initials, "\\umar_serije_metadata_", initials, ".xlsx")
update_metadata(meta_filename, con, schema = "platform",
                path = log_path)
