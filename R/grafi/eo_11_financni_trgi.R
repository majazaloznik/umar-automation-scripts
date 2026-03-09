# source("\\\\192.168.38.7\\public$\\Avtomatizacija\\umar-automation-scripts\\R\\grafi\\00_setup.R")

filename <- "EO_11_financni_trgi_auto.xlsx"
################################################################################
message("\nPreparing data for the chart in ", filename)

codes <- c("BS--I1_5GGS--1--0--2--M",
           "BS--I1_5GGS--1--0--8--M",
           "BS--I1_5CCS--1--0--14--M",
           "BS--I1_5DDS--1--0--14--M",
           "BS--I1_5GGS--1--0--14--M",
           "BS--I1_5EES--1--0--14--M",
           "BS--I1_5FFS--1--0--14--M")

# labels <- data.frame(
#   code = names(raw)[-1],  # exclude period_id
#   label_sl = c("Potrošniški krediti",
#                "Stanovanjski krediti",
#                "Krediti podjetjem in NFI",
#                "Skupaj"),
#   label_en = c("Consumer loans",
#                "Lending for house purchases",
#                "Enterprises and NFIs",
#                "Total"))
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
#   openxlsx2::wb_save("G:\\EO\\EO slike avtomatizirane\\EO_11_financni_trgi_auto.xlsx")


################################################################################
# rebase all except exports
raw <- process_codes_vectorized(codes, con) |>
  mutate(`BS--I1_5CCS--1--0--14--M` = `BS--I1_5CCS--1--0--14--M` + `BS--I1_5DDS--1--0--14--M`,
         `Skupaj` =
         `BS--I1_5GGS--1--0--2--M` +
         `BS--I1_5GGS--1--0--8--M` +
         `BS--I1_5CCS--1--0--14--M` +
         `BS--I1_5GGS--1--0--14--M` +
         `BS--I1_5EES--1--0--14--M` +
         `BS--I1_5FFS--1--0--14--M`) |>
  select(-`BS--I1_5DDS--1--0--14--M`, -`BS--I1_5GGS--1--0--14--M`,
         -`BS--I1_5EES--1--0--14--M`, -`BS--I1_5FFS--1--0--14--M`) |>
  arrange(period_id) |>
  yoy_growth(value_cols = c(codes[1:3], "Skupaj")) |>
  mutate(crta = 0,
         period_id = as.Date(paste0(substr(period_id, 1, 4), "-",
                                    substr(period_id, 6, 7), "-01")))



wb <- load_wb_eo(filename)

wb <- write_wb(wb, raw)

try_save_eo(filename)
