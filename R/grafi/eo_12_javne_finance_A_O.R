# source("\\\\192.168.38.7\\public$\\Avtomatizacija\\umar-automation-scripts\\R\\grafi\\00_setup.R")

filename <- "EO_12_javne_finance_A_O_auto.xlsx"
################################################################################
message("\nPreparing data for the chart in ", filename)

codes <- c("MF--KBJF--4--A",
           "MF--KBJF--916--A",
           "MF--KBJF--913--A",
           "MF--KBJF--917--A",
           "MF--KBJF--409--A",
           "MF--KBJF--41--A",
           "MF--KBJF--919--A",
           "MF--KBJF--45--A")
codes2 <- c("MF--KBJF--4--M",
           "MF--KBJF--916--M",
           "MF--KBJF--913--M",
           "MF--KBJF--917--M",
           "MF--KBJF--409--M",
           "MF--KBJF--41--M",
           "MF--KBJF--919--M",
           "MF--KBJF--45--M")

# labels <- data.frame(
#   code = names(raw)[-1],  # exclude period_id
#   label_sl = c("ODHODKI, skupaj (v %)",
#                "Plače in drugi stroški dela**",
#                "Izdatki za blago in storitve",
#                "Plačila obresti",
#                "Rezerve",
#                "Tekoči transferi posam. in gospod.",
#                "Izdatki za investicije",
#                "Plačila v proračun EU"),
#   label_en = c("TOTAL EXPENDITURE (growth in %)",
#                "Salaries, wages and other personnel expend. with social contrib.",
#                "Expenditure on goods and services",
#                "Interest payments",
#                "Current transfers",
#                "Reserves",
#                "Capital exp. and capital transf.",
#                "Payments to the EU budget"))
# # Force UTF-8 encoding
# labels$label_sl <- enc2utf8(labels$label_sl)
# labels$label_en <- enc2utf8(labels$label_en)
# #
# wb <- openxlsx2::wb_workbook() |>
#   openxlsx2::wb_add_worksheet("podatki") |>
#   openxlsx2::wb_add_data_table(x = raw, table_name = "datatable") |>
#   openxlsx2::wb_add_worksheet("sifrant") |>
#   openxlsx2::wb_add_data_table(sheet = "sifrant", x = labels, table_name = "labelstable") |>
#   openxlsx2::wb_set_col_widths(sheet = "sifrant", cols = 1:ncol(labels), widths = "auto") |>
#   openxlsx2::wb_save("G:\\EO\\EO slike avtomatizirane\\EO_12_javne_finance_A_O_auto.xlsx")

transform_month_format <- function(x) {
  year <- substr(x, 1, 4)
  month <- as.integer(substr(x, 6, 7))
  roman <- utils::as.roman(month)
  sprintf("%s I-%s", year, roman)
}
################################################################################
raw <- tbl(con, dbplyr::in_schema("views", "jf_letni")) |>
  filter(series_code %in% codes) |>
  select(series_code, period_id, contribution) |>
  pivot_wider(names_from = series_code, values_from = contribution) |>
  arrange(period_id) |>
  collect()|>
  dplyr::select(period_id, dplyr::all_of(codes)) |>
  filter(substr(period_id, 1, 4) > 2014)

raw2 <- tbl(con, dbplyr::in_schema("views", "jf_kumulative")) |>
  filter(series_code %in% codes2,
         max_month == TRUE) |>
  select(series_code, period_id, contribution) |>
  pivot_wider(names_from = series_code, values_from = contribution) |>
  arrange(period_id) |>
  collect()|>
  dplyr::select(period_id, dplyr::all_of(codes2)) |>
  filter(substr(period_id, 1, 4) > 2014) |>
  tail(2) |>
  mutate(period_id = transform_month_format(period_id))

names(raw)[-1] <- sub("--[^-]$", "", names(raw)[-1])
names(raw2)[-1] <- sub("--[^-]$", "", names(raw2)[-1])

final <- bind_rows(raw, raw2)


wb <- load_wb_eo(filename)

wb <- write_wb(wb, final)

try_save_eo(filename)
