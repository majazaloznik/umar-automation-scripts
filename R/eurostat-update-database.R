# devtools::install_github("majazaloznik/EUROSTATfetchR")
# devtools::install_github("majazaloznik/UMARimportR")
# devtools::install_github("majazaloznik/UMARaccessR")

library(dplyr)
library(EUROSTATfetchR)
# logging in as  maintainer
con <- DBI::dbConnect(RPostgres::Postgres(),
                      dbname = "platform",
                      host = "localhost",
                      port = 5432,
                      user = "postgres",
                      password = Sys.getenv("PG_PG_PSW"),
                      client_encoding = "utf8")
# set schema search path
# DBI::dbExecute(con, "set search_path to platform")
# get tables to update
update_tables <- UMARaccessR::sql_get_tables_from_source(con, "platform", 7, TRUE)
# update all the tables from eurosat
purrr::walk(update_tables$code, ~EUROSTAT_import_data_points(.x, con, schema = "platform"))
# cleanup hashes for Eurostat tables.
purrr::walk(update_tables$id, ~UMARimportR::vintage_cleanup(con, .x, schema = "platform"))


# # # # import single table
# EUROSTAT_import_structure( con, "sts_sepr_m", source_id = 7,
#                            schema = "platform", all_levels = FALSE,
#                            keep_vintage = FALSE)


# # update single table
# EUROSTAT_import_data_points("teina010", con, "platform")
# if data point import failed but vintages were created, run
# UMARimportR::remove_empty_vintages(con, "platform")

# # delete a table!!
# UMARaccessR::sql_get_table_id_from_table_code(con, "1701116S", "platform")
# UMARimportR::delete_table(con, 252, "platform")

# # update series selection list
# df <- UMARaccessR::sql_get_all_series_wtable_names(con)
# UMARaccessR::create_selection_excel(df, outfile = "O:\\Avtomatizacija\\indikatorji_porocilo\\navodila_za_avtorje\\seznam_serij")

DBI::dbExecute(con, "set search_path to views")
DBI::dbExecute(con, "REFRESH MATERIALIZED VIEW mat_latest_data_points")

#source("\\\\192.168.38.7\\public$\\Avtomatizacija\\umar-automation-scripts\\R\\update_indicator_report.R")

