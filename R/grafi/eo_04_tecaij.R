# source("\\\\192.168.38.7\\public$\\Avtomatizacija\\umar-automation-scripts\\R\\grafi\\00_setup.R")

filename <- "EO_04_tecaji_auto.xlsx"
################################################################################
message("\nPreparing data for the chart in ", filename)

codes <- c( "NEER_EA_18_Q",
            "REER_EA_18_Q",
            "REER_PPI_Q",
            "REER_ULC_Q")

# labels <- data.frame(
#   code = names(raw)[-c(1, 6)],  # exclude period_id
#   label_sl = c("NEER",
#                "REER hicp",
#                "REER ppi",
#                "REER ulc"),
#   label_en = c("NEER",
#                "REER hicp",
#                "REER ppi",
#                "REER ulc"))
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
#   openxlsx2::wb_save("G:\\EO\\EO slike avtomatizirane\\EO_04_tecaji_auto.xlsx")


################################################################################
# set schema search path
con_tecaji <- DBI::dbConnect(RPostgres::Postgres(),
                      dbname = "produktivnost",
                      host = "localhost",
                      port = 5432,
                      user = "postgres",
                      password = Sys.getenv("PG_PG_PSW"),
                      client_encoding = "utf8")

DBI::dbExecute(con_tecaji, "set search_path to tecaji")
Sys.setlocale("LC_CTYPE", "Slovenian_Slovenia.utf8")
raw <- tbl(con_tecaji, "tečaji_četrtletni") |>
  filter(type %in% codes,
         year > 2014,
         currency == "SIT") |>
  select(type, indeks_2007, year, q) |>
  collect() |>
  mutate(period_id = paste0(year, "Q", q)) |>
  pivot_wider(names_from = type, values_from = indeks_2007) |>
  rebase_multiple(value_cols = codes,
                  base_year = 2015) |>
  arrange(period_id) |>
  mutate(year = substr(period_id, 1, 4),
         crta = 100,
         period_id =paste0("Q", q, " ", substr(year, 3, 4))) |>
  select(-year, -q) |>
  relocate(period_id)

wb <- load_wb_eo(filename)

wb <- write_wb(wb, raw)

try_save_eo(filename)
