# ============================================================================
# Eurostat metabase structure monitor
# ============================================================================

ingest <- function(con, force = FALSE) {
  message("/n*** starting ingest ***")
  url <- "https://ec.europa.eu/eurostat/api/dissemination/catalogue/metabase.txt.gz"

  ## --- fetch ---
  tmp <- tempfile(fileext = ".txt.gz")
  httr2::request(url) |> httr2::req_perform(path = tmp)
  sha <- digest::digest(file = tmp, algo = "sha256")

  mb <- data.table::fread(tmp, header = FALSE, sep = "\t",
                          na.strings = NULL,                 # NA = Namibia
                          col.names = c("dataset", "dim", "pos"))
  mb[, ord := data.table::rowid(dataset, dim)]

  ## --- dedup guard ---
  snaps <- DBI::dbGetQuery(con,
                           "SELECT file_sha256 FROM eurostat.snapshot ORDER BY snapshot_id DESC")

  if (!force && nrow(snaps) && snaps$file_sha256[1] == sha) {
    return(list(status = "unchanged", snapshot_id = NA_integer_, n_rows = NA_integer_))
  }
  rolled_back <- sha %in% snaps$file_sha256

  ## --- ingest (transaction returns the new snapshot_id) ---
  sid <- DBI::dbWithTransaction(con, {
    ts <- Sys.time()                                   # observation time (no header available)

    this_sid <- DBI::dbGetQuery(con, "
      INSERT INTO eurostat.snapshot (file_sha256, observed_at, n_rows)
      VALUES ($1,$2,$3) RETURNING snapshot_id",
                                list(sha, ts, nrow(mb)))$snapshot_id

    DBI::dbWriteTable(con, "staging_tmp", as.data.frame(mb),
                      temporary = TRUE, overwrite = TRUE)
    DBI::dbExecute(con, "ANALYZE staging_tmp")
    DBI::dbExecute(con, "CREATE INDEX ON staging_tmp (dataset, dim, pos)")

    n_live <- DBI::dbGetQuery(con,
                              "SELECT count(*) n FROM eurostat.metabase WHERE valid_to IS NULL")$n

    if (n_live == 0) {
      DBI::dbExecute(con, "
        INSERT INTO eurostat.metabase
          (dataset,dim,pos,ord,valid_from,valid_to,from_snapshot_id,to_snapshot_id)
        SELECT dataset,dim,pos,ord,$1,NULL,$2,NULL FROM staging_tmp", list(ts, this_sid))
    } else {
      DBI::dbExecute(con, "
        UPDATE eurostat.metabase m SET valid_to = $1, to_snapshot_id = $2
        WHERE m.valid_to IS NULL
          AND NOT EXISTS (SELECT 1 FROM staging_tmp s
            WHERE s.dataset=m.dataset AND s.dim=m.dim AND s.pos=m.pos)", list(ts, this_sid))
      DBI::dbExecute(con, "
        INSERT INTO eurostat.metabase
          (dataset,dim,pos,ord,valid_from,valid_to,from_snapshot_id,to_snapshot_id)
        SELECT s.dataset,s.dim,s.pos,s.ord,$1,NULL,$2,NULL FROM staging_tmp s
        WHERE NOT EXISTS (SELECT 1 FROM eurostat.metabase m
          WHERE m.valid_to IS NULL
            AND m.dataset=s.dataset AND m.dim=s.dim AND m.pos=s.pos)", list(ts, this_sid))
    }

    this_sid                                            # <- return value of dbWithTransaction
  })
  message("/n*** ingest complete ***")
  list(status = "changed", snapshot_id = as.character(sid),
       n_rows = nrow(mb),
       rolled_back = rolled_back)
}

compute_alerts <- function(con, sid) {
  at <- DBI::dbGetQuery(con,
                        "SELECT observed_at FROM eurostat.snapshot WHERE snapshot_id = $1", list(sid))$observed_at

  DBI::dbGetQuery(con, "
    -- datasets that gained their FIRST-EVER live rows in this run = brand new
    WITH new_ds AS (
      SELECT DISTINCT m.dataset
      FROM eurostat.metabase m
      WHERE m.valid_from = $1
        AND NOT EXISTS (
          SELECT 1 FROM eurostat.metabase o
          WHERE o.dataset = m.dataset
            AND o.valid_from < $1)          -- any earlier row at all = not new
    ),
    dim_ev AS (
      SELECT dataset, dim, 'dim_added' AS change_type FROM eurostat.metabase m
      WHERE m.valid_from = $1 AND m.dim <> 'time'
        AND m.dataset NOT IN (SELECT dataset FROM new_ds)      -- exclude new datasets
        AND NOT EXISTS (SELECT 1 FROM eurostat.metabase o
          WHERE o.dataset=m.dataset AND o.dim=m.dim AND o.valid_from < m.valid_from
            AND (o.valid_to IS NULL OR o.valid_to >= m.valid_from))
      UNION ALL
      SELECT dataset, dim, 'dim_removed' FROM eurostat.metabase m
      WHERE m.valid_to = $1 AND m.dim <> 'time'
        AND m.dataset NOT IN (SELECT dataset FROM new_ds)
        AND NOT EXISTS (SELECT 1 FROM eurostat.metabase o
          WHERE o.dataset=m.dataset AND o.dim=m.dim AND o.valid_to IS NULL)
    ),
    pos_ev AS (
      SELECT dataset,
             count(*) FILTER (WHERE kind='added')   AS pos_added,
             count(*) FILTER (WHERE kind='removed') AS pos_removed
      FROM (
        SELECT dataset,'added'   AS kind FROM eurostat.metabase
          WHERE valid_from=$1 AND dim<>'time' AND dataset NOT IN (SELECT dataset FROM new_ds)
        UNION ALL
        SELECT dataset,'removed'         FROM eurostat.metabase
          WHERE valid_to  =$1 AND dim<>'time' AND dataset NOT IN (SELECT dataset FROM new_ds)
      ) x GROUP BY dataset
    )
    SELECT coalesce(d.dataset, p.dataset) AS dataset,
           'changed' AS event,
           string_agg(DISTINCT d.dim||':'||d.change_type, ', ') AS dim_changes,
           max(p.pos_added)   AS level_added,
           max(p.pos_removed) AS level_removed
    FROM dim_ev d FULL JOIN pos_ev p ON p.dataset = d.dataset
    GROUP BY coalesce(d.dataset, p.dataset)

    UNION ALL

    SELECT dataset, 'dataset_added' AS event, NULL, NULL, NULL
    FROM new_ds

    ORDER BY event, dataset", list(at))
}


send_failure_email <- function(msg) {
  try({
    gmailr::gm_auth_configure(path ="data/gmailr/credentials.json")
    gmailr::gm_auth(email = "umar.data.bot@gmail.com", cache = ".secret")
    email <- gmailr::gm_mime() |>
      gmailr::gm_to("maja.zaloznik@gmail.com") |>
      gmailr::gm_from("bot@gov.si") |>
      gmailr::gm_subject("[UMAR-BOT] Eurostat metabase ingest FAILED") |>
      gmailr::gm_text_body(sprintf("%s  on  %s\n\n%s",
                                   Sys.time(), Sys.info()[["nodename"]], msg))
    gmailr::gm_send_message(email)
  }, error = function(e) message("email send failed: ", conditionMessage(e)))
}

send_alert_email <- function(alerts, sid) {
  body <- paste0(
    sprintf("Eurostat metabase structure changes (snapshot %d, %s)\n\n", sid, Sys.time()),
    paste(capture.output(print(alerts, row.names = FALSE)), collapse = "\n")
  )
  tryCatch({
    gmailr::gm_auth_configure(path = "data/gmailr/credentials.json")
    gmailr::gm_auth(email = "umar.data.bot@gmail.com", cache = ".secret")
    email <- gmailr::gm_mime() |>
      gmailr::gm_to("maja.zaloznik@gmail.com") |>
      gmailr::gm_from("bot@gov.si") |>
      gmailr::gm_subject(sprintf("[UMAR-BOT] Eurostat structure changes: %d datasets", nrow(alerts))) |>
      gmailr::gm_text_body(body)
    gmailr::gm_send_message(email)
  }, error = function(e) message("alert email failed: ", conditionMessage(e)))
}

main <- function() {
  con <- DBI::dbConnect(RPostgres::Postgres(),
                        dbname = "platform", host = "localhost", port = 5432,
                        user = "postgres", password = Sys.getenv("PG_PG_PSW"),
                        client_encoding = "utf8")
  on.exit(DBI::dbDisconnect(con), add = TRUE)           # also releases the advisory lock

  # singleton run
  if (!DBI::dbGetQuery(con,
                       "SELECT pg_try_advisory_lock(hashtext('eurostat_metabase_ingest'))")[[1]]) {
    message("another ingest holds the lock; exiting"); return(invisible())
  }

  res <- tryCatch(
    ingest(con),
    error = function(e) {
      send_failure_email(conditionMessage(e))
      stop(e)                                           # re-raise so .Rout records the traceback
    })

  if (identical(res$status, "unchanged")) {
    message("unchanged since last run; exiting")
  } else {
    if (isTRUE(res$rolled_back))
      warning(sprintf("metabase reverted to a previously-seen structure (snapshot %s)",
                      format(res$snapshot_id)))
    message(sprintf("ingested snapshot %s: %d rows",
                    format(res$snapshot_id), res$n_rows))
  }

  if (identical(res$status, "changed")) {
    alerts <- compute_alerts(con, res$snapshot_id)
    if (nrow(alerts)) send_alert_email(alerts, res$snapshot_id)
  }

  invisible(res)
}

main()
