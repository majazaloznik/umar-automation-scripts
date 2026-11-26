#' Newest file in a folder matching a pattern (by mtime)
#'
#' @param dir folder to search
#' @param pattern regex for the file name
#' @return full path of the most recently modified match
newest_file <- function(dir, pattern) {
  f <- list.files(dir, pattern = pattern, full.names = TRUE)
  f <- f[!grepl("^~\\$", basename(f))]   # Excel lock files
  if (length(f) == 0) stop("no files matching '", pattern, "' in ", dir, call. = FALSE)
  f[which.max(file.mtime(f))]
}

#' Upsert rows into one sheet of a umar-data Excel file, by period
#'
#' Replaces only the given sheet; other sheets in the file are kept. Writes
#' only if something changed, and logs the outcome. Creates the file or the
#' sheet if it doesn't exist yet.
#'
#' @param df data frame with a `period` column and one column per series code
#' @param path umar-data file, e.g. umar-data/JK/umar_serije_podatki_JK.xlsx
#' @param sheet sheet name (interval): "M", "Q", "A" or "D"
#' @return number of new periods (0 also when only existing values were revised)
upsert_umar_data <- function(df, path, sheet = "M") {
  df$period <- as.Date(df$period)
  label <- sprintf("%s [%s]", basename(path), sheet)
  has_sheet <- file.exists(path) && sheet %in% readxl::excel_sheets(path)
  existing <- if (has_sheet) readxl::read_excel(path, sheet = sheet, .name_repair = "unique_quiet")

  if (is.null(existing) || nrow(existing) == 0) {
    updated <- df
    n_new <- nrow(df)
  } else {
    existing <- existing |>
      dplyr::mutate(period = as.Date(period), dplyr::across(-period, as.numeric))
    extra <- setdiff(names(df), names(existing))
    if (length(extra)) stop(label, ": columns not in file: ", toString(extra), call. = FALSE)
    n_new <- sum(!df$period %in% existing$period)
    updated <- dplyr::rows_upsert(existing, df, by = "period")
    if (isTRUE(all.equal(updated, existing, check.attributes = FALSE))) {
      UmarDataBotR::log_msg("%s: no changes", label)
      return(0L)
    }
  }

  wb <- if (file.exists(path)) openxlsx2::wb_load(path) else openxlsx2::wb_workbook()
  # remove and re-add rather than overwrite, so no stale Excel table definitions remain
  if (sheet %in% openxlsx2::wb_get_sheet_names(wb)) wb <- openxlsx2::wb_remove_worksheet(wb, sheet)
  wb <- wb |>
    openxlsx2::wb_add_worksheet(sheet) |>
    openxlsx2::wb_add_data(sheet = sheet, x = updated, na.strings = "")
  openxlsx2::wb_save(wb, path, overwrite = TRUE)

  UmarDataBotR::log_msg("%s written: %d new period(s)", label, n_new)
  n_new
}
