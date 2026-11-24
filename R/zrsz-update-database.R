# devtools::install_github("majazaloznik/ZRSZfetchR")

library(ZRSZfetchR)

# logging in as  maintainer
con <- DBI::dbConnect(RPostgres::Postgres(),
                      dbname = "platform",
                      host = "localhost",
                      port = 5432,
                      user = "postgres",
                      password = Sys.getenv("PG_PG_PSW"),
                      client_encoding = "utf8")

# Import data for all tables
purrr::walk(1:nrow(ZRSZfetchR:::meta), function(i) {
  meta <- ZRSZfetchR:::meta[i,]
  message("Processing table: ", meta$code)
  tryCatch({
    ZRSZ_import_data_points(meta, con, schema = "platform")
  }, error = function(e) {
    message("Error processing ", meta$code, ": ", e$message)
  })
})


# source("\\\\192.168.38.7\\public$\\Avtomatizacija\\umar-automation-scripts\\R\\update_indicator_report.R")

table_ids <- c(33, 127, 444, 445, 446, 447, 451, 453, 454)
purrr::map(table_ids, ~UMARimportR::vintage_cleanup(con, .x,
                                                    schema = "platform"))

DBI::dbExecute(con, "set search_path to views")
DBI::dbExecute(con, "REFRESH MATERIALIZED VIEW mat_latest_data_points")


