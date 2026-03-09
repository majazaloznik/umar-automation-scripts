##
#' Script for reading the financial distres data from the data/ folder in
#' umar-automation-scripts and writing it to the umar data file for automated ingestion


# get the data from the most recent excel file in the folder.
################################################################################
path <- "\\\\192.168.38.7\\public$\\Avtomatizacija\\umar-automation-scripts\\data\\fin.vzdrznost"
library(dplyr)
files <- list.files(path, pattern = paste0("^FinancialDistress", ".*\\.xlsx$"), full.names = TRUE)

# Select most recent file by modification time
if (length(files) > 1) {
  file_times <- file.info(files)$mtime
  file_path <- files[which.max(file_times)]
  message("Multiple files found, selected most recent: ", basename(file_path))
} else {
  file_path <- files[1]
}

df <- readxl::read_excel(file_path,
                         sheet = "FinancialDistress")
colnames(df)[1:2] <- c("month", "year")

# insane fill to fix malformed original data...
year_filled <- rep(NA, nrow(df))
year_filled[!is.na(df$year)] <- df$year[!is.na(df$year)]

# Forward fill, incrementing year when month wraps from 12 to lower
for(i in which(!is.na(year_filled))) {
  current_year <- year_filled[i]
  current_month <- df$month[i]

  # Fill forward
  j <- i + 1
  while(j <= nrow(df) && is.na(year_filled[j])) {
    if(df$month[j] < df$month[j-1]) {  # month wrapped
      current_year <- current_year + 1
    }
    year_filled[j] <- current_year
    j <- j + 1
  }

  # Fill backward
  current_year <- year_filled[i]
  j <- i - 1
  while(j >= 1 && is.na(year_filled[j])) {
    if(df$month[j+1] < df$month[j]) {  # month wrapped (going backward)
      current_year <- current_year - 1
    }
    year_filled[j] <- current_year
    j <- j - 1
  }
}
df$year <- year_filled
df$date <- as.Date(paste(year_filled, df$month, "1", sep = "-"))

df <- df |>
  select(-month, -year) |>
  relocate(date)

colnames(df) <- c("period", "SURS-UMAR--HM001--FDT--M",
                  "SURS-UMAR--HM001--RD--M",
                  "SURS-UMAR--HM001--DS--M",
                  "SURS-UMAR--HM001--1Q--M",
                  "SURS-UMAR--HM001--2Q--M",
                  "SURS-UMAR--HM001--3Q--M",
                  "SURS-UMAR--HM001--4Q--M")

path <- "\\\\192.168.38.7\\public$\\Avtomatizacija\\umar-data\\HM\\umar_serije_podatki_HM.xlsx"
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

