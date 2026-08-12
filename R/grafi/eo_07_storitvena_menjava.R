# source("\\\\192.168.38.7\\public$\\Avtomatizacija\\umar-automation-scripts\\R\\grafi\\00_setup.R")

filename <- "EO_07_storitvena_menjava_auto.xlsx"
################################################################################
# Data series from the platform database
################################################################################
base::message("\nPreparing data for the chart in ", filename)
codes <- c( "UMAR-BS--MH002--REA--EX--SKUP--M",
            "UMAR-BS--MH002--REA--IM--SKUP--M")
#
# labels <- data.frame(
#   code = names(raw)[c(2:5)],  # exclude period_id
#   label_sl = c("Nezglajeni podatki",
#                "Nezglajeni podatki",
#                "Izvoz storitev (3mds*)",
#                "Uvoz storitev (3mds*)"),
#   label_en = c("Non-smoothed data",
#                "Non-smoothed data",
#                "Exports of services (3MMA*)",
#                "Exports of services (3MMA*)"))
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
#   openxlsx2::wb_save(paste0("G:\\EO\\EO slike avtomatizirane\\", filename))
#
#

################################################################################
raw <- process_codes_vectorized(codes, con) |>
  rebase_multiple(value_cols = c(codes),
                  base_year = 2021) |>
  mutate(`UMAR-BS--MH002--REA--EX--SKUP--M-smooth` =
           zoo::rollmean(`UMAR-BS--MH002--REA--EX--SKUP--M`, 3, fill = NA, align = "right"),
         `UMAR-BS--MH002--REA--IM--SKUP--M-smooth` =
           zoo::rollmean(`UMAR-BS--MH002--REA--IM--SKUP--M`, 3, fill = NA, align = "right"),
         crta = 100) |>
  filter(substr(period_id, 1, 4) > 2021) |>
  mutate(period_id = as.Date(paste0(substr(period_id, 1, 4), "-",
                                    substr(period_id, 6, 7), "-01"))) |>
  filter_ten_years()

wb <- load_wb_eo(filename)

wb <- write_wb(wb, raw)

try_save_eo(filename)
