#  source("\\\\192.168.38.7\\public$\\Avtomatizacija\\umar-automation-scripts\\R\\tabele\\eo_00_setup.R")


codes <- c("MF--KBJF--7--M",
           "MF--KBJF--901--M",
           "MF--KBJF--70--M",
           "MF--KBJF--700--M",
           "MF--KBJF--701--M",
           "MF--KBJF--702--M",
           "MF--KBJF--703--M",
           "MF--KBJF--704--M",
           "MF--KBJF--705--M",
           "MF--KBJF--706--M",
           "MF--KBJF--71--M",
           "MF--KBJF--72--M",
           "MF--KBJF--73--M",
           "MF--KBJF--74--M",
           "MF--KBJF--78--M",
           "MF--KBJF--4--M",
           "MF--KBJF--40--M",
           "MF--KBJF--911--M",
           "MF--KBJF--912--M",
           "MF--KBJF--913--M",
           "MF--KBJF--403--M",
           "MF--KBJF--404--M",
           "MF--KBJF--409--M",
           "MF--KBJF--41--M",
           "MF--KBJF--410--M",
           "MF--KBJF--411--M",
           "MF--KBJF--412--M",
           "MF--KBJF--413--M",
           "MF--KBJF--414--M",
           "MF--KBJF--42--M",
           "MF--KBJF--43--M",
           "MF--KBJF--45--M",
           "MF--KBJF--906--M")


raw <- process_codes_vectorized(codes, con) |>
  mutate(`MF--KBJF--9XX--M` = `MF--KBJF--911--M` + `MF--KBJF--912--M`, .keep = "unused") |>
  mutate(`MF--KBJF--4xx--M` = `MF--KBJF--403--M` + `MF--KBJF--404--M`, .keep = "unused") |>
  mutate(`MF--KBJF--41x--M` = `MF--KBJF--412--M` + `MF--KBJF--413--M`, .keep = "unused") |>
  relocate(`MF--KBJF--9XX--M`, .after = `MF--KBJF--40--M`) |>
  relocate(`MF--KBJF--4xx--M`, .after = `MF--KBJF--913--M`) |>
  relocate(`MF--KBJF--41x--M`, .after = `MF--KBJF--411--M`)

out <- process_indicators(raw)|>
  dplyr::mutate(dplyr::across(-indicator, ~ .x / 1e6))


wb <- load_wb_id()  |> fix_wb_encoding()
wb$clean_sheet(sheet = "8-javne finance", dims = "B1:AZ34", styles = FALSE)
wb$add_data(sheet = "8-javne finance",  x = out[1:15,-1],  dims = "B4", colNames = FALSE)
wb$add_data(sheet = "8-javne finance",  x = out[16:30,-1],  dims = "B20", colNames = FALSE)
wb$add_data(sheet = "8-javne finance",  x = colnames(out)[-1],  dims = "B1:AJ1")
try_save_id()

wb <- load_wb_id_en()  |> fix_wb_encoding()
wb$clean_sheet(sheet = "8-public finances", dims = "B1:AZ34", styles = FALSE)
wb$add_data(sheet = "8-public finances",  x = out[1:15,-1],  dims = "B4", colNames = FALSE)
wb$add_data(sheet = "8-public finances",  x = out[16:30,-1],  dims = "B20", colNames = FALSE)
wb$add_data(sheet = "8-public finances",  x = colnames(out)[-1],  dims = "B1:AJ1")
try_save_id_en()

full <- process_indicators(raw, full = TRUE)|>
  dplyr::mutate(dplyr::across(-indicator, ~ .x / 1e6))

wb <- load_wb_ex()  |> fix_wb_encoding()
wb$clean_sheet(sheet = "8-javne finance", dims = "B1:AZ34", styles = FALSE)
wb$add_data(sheet = "8-javne finance",  x = full[1:15,-1],  dims = "B4", colNames = FALSE)
wb$add_data(sheet = "8-javne finance",  x = full[16:30,-1],  dims = "B20", colNames = FALSE)
wb$add_data(sheet = "8-javne finance",  x = t(colnames(full)[-1]),  dims = "B1", colNames = FALSE)
try_save_ex()

wb <- load_wb_ex_en()  |> fix_wb_encoding()
wb$clean_sheet(sheet = "8-public finances", dims = "B1:AZ34", styles = FALSE)
wb$add_data(sheet = "8-public finances",  x = full[1:15,-1],  dims = "B4", colNames = FALSE)
wb$add_data(sheet = "8-public finances",  x = full[16:30,-1],  dims = "B20", colNames = FALSE)
wb$add_data(sheet = "8-public finances",  x = t(colnames(full)[-1]),  dims = "B1", colNames = FALSE)
try_save_ex_en()
