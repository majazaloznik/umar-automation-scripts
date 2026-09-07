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
  subs <- DBI::dbGetQuery(con,
                          "SELECT email, dataset, scope, kind FROM eurostat.subscription")
  if (nrow(subs) == 0 || nrow(alerts) == 0) return(data.frame())

  alerts$breaking <- is_breaking(alerts)

  # resolve each distinct folder once per run, reuse across subscribers
  folder_codes <- unique(subs$dataset[subs$kind == "folder"])
  folder_map <- stats::setNames(lapply(folder_codes, function(fc) {
    UMARaccessR::sql_resolve_eurostat_folder_datasets(con, fc, "eurostat")$code
  }), folder_codes)

  matched <- do.call(rbind, lapply(seq_len(nrow(subs)), function(i) {
    s <- subs[i, ]
    hits <-
      if (s$dataset == "*") {
        alerts
      } else if (s$kind == "folder") {
        alerts[alerts$dataset %in% folder_map[[s$dataset]], ]
      } else {
        alerts[alerts$dataset == s$dataset, ]
      }
    if (s$scope == "breaking") hits <- hits[hits$breaking, ]
    if (nrow(hits) == 0) return(NULL)
    cbind(email = s$email, hits)
  }))

  if (is.null(matched)) return(data.frame())
  unique(matched)
}


