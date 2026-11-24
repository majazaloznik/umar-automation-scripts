# source("\\\\192.168.38.7\\public$\\Avtomatizacija\\umar-automation-scripts\\R\\grafi\\00_setup.R")

filename <- "EO_14_davcne_medletne.xlsx"
################################################################################
base::message("\nPreparing data for the chart in ", filename)

# new way, from platform
codes <- c("FURS-UMAR--UDB008--FILT--M")
final <- process_codes_vectorized(codes, con) |>
  yoy_growth(codes) |>
  mutate(crta = 0,
         period_id = as.Date(paste0(substr(period_id, 1, 4), "-",
                                    substr(period_id, 6, 7), "-01"))) |>
  select(period_id, crta, `FURS-UMAR--UDB008--FILT--M`) |>
  filter(substr(period_id, 1, 4) > 2019)

# labels <- data.frame(
#   code = names(final)[3],  # exclude period_id
#   label_sl = c("Davčne blagajne nom. medletna rast*"),
#   label_en = c("Davčne blagajne nom. medletna rast*"))
# # Force UTF-8 encoding
# labels$label_sl <- enc2utf8(labels$label_sl)
# labels$label_en <- enc2utf8(labels$label_en)
#
# wb <- openxlsx2::wb_workbook() |>
#   openxlsx2::wb_add_worksheet("podatki") |>
#   openxlsx2::wb_add_data_table(x = final, table_name = "datatable") |>
#   openxlsx2::wb_add_worksheet("sifrant") |>
#   openxlsx2::wb_add_data_table(sheet = "sifrant", x = labels, table_name = "labelstable") |>
#   openxlsx2::wb_set_col_widths(sheet = "sifrant", cols = 1:ncol(labels), widths = "auto") |>
#   openxlsx2::wb_save("G:\\EO\\EO slike avtomatizirane\\EO_14_davcne_medletne.xlsx")




wb <- load_wb_eo(filename)

wb <- write_wb(wb, final)

try_save_eo(filename)

