##
#' Script for reading the texcise duty - trošarina - data and directing it
#' into the umar data pipeline.
#'
#'
#' the first part of the script is the regular monthly update. the second part is commented
#' out for archival purposes and was the one off run to ingest the
#' old data series before the break september 2025

#' trosarine new read - monthly update
#' the data needs to be (manually) placed in the required folder!
################################################################################
input_dir   <- "\\\\192.168.38.7\\public$\\Avtomatizacija\\umar-automation-scripts\\data\\trosarine"
master_path <- "\\\\192.168.38.7\\public$\\Avtomatizacija\\umar-data\\LF\\umar_serije_podatki_LF.xlsx"
lookup_path <- "\\\\192.168.38.7\\public$\\Avtomatizacija\\umar-automation-scripts\\data\\trosarine\\sifranti\\trosarine_lookup.xlsx"

UmarDataBotR::log_msg("trošarine | start")



files <- list.files(input_dir, pattern = "\\.xlsx$",
                    full.names = TRUE, ignore.case = TRUE)
if (!length(files)) stop("no .xlsx files in ", input_dir)

info   <- file.info(files)
latest <- rownames(info)[which.max(info$mtime)]
UmarDataBotR::log_msg("trošarine: latest: %s  (mtime %s)",
                      basename(latest), format(info[latest, "mtime"]))

new <- openxlsx2::read_xlsx(latest, sheet = 1L)
new <- new[rowSums(is.na(new)) < ncol(new), ] # remove empty rows
new <- new[, colSums(is.na(new)) < nrow(new), drop = FALSE] # remove empty columns
UmarDataBotR::log_msg("trošarine: new rows: %d", nrow(new))

## clean up
colnames(new)[c(2, 6,7)] <- c("Izdelek", "kolicina", "znesek")
mesec_map <- c(januar = 1, februar = 2, marec = 3, april = 4,
               maj = 5, junij = 6, julij = 7, avgust = 8,
               september = 9, oktober = 10, november = 11, december = 12)
m <- mesec_map[tolower(trimws(new$Mesec))]

if (anyNA(m))
  stop("unrecognised month(s): ",
       toString(unique(new$Mesec[is.na(m)])))

new$period <- as.Date(sprintf("%d-%02d-01", as.integer(new$Leto), m))

lookup <- openxlsx2::read_xlsx(lookup_path, sheet = 1L)
cleaned <-  new |>
  dplyr::left_join(lookup |> dplyr::select(nove, kratice_nove, kolicina), by = c("Izdelek" = "nove",
                                                                                 "EM po Ztro" = "kolicina")) |>
  dplyr::select(period, kratice_nove, kolicina, znesek) |>
  tidyr::pivot_longer(c(kolicina, znesek)) |>
  dplyr::mutate(name = ifelse(name == "kolicina", "K", "Z"),
                code = paste("MF-UMAR", "LF002", name, kratice_nove, "M", sep = "--"),
                .keep = "unused") |>
  dplyr::select(-name) |>
  tidyr::pivot_wider(names_from = code, values_from = value)

# remove NAs
num <- vapply(cleaned, is.numeric, logical(1))
cleaned[num][is.na(cleaned[num])] <- 0
if (!file.exists(master_path)) stop("master not found: ", master_path)
master <- openxlsx2::read_xlsx(master_path, sheet = 1L)
UmarDataBotR::log_msg("trošarine: master rows: %d", nrow(master))

extra <- setdiff(names(cleaned), names(master))
if (length(extra))
  stop(sprintf("column mismatch | extra: %s", toString(extra)))

cleaned$period <- as.Date(cleaned$period)
master$period  <- as.Date(master$period)

already <- cleaned$period %in% master$period
if (all(already)) {
  UmarDataBotR::log_msg("tro\u0161arine: no new data: %s already in master",
                        toString(unique(cleaned$period)))
  n_new <- 0L
} else if (any(already)) {
  stop("partial overlap with master: ", toString(unique(cleaned$period[already])))
} else {
  combined <- master |> dplyr::rows_upsert(cleaned, by = "period")
  openxlsx2::write_xlsx(combined, master_path, sheet = "M", overwrite = TRUE)
  n_new <- length(unique(cleaned$period))
  UmarDataBotR::log_msg("tro\u0161arine: master written: %d new period(s)", n_new)
}
n_new


