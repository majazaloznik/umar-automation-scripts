#' BS admin tasks. source() this file, then call what you need; nothing runs on
#' source. Every call is logged to logs/BS-admin.log.
#' options are:
#' 1. bs_add_table(px_code)
#' 2. bs_update_table(px_code)
#' 3. delete_latest_vintages(table_id)
#' 4. delete_table(table_id)

source("R/common/admin-common.R")

#' Run a BS admin action
#'
#' Thin wrapper around [admin_do()] with `source = "BS"`. `...` is forwarded
#' lazily, so `expr` is still evaluated inside the logged run.
#'
#' @param ... passed to [admin_do()] after `source`: `label`, `expr`, `destructive`.
#' @keywords internal
bs_do <- function(...) admin_do("BS", ...)

#' Add a new BS table (structure only)
#'
#' Imports the structure (dimension levels, series, series levels) for one
#' BS px table. Follow with [bs_update_table()] to load the data.
#'
#' @param px_code BS px code, e.g. "i_32_6ms".
#' @param all_levels logical. `FALSE` (default) lets you select the dimension levels to import.
#' @param keep_vintage logical, passed to `BSfetchR::BS_import_structure()`.
#'
#' @return the result of `BS_import_structure()`, invisibly.
#' @keywords internal
bs_add_table <- function(px_code, all_levels = FALSE, keep_vintage = FALSE) {
  con <- platform_con(); on.exit(DBI::dbDisconnect(con))
  bs_do(paste("add table", px_code),
        {
          res <- BSfetchR::BS_import_structure(px_code, con, "platform",
                                               all_levels = all_levels,
                                               keep_vintage = keep_vintage)
          UmarDataBotR::log_msg("inserted: %s", paste(names(res), purrr::map_int(res, \(x) sum(x$count)), sep = "=", collapse = ", "))
          res
        })
}

#' Update one BS table
#'
#' Imports the data points for one table, then removes redundant vintages.
#' The regular update runs this for all tables, so use it for a single
#' table or after [bs_add_table()].
#'
#' @param px_code BS px code.
#' @param refresh_mat_view logical
#'
#' @return the result of `vintage_cleanup()`, invisibly.
#' @keywords internal
bs_update_table <- function(px_code, refresh_mat_view = FALSE) {
  con <- platform_con(); on.exit(DBI::dbDisconnect(con))
  bs_do(paste("update table", px_code), {
    table_id <- UMARaccessR::sql_get_table_id_from_table_code(con, px_code)
    if (is.na(table_id)) stop("Unknown table code: ", px_code, call. = FALSE)
    res <- BSfetchR::BS_import_data_points(px_code, con, schema = "platform")
    UmarDataBotR::log_msg("%s: %d new vintage(s), %d new data point(s)",
                          px_code, res$new_vintages, res$new_datapoints)
    if (res$new_vintages > 0) {
      UmarDataBotR::log_msg("Starting vintage cleanup.")
      UMARimportR::vintage_cleanup(con, table_id = table_id, schema = "platform")
      if (refresh_mat_view){
        UmarDataBotR::log_msg("Starting refresh of mat. view.")
        DBI::dbExecute(con, "REFRESH MATERIALIZED VIEW views.mat_latest_data_points")}
      UmarDataBotR::log_msg("vintage cleanup done%s", if (refresh_mat_view) ", view refreshed" else "")
    }
    res
  })
}
