# devtools::install_github("majazaloznik/PMIfetchR")
cat("Run started:", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "\n")
library(PMIfetchR)
con <- DBI::dbConnect(RPostgres::Postgres(),
                      dbname = "platform",
                      host = "localhost",
                      port = 5432,
                      user = "postgres",
                      password = Sys.getenv("PG_PG_PSW"),
                      client_encoding = "utf8")

# # 1. Source (one-time)
# source_df <- prepare_source_table(con)
# UMARimportR::insert_new_source(con, source_df)

# # 2. Structure (one-time per region)
# PMI_import_structure("eurozone", con)
# PMI_import_structure("germany", con)

# # 3. Historical data (one-time per region)
# PMI_import_historical_data(
#   system.file("extdata", "historical_ea_data.csv", package = "PMIfetchR"),
#   "eurozone", con)
# PMI_import_historical_data(
#   system.file("extdata", "historical_de_data.csv", package = "PMIfetchR"),
#   "germany", con)

# 4. Latest data (scrape first, then import)
releases_ez <- get_latest_pmi(region = "Eurozone")
releases_de <- get_latest_pmi(region = "Germany")
PMI_import_data(releases_ez, "eurozone", con)
PMI_import_data(releases_de, "germany", con)

# get tables to update
update_tables <- UMARaccessR::sql_get_tables_from_source(con, "platform", 9, TRUE)
# cleanup hashes for all tables.
purrr::walk(update_tables$id, ~UMARimportR::vintage_cleanup(con, .x, schema = "platform"))

print("vintages cleaned up")
