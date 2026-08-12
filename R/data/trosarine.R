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
tag <- "[trosarine]"
input_dir   <- "\\\\192.168.38.7\\public$\\Avtomatizacija\\umar-automation-scripts\\data\\trosarine"
master_path <- "\\\\192.168.38.7\\public$\\Avtomatizacija\\umar-data\\LF\\umar_serije_podatki_LF.xlsx"
lookup_path <- "\\\\192.168.38.7\\public$\\Avtomatizacija\\umar-automation-scripts\\data\\trosarine\\sifranti\\trosarine_lookup.xlsx"

message(sprintf("%s %s | start", tag, Sys.time()))

ok <- tryCatch({

  files <- list.files(input_dir, pattern = "\\.xlsx$",
                      full.names = TRUE, ignore.case = TRUE)
  if (!length(files)) stop("no .xlsx files in ", input_dir)

  info   <- file.info(files)
  latest <- rownames(info)[which.max(info$mtime)]
  message(sprintf("%s latest: %s  (mtime %s)",
                  tag, basename(latest), format(info[latest, "mtime"])))

  new <- openxlsx2::read_xlsx(latest, sheet = 1L)
  new <- new[rowSums(is.na(new)) < ncol(new), ] # remove empty rows
  new <- new[, colSums(is.na(new)) < nrow(new), drop = FALSE] # remove empty columns
  message(sprintf("%s new rows: %d", tag, nrow(new)))

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
  message(sprintf("%s master rows: %d", tag, nrow(master)))

  extra <- setdiff(names(cleaned), names(master))
  if (length(extra))
    stop(sprintf("column mismatch | extra: %s", toString(extra)))

  cleaned$period <- as.Date(cleaned$period)
  master$period  <- as.Date(master$period)

  if (any(cleaned$period %in% master$period))
    stop("period(s) already in master: ",
         toString(intersect(cleaned$period, master$period)))

  combined <- master |> dplyr::rows_upsert(cleaned, by = "period")

  combined <- master |>
    dplyr::rows_upsert(cleaned, by = "period")

  message(sprintf("%s combined rows: %d (+%d)",
                  tag, nrow(combined), nrow(cleaned)))

  openxlsx2::write_xlsx(combined, master_path, sheet = "M", overwrite = TRUE)
  message(sprintf("%s master written: %s", tag, master_path))

  TRUE
},
error = function(e) {
  message(sprintf("%s FAIL | %s", tag, conditionMessage(e)))
  FALSE
})

message(sprintf("%s %s | %s", tag, Sys.time(), if (isTRUE(ok)) "OK" else "FAIL"))







# # # trosarine read - one off
# # ################################################################################
# library(dplyr)
# library(tidyr)
# path <- "\\\\192.168.38.7\\public$\\Avtomatizacija\\umar-automation-scripts\\data\\trosarine\\stare"
# filename <- "trosarine_stare_raw.xlsx"
# df <- readxl::read_excel(paste(path, filename, sep = "\\")) |>
#   filter(datum < "2025-09-01") |>
#   mutate(num_value = as.numeric(num_value))
#
# kolicine <- df |>
#   filter(meritev != "trošarina") |>
#   select(Izdelek, datum, num_value) |>
#   pivot_wider(names_from = Izdelek,
#               values_from = num_value)
#
# colnames(kolicine) <- c("period",
#                       "MF-UMAR--LF001--K--B9X--M",
#                       "MF-UMAR--LF001--K--BDIZ--M",
#                       "MF-UMAR--LF001--K--CGT--M",
#                       "MF-UMAR--LF001--K--ALK--M",
#                       "MF-UMAR--LF001--K--DIZ--M",
#                       "MF-UMAR--LF001--K--ELN--M",
#                       "MF-UMAR--LF001--K--ELP--M",
#                       "MF-UMAR--LF001--K--KOEL--M",
#                       "MF-UMAR--LF001--K--VIN--M",
#                       "MF-UMAR--LF001--K--PIV--M",
#                       "MF-UMAR--LF001--K--VPIJ--M",
#                       "MF-UMAR--LF001--K--ZPO--M",
#                       "MF-UMAR--LF001--K--ZPP--M",
#                       "MF-UMAR--LF001--K--ZPPV--M",
#                       "MF-UMAR--LF001--K--TOB--M",
#                       "MF-UMAR--LF001--K--ECG--M")
# zneski <- df |>
#   filter(meritev == "trošarina") |>
#   select(Izdelek, datum, num_value) |>
#   pivot_wider(names_from = Izdelek,
#               values_from = num_value)
#
# colnames(zneski) <- c("period",
#                         "MF-UMAR--LF001--Z--B9X--M",
#                         "MF-UMAR--LF001--Z--BDIZ--M",
#                         "MF-UMAR--LF001--Z--CGT--M",
#                         "MF-UMAR--LF001--Z--ALK--M",
#                         "MF-UMAR--LF001--Z--DIZ--M",
#                         "MF-UMAR--LF001--Z--ELN--M",
#                         "MF-UMAR--LF001--Z--ELP--M",
#                         "MF-UMAR--LF001--Z--KOEL--M",
#                         "MF-UMAR--LF001--Z--VIN--M",
#                         "MF-UMAR--LF001--Z--PIV--M",
#                         "MF-UMAR--LF001--Z--VPIJ--M",
#                         "MF-UMAR--LF001--Z--ZPO--M",
#                         "MF-UMAR--LF001--Z--ZPP--M", # zp za pogon vozil nima zneskov!
#                         "MF-UMAR--LF001--Z--TOB--M",
#                         "MF-UMAR--LF001--Z--ECG--M")
#
# final <- zneski |>
#   left_join(kolicine)
#
#
# path <- "\\\\192.168.38.7\\public$\\Avtomatizacija\\umar-data\\LF\\umar_serije_podatki_LF.xlsx"
# # Read existing file
# existing <- readxl::read_excel(path) |>
#   mutate(period = as.POSIXct(period, tz = "UTC"))
#
# # every other column: logical NA -> numeric NA
# other <- setdiff(names(existing), "period")
# existing[other] <- lapply(existing[other], as.numeric)
#
# # Update/merge with new data
# updated <- existing |>
#   dplyr::rows_upsert(final, by = "period")
#
# # Write back
# openxlsx::write.xlsx(updated,
#                      file = path,
#                      sheetName = "M",
#                      overwrite = TRUE)
#
