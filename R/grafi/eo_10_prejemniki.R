# source("\\\\192.168.38.7\\public$\\Avtomatizacija\\umar-automation-scripts\\R\\grafi\\00_setup.R")

filename <- "EO_10_prejemniki_pomoci_auto.xlsx"
################################################################################
message("\nPreparing data for the chart in ", filename)

codes <- c("DESEZ--STu--u_DSP--Y--M",
           "DESEZ--STu--p_DNB--Y--M")

# labels <- data.frame(
#   code = names(raw)[-1],  # exclude period_id
#   label_sl = c("Upravičenci do denarne socialne pomoči (DSP)",
#                "Prejemniki denarnega nad. za brezposelnost (DNB)"),
#   label_en = c("Beneficiaries of financial social assistance (FSA)",
#                "Recipients of unemployment benefits (UB)"))
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


################################################################################
# prep data
raw <- process_codes_vectorized(codes, con) |>
  rolling_mean(value_col = codes, k = 3) |>
  arrange(period_id) |>
  mutate(period_id = as.Date(paste0(substr(period_id, 1, 4), "-",
                                    substr(period_id, 6, 7), "-01"))) |>
  mutate(dplyr::across(dplyr::all_of(codes),\(x) x / 1000))

wb <- load_wb_eo(filename)

wb <- write_wb(wb, raw)

try_save_eo(filename)
