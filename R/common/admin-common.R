#' Run a manual admin action with logging
#'
#' Wraps one manual action in a [UmarDataBotR::run_start()] /
#' [UmarDataBotR::with_run()] pair, appending to `logs/<source>-admin.log`.
#' The run name records the source, the Windows user and the action. No emails
#' are sent and R is not quit on failure.
#'
#' Destructive actions log and print `preview` and then ask for confirmation.
#' [utils::askYesNo()] returns its default (`FALSE`) in a non-interactive
#' session, so a scheduled or piped run can never perform one.
#'
#' @param source short source name, e.g. "BS". Determines the log file.
#' @param label short description of the action.
#' @param expr the code to run, evaluated lazily inside the run.
#' @param destructive logical. If `TRUE`, ask for confirmation first.
#' @param preview optional character vector of lines (what is about to
#'   happen), logged and printed before the confirmation prompt.
#'
#' @return the value of `expr`, invisibly, or `NULL` if aborted or failed.
#' @keywords internal
admin_do <- function(source, label, expr, destructive = FALSE, preview = NULL) {
  log_file <- file.path("logs", paste0(source, "-admin.log"))
  dir.create(dirname(log_file), showWarnings = FALSE, recursive = TRUE)
  run <- UmarDataBotR::run_start(
    sprintf("%s admin [%s]: %s", source, Sys.info()[["user"]], label),
    maintainer = "maja.zaloznik@gmail.com", heartbeat = FALSE, log_file = log_file)
  invisible(lapply(preview, UmarDataBotR::log_msg))
  if (destructive && !isTRUE(utils::askYesNo(paste0("Really: ", label, "?"),
                                             default = FALSE))) {
    UmarDataBotR::log_msg("ABORTED by user")
    return(invisible(NULL))
  }
  out <- NULL
  UmarDataBotR::with_run(run, { out <- expr }, send = FALSE, quit_on_failure = FALSE)
  invisible(out)
}

#' Look up one table, failing loudly if it does not exist
#'
#' @param con database connection.
#' @param table_id platform table id.
#' @return one-row data frame, see [UMARaccessR::sql_get_table_info_from_table_id()].
#' @keywords internal
table_info <- function(con, table_id) {
  info <- UMARaccessR::sql_get_table_summary(table_id, con)
  if (is.null(info)) stop("No table with id ", table_id, call. = FALSE)
  info
}

#' Delete the most recent vintages of a table (any source)
#'
#' Destructive: shows what will be deleted, then asks for confirmation. Logged
#' to the table's source log, with the deleted vintage ids.
#'
#' @param table_id platform table id.
#' @return the result of `UMARimportR::delete_vintage()`, invisibly.
#' @keywords internal
delete_latest_vintages <- function(table_id) {
  con <- platform_con(); on.exit(DBI::dbDisconnect(con))
  info <- table_info(con, table_id)
  ids <- UMARaccessR::sql_get_latest_vintages_for_table_id(table_id, con)$vintage_id
  if (length(ids) == 0) stop("Table ", table_id, " (", info$code, ") has no vintages", call. = FALSE)
  admin_do(info$source,
           sprintf("delete latest vintages of table %s (%s)", info$table_id, info$code),
           destructive = TRUE,
           preview = c(sprintf("Table %s: %s -- %s", info$table_id, info$code, info$name),
                       sprintf("%d latest vintage(s) to delete: %s", length(ids),
                               paste(utils::head(ids, 20), collapse = ","))),
           {
             UmarDataBotR::log_msg("vintage ids: %s", paste(ids, collapse = ","))
             res <- UMARimportR::delete_vintage(con, ids)
             UmarDataBotR::log_msg("deleted %d vintage(s), %d data point(s), %d flag(s)",
                                   sum(res$vintage_count), sum(res$data_points_count), sum(res$flag_count))
             res
           })
}

#' Delete a table and all its series and data (any source)
#'
#' Destructive: shows the table and how much will go, then asks for
#' confirmation. Logged to the table's source log.
#'
#' @param table_id platform table id.
#' @return the result of `UMARimportR::delete_table()`, invisibly.
#' @keywords internal
delete_table <- function(table_id) {
  con <- platform_con(); on.exit(DBI::dbDisconnect(con))
  info <- table_info(con, table_id)
  admin_do(info$source,
           sprintf("DELETE table %s (%s)", info$table_id, info$code),
           destructive = TRUE,
           preview = c(sprintf("Table %s: %s -- %s", info$table_id, info$code, info$name),
                       sprintf("%d series and %d vintages will be deleted.",
                               info$n_series, info$n_vintages)),
           {
             res <- UMARimportR::delete_table(con, table_id, "platform")
             UmarDataBotR::log_msg("deleted %d table(s), %d series, %d vintages(s), %d data point(s), %d flag(s), %d dimension(s), %d dimension level(s), %d series level(s), %d category table(s)",
                                   sum(res$table_count),
                                   sum(res$series_count),
                                   sum(res$vintage_count),
                                   sum(res$data_points_count),
                                   sum(res$flag_count),
                                   sum(res$dimension_count),
                                   sum(res$dimension_levels_count),
                                   sum(res$series_levels_count),
                                   sum(res$category_table_count))
             res
             })
}

#' Connect to the platform database
#'
#' Opens a new connection to the local `platform` database. The password is
#' read from the `PG_PG_PSW` environment variable. The caller is responsible
#' for disconnecting, usually with `on.exit(DBI::dbDisconnect(con))`.
#'
#' @return a `DBIConnection`
#' @keywords internal
platform_con <- function() DBI::dbConnect(RPostgres::Postgres(),
                                          dbname = "platform",
                                          host = "localhost",
                                          port = 5432,
                                          user = "postgres",
                                          password = Sys.getenv("PG_PG_PSW"),
                                          client_encoding = "utf8")

#' Connect to the platform database
#'
#' Opens a new connection to the local `davcne` database. The password is
#' read from the `PG_PG_PSW` environment variable. The caller is responsible
#' for disconnecting, usually with `on.exit(DBI::dbDisconnect(con))`.
#'
#' @return a `DBIConnection`
#' @keywords internal
davcne_con <- function() DBI::dbConnect(RPostgres::Postgres(),
                                          dbname = "davcne",
                                          host = "localhost",
                                          port = 5432,
                                          user = "postgres",
                                          password = Sys.getenv("PG_PG_PSW"),
                                          client_encoding = "utf8")
