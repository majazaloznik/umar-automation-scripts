# source("\\\\192.168.38.7\\public$\\Avtomatizacija\\umar-automation-scripts\\R\\grafi\\00_setup.R")

filename <- "GT_18_elektrika_auto.xlsx"

################################################################################
message("\nPreparing data for the chart in ", filename)

codes <- c("UMAR-SODO--AK001--IND--M",
                  "UMAR-SODO--AK001--GOSP--M",
                  "UMAR-SODO--AK001--MPO--M",
                  "UMAR-SODO--AK001--SKUP--M")

################################################################################
raw <- process_codes_vectorized(codes, con) |>
  mutate(crta = 0,
         period_id = as.Date(paste0(substr(period_id, 1, 4), "-",
                                    substr(period_id, 6, 7), "-01"))) |>
  filter(substr(period_id, 1, 4) > 2021) |>
  arrange(period_id)

# labels <- data.frame(
#   code = names(raw)[-1],  # exclude period_id
#   label_sl = c("Industrija",
#                "Gospodinjstva",
#                "Mali poslovni odjem",
#                "Skupaj poraba distrib. omrežja"),
#   label_en = c("Industry",
#                "Households",
#                "Small business consumption",
#                "Total distribution network consumption"))
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
#

wb <- load_wb(filename)

wb <- write_wb(wb, raw)

try_save(filename)
