# Process UMAR quarterly and monthly data
library(openxlsx2)

# Find most recent smtk file

input_dir <- "\\\\192.168.38.7\\public$\\Users\\AKu\u0161trin\\Dinami\u010dni_faktorski_model\\"
files <- list.files(input_dir, pattern = "^smtk_\\d{4}_q\\d\\.xlsx$", full.names = TRUE)

if (length(files) == 0) {
  stop("No matching smtk files found")
}

# Get most recent file by modification time
input_file <- files[which.max(file.mtime(files))]
message("Processing file:", basename(input_file), "\n")

# Read and process Q sheet (quarterly data)
q_data <- openxlsx2::read_xlsx(input_file, sheet = "Q")
names(q_data) <- c("period", "UMAR-SURS--JK002--V--Q", "UMAR-SURS--JK002--M--Q")
q_data <- q_data[1:3] # in case other stuff gets tacked on the end

# Convert "1996 Q1" to Date (first day of quarter)
q_data$period <- q_data$period |>
  stringr::str_extract("(\\d{4}) Q(\\d)") |>
  stringr::str_replace("(\\d{4}) Q(\\d)", "\\1-\\2") |>
  {\(x) paste0(stringr::str_sub(x, 1, 4), "-",
               sprintf("%02d", (as.numeric(stringr::str_sub(x, 6, 6)) - 1) * 3 + 1),
               "-01")}() |>
  as.Date()

# Read and process M sheet (monthly data)
m_data <- openxlsx2::read_xlsx(input_file, sheet = "M")
names(m_data) <- c("period", "UMAR-SURS--JK001--V--M", "UMAR-SURS--JK001--M--M")
m_data <- m_data[1:3] # in case other stuff gets tacked on the end

# Convert "Jan 1996" to Date (first day of month)
m_data$period <- lubridate::dmy(paste0("01-", m_data$period))

# Write to new workbook
output_file <- "\\\\192.168.38.7\\public$\\Avtomatizacija\\umar-data\\JK\\umar_serije_podatki_JK.xlsx"

# Create workbook and add sheets
wb <- openxlsx2::wb_workbook()
wb <- wb |>
  openxlsx2::wb_add_worksheet("Q") |>
  openxlsx2::wb_add_data_table(sheet = "Q", x = q_data, na.strings = "") |>
  openxlsx2::wb_add_worksheet("M") |>
  openxlsx2::wb_add_data_table(sheet = "M", x = m_data, na.strings = "")

# Save workbook
openxlsx2::wb_save(wb, output_file, overwrite = TRUE)

message("Output written to:", output_file, "\n")
message("Q sheet rows:", nrow(q_data), "\n")
message("M sheet rows:", nrow(m_data), "\n")

source("\\\\192.168.38.7\\public$\\Avtomatizacija\\umar-automation-scripts\\R\\umar-add_new_data_full.R")
