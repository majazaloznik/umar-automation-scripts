# source("\\\\192.168.38.7\\public$\\Avtomatizacija\\umar-automation-scripts\\R\\grafi\\00_setup.R")

filename <- "EO_05_kratk.kazal_auto.xlsx"
################################################################################
message("\nPreparing data for the chart in ", filename)

codes <- c("UMAR-SURS--MH003--OSNO--REA--EX--SKUP--SKUP--M",
           "SURS--1701111S--sa--C[skd]--M",
           "SURS--1957408S--SA--CC--M",
           "SURS--2001303S--2--2--47 brez 47.3--M",
            "SURS--2080006S--2--H+I+J+L+M+N--M",
           "SURS--2001303S--2--2--G--M")

# labels <- data.frame(
#   code = names(raw)[-1],  # exclude period_id
#   label_sl = c("Izvoz blaga *",
#                "Ind. proiz. predelovalnih dej.",
#                "Vred. opr. del v gradbeništvu",
#                "Prih. v trgovini na drobno brez mot. goriv",
#                "Storitveni prihodek (nom.)"),
#   label_en = c("Goods export *",
#                "Ind. prod. in manufacturing",
#                "Construction output",
#                "Turnover in retail trade without motor fuels",
#                "Turnover in service activities"))
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
#   openxlsx2::wb_save("G:\\EO\\EO slike avtomatizirane\\EO_05_kratk.kazal_auto.xlsx")
#

################################################################################
# rebase all except exports
raw <- process_codes_vectorized(codes, con)

raw <- process_codes_vectorized(codes, con) |>
  rolling_mean(value_col = codes) |>
  rebase_multiple(value_cols = codes[-1],
                  base_year = 2010) |>
  mutate(crta = 100,
         period_id = as.Date(paste0(substr(period_id, 1, 4), "-",
                                    substr(period_id, 6, 7), "-01"))) |>
  arrange(period_id)

# remove 47 brez 47.3 rows where G doesn't have data yet.
last_valid <- max(which(!is.na(raw$`SURS--2001303S--2--2--G--M`)))
raw$`SURS--2001303S--2--2--47 brez 47.3--M`[(last_valid + 1):nrow(raw)] <- NA
raw <- raw |> select(-`SURS--2001303S--2--2--G--M`)

wb <- load_wb_eo(filename)

wb <- write_wb(wb, raw)

try_save_eo(filename)

