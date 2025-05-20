# devtools::install_github("majazaloznik/BSfetchR")
# devtools::install_github("majazaloznik/UMARimportR")
# devtools::install_github("majazaloznik/UMARaccessR")

library(dplyr)
library(BSfetchR)
# logging in as  maintainer
con <- DBI::dbConnect(RPostgres::Postgres(),
                      dbname = "platform",
                      host = "localhost",
                      port = 5432,
                      user = "postgres",
                      password = Sys.getenv("PG_PG_PSW"),
                      client_encoding = "utf8")


# get tables to update
update_tables <- UMARaccessR::sql_get_tables_from_source(con, "platform", 5, TRUE)
# update all the tables from BS
purrr::walk(update_tables$code, ~BS_import_data_points(.x, con, schema = "platform"))
# cleanup hashes for all tables.
UMARimportR::vintage_cleanup(con, schema = "platform")


# # add single table, selecting levels
# BS_import_structure("FSR_IUS", con, "platform", all_levels = FALSE, keep_vintage = FALSE)

# # update single table
# BS_import_data_points("I1_5BBS", con, "platform")
# if data point import failed but vintages were created, run
# UMARimportR::remove_empty_vintages(con, "platform")

# # remove specific table
# UMARimportR::delete_table(con, 219, "platform")

# # update series selection list
# df <- UMARaccessR::sql_get_all_series_wtable_names(con, "platform")
# UMARaccessR::create_selection_excel(df, outfile = "O:\\Avtomatizacija\\indikatorji_porocilo\\navodila_za_avtorje\\seznam_serij")

DBI::dbExecute(con, "set search_path to views")
DBI::dbExecute(con, "REFRESH MATERIALIZED VIEW latest_data_points")





