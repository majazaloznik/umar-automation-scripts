# source("\\\\192.168.38.7\\public$\\Avtomatizacija\\umar-automation-scripts\\R\\tabele\\eo_00_setup.R")

codes <- c("SURS--0400608S--TOT--2--M",
           "SURS--0400608S--01--2--M",
           "SURS--0400608S--02--2--M",
           "SURS--0400608S--03--2--M",
           "SURS--0400608S--04--2--M", # stanovanja?
           "SURS--0400608S--05--2--M",
           "SURS--0400608S--06--2--M",
           "SURS--0400608S--07--2--M",
           "SURS--0400608S--08--2--M",
           "SURS--0400608S--09--2--M",
           "SURS--0400608S--10--2--M",
           "SURS--0400608S--11--2--M",
           "SURS--0400608S--12--2--M",
           "SURS--0400608S--13--2--M",
           "SURS--0400609S--TOT--2--M",
           "SURS--0400608S--9999900201--2--M",

           "SURS--0457102S--B_TO_E--02--M",
           "SURS--0457202S--B_TO_E--02--M",
           "SURS--0457302S--B_TO_E--02--M",
           "SURS--0457303S--B_TO_E--02--M",
           "SURS--0457304S--B_TO_E--02--M",
           "SURS--0425002S--B_TO_E--02--M"
           )

codes2 <- c("SURS--0400608S--TOT--10--M",
           "SURS--0400608S--01--10--M",
           "SURS--0400608S--02--10--M",
           "SURS--0400608S--03--10--M",
           "SURS--0400608S--04--10--M", # stanovanja?
           "SURS--0400608S--05--10--M",
           "SURS--0400608S--06--10--M",
           "SURS--0400608S--07--10--M",
           "SURS--0400608S--08--10--M",
           "SURS--0400608S--09--10--M",
           "SURS--0400608S--10--10--M",
           "SURS--0400608S--11--10--M",
           "SURS--0400608S--12--10--M",
           "SURS--0400608S--13--10--M",
           "EUROSTAT--prc_hicp_mv12r--CP00--SI--M",
           "SURS--0400608S--9999900201--10--M")

raw <- process_codes_vectorized(codes, con) |>
  arrange(period_id) |>
  mutate(across(where(is.numeric), ~ .x - 100))


out <- process_indicators(raw, n_years = 3, n_quarters = 9, n_months = 25, agg_fun = "mean")

raw2 <- process_codes_vectorized(codes2, con) |>
  arrange(period_id) |>
  mutate(across(where(is.numeric) & !`EUROSTAT--prc_hicp_mv12r--CP00--SI--M` , ~ .x - 100))


out2 <- process_indicators(raw2, n_years = 3, n_quarters = 0, n_months = 0, agg_fun = "last")

con_prod <- DBI::dbConnect(RPostgres::Postgres(),
                           dbname = "produktivnost",
                           host = "localhost",
                           port = 5432,
                           user = "postgres",
                           password = Sys.getenv("PG_PG_PSW"),
                           client_encoding = "utf8")

library(dplyr)
DBI::dbExecute(con_prod, "set search_path to tecaji")

neer_m <- tbl(con_prod, "te\u010Daji_mese\u010Dni") |>
  filter(currency == "SIT",
         type == "NEER_EA_18_M",
         year > 2020) |>
  select(year, month, yoy) |>
  collect()

reer_hicp_m <- tbl(con_prod, "te\u010Daji_mese\u010Dni") |>
  filter(currency == "SIT",
         type == "REER_EA_18_M",
         year > 2020) |>
  select(year, month, yoy) |>
  collect()

reer_ulc <- tbl(con_prod, "te\u010Daji_\u010Detrtletni") |>
  filter(currency == "SIT",
         type == "REER_ULC_Q",
         year > 2020) |>
  select(year, month, yoy) |>
  collect()

usd_eur <- tbl(con_prod, "nonEA_te\u010Daji_mese\u010Dni") |>
  filter(currency == "USD",
         year > 2020) |>
  select(year, month, obsvalue) |>
  collect()

reer_ulc_m <- tidyr::expand_grid(year = unique(reer_ulc$year), month = 1:12) |>
  dplyr::mutate(quarter_month = findInterval(month, c(1, 4, 7, 10))) |>
  dplyr::mutate(quarter_month = c(1, 4, 7, 10)[quarter_month]) |>
  dplyr::left_join(reer_ulc, by = c("year", "quarter_month" = "month")) |>
  select(-quarter_month)

monthly <- full_join(neer_m, reer_hicp_m, by = c("year", "month")) |>
  full_join(reer_ulc_m, by = c("year", "month")) |>
  full_join(usd_eur, by = c("year", "month")) |>
  mutate(period_id = paste0(year, "M", sprintf("%02d", month)), .keep = "unused")

out_3 <- process_indicators(monthly, n_years = 3, n_quarters = 9, n_months = 25, agg_fun = "mean")
month_cols <- grep("^\\d{2}-\\d{2}$", names(out_3))
out_3[out_3$indicator == "yoy", month_cols] <- NA


wb <- load_wb_id()  |> fix_wb_encoding()
wb$clean_sheet(sheet = "5-cene", dims = "B2:AL29", styles = FALSE)
wb$add_data(sheet = "5-cene",  x = t(colnames(out)[-1]),  dims = "B1", colNames = FALSE, na.strings = "")
wb$add_data(sheet = "5-cene",  x = out[1:16,-1],  dims = "B2", colNames = FALSE, na.strings = "")
wb$add_data(sheet = "5-cene",  x = out[17:22,-1],  dims = "B19", colNames = FALSE, na.strings = "")
wb$add_data(sheet = "5-cene",  x = out_3[,-1],  dims = "B26", colNames = FALSE, na.strings = "")
# overwrite annual data with correct 12 month averages!
wb$add_data(sheet = "5-cene",  x = out2[1:16,-1],  dims = "B2", colNames = FALSE, na.strings = "")

try_save_id()

wb <- load_wb_id_en()  |> fix_wb_encoding()
wb$clean_sheet(sheet = "5-prices", dims = "B2:AL29", styles = FALSE)
wb$add_data(sheet = "5-prices",  x = t(colnames(out)[-1]),  dims = "B1", colNames = FALSE, na.strings = "")
wb$add_data(sheet = "5-prices",  x = out[1:16,-1],  dims = "B2", colNames = FALSE, na.strings = "")
wb$add_data(sheet = "5-prices",  x = out[17:22,-1],  dims = "B19", colNames = FALSE, na.strings = "")
wb$add_data(sheet = "5-prices",  x = out_3[,-1],  dims = "B26", colNames = FALSE, na.strings = "")
# overwrite annual data with correct 12 month averages!
wb$add_data(sheet = "5-prices",  x = out2[1:16,-1],  dims = "B2", colNames = FALSE, na.strings = "")

try_save_id_en()




out <- process_indicators(raw, n_years = 5, n_quarters = 15, n_months = 35, agg_fun = "mean")

max_period <- max(raw2$period_id)
max_year <- as.integer(substr(max_period, 1, 4))
max_month <- as.integer(substr(max_period, 6, 7))

out2 <- process_indicators(raw2, n_years = 5, n_quarters = 0, n_months = 0, agg_fun = "last")

out_3 <- process_indicators(monthly, n_years = 5, n_quarters = 15, n_months = 35, agg_fun = "mean")
month_cols <- grep("^\\d{2}-\\d{2}$", names(out_3))
out_3[out_3$indicator == "yoy", month_cols] <- NA


wb <- load_wb_ex()  |> fix_wb_encoding()
wb$clean_sheet(sheet = "5-cene", dims = "B2:BD23", styles = FALSE)
wb$add_data(sheet = "5-cene",  x = t(colnames(out)[-1]),  dims = "B1", colNames = FALSE, na.strings = "")
wb$add_data(sheet = "5-cene",  x = out[1:16,-1],  dims = "B2", colNames = FALSE, na.strings = "")
wb$add_data(sheet = "5-cene",  x = out[17:22,-1],  dims = "B19", colNames = FALSE, na.strings = "")
wb$add_data(sheet = "5-cene",  x = out_3[,-1],  dims = "B26", colNames = FALSE, na.strings = "")
# overwrite annual data with correct 12 month averages!
wb$add_data(sheet = "5-cene",  x = out2[1:16,-1],  dims = "B2", colNames = FALSE, na.strings = "")

try_save_ex()

wb <- load_wb_ex_en()  |> fix_wb_encoding()
wb$clean_sheet(sheet = "5-prices", dims = "B2:BD23", styles = FALSE)
wb$add_data(sheet = "5-prices",  x = t(colnames(out)[-1]),  dims = "B1", colNames = FALSE, na.strings = "")
wb$add_data(sheet = "5-prices",  x = out[1:16,-1],  dims = "B2", colNames = FALSE, na.strings = "")
wb$add_data(sheet = "5-prices",  x = out[17:22,-1],  dims = "B19", colNames = FALSE, na.strings = "")
wb$add_data(sheet = "5-prices",  x = out_3[,-1],  dims = "B26", colNames = FALSE, na.strings = "")
# overwrite annual data with correct 12 month averages!
wb$add_data(sheet = "5-prices",  x = out2[1:16,-1],  dims = "B2", colNames = FALSE, na.strings = "")

try_save_ex_en()

