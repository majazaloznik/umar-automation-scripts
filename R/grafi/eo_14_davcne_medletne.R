# source("\\\\192.168.38.7\\public$\\Avtomatizacija\\umar-automation-scripts\\R\\grafi\\00_setup.R")

filename <- "EO_14_davcne_medletne.xlsx"
################################################################################
base::message("\nPreparing data for the chart in ", filename)

tmp <- tbl(con2, "davcni_racuni") |>
  group_by(datum) |>
  filter(filter == "1") |>
  summarise(znesek = sum(znesek),
            .groups = 'drop') |>
  collect()

final <- tmp |>
  arrange(datum)|>
  mutate(year = lubridate::year(datum),
         month = lubridate::month(datum)) |>
  group_by(year, month) |>
  filter(n() == lubridate::days_in_month(dplyr::first(datum))) |>
  summarise(znesek = sum(znesek), .groups = "drop") |>
  mutate(filtrirane_davcne_medletna =  (znesek / lag(znesek, n = 12) - 1) * 100) |>
  mutate(crta = 0,
         period_id = as.Date(paste0(year, "-", month, "-01"))) |>
  select(period_id, crta, filtrirane_davcne_medletna) |>
  filter(!is.na(filtrirane_davcne_medletna))


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

