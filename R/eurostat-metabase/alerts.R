#' Classify alert rows as breaking or not
#'
#' A change is breaking if it can break an existing query: a removed dataset,
#' any dimension change, or a removed level. Added levels and added datasets
#' are not breaking.
#'
#' @param alerts A data frame of change rows as returned by
#'   `UMARaccessR::sql_get_eurostat_metabase_changes_from_snapshot`.
#'
#' @return A logical vector, one element per input row, TRUE where breaking.
is_breaking <- function(alerts) {
  alerts$event == "dataset_removed" |
    (!is.na(alerts$dim_changes)) |                             # any dim added/removed
    (!is.na(alerts$level_removed) & alerts$level_removed > 0)
}


#' Filter alert rows to each subscriber
#'
#' Joins this run's change rows to the `eurostat.subscription` table. A '*'
#' subscription matches all datasets; otherwise an exact dataset match. A
#' 'breaking' scope keeps only breaking rows; 'all' keeps everything for the
#' matched datasets.
#'
#' @param con Database connection object
#' @param alerts A data frame of change rows for the current snapshot.
#'
#' @return A data frame of matched rows with a leading `email` column, one row
#'   per (subscriber, affected dataset); empty if nothing matched.
filter_alerts <- function(con, alerts) {
  subs <- DBI::dbGetQuery(con, "SELECT email, dataset, scope FROM eurostat.subscription")
  if (nrow(subs) == 0 || nrow(alerts) == 0)
    return(data.frame())

  alerts$breaking <- is_breaking(alerts)

  # for each subscription row, find matching alerts
  # '*' matches all datasets; otherwise exact dataset match
  # scope 'breaking' keeps only breaking rows; 'all' keeps everything
  matched <- do.call(rbind, lapply(seq_len(nrow(subs)), function(i) {
    s <- subs[i, ]
    hits <- if (s$dataset == "*") alerts else alerts[alerts$dataset == s$dataset, ]
    if (s$scope == "breaking") hits <- hits[hits$breaking, ]
    if (nrow(hits) == 0) return(NULL)
    cbind(email = s$email, hits)
  }))

  if (is.null(matched)) return(data.frame())
  # a '*' subscriber who also has a specific row for the same dataset could double-match
  unique(matched)
}



#' Look up the specific levels removed for a set of datasets
#'
#' Returns the actual position codes removed (not just counts) for the given
#' datasets in a snapshot, so alert emails can list removed levels — the
#' actionable case, since a removed level breaks queries filtering on it.
#' The `time` dimension is excluded.
#'
#' @param con Database connection object
#' @param sid Snapshot identifier
#' @param datasets Character vector of dataset codes to report on.
#'
#' @return A data frame with `dataset`, `dim`, and `removed` (comma-separated
#'   codes); empty if no datasets supplied or none had removals.
removed_levels_detail <- function(con, sid, datasets) {
  if (length(datasets) == 0) return(data.frame())
  in_list <- paste(DBI::dbQuoteString(con, datasets), collapse = ",")
  DBI::dbGetQuery(con, sprintf("
    SELECT m.dataset, m.dim, string_agg(m.pos, ', ' ORDER BY m.pos) AS removed
    FROM eurostat.metabase m
    WHERE m.to_snapshot_id = $1 AND m.dim <> 'time'
      AND m.dataset IN (%s)
    GROUP BY m.dataset, m.dim
    ORDER BY m.dataset, m.dim", in_list),
                  list(sid))
}


