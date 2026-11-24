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

print("updating tables\n")
# update all the tables from SUR
purrr::walk(update_tables$code, ~SURS_import_data_points(.x, con, schema = "platform"))
print("updating tables done\n")
DBI::dbExecute(con, "set search_path to views")
DBI::dbExecute(con, "REFRESH MATERIALIZED VIEW mat_latest_data_points")
print("materialized view updated")
# cleanup hashes for all tables.
purrr::walk(update_tables$id, ~UMARimportR::vintage_cleanup(con, .x, schema = "platform"))

print("vintages cleaned up")

# # # # # # import single table
# SURS_import_structure("0419001S", con, "platform", all_levels = FALSE)

# delete most recent vintages for single table
# idz  <- UMARaccessR::sql_get_latest_vintages_for_table_id( 51, con)$vintage_id
# UMARimportR::delete_vintage(con, idz)

# if table is archived and no timeval is defined, then you need
# debugonce(get_table_levels_from_px)
# and then mtd$variables[[1]]$time <- TRUE or whichever dimension is the time one
# then continue normally.

# # update single table
# SURS_import_data_points("0419001S", con, "platform")
# if data point import failed but vintages were created, run
# UMARimportR::remove_empty_vintages(con, "platform")

# # delete a table!!
# UMARaccessR::sql_get_table_id_from_table_code(con, "1701116S", "platform")
# UMARimportR::delete_table(con, 252, "platform")

# update series selection list
# df <- UMARaccessR::sql_get_all_series_wtable_names(con)
# UMARaccessR::create_selection_excel(df, outfile = "O:\\Avtomatizacija\\indikatorji_porocilo\\navodila_za_avtorje\\seznam_serij")

source("\\\\192.168.38.7\\public$\\Avtomatizacija\\umar-automation-scripts\\R\\update_indicator_report.R")
