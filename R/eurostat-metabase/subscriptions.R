
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

  known   <- DBI::dbGetQuery(con, "SELECT DISTINCT dataset FROM eurostat.metabase")$dataset
  chk     <- subs[subs$dataset != "*", ]
  unknown <- chk[!chk$dataset %in% known, ]
  if (nrow(unknown))
    problems <- c(problems, sprintf("unknown dataset '%s' (%s)",
                                    unknown$dataset, unknown$email))

  dup <- subs[duplicated(subs[, c("email", "dataset")]), ]
  if (nrow(dup))
    problems <- c(problems, sprintf("duplicate subscription %s / %s",
                                    dup$email, dup$dataset))

  # clean set = valid scope, known dataset (or '*'), de-duplicated
  clean <- subs[
    subs$scope %in% c("breaking", "all") &
      (subs$dataset == "*" | subs$dataset %in% known) &
      !duplicated(subs[, c("email", "dataset")]), ]

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
