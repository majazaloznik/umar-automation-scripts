# source("\\\\192.168.38.7\\public$\\Avtomatizacija\\umar-automation-scripts\\R\\grafi\\00_setup.R")

filename <- "EO_03_surovine_auto.xlsx"
################################################################################
base::message("\nPreparing data for the chart in ", filename)

codes <- c("WB-UMAR--UB001--ENE--M",
           "WB-UMAR--UB001--NON--M",
           "WB-UMAR--UB001--FOOD--M",
           "WB-UMAR--UB001--MM--M")
#
# labels <- data.frame(
#   code = names(raw)[-1],  # exclude period_id
#   label_sl = c("Energenti",
#                "Neenergetske surovine",
#                "Hrana",
#                "Kovine"),
#   label_en = c("Energy",
#                "Non-energy commodities",
#                "Food",
#                "Metals"))
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
#   openxlsx2::wb_save("G:\\EO\\EO slike avtomatizirane\\EO_03_surovine_auto.xlsx")
#

################################################################################
# rebase
raw <- process_codes_vectorized(codes, con) |>
  filter(period_id > "2020M01") |>
  rebase_multiple(value_cols = codes,
                  base_year = 2021) |>
  mutate(crta = 100,
         period_id = as.Date(paste0(substr(period_id, 1, 4), "-",
                                    substr(period_id, 6, 7), "-01"))) |>
  arrange(period_id)


wb <- load_wb_eo(filename)

wb <- write_wb(wb, raw)

try_save_eo(filename)

