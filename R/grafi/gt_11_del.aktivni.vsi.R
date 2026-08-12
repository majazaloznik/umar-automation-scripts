# source("\\\\192.168.38.7\\public$\\Avtomatizacija\\umar-automation-scripts\\R\\grafi\\00_setup.R")

filename <- "GT_11_del.aktivni_vsi_auto.xlsx"

################################################################################
base::message("\nPreparing data for the chart in ", filename)

codes <- c("DESEZ--DA--VSI--Y--M")

################################################################################
raw <- process_codes_vectorized(codes, con) |>
  rowwise() |>
  mutate(`DESEZ--DA--VSI--Y--M` = `DESEZ--DA--VSI--Y--M` / 1000,
         period_id = as.Date(paste0(substr(period_id, 1, 4), "-",
                                    substr(period_id, 6, 7), "-01")),
         .keep = "unused") |>
  arrange(period_id) |>
  filter(period_id >= "2022-01-01" )
#
# labels <- data.frame(
#   code = names(raw)[-1],  # exclude period_id
#   label_sl = c("Delovno aktivni"),
#   label_en = c("Persons in employment"))
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
#   openxlsx2::wb_save(paste0("G:\\GT\\SLIKE\\GT slike avtomatizirane\\", filename))
#


wb <- load_wb(filename)

wb <- write_wb(wb, raw)

try_save(filename)
