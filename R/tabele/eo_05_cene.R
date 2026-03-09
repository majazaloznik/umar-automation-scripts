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


wb <- load_wb_id()  |> fix_wb_encoding()
wb$clean_sheet(sheet = "5-cene", dims = "B2:AK23", styles = FALSE)
wb$add_data(sheet = "5-cene",  x = t(colnames(out)[-1]),  dims = "B1", colNames = FALSE, na.strings = "")
wb$add_data(sheet = "5-cene",  x = out[1:16,-1],  dims = "B2", colNames = FALSE, na.strings = "")
wb$add_data(sheet = "5-cene",  x = out[17:22,-1],  dims = "B19", colNames = FALSE, na.strings = "")
# overwrite annual data with correct 12 month averages!
wb$add_data(sheet = "5-cene",  x = out2[1:16,-1],  dims = "B2", colNames = FALSE, na.strings = "")

try_save_id()


wb <- load_wb_id_en()  |> fix_wb_encoding()
wb$clean_sheet(sheet = "5-prices", dims = "B2:AK23", styles = FALSE)
wb$add_data(sheet = "5-prices",  x = t(colnames(out)[-1]),  dims = "B1", colNames = FALSE, na.strings = "")
wb$add_data(sheet = "5-prices",  x = out[1:16,-1],  dims = "B2", colNames = FALSE, na.strings = "")
wb$add_data(sheet = "5-prices",  x = out[17:22,-1],  dims = "B19", colNames = FALSE, na.strings = "")
# overwrite annual data with correct 12 month averages!
wb$add_data(sheet = "5-prices",  x = out2[1:16,-1],  dims = "B2", colNames = FALSE, na.strings = "")

try_save_id_en()

out <- process_indicators(raw, n_years = 5, n_quarters = 15, n_months = 35, agg_fun = "mean")

max_period <- max(raw2$period_id)
max_year <- as.integer(substr(max_period, 1, 4))
max_month <- as.integer(substr(max_period, 6, 7))

n_years <- if(max_month == 12) max_year - 2019 else max_year - 2020

out2 <- process_indicators(raw2, n_years = n_years, n_quarters = 0, n_months = 0, agg_fun = "last")

wb <- load_wb_ex()  |> fix_wb_encoding()
wb$clean_sheet(sheet = "5-cene", dims = "B2:AK23", styles = FALSE)
wb$add_data(sheet = "5-cene",  x = t(colnames(out)[-1]),  dims = "B1", colNames = FALSE, na.strings = "")
wb$add_data(sheet = "5-cene",  x = out[1:16,-1],  dims = "B2", colNames = FALSE, na.strings = "")
wb$add_data(sheet = "5-cene",  x = out[17:22,-1],  dims = "B19", colNames = FALSE, na.strings = "")
# overwrite annual data with correct 12 month averages!
wb$add_data(sheet = "5-cene",  x = out2[1:16,-1],  dims = "B2", colNames = FALSE, na.strings = "")

try_save_ex()

wb <- load_wb_ex_en()  |> fix_wb_encoding()
wb$clean_sheet(sheet = "5-prices", dims = "B2:AK23", styles = FALSE)
wb$add_data(sheet = "5-prices",  x = t(colnames(out)[-1]),  dims = "B1", colNames = FALSE, na.strings = "")
wb$add_data(sheet = "5-prices",  x = out[1:16,-1],  dims = "B2", colNames = FALSE, na.strings = "")
wb$add_data(sheet = "5-prices",  x = out[17:22,-1],  dims = "B19", colNames = FALSE, na.strings = "")
# overwrite annual data with correct 12 month averages!
wb$add_data(sheet = "5-prices",  x = out2[1:16,-1],  dims = "B2", colNames = FALSE, na.strings = "")

try_save_ex_en()

