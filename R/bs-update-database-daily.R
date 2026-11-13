# pak::pkg_install("majazaloznik/BSfetchR")
# pak::pkg_install("majazaloznik/UMARimportR")
# pak::pkg_install("majazaloznik/UMARaccessR")
# pak::pkg_install("majazaloznik/UmarDataBotR")

run <- UmarDataBotR::run_start(
  name       = "BS-platform",
  maintainer = "maja.zaloznik@gmail.com",
  heartbeat  = TRUE)

UmarDataBotR::with_run(run, {

  con <- UmarDataBotR::run_step(run,
                                "DB connect",
                                DBI::dbConnect(RPostgres::Postgres(),
                                               dbname = "platform",
                                               host = "localhost",
                                               port = 5432,
                                               user = "postgres",
                                               password = Sys.getenv("PG_PG_PSW"),
                                               client_encoding = "utf8"))

  update_tables <- UmarDataBotR::run_step(
    run, "get BS tables",
    UMARaccessR::sql_get_tables_from_source(con, "platform", 5, TRUE))

  # BS_import_data_points() catches its own errors and returns them in
  # $data_error, so re-raise them as a non-critical step failure
  import_table <- function(code) {
    r <- BSfetchR::BS_import_data_points(code, con, schema = "platform")
    if (!is.null(r$data_error)) stop(r$data_error, call. = FALSE)
    r
  }

  results <- purrr::map(update_tables$code, \(code)
                        UmarDataBotR::run_step(run, paste("BS import", code),
                                               import_table(code), critical = FALSE))
  names(results) <- update_tables$code

  n_failed <- sum(purrr::map_lgl(results, is.null))
  UmarDataBotR::run_summary(run, "%d tables processed, %d failed.",
                            length(results), n_failed)

  purrr::walk(update_tables$id, \(id)
              UmarDataBotR::run_step(run, paste("vintage_cleanup", id),
                                     UMARimportR::vintage_cleanup(con, id, schema = "platform"),
                                     critical = FALSE))

  UmarDataBotR::run_step(run, "refresh mat_latest_data_points",
                         DBI::dbExecute(con, "REFRESH MATERIALIZED VIEW views.mat_latest_data_points"))

  DBI::dbDisconnect(con)
})
