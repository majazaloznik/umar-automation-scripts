# source("\\\\192.168.38.7\\public$\\Avtomatizacija\\umar-automation-scripts\\R\\grafi\\00_setup.R")

filename <- "EO_15_ESI_auto.xlsx"
################################################################################
base::message("\nPreparing data for the chart in ", filename)

codes <- c("EUROSTAT--ei_bssi_m_r2--BS-ICI-BAL--SA--EA21--M",
           "EUROSTAT--ei_bssi_m_r2--BS-SCI-BAL--SA--EA21--M",
           "EUROSTAT--ei_bssi_m_r2--BS-CSMCI-BAL--SA--EA21--M",
           "EUROSTAT--ei_bssi_m_r2--BS-RCI-BAL--SA--EA21--M",
           "EUROSTAT--ei_bssi_m_r2--BS-CCI-BAL--SA--EA21--M",
           "EUROSTAT--ei_bssi_m_r2--BS-ESI-I--SA--EA21--M",
           "EUROSTAT--ei_bssi_m_r2--BS-ICI-BAL--SA--EA20--M",
           "EUROSTAT--ei_bssi_m_r2--BS-SCI-BAL--SA--EA20--M",
           "EUROSTAT--ei_bssi_m_r2--BS-CSMCI-BAL--SA--EA20--M",
           "EUROSTAT--ei_bssi_m_r2--BS-RCI-BAL--SA--EA20--M",
           "EUROSTAT--ei_bssi_m_r2--BS-CCI-BAL--SA--EA20--M",
           "EUROSTAT--ei_bssi_m_r2--BS-ESI-I--SA--EA20--M")

# labels <- data.frame(
#   code = names(raw)[-1],  # exclude period_id
#   label_sl = c("Industrija",
#                "Storitve",
#                "Potrošniki",
#                "Trgovina na drobno",
#                "Gradbeništvo",
#                "ESI (desna os)"),
#   label_en = c("Industry",
#                "Services",
#                "Consumers",
#                "Retail trade",
#                "Construction",
#                "ESI (right axis)"))
# # Force UTF-8 encoding
# labels$label_sl <- enc2utf8(labels$label_sl)
# labels$label_en <- enc2utf8(labels$label_en)
#
# wb <- openxlsx2::wb_workbook() |>
#   openxlsx2::wb_add_worksheet("podatki") |>
#   openxlsx2::wb_add_data_table(x = raw, table_name = "datatable") |>
#   openxlsx2::wb_add_worksheet("sifrant") |>
#   openxlsx2::wb_add_data_table(sheet = "sifrant", x = labels, table_name = "labelstable") |>
#   openxlsx2::wb_set_col_widths(sheet = "sifrant", cols = 1:ncol(labels), widths = "auto") |>
#   openxlsx2::wb_save("G:\\EO\\EO slike avtomatizirane\\EO_15_ESI_auto.xlsx")


################################################################################
# rebase
raw <- process_codes_vectorized(codes, con) |>
  mutate(period_id = as.Date(paste0(substr(period_id, 1, 4), "-",
                                    substr(period_id, 6, 7), "-01"))) |>
  arrange(period_id) |>
  mutate()

ea21_cols <- grep("EA21", names(raw), value = TRUE)
raw[raw$period < as.Date("2026-01-01"), ea21_cols] <- NA

ea20_cols <- gsub("EA21", "EA20", ea21_cols)

raw[ea21_cols] <- mapply(\(a, b) dplyr::coalesce(raw[[a]], raw[[b]]), ea21_cols, ea20_cols)
raw[ea20_cols] <- NULL

wb <- load_wb_eo(filename)

wb <- write_wb(wb, raw)

try_save_eo(filename)

