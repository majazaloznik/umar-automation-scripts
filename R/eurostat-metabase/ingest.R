#' Fetch the Eurostat metabase and ingest structural changes
#'
#' Fetches the current Eurostat metabase file, compares it by content hash to
#' the latest stored snapshot, and — if changed — records a new snapshot and
#' applies the structural diff to the SCD2 `eurostat.metabase` table (expiring
#' rows that vanished, inserting rows that appeared). On the first run (empty
#' live set) it bulk-inserts everything via the bootstrap branch.
#'
#' Dedup is by SHA-256 of the file against the latest snapshot only, so a
#' rollback to a previously-seen (but not latest) structure is re-ingested
#' rather than skipped. The observation timestamp is fetch time; the metabase
#' endpoint provides no Last-Modified header.
#'
#' @param con Database connection object
#' @param force Logical; if TRUE, skip the dedup guard and ingest even if the
#'   file matches the latest snapshot. Used for manual re-diffing.
#'
#' @return A list with `status` ("unchanged" or "changed"), `snapshot_id`
#'   (character, or NA when unchanged), `n_rows`, and `rolled_back` (logical).
ingest <- function(con, force = FALSE) {
  message("\n*** starting ingest ***")
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
  message("\n*** ingest complete ***")
  list(status = "changed", snapshot_id = as.character(sid),
       n_rows = nrow(mb),
       rolled_back = rolled_back)
}
