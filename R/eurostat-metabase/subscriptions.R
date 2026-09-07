
#' Load and validate the subscription sheet into the database
#'
#' Reads the shared subscription spreadsheet, normalises and validates it, and
#' truncate-reloads the `eurostat.subscription` table. Columns are selected by
#' name so extra columns (e.g. a free-text notes column) are ignored. Bad rows
#' (invalid scope, unknown dataset, duplicates) are skipped and reported by
#' email rather than halting the load, so one person's mistake does not block
#' everyone's subscriptions.
#'
#' A safety gate refuses the load if it would remove existing subscriptions for
#' more than one email address, on the assumption that no one edits another
#' person's rows — a multi-person removal signals a corrupted sheet.
#'
#' @param con Database connection object
#' @param path Character path to the subscription .xlsx on the network share.
#'
#' @return Invisibly, a list with `loaded` (rows loaded), `skipped` (rows
#'   dropped), and `problems` (character vector of validation messages).

load_subscriptions <- function(con,
                               path = "\\\\192.168.38.7\\public$\\Avtomatizacija\\umar-automation-scripts\\data\\umar_data_bot_subscriptions\\eurostat_email_prijave.xlsx") {

  raw <- readxl::read_excel(path, col_types = "text")

  # select by name so extra columns (e.g. notes) are ignored and can't shift anything
  req <- c("email", "dataset", "scope")
  missing_cols <- setdiff(req, tolower(names(raw)))
  if (length(missing_cols))
    stop(sprintf("subscription sheet missing column(s): %s",
                 paste(missing_cols, collapse = ", ")))
  names(raw) <- tolower(names(raw))

  # normalise
  subs <- data.frame(
    email   = tolower(trimws(raw$email)),
    dataset = tolower(trimws(raw$dataset)),
    scope   = tolower(trimws(ifelse(is.na(raw$scope) | raw$scope == "", "breaking", raw$scope))),
    stringsAsFactors = FALSE)

  # drop blank rows (trailing empties are common in Excel)
  subs <- subs[nzchar(subs$email) & nzchar(subs$dataset), ]

  # --- validation: collect problems, drop bad rows, don't halt ---
  problems <- character(0)

  bad_scope <- subs[!subs$scope %in% c("breaking", "all"), ]
  if (nrow(bad_scope))
    problems <- c(problems, sprintf("bad scope '%s' (%s / %s)",
                                    bad_scope$scope, bad_scope$email, bad_scope$dataset))

  known_datasets <- DBI::dbGetQuery(con,
                                    "SELECT DISTINCT dataset AS code FROM eurostat.metabase WHERE valid_to IS NULL")$code
  known_folders  <- DBI::dbGetQuery(con,
                                    "SELECT code FROM eurostat.toc_node WHERE type = 'folder' AND valid_to IS NULL")$code

  chk     <- subs[subs$dataset != "*", ]
  unknown <- chk[!chk$dataset %in% known_datasets & !chk$dataset %in% known_folders, ]
  if (nrow(unknown))
    problems <- c(problems, sprintf("unknown dataset or folder '%s' (%s)",
                                    unknown$dataset, unknown$email))

  dup <- subs[duplicated(subs[, c("email", "dataset")]), ]
  if (nrow(dup))
    problems <- c(problems, sprintf("duplicate subscription %s / %s",
                                    dup$email, dup$dataset))

  # derive kind: '*' and datasets -> 'dataset'; known folders -> 'folder'
  subs$kind <- ifelse(subs$dataset != "*" & subs$dataset %in% known_folders,
                      "folder", "dataset")

  # clean set = valid scope, known dataset/folder (or '*'), de-duplicated
  clean <- subs[
    subs$scope %in% c("breaking", "all") &
      (subs$dataset == "*" |
         subs$dataset %in% known_datasets |
         subs$dataset %in% known_folders) &
      !duplicated(subs[, c("email", "dataset")]),
    c("email", "dataset", "scope", "kind")]      # explicit columns incl. kind

  # --- safety gate: removals must affect at most one email ---
  current <- DBI::dbGetQuery(con, "SELECT email, dataset FROM eurostat.subscription")
  if (nrow(current) > 0) {
    k <- function(d) paste(d$email, d$dataset, sep = "\u0001")
    removed <- current[!k(current) %in% k(clean), ]
    affected <- unique(removed$email)
    if (length(affected) > 1)
      stop(sprintf(
        "sheet removes subscriptions for %d people (%s) — refusing; one person should not edit others' rows",
        length(affected), paste(affected, collapse = ", ")))
  }

  # report problems (after the gate, so a corrupt sheet fails before spamming)
  if (length(problems)) {
    msg <- paste0("Subscription sheet problems (bad rows skipped):\n  ",
                  paste(problems, collapse = "\n  "))
    message(msg)
    send_failure_email(msg)
  }

  # --- swap ---
  DBI::dbWithTransaction(con, {
    DBI::dbExecute(con, "TRUNCATE eurostat.subscription")
    DBI::dbWriteTable(con, DBI::Id(schema = "eurostat", table = "subscription"),
                      clean, append = TRUE)
  })

  message(sprintf("loaded %d subscriptions (%d rows skipped)",
                  nrow(clean), nrow(subs) - nrow(clean)))
  invisible(list(loaded = nrow(clean),
                 skipped = nrow(subs) - nrow(clean),
                 problems = problems))
}


#' Subscribe the bot to all currently-ingested Eurostat tables
#'
#' Ensures the monitoring address is subscribed (breaking scope) to exactly the
#' Eurostat datasets currently ingested into platform.table, so a structural
#' change to any pipeline dependency is alerted on. Idempotent: replaces the
#' bot's own subscriptions each run with the current ingested set.
#'
#' Runs AFTER load_subscriptions: that function truncate-reloads the table from
#' the Excel sheet, so the bot's rows (which come from platform.table, not the
#' sheet) must be applied afterwards or they would be wiped.
#'
#' Cross-checks the ingested codes against the live metabase and emails the
#' maintainer about any ingested table that is NOT in the current metabase --
#' that is precisely a pipeline dependency that may have been renamed or removed
#' upstream (the agr_r_animal failure mode), and is the highest-value warning
#' this monitor can raise for our own pipelines.
#'
#' @param con Database connection object
#' @param monitor_email Character; the monitoring address for pipeline dependencies.
#' @param eurostat_source_id Integer; source id of Eurostat in platform.source.
#'
#' @return Invisibly, the number of bot subscriptions written.
subscribe_bot_to_ingested <- function(con,
                                      monitor_email = "majazaloznik@gmail.com",
                                      eurostat_source_id = 7) {
  ingested <- DBI::dbGetQuery(con,
                              "SELECT DISTINCT code FROM platform.table WHERE source_id = $1",
                              list(eurostat_source_id))$code
  ingested <- tolower(trimws(ingested))

  if (length(ingested) == 0) {
    message("no ingested Eurostat tables found; bot subscribes to nothing")
    return(invisible(0))
  }

  # cross-check: which ingested dependencies are NOT in the live metabase?
  live <- DBI::dbGetQuery(con,
                          "SELECT DISTINCT dataset FROM eurostat.metabase WHERE valid_to IS NULL")$dataset
  missing <- setdiff(ingested, live)
  if (length(missing)) {
    send_failure_email(sprintf(
      paste0("Pipeline dependency check: %d ingested Eurostat table(s) are NOT ",
             "in the current metabase -- possibly renamed or removed upstream:\n  %s"),
      length(missing), paste(missing, collapse = "\n  ")))
  }

  # subscribe the bot to the ingested set (breaking scope, dataset kind)
  df <- data.frame(email = monitor_email,
                   dataset = ingested,
                   scope = "breaking",
                   kind = "dataset",
                   stringsAsFactors = FALSE)

  DBI::dbWithTransaction(con, {
    DBI::dbExecute(con, "DELETE FROM eurostat.subscription WHERE email = $1",
                   list(monitor_email))
    DBI::dbWriteTable(con, DBI::Id(schema = "eurostat", table = "subscription"),
                      df, append = TRUE)
  })

  message(sprintf("bot subscribed to %d ingested tables (%d missing from metabase)",
                  nrow(df), length(missing)))
  invisible(nrow(df))
}
