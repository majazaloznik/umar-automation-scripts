# devtools::install_github("majazaloznik/ZRSZfetchR")

library(ZRSZfetchR)

# logging in as  maintainer
con <- DBI::dbConnect(RPostgres::Postgres(),
                      dbname = "platform",
                      host = "localhost",
                      port = 5432,
                      user = "majaz",
                      password = Sys.getenv("PG_MZ_PSW"),
                      client_encoding = "utf8")


# update BO table
meta <- ZRSZfetchR:::meta[1,]
x <- ZRSZ_import_data_points(meta, con, schema = "platform")

# update BO_OS_table
meta <- ZRSZfetchR:::meta[2,]
x <- ZRSZ_import_data_points(meta, con, schema = "platform")

source("\\\\192.168.38.7\\public$\\Avtomatizacija\\umar-automation-scripts\\R\\update_indicator_report.R")

