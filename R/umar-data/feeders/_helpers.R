#' Newest file in a folder matching a pattern (by mtime)
newest_file <- function(dir, pattern) {
  f <- list.files(dir, pattern = pattern, full.names = TRUE)
  if (length(f) == 0) stop("no files matching '", pattern, "' in ", dir, call. = FALSE)
  f[which.max(file.mtime(f))]
}

#' Upsert new rows into a umar-data Excel file by period
#' @return number of new periods (0 if all already present and unchanged)
upsert_umar_data <- function(df, path, sheet = "M") {
  existing <- readxl::read_excel(path, sheet = sheet) |>
    dplyr::mutate(period = as.Date(period), dplyr::across(-period, as.numeric))
  df$period <- as.Date(df$period)
  extra <- setdiff(names(df), names(existing))
  if (length(extra)) stop("columns not in ", basename(path), ": ", toString(extra), call. = FALSE)
  n_new <- sum(!df$period %in% existing$period)
  updated <- dplyr::rows_upsert(existing, df, by = "period")
  if (!identical(updated, existing))
    openxlsx::write.xlsx(updated, path, sheetName = sheet, overwrite = TRUE)
  n_new
}

#' Pair metadata and data files by initials
umar_data_files <- function(dir) {
  f <- list.files(dir, "^umar_serije_(metadata|podatki)_.+\\.xlsx$",
                  recursive = TRUE, full.names = TRUE)
  b <- basename(f)
  data.frame(path = f,
             type = sub("^umar_serije_(metadata|podatki)_.*", "\\1", b),
             initials = sub("^umar_serije_(metadata|podatki)_(.+)\\.xlsx$", "\\2", b)) |>
    tidyr::pivot_wider(names_from = type, values_from = path)
}
