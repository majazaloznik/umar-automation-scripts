################################################################################
# DAVCNE -> PLATFORM
# Monthly aggregates of davcni_racuni into the platform database.
# Runs weekly, in the same .bat as the davcne import, after it. Idempotent:
# most weeks there is no new complete month and nothing is imported.
################################################################################
setwd("\\\\192.168.38.7\\public$\\Avtomatizacija\\umar-automation-scripts\\")
source("R/davcne/_functions_davcne_update_platform.R")
source("R/common/admin-common.R")

meta_file <- "\\\\192.168.38.7\\public$\\Avtomatizacija\\umar-data\\UDB\\umar_serije_metadata_UDB.xlsx"

run <- UmarDataBotR::run_start("davcne_update_platform",
                           maintainer = "maja.zaloznik@gmail.com",
                           recipients = character(),  # add users who want the monthly notice
                           heartbeat  = TRUE)

UmarDataBotR::with_run(run, {
  con_d <- davcne_con()
  con <- platform_con()

  DBI::dbExecute(con, "set search_path to platform")

  long <- UmarDataBotR::run_step(run, "read and aggregate davcni_racuni", read_davcne_long(con_d))
  UmarDataBotR::run_summary(run, "Zadnji popoln mesec: %s", format(max(long$period), "%Y-%m"))

  new_codes <- UmarDataBotR::run_step(run, "register new series",
                                  register_new_davcne_series(long, meta_file, con))
  if (length(new_codes) > 0)
    UmarDataBotR::run_summary(run, "Na novo registriranih serij: %d", length(new_codes))

  code_map <- davcne_code_map(meta_file)
  tables   <- UmarDataBotR::run_step(run, "build wide tables", davcne_wide_tables(long, code_map))

  results <- purrr::imap_dbl(tables, \(x, lvl) UmarDataBotR::run_step(
    run, paste("import", lvl),
    UMARfetchR::import_data_df(x, "M", code_map$series_code, con, schema = "platform"),
    critical = FALSE, fallback = NA_real_))
  UmarDataBotR::run_summary(run, "Novih podatkovnih to\u010dk: %s",
                        paste(names(results), results, sep = " = ", collapse = ", "))
  UmarDataBotR::new_data(run, sum(results, na.rm = TRUE) > 0)

  # vintage cleanup only for tables that got new data (nothing to clean otherwise)
  ok_levels <- names(results)[!is.na(results) & results > 0]
  table_ids <- code_map |>
    dplyr::filter(level %in% ok_levels) |>
    dplyr::distinct(table_code) |>
    dplyr::pull() |>
    purrr::map_int(\(x) as.integer(UMARaccessR::sql_get_table_id_from_table_code(con, x, "platform")))
  if (length(table_ids) > 0)
    UmarDataBotR::run_step(run, "vintage cleanup",
                       purrr::walk(table_ids, \(id) UMARimportR::vintage_cleanup(con, id, schema = "platform")))

  DBI::dbDisconnect(con_d)
  DBI::dbDisconnect(con)
})
