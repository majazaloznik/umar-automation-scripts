##
#' Script for reading the poraba elektrike data from the data/ folder in
#' umar-automation-scripts and writing it to the umar data file for automated ingestion
#' the file is maintained by Andrej kustrin

# get the data from the most recent excel file in the folder.
################################################################################
path <- "\\\\192.168.38.7\\public$\\Avtomatizacija\\umar-automation-scripts\\data\\elektrika"
library(dplyr)
files <- list.files(path, pattern = paste0("^Poraba el. po odjemnih skupinah", ".*\\.xlsx$"), full.names = TRUE)

# Select most recent file by modification time
if (length(files) > 1) {
  file_times <- file.info(files)$mtime
  file_path <- files[which.max(file_times)]
  message("Multiple files found, selected most recent: ", basename(file_path))
} else {
  file_path <- files[1]
}

df <- readxl::read_excel(file_path,
                         sheet =  1)

colnames(df) <- c("period", "UMAR-SODO--AK001--IND--M",
                  "UMAR-SODO--AK001--GOSP--M",
                  "UMAR-SODO--AK001--MPO--M",
                  "UMAR-SODO--AK001--SKUP--M")


path <- "\\\\192.168.38.7\\public$\\Avtomatizacija\\umar-data\\AK\\umar_serije_podatki_AK.xlsx"
# Read existing file
existing <- readxl::read_excel(path)

# Update/merge with new data
updated <- existing |>
  dplyr::rows_upsert(df, by = "period")

# Write back
openxlsx::write.xlsx(updated,
                     file = path,
                     sheetName = "M",
                     overwrite = TRUE)

