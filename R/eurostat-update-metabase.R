main <- function() {
  url <- "https://ec.europa.eu/eurostat/api/dissemination/catalogue/metabase.txt.gz"

  ## --- fetch (no DB lock held; network is slow) ---
  tmp <- tempfile(fileext = ".txt.gz")
  httr2::request(url) |> httr2::req_perform(path = tmp)
  sha <- digest::digest(file = tmp, algo = "sha256")

  mb <- data.table::fread(tmp, header = FALSE, sep = "\t",
                          na.strings = NULL,                 # NA = Namibia
                          col.names = c("dataset", "dim", "pos"))
  mb[, ord := data.table::rowid(dataset, dim)]

  ## --- DB critical section ---
  con <- DBI::dbConnect(RPostgres::Postgres(),
                        dbname = "platform", host = "localhost", port = 5432,
                        user = "postgres", password = Sys.getenv("PG_PG_PSW"),
                        client_encoding = "utf8")
  on.exit(DBI::dbDisconnect(con), add = TRUE)

  # singleton run
  if (!DBI::dbGetQuery(con,
                       "SELECT pg_try_advisory_lock(hashtext('eurostat_metabase_ingest'))")[[1]]) {
    message("another ingest holds the lock; exiting"); return(invisible())
  }

  # dedup: exit if identical to latest snapshot; warn (but proceed) on rollback
  snaps <- DBI::dbGetQuery(con,
                           "SELECT file_sha256 FROM eurostat.snapshot ORDER BY snapshot_id DESC")
  if (nrow(snaps) && snaps$file_sha256[1] == sha) {
    message("unchanged since last run; exiting"); return(invisible())
  }
  if (sha %in% snaps$file_sha256) {
    warning(sprintf("metabase reverted to a previously-seen structure (sha %s)",
                    substr(sha, 1, 12)))
  }

  DBI::dbWithTransaction(con, {
    ts  <- Sys.time()
    sid <- DBI::dbGetQuery(con, "
      INSERT INTO eurostat.snapshot (file_sha256, observed_at, n_rows)
      VALUES ($1,$2,$3) RETURNING snapshot_id", list(sha, ts, nrow(mb)))$snapshot_id

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
        SELECT dataset,dim,pos,ord,$1,NULL,$2,NULL FROM staging_tmp", list(ts, sid))
    } else {
      DBI::dbExecute(con, "
        UPDATE eurostat.metabase m SET valid_to = $1, to_snapshot_id = $2
        WHERE m.valid_to IS NULL
          AND NOT EXISTS (SELECT 1 FROM staging_tmp s
            WHERE s.dataset=m.dataset AND s.dim=m.dim AND s.pos=m.pos)", list(ts, sid))
      DBI::dbExecute(con, "
        INSERT INTO eurostat.metabase
          (dataset,dim,pos,ord,valid_from,valid_to,from_snapshot_id,to_snapshot_id)
        SELECT s.dataset,s.dim,s.pos,s.ord,$1,NULL,$2,NULL FROM staging_tmp s
        WHERE NOT EXISTS (SELECT 1 FROM eurostat.metabase m
          WHERE m.valid_to IS NULL
            AND m.dataset=s.dataset AND m.dim=s.dim AND m.pos=s.pos)", list(ts, sid))
    }
  })

  message(sprintf("ingested snapshot: %d rows", nrow(mb)))
  invisible(TRUE)
}

main()
