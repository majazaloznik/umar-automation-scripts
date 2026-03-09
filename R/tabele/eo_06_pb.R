# source("\\\\192.168.38.7\\public$\\Avtomatizacija\\umar-automation-scripts\\R\\tabele\\eo_00_setup.R")

codes <- c("BS--i_32_6ms--0--M",
           "BS--i_32_6ms--3--M",
           "BS--i_32_6ms--4--M",
           "BS--i_32_6ms--5--M",
           "BS--i_32_6ms--6--M",
           "BS--i_32_6ms--7--M",
           "BS--i_32_6ms--13--M",
           "BS--i_32_6ms--19--M",
           "BS--i_32_6ms--20--M", # 20+22+30 = primarni prejemki
           "BS--i_32_6ms--22--M",
           "BS--i_32_6ms--30--M",
           "BS--i_32_6ms--21--M", # 21+26+21 = primarni izdatki
           "BS--i_32_6ms--26--M",
           "BS--i_32_6ms--31--M",
           "BS--i_32_6ms--32--M",
           "BS--i_32_6ms--33--M",
           "BS--i_32_6ms--35--M",
           "BS--i_32_6ms--37--M",
           "BS--i_32_6ms--46--M",
           "BS--i_32_6ms--47--M",
           "BS--i_32_6ms--48--M",
           "BS--i_32_6ms--52--M",
           "BS--i_32_6ms--56--M",
           "BS--i_32_6ms--67--M",
           "BS--i_32_6ms--68--M",
           "BS--i_32_6ms--69--M",
           "BS--i_32_6ms--70--M",
           "BS--i_32_6ms--71--M",
           "BS--i_32_6ms--74--M",
           "BS--i_32_6ms--76--M",
           "BS--i_32_6ms--77--M",
           "BS--i_32_6ms--78--M",
           "BS--i_32_6ms--79--M", # ?
           "BS--i_32_6ms--80--M",
           "BS--i_32_6ms--81--M",
           "BS--i_32_6ms--84--M",
           "BS--i_32_6ms--87--M",
           "BS--i_32_6ms--88--M",
           "BS--i_32_6ms--89--M",
           "BS--i_32_6ms--90--M",
           "BS--i_32_6ms--91--M",
           "BS--i_32_6ms--102--M")

codes2 <- c("SURS--2490411S--2--EUR--00--41--M",
            "SURS--2490411S--2--EUR--00--521--M", # investicije
            "SURS--2490411S--2--EUR--00--111--M",
            "SURS--2490411S--2--EUR--00--121--M",
            "SURS--2490411S--2--EUR--00--21--M",
            "SURS--2490411S--2--EUR--00--22--M",
            "SURS--2490411S--2--EUR--00--31--M",
            "SURS--2490411S--2--EUR--00--322--M",
            "SURS--2490411S--2--EUR--00--42--M",
            "SURS--2490411S--2--EUR--00--53--M",# vmesna
            "SURS--2490411S--2--EUR--00--112--M",
            "SURS--2490411S--2--EUR--00--122--M",
            "SURS--2490411S--2--EUR--00--321--M",
            "SURS--2490411S--2--EUR--00--51--M",
            "SURS--2490411S--2--EUR--00--522--M",
            "SURS--2490411S--2--EUR--00--61--M",
            "SURS--2490411S--2--EUR--00--62--M",
            "SURS--2490411S--2--EUR--00--63--M",
            "SURS--2490411S--2--EUR--00--7--M", # [iroka]
            "SURS--2490411S--1--EUR--00--41--M",
            "SURS--2490411S--1--EUR--00--521--M", # investicije
            "SURS--2490411S--1--EUR--00--111--M",
            "SURS--2490411S--1--EUR--00--121--M",
            "SURS--2490411S--1--EUR--00--21--M",
            "SURS--2490411S--1--EUR--00--22--M",
            "SURS--2490411S--1--EUR--00--31--M",
            "SURS--2490411S--1--EUR--00--322--M",
            "SURS--2490411S--1--EUR--00--42--M",
            "SURS--2490411S--1--EUR--00--53--M",# vmesna
            "SURS--2490411S--1--EUR--00--112--M",
            "SURS--2490411S--1--EUR--00--122--M",
            "SURS--2490411S--1--EUR--00--321--M",
            "SURS--2490411S--1--EUR--00--51--M",
            "SURS--2490411S--1--EUR--00--522--M",
            "SURS--2490411S--1--EUR--00--61--M",
            "SURS--2490411S--1--EUR--00--62--M",
            "SURS--2490411S--1--EUR--00--63--M",
            "SURS--2490411S--1--EUR--00--7--M") # [iroka]

raw <- process_codes_vectorized(codes, con) |>
  arrange(period_id) |>
  rowwise() |>
  mutate(`BS--i_32_6ms--pdp--M` = sum(`BS--i_32_6ms--20--M`,
           `BS--i_32_6ms--22--M`, `BS--i_32_6ms--30--M`, na.rm = TRUE), .keep = "unused") |>
  relocate(`BS--i_32_6ms--pdp--M`, .after = `BS--i_32_6ms--19--M`) |>
  mutate(`BS--i_32_6ms--pdi--M` = sum(`BS--i_32_6ms--21--M`,
           `BS--i_32_6ms--26--M`, `BS--i_32_6ms--31--M`, na.rm = TRUE), .keep = "unused") |>
  relocate(`BS--i_32_6ms--pdi--M`, .after = `BS--i_32_6ms--pdp--M`)

out <- process_indicators(raw, n_years = 3, n_quarters = 9, n_months = 25, agg_fun = "sum")


raw2 <- process_codes_vectorized(codes2, con) |>
  rowwise() |>
  arrange(period_id) |>
  mutate(`SURS--2490411S--2--EUR--00--inv--M` = sum(
    `SURS--2490411S--2--EUR--00--41--M`,
    `SURS--2490411S--2--EUR--00--521--M`), .keep = "unused") |>

  mutate(`SURS--2490411S--2--EUR--00--vm--M` = sum(
    `SURS--2490411S--2--EUR--00--111--M`,
    `SURS--2490411S--2--EUR--00--121--M`,
    `SURS--2490411S--2--EUR--00--21--M`,
    `SURS--2490411S--2--EUR--00--22--M`,
    `SURS--2490411S--2--EUR--00--31--M`,
    `SURS--2490411S--2--EUR--00--322--M`,
    `SURS--2490411S--2--EUR--00--42--M`,
    `SURS--2490411S--2--EUR--00--53--M`), .keep = "unused") |>

  mutate(`SURS--2490411S--2--EUR--00--sir--M` = sum(
    `SURS--2490411S--2--EUR--00--112--M`,
    `SURS--2490411S--2--EUR--00--122--M`,
    `SURS--2490411S--2--EUR--00--321--M`,
    `SURS--2490411S--2--EUR--00--51--M`,
    `SURS--2490411S--2--EUR--00--522--M`,
    `SURS--2490411S--2--EUR--00--61--M`,
    `SURS--2490411S--2--EUR--00--62--M`,
    `SURS--2490411S--2--EUR--00--63--M`,
    `SURS--2490411S--2--EUR--00--7--M`), .keep = "unused") |>

  mutate(`SURS--2490411S--1--EUR--00--inv--M` = sum(
    `SURS--2490411S--1--EUR--00--41--M`,
    `SURS--2490411S--1--EUR--00--521--M`), .keep = "unused") |>

  mutate(`SURS--2490411S--1--EUR--00--vm--M` = sum(
    `SURS--2490411S--1--EUR--00--111--M`,
    `SURS--2490411S--1--EUR--00--121--M`,
    `SURS--2490411S--1--EUR--00--21--M`,
    `SURS--2490411S--1--EUR--00--22--M`,
    `SURS--2490411S--1--EUR--00--31--M`,
    `SURS--2490411S--1--EUR--00--322--M`,
    `SURS--2490411S--1--EUR--00--42--M`,
    `SURS--2490411S--1--EUR--00--53--M`), .keep = "unused") |>

  mutate( `SURS--2490411S--1--EUR--00--sir--M` = sum(
    `SURS--2490411S--1--EUR--00--112--M`,
    `SURS--2490411S--1--EUR--00--122--M`,
    `SURS--2490411S--1--EUR--00--321--M`,
    `SURS--2490411S--1--EUR--00--51--M`,
    `SURS--2490411S--1--EUR--00--522--M`,
    `SURS--2490411S--1--EUR--00--61--M`,
    `SURS--2490411S--1--EUR--00--62--M`,
    `SURS--2490411S--1--EUR--00--63--M`,
    `SURS--2490411S--1--EUR--00--7--M`), .keep = "unused")


out2 <- process_indicators(raw2, n_years = 3, n_quarters = 9, n_months = 25, agg_fun = "sum")|>
  dplyr::mutate(dplyr::across(-indicator, ~ .x / 1e6))

out <- out2[0,] |>
  bind_rows(out) |>
  select(any_of(names(out2)))


wb <- load_wb_id()  |> fix_wb_encoding()
wb$clean_sheet(sheet = 6, dims = "B1:AL46", styles = FALSE)
wb$add_data(sheet = 6,  x = t(colnames(out)[-1]),  dims = "B1", colNames = FALSE, na.strings = "")
wb$add_data(sheet = 6,  x = out[,-1],  dims = "B2", colNames = FALSE, na.strings = "")
wb$add_data(sheet = 6,  x = out2[,-1],  dims = "B41", colNames = FALSE, na.strings = "")
try_save_id()


wb <- load_wb_id_en()  |> fix_wb_encoding()
wb$clean_sheet(sheet = 6, dims = "B1:AL46", styles = FALSE)
wb$add_data(sheet = 6,  x = t(colnames(out)[-1]),  dims = "B1", colNames = FALSE, na.strings = "")
wb$add_data(sheet = 6,  x = out[,-1],  dims = "B2", colNames = FALSE, na.strings = "")
wb$add_data(sheet = 6,  x = out2[,-1],  dims = "B41", colNames = FALSE, na.strings = "")
try_save_id_en()


out <- process_indicators(raw, agg_fun = "sum", full = TRUE)

out2 <- process_indicators(raw2,  agg_fun = "sum", full = TRUE)|>
  dplyr::mutate(dplyr::across(-indicator, ~ .x / 1e6))

out <- out2[0,] |>
  bind_rows(out) |>
  select(any_of(names(out2)))

wb <- load_wb_ex()  |> fix_wb_encoding()
wb$clean_sheet(sheet = 6, dims = "B1:BC46", styles = FALSE)
wb$add_data(sheet = 6,  x = t(colnames(out)[-1]),  dims = "B1", colNames = FALSE, na.strings = "")
wb$add_data(sheet = 6,  x = out[,-1],  dims = "B2", colNames = FALSE, na.strings = "")
wb$add_data(sheet = 6,  x = out2[,-1],  dims = "B41", colNames = FALSE, na.strings = "")
try_save_ex()


wb <- load_wb_ex_en()  |> fix_wb_encoding()
wb$clean_sheet(sheet = 6, dims = "B1:BC46", styles = FALSE)
wb$add_data(sheet = 6,  x = t(colnames(out)[-1]),  dims = "B1", colNames = FALSE, na.strings = "")
wb$add_data(sheet = 6,  x = out[,-1],  dims = "B2", colNames = FALSE, na.strings = "")
wb$add_data(sheet = 6,  x = out2[,-1],  dims = "B41", colNames = FALSE, na.strings = "")
try_save_ex_en()
