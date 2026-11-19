#' Newest file in a folder matching a pattern (by mtime)
newest_file <- function(dir, pattern) {
  f <- list.files(dir, pattern = pattern, full.names = TRUE)
  if (length(f) == 0) stop("no files matching '", pattern, "' in ", dir, call. = FALSE)
  f[which.max(file.mtime(f))]
}

#' Upsert rows into a umar-data Excel file by period
#'
#' Writes the file only if something changed, and logs the outcome.
#' @return number of new periods (0 also when only existing values were revised)
upsert_umar_data <- function(df, path, sheet = "M") {
  df$period <- as.Date(df$period)
  existing <- readxl::read_excel(path, sheet = sheet, .name_repair = "unique_quiet")
  if (nrow(existing) == 0) {
    updated <- df
    n_new <- nrow(df)
  } else {
    existing <- existing |>
      dplyr::mutate(period = as.Date(period), dplyr::across(-period, as.numeric))
    extra <- setdiff(names(df), names(existing))
    if (length(extra)) stop("columns not in ", basename(path), ": ", toString(extra), call. = FALSE)
    n_new <- sum(!df$period %in% existing$period)
    updated <- dplyr::rows_upsert(existing, df, by = "period")
    if (isTRUE(all.equal(updated, existing, check.attributes = FALSE))) {
      UmarDataBotR::log_msg("%s: no changes", basename(path))
      return(0L)
    }
  }
  openxlsx::write.xlsx(updated, path, sheetName = sheet, overwrite = TRUE)
  UmarDataBotR::log_msg("%s written: %d new period(s)", basename(path), n_new)
  n_new
}
