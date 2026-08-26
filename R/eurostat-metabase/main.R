#' Run the Eurostat metabase structure monitor
#'
#' Entry point called by the scheduled batch job. Connects, takes a singleton
#' advisory lock, configures email, refreshes subscriptions, ingests the
#' metabase, and — if the structure changed — computes and sends per-subscriber
#' alerts. Every stage is wrapped so failures email the maintainer and are
#' recorded in the log rather than failing silently.
#'
#' @return Invisibly, the ingest result list.
main <- function() {
  con <- DBI::dbConnect(RPostgres::Postgres(),
                        dbname = "platform", host = "localhost", port = 5432,
                        user = "postgres", password = Sys.getenv("PG_PG_PSW"),
                        client_encoding = "utf8")
  on.exit(DBI::dbDisconnect(con), add = TRUE)

  if (!DBI::dbGetQuery(con,
                       "SELECT pg_try_advisory_lock(hashtext('eurostat_metabase_ingest'))")[[1]]) {
    message("another ingest holds the lock; exiting"); return(invisible())
  }

  init_email()
  load_subscriptions(con)            # validate human input first; fails fast if corrupt

  res <- tryCatch(
    ingest(con),
    error = function(e) { send_failure_email(conditionMessage(e)); stop(e) })

  if (identical(res$status, "unchanged")) {
    message("unchanged since last run; exiting")
    return(invisible(res))
  }

  if (isTRUE(res$rolled_back))
    warning(sprintf("metabase reverted to a previously-seen structure (snapshot %s)",
                    format(res$snapshot_id)))
  message(sprintf("ingested snapshot %s: %d rows", format(res$snapshot_id), res$n_rows))

  tryCatch(
    send_alerts_perperson(con,
                          UMARaccessR::sql_get_eurostat_metabase_changes_from_snapshot(
                            con, res$snapshot_id, "eurostat"),
                          res$snapshot_id),
    error = function(e) {
      send_failure_email(sprintf("alert stage failed for snapshot %s: %s",
                                 format(res$snapshot_id), conditionMessage(e)))
      stop(e)
    })

  invisible(res)
}
