# source("\\\\192.168.38.7\\public$\\Avtomatizacija\\umar-automation-scripts\\R\\grafi\\00_setup.R")

filename <- "EO_12_javne_finance_Q_P_auto.xlsx"
################################################################################
message("\nPreparing data for the chart in ", filename)

codes <- c("MF--KBJF--7--M",
           "MF--KBJF--914--M",
           "MF--KBJF--701--M",
           "MF--KBJF--71--M",
           "MF--KBJF--78--M",
           "MF--KBJF--915--M")

# labels <- data.frame(
#   code = names(raw)[-1],  # exclude period_id
#   label_sl = c("PRIHODKI, skupaj (v %)",
#                "Davčni prihodki*",
#                "Prispevki za soc. varnost",
#                "Nedavčni prihodki",
#                "Prejeta sredstva iz EU",
#                "Ostalo"),
#   label_en = c("TOTAL REVENUE (growth in %)",
#                "Tax revenues",
#                "Social security contributions",
#                "Non-tax revenues",
#                "Receipts from the EU budget",
#                "Other"))
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
#   openxlsx2::wb_save("G:\\EO\\EO slike avtomatizirane\\EO_12_javne_finance_Q_P_auto.xlsx")
#

################################################################################
raw <- tbl(con, dbplyr::in_schema("views", "jf_cetrtletni")) |>
  filter(series_code %in% codes) |>
  select(series_code, period_id, contribution) |>
  pivot_wider(names_from = series_code, values_from = contribution) |>
  arrange(period_id) |>
  collect()|>
  dplyr::select(period_id, dplyr::all_of(codes)) |>
  filter(substr(period_id, 1, 4) > 2019) |>
  mutate(q_id = paste(substr(period_id, 5, 6),
                      substr(period_id, 3, 4)))


wb <- load_wb_eo(filename)

wb <- write_wb(wb, raw)

try_save_eo(filename)
