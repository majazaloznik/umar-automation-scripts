# devtools::install_github("majazaloznik/ECBfetchR")
cat("Run started:", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "\n")
library(ECBfetchR)

con <- DBI::dbConnect(RPostgres::Postgres(),
                      dbname = "platform",
                      host = "localhost",
                      port = 5432,
                      user = "postgres",
                      password = Sys.getenv("PG_PG_PSW"),
                      client_encoding = "utf8")
fix_ecb_url()

# current list of tracked series
series_keys <- c("BPS.Q.N.I9.W1.S1.S1.LE.N.FA._T.F._Z.EUR._T._X.N.ALL",
                 "BPS.Q.N.I9.W1.S1.S1.T.B.CA._Z._Z._Z.EUR_R_B1GQ._T._X.N.ALL",
                 "FM.M.U2.EUR.RT.MM.EURIBOR3MD_.HSTA",
                 "FM.M.U2.EUR.RT.MM.EURIBOR6MD_.HSTA")


purrr::walk(series_keys, ~{
  message("Processing: ", .x)
  ECB_import_data_points(.x, con)
})

update_tables <- UMARaccessR::sql_get_tables_from_source(con, "platform", 8, TRUE)

# cleanup hashes for Eurostat tables.
purrr::walk(update_tables$id, ~UMARimportR::vintage_cleanup(con, .x, schema = "platform"))

# # # insert struct for single series
# series_key <- "FM.D.U2.EUR.4F.KR.MRR_FR.LEV"
# ECB_import_structure(series_key, con)
# #
# # # insert data for single series
# ECB_import_data_points(series_key, con)
