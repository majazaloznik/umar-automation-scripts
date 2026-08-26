
#' Configure Gmail authentication for the bot account
#'
#' Configures gmailr with the bot's OAuth credentials and token cache. Must be
#' called once per session before any email is sent; both the failure and
#' alert senders assume auth is already configured.
#'
#' @return Invisibly NULL; called for its side effect.

init_email <- function() {
gmailr::gm_auth_configure(
  path = "\\\\192.168.38.7\\public$\\Avtomatizacija\\umar-automation-scripts\\data\\gmailr\\credentials.json")
gmailr::gm_auth(email = "umar.data.bot@gmail.com",
                cache = "\\\\192.168.38.7\\public$\\Avtomatizacija\\umar-automation-scripts\\.secret")
}


#' Email an operational failure to the maintainer
#'
#' Sends a plain-text failure notice to the maintainer address. Wrapped so a
#' send failure (e.g. auth problem) is caught and logged rather than masking
#' the original error. Requires `init_email()` to have run.
#'
#' @param msg Character message describing the failure.
#'
#' @return Invisibly NULL; called for its side effect.
send_failure_email <- function(msg) {
  tryCatch({
    email <- gmailr::gm_mime() |>
      gmailr::gm_to("maja.zaloznik@gmail.com") |>
      gmailr::gm_subject("[UMAR-BOT] Eurostat metabase ingest FAILED") |>
      gmailr::gm_text_body(sprintf("%s  on  %s\n\n%s",
                                   Sys.time(), Sys.info()[["nodename"]], msg))
    gmailr::gm_send_message(email)
  }, error = function(e) message("email send failed: ", conditionMessage(e)))
}


#' Build the HTML body for a subscriber's alert email
#'
#' Formats one subscriber's matched change rows into a monospace HTML table,
#' with a listing of specifically removed levels and a rename hint on any
#' removed dataset.
#'
#' @param con Database connection object (needed for the removed-levels lookup)
#' @param rows A data frame of this subscriber's matched change rows.
#' @param sid Snapshot identifier.
#'
#' @return A single character string of HTML for the email body.
format_alert_body <- function(con, rows, sid) {
  out <- c(sprintf("Eurostat strukturne spremembe — snapshot %s, %s\n",
                   format(sid), format(Sys.time(), "%Y-%m-%d %H:%M")))

  tbl <- rows[, c("dataset", "event", "dim_changes", "level_added", "level_removed")]
  tbl[] <- lapply(tbl, function(c) ifelse(is.na(c), "", as.character(c)))
  colnames(tbl) <- c("tabela", "dogodek", "dim_spremembe", "level_dodan", "level_izbrisan")
  out <- c(out, paste(knitr::kable(tbl, align = "l", format = "pipe", row.names = TRUE), collapse = "\n"))

  # hint for removed datasets — the rename case we can't yet link automatically
  removed <- rows[rows$event == "dataset_removed", "dataset"]
  if (length(removed))
    out <- c(out, sprintf(
      "\nNote: %s tabela izbrisana. Mogoče so jo preimenovali, preveri na Eurostatu.",
      paste(unique(removed), collapse = ", ")))
  # removed levels
  removed <- removed_levels_detail(con, sid, unique(rows$dataset))
  if (nrow(removed))
    out <- c(out, "\nIzbrisani levelsi (lahko breaknejo poizvedbe, ki jih izrecno uporabljajo):",
             sprintf("  %s / %s: %s", removed$dataset, removed$dim, removed$removed))
  out <- c(out,
           "\n\nTvoj Umar Data Bot &#129302;")
  paste(out, collapse = "\n")
}



#' Send per-subscriber alert emails for a snapshot
#'
#' Filters the run's changes to each subscriber and sends one digest email per
#' affected subscriber, containing only their matched datasets. Sends nothing
#' to subscribers with no matches. Requires `init_email()` to have run.
#'
#' @param con Database connection object
#' @param alerts A data frame of change rows for the current snapshot.
#' @param sid Snapshot identifier.
#'
#' @return Invisibly, the number of emails sent.
send_alerts_perperson <- function(con, alerts, sid) {
  matched <- filter_alerts(con, alerts)
  if (nrow(matched) == 0) {
    message("no subscribers matched this run's changes")
    return(invisible(0))
  }

  emails <- unique(matched$email)
  sent <- 0
  for (addr in emails) {
    rows <- matched[matched$email == addr, ]
    rownames(rows) <- seq(nrow(rows))
    body <- format_alert_body(con, rows, sid)
    ok <- tryCatch({
      msg <- gmailr::gm_mime() |>
        gmailr::gm_to(addr) |>
        gmailr::gm_subject(sprintf(
          "[Umar-Data-Bot] Eurostat strukturne spremembe - st. spremenjenih tabel: %d",
          length(unique(rows$dataset)))) |>
        gmailr::gm_html_body(sprintf("<pre style=\"font-family:monospace\">%s</pre>", body))
      gmailr::gm_send_message(msg)
      TRUE
    }, error = function(e) {
      message(sprintf("send to %s failed: %s", addr, conditionMessage(e)))
      FALSE
    })
    if (ok) sent <- sent + 1
  }
  message(sprintf("sent %d/%d subscriber emails", sent, length(emails)))
  invisible(sent)
}
