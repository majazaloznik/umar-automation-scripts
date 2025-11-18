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
# clean up vintages and add new hashes
table_ids <- c(220, 222, 233, 234, 235, 236, 237, 238, 239, 240, 241, 242, 243,
244, 245, 246, 247, 248, 249, 257)
purrr::map(table_ids, ~UMARimportR::vintage_cleanup(con, .x,
                                                   schema = "platform"))

# # delete most recent vintages for single table
# idz  <- UMARaccessR::sql_get_latest_vintages_for_table_id( 257, con)$vintage_id
# UMARimportR::delete_vintage(con, idz)
# # # # add single table, selecting levels
# BS_import_structure("i_32_6ms", con, "platform", all_levels = FALSE, keep_vintage = FALSE)
# #

# # # # update single table
# BS_import_data_points("i_32_6ms", con, "platform")
# UMARimportR::vintage_cleanup(con, 257, schema = "platform")

# if data point import failed but vintages were created, run
# UMARimportR::remove_empty_vintages(con, "platform")

# # remove specific table
# UMARimportR::delete_table(con, 219, "platform")

# # update series selection list
# df <- UMARaccessR::sql_get_all_series_wtable_names(con, "platform")
# UMARaccessR::create_selection_excel(df, outfile = "O:\\Avtomatizacija\\indikatorji_porocilo\\navodila_za_avtorje\\seznam_serij")

DBI::dbExecute(con, "set search_path to views")
DBI::dbExecute(con, "REFRESH MATERIALIZED VIEW mat_latest_data_points")





