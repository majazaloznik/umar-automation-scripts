################################################################################
# UMAR DATA UPDATE
#   1. feeders:  source files -> umar-data Excel files      (umar-data/feeders/)
#   2. ingest:   umar-data Excel files -> platform           (one step per author)
#   3. post:     vintage cleanup + view refresh, only if something was imported
#   4. derived:  outputs computed from the database          (umar-data/derived/)
################################################################################
# pak::pkg_install("majazaloznik/UMARfetchR")
# pak::pkg_install("majazaloznik/UmarDataBotR")
setwd("\\\\192.168.38.7\\public$\\Avtomatizacija\\umar-automation-scripts\\")
source("R/common/admin-common.R")   # platform_con()
source("R/umar-data/feeders/_helpers.R")    # newest_file(), upsert_umar_data()

umar_data_dir <- "\\\\192.168.38.7\\public$\\Avtomatizacija\\umar-data"
log_path      <- "\\\\192.168.38.7\\public$\\Avtomatizacija\\umar-automation-scripts\\logs\\UMARfetchR"
feeder_dir    <- "R/umar-data/feeders"
derived_dir   <- "R/umar-data/derived"

#' Run a feeder or derived script in its own environment
#'
#' @return the value of the script's last expression (feeders: new periods)
run_script <- function(file) {
  source(file, local = new.env(), encoding = "UTF-8")$value
}

#' Pair metadata and data files by initials
umar_data_files <- function(dir) {
  f <- list.files(dir, "^umar_serije_(metadata|podatki)_.+\\.xlsx$",
                  recursive = TRUE, full.names = TRUE)
  b <- basename(f)
  data.frame(path = f,
             type = sub("^umar_serije_(metadata|podatki)_.*", "\\1", b),
             initials = sub("^umar_serije_(metadata|podatki)_(.+)\\.xlsx$", "\\2", b)) |>
    tidyr::pivot_wider(names_from = type, values_from = path)
}

run <- UmarDataBotR::run_start("umar_data_update",
                               maintainer = "maja.zaloznik@gmail.com",
                               heartbeat  = TRUE)

UmarDataBotR::with_run(run, {

  # 1. feeders: every script in feeders/ -------------------------------------
  UmarDataBotR::log_msg("start processing feeder files")
  feeders <- list.files(feeder_dir, "^feed_.*\\.R$", full.names = TRUE)
  fed <- purrr::map_int(feeders, \(f) UmarDataBotR::run_step(
    run, sub("\\.R$", "", basename(f)), run_script(f),
    critical = FALSE, fallback = NA_integer_))
  names(fed) <- sub("^feed_(.*)\\.R$", "\\1", basename(feeders))
  UmarDataBotR::run_summary(run, "Nova obdobja v umar-data: %s",
                            paste(names(fed), fed, sep = "=", collapse = ", "))

  # 2. ingest -----------------------------------------------------------------
  UmarDataBotR::log_msg("start database ingest")
  con <- UmarDataBotR::run_step(run, "connect platform", platform_con())

  pairs <- umar_data_files(umar_data_dir)
  unpaired <- pairs$initials[is.na(pairs$metadata) | is.na(pairs$podatki)]
  if (length(unpaired)) UmarDataBotR::run_step(run, "file pairing",
                                               stop("missing metadata or data file for: ", toString(unpaired)), critical = FALSE)
  pairs <- pairs[!pairs$initials %in% unpaired, ]

  ingested <- purrr::pmap(pairs, \(initials, metadata, podatki) UmarDataBotR::run_step(
    run, paste("ingest", initials),
    UMARfetchR::update_data(metadata, podatki, con, "platform", path = log_path),
    critical = FALSE))
  names(ingested) <- pairs$initials

  rows <- purrr::map_dbl(ingested, \(r) if (is.null(r)) NA_real_ else r$rows)
  imported <- rows[!is.na(rows) & rows > 0]
  UmarDataBotR::run_summary(run, "Uvo\u017eeni podatki: %s",
                            if (length(imported)) paste(names(imported), imported, sep = "=", collapse = ", ")
                            else "nobenih")
  UmarDataBotR::new_data(run, length(imported) > 0)

  # each author gets their own import log
  notify <- purrr::keep(ingested[names(imported)], \(r) !is.na(r$email))
  if (length(notify) > 0) UmarDataBotR::run_step(run, "author emails", {
    UmarDataBotR::bot_auth()
    purrr::walk(notify, \(r) UMARfetchR::email_log(r$log_file, r$email, r$initials))
  }, critical = FALSE)

  # 3. post-processing, only if something was imported --------------------------

  if (length(imported) > 0) {
    UmarDataBotR::log_msg("start postprocessing in database")
    codes <- unique(unlist(purrr::map(ingested[names(imported)], "codes")))
    table_ids <- UmarDataBotR::run_step(run, "find affected tables",
                                        DBI::dbGetQuery(con, sprintf(
                                          "SELECT DISTINCT table_id FROM platform.series WHERE code IN (%s)",
                                          paste(DBI::dbQuoteString(con, codes), collapse = ",")))$table_id)

    purrr::walk(table_ids, \(id) UmarDataBotR::run_step(
      run, paste("vintage_cleanup", id),
      UMARimportR::vintage_cleanup(con, table_id = as.numeric(id), schema = "platform"),
      critical = FALSE))

    UmarDataBotR::run_step(run, "refresh views", {
      DBI::dbExecute(con, "REFRESH MATERIALIZED VIEW views.mat_latest_series_insolvency_skd21")
      DBI::dbExecute(con, "REFRESH MATERIALIZED VIEW views.mat_latest_series_stecaji_skd21")
      DBI::dbExecute(con, "REFRESH MATERIALIZED VIEW views.mat_latest_data_points")
    })
  }

  # 4. derived outputs: every script in derived/, after the refresh ---------------
  derived <- list.files(derived_dir, "\\.R$", full.names = TRUE)
  UmarDataBotR::log_msg("start derived calculations")
  purrr::walk(derived, \(f) UmarDataBotR::run_step(
    run, sub("\\.R$", "", basename(f)), run_script(f), critical = FALSE))

  DBI::dbDisconnect(con)
})
