# devtools::install_github("majazaloznik/ZRSZfetchR")
library(ZRSZfetchR)
schema = "platform"
# logging in as  maintainer
con <- DBI::dbConnect(RPostgres::Postgres(),
                      dbname = "platform",
                      host = "localhost",
                      port = 5432,
                      user = "majaz",
                      password = Sys.getenv("PG_MZ_PSW"),
                      client_encoding = "utf8")
# set schema search path
DBI::dbExecute(con, paste("set search_path to", schema))

# update BO table
zrsz_bo_script(con, schema)


source("\\\\192.168.38.7\\public$\\Avtomatizacija\\umar-automation-scripts\\R\\update_indicator_report.R")

