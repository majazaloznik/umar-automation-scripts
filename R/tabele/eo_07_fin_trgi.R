# source("\\\\192.168.38.7\\public$\\Avtomatizacija\\umar-automation-scripts\\R\\tabele\\eo_00_setup.R")

codes <- c("BS--I1_2AS--1--0--3--M",
           "BS--I1_5EES--1--0--23--M",
           "BS--I1_5FFS--1--0--23--M",
           "BS--I1_5GGS--1--0--23--M",
           "BS--I1_5DDS--1--0--23--M",
           "BS--I1_5CCS--1--0--23--M",
           "BS--I1_5BBS--1--0--23--M",
           "BS--I1_5AAS--1--0--0--M",
           "BS--I1_5AAS--1--0--1--M",
           "BS--I1_5AAS--1--0--20--M", # 20+22!
           "BS--I1_5AAS--1--0--22--M",
           "BS--I1_6AAS--1--0--0--M", # 0+1+2+3
           "BS--I1_6AAS--1--0--1--M",
           "BS--I1_6AAS--1--0--2--M",
           "BS--I1_6AAS--1--0--3--M",
           "BS--I1_6AAS--1--0--4--M", # 4+5+6
           "BS--I1_6AAS--1--0--5--M",
           "BS--I1_6AAS--1--0--6--M")
codes2 <- c("BS--I2_4_2AS--0--0--M",
           "BS--I2_4_2AS--0--1--M",
           "BS--I2_4_3AS--0--11--M",
           "BS--I2_4_4AS--0--48--M",
           "ECB--FM--U2--EUR--RT--MM--EURIBOR3MD_--HSTA--M",
           "ECB--FM--U2--EUR--RT--MM--EURIBOR6MD_--HSTA--M")



raw <- process_codes_vectorized(codes, con) |>
  arrange(period_id) |>
  mutate(`BS--I1_5AAS--1--0--20n22--M` = `BS--I1_5AAS--1--0--20--M` +
           `BS--I1_5AAS--1--0--22--M`, .keep = "unused") |>
  relocate(`BS--I1_5AAS--1--0--20n22--M`, .after = `BS--I1_5AAS--1--0--1--M`) |>
  mutate(`BS--I1_6AAS--1--0--0123--M` = `BS--I1_6AAS--1--0--0--M` +
           `BS--I1_6AAS--1--0--1--M`+
           `BS--I1_6AAS--1--0--2--M`+
           `BS--I1_6AAS--1--0--3--M`,
         `BS--I1_6AAS--1--0--456--M` = `BS--I1_6AAS--1--0--4--M` +
           `BS--I1_6AAS--1--0--5--M` + `BS--I1_6AAS--1--0--6--M`) |>
  relocate(`BS--I1_6AAS--1--0--0123--M`, .after = `BS--I1_5AAS--1--0--20n22--M`) |>
  relocate(`BS--I1_6AAS--1--0--456--M`, .after = `BS--I1_6AAS--1--0--3--M`)

out <- process_indicators(raw, n_years = 3, n_quarters = 0, n_months = 29, agg_fun = "last")

raw2 <- process_codes_vectorized(codes2, con) |>
  arrange(period_id)

out2 <- process_indicators(raw2, n_years = 3, n_quarters = 0, n_months = 29, agg_fun = "mean")

out <- out2[0,] |>
  bind_rows(out) |>
  select(any_of(names(out2)))

wb <- load_wb_id()  |> fix_wb_encoding()
wb$clean_sheet(sheet = "7-fin. trgi", dims = "B3:BZ32", styles = FALSE)
wb$clean_sheet(sheet = "7-fin. trgi", dims = "B34:BZ37", styles = FALSE)
wb$add_data(sheet = "7-fin. trgi",  x = t(colnames(out)[-1]),  dims = "B1", colNames = FALSE, na.strings = "")
wb$add_data(sheet = "7-fin. trgi",  x = out[1:7,-1],  dims = "B3", colNames = FALSE, na.strings = "")
wb$add_data(sheet = "7-fin. trgi",  x = out[8:10,-1],  dims = "B11", colNames = FALSE, na.strings = "")
wb$add_data(sheet = "7-fin. trgi",  x = out[11:19,-1],  dims = "B15", colNames = FALSE, na.strings = "")
wb$add_data(sheet = "7-fin. trgi",  x = out2[1:2,-1],  dims = "B26", colNames = FALSE, na.strings = "")
wb$add_data(sheet = "7-fin. trgi",  x = out2[3,-1],  dims = "B29", colNames = FALSE, na.strings = "")
wb$add_data(sheet = "7-fin. trgi",  x = out2[4,-1],  dims = "B31", colNames = FALSE, na.strings = "")
wb$add_data(sheet = "7-fin. trgi",  x = out2[5:6,-1],  dims = "B36", colNames = FALSE, na.strings = "")
try_save_id()

wb <- load_wb_id_en()  |> fix_wb_encoding()
wb$clean_sheet(sheet = "7-fin. markets", dims = "B3:BZ32", styles = FALSE)
wb$clean_sheet(sheet = "7-fin. markets", dims = "B34:BZ37", styles = FALSE)
wb$add_data(sheet = "7-fin. markets",  x = t(colnames(out)[-1]),  dims = "B1", colNames = FALSE, na.strings = "")
wb$add_data(sheet = "7-fin. markets",  x = out[1:7,-1],  dims = "B3", colNames = FALSE, na.strings = "")
wb$add_data(sheet = "7-fin. markets",  x = out[8:10,-1],  dims = "B11", colNames = FALSE, na.strings = "")
wb$add_data(sheet = "7-fin. markets",  x = out[11:19,-1],  dims = "B15", colNames = FALSE, na.strings = "")
wb$add_data(sheet = "7-fin. markets",  x = out2[1:2,-1],  dims = "B26", colNames = FALSE, na.strings = "")
wb$add_data(sheet = "7-fin. markets",  x = out2[3,-1],  dims = "B29", colNames = FALSE, na.strings = "")
wb$add_data(sheet = "7-fin. markets",  x = out2[4,-1],  dims = "B31", colNames = FALSE, na.strings = "")
wb$add_data(sheet = "7-fin. markets",  x = out2[5:6,-1],  dims = "B36", colNames = FALSE, na.strings = "")
try_save_id_en()

out <- process_indicators(raw, n_quarters = 0,  agg_fun = "last", full = TRUE)

out2 <- process_indicators(raw2, n_quarters = 0, agg_fun = "mean", full = TRUE)

out <- out2[0,] |>
  bind_rows(out) |>
  select(any_of(names(out2)))

wb <- load_wb_ex()  |> fix_wb_encoding()
wb$clean_sheet(sheet = "7-fin. trgi", dims = "B3:BY32", styles = FALSE)
wb$clean_sheet(sheet = "7-fin. trgi", dims = "B34:BY37", styles = FALSE)
wb$add_data(sheet = "7-fin. trgi",  x = t(colnames(out)[-1]),  dims = "B1", colNames = FALSE, na.strings = "")
wb$add_data(sheet = "7-fin. trgi",  x = out[1:7,-1],  dims = "B3", colNames = FALSE, na.strings = "")
wb$add_data(sheet = "7-fin. trgi",  x = out[8:10,-1],  dims = "B11", colNames = FALSE, na.strings = "")
wb$add_data(sheet = "7-fin. trgi",  x = out[11:19,-1],  dims = "B15", colNames = FALSE, na.strings = "")
wb$add_data(sheet = "7-fin. trgi",  x = out2[1:2,-1],  dims = "B26", colNames = FALSE, na.strings = "")
wb$add_data(sheet = "7-fin. trgi",  x = out2[3,-1],  dims = "B29", colNames = FALSE, na.strings = "")
wb$add_data(sheet = "7-fin. trgi",  x = out2[4,-1],  dims = "B31", colNames = FALSE, na.strings = "")
wb$add_data(sheet = "7-fin. trgi",  x = out2[5:6,-1],  dims = "B36", colNames = FALSE, na.strings = "")
try_save_ex()

wb <- load_wb_ex_en()  |> fix_wb_encoding()
wb$clean_sheet(sheet = "7-fin. markets", dims = "B3:BY32", styles = FALSE)
wb$clean_sheet(sheet = "7-fin. markets", dims = "B34:BY37", styles = FALSE)
wb$add_data(sheet = "7-fin. markets",  x = t(colnames(out)[-1]),  dims = "B1", colNames = FALSE, na.strings = "")
wb$add_data(sheet = "7-fin. markets",  x = out[1:7,-1],  dims = "B3", colNames = FALSE, na.strings = "")
wb$add_data(sheet = "7-fin. markets",  x = out[8:10,-1],  dims = "B11", colNames = FALSE, na.strings = "")
wb$add_data(sheet = "7-fin. markets",  x = out[11:19,-1],  dims = "B15", colNames = FALSE, na.strings = "")
wb$add_data(sheet = "7-fin. markets",  x = out2[1:2,-1],  dims = "B26", colNames = FALSE, na.strings = "")
wb$add_data(sheet = "7-fin. markets",  x = out2[3,-1],  dims = "B29", colNames = FALSE, na.strings = "")
wb$add_data(sheet = "7-fin. markets",  x = out2[4,-1],  dims = "B31", colNames = FALSE, na.strings = "")
wb$add_data(sheet = "7-fin. markets",  x = out2[5:6,-1],  dims = "B36", colNames = FALSE, na.strings = "")
try_save_ex_en()
