# devtools::install_github("majazaloznik/SURSfetchR")
# devtools::install_github("majazaloznik/UMARimportR")
# devtools::install_github("majazaloznik/UMARaccessR")

library(dplyr)
library(SURSfetchR)
# logging in as  maintainer
con <- DBI::dbConnect(RPostgres::Postgres(),
                      dbname = "platform",
                      host = "localhost",
                      port = 5432,
                      user = "postgres",
                      password = Sys.getenv("PG_PG_PSW"),
                      client_encoding = "utf8")
# set schema search path
DBI::dbExecute(con, "set search_path to platform")
# get tables to update
update_tables <- UMARaccessR::sql_get_tables_from_source(con, "platform", 1, TRUE)
# update all the tables from SUR
purrr::walk(update_tables$code, ~SURS_import_data_points(.x, con, schema = "platform"))
# cleanup hashes for all tables.
UMARimportR::vintage_cleanup(con, schema = "platform")

# # # import single table
# SURS_import_structure("0400600S", con, "platform", all_levels = FALSE)
# # # update single table
# SURS_import_data_points("0400600S", con, "platform")
# if data point import failed but vintages were created, run
# UMARimportR::remove_empty_vintages(con, "platform")

# # delete a table!!
# UMARaccessR::sql_get_table_id_from_table_code(con, "1701116S", "platform")
# UMARimportR::delete_table(con, 252, "platform")

# # update series selection list
# df <- UMARaccessR::sql_get_all_series_wtable_names(con)
# UMARaccessR::create_selection_excel(df, outfile = "O:\\Avtomatizacija\\indikatorji_porocilo\\navodila_za_avtorje\\seznam_serij")

DBI::dbExecute(con, "set search_path to views")
DBI::dbExecute(con, "REFRESH MATERIALIZED VIEW latest_data_points")

source("\\\\192.168.38.7\\public$\\Avtomatizacija\\umar-automation-scripts\\R\\update_indicator_report.R")

