# source("\\\\192.168.38.7\\public$\\Avtomatizacija\\umar-automation-scripts\\R\\tabele\\eo_00_setup.R")

codes <- c("SURS--1701111S--orig--B+C+D[skd]--M",
          "SURS--1701111S--orig--B[skd]--M",
          "SURS--1701111S--orig--C[skd]--M",
          "SURS--1701111S--orig--D[skd]--M",
          "SURS--1957408S--O--CC--M",
          "SURS--1957408S--O--11--M",
          "SURS--1957408S--O--2--M",
          "SURS--2080006S--1--H+I+J+L+M+N--M",
          "SURS--2080006S--1--H--M",
          "SURS--2080006S--1--J--M",
          "SURS--2080006S--1--M--M",
          "SURS--2080006S--1--N--M",
          "SURS--2001303S--2--1--G--M",
          "SURS--2001303S--2--1--47--M",
          "SURS--2001303S--2--1--45--M",
          "SURS--2001303S--2--1--46--M",
          "SURS--2164433S--0--9--M",
          "SURS--2164433S--0--10--M",
          "SURS--2164433S--0--11--M",
          "SURS--2013903S--1--55+56--M")

codes2 <- c("SURS--1505001S--001--M")

codes3 <- c("SURS--2855901S--1--2--M",
          "SURS--2855901S--2--2--M",
          "SURS--2855901S--6--2--M",
          "SURS--2855901S--5--2--M",
          "SURS--2855901S--3--2--M",
          "SURS--2855901S--4--2--M")

raw <- process_codes_vectorized(codes, con)
out <- process_indicators(raw, yoy = TRUE, n_years = 3, n_quarters = 9, n_months = 26)

raw2 <- process_codes_vectorized(codes2, con)
out2 <- process_indicators(raw2, n_years = 3, n_quarters = 9, n_months = 26)|>
  dplyr::mutate(dplyr::across(-indicator, ~ .x / 1e3))

raw3 <- process_codes_vectorized(codes3, con)
out3 <- process_indicators(raw3, agg_fun = "mean", n_years = 3, n_quarters = 9, n_months = 26)

out2 <- out3[0,] |>
  bind_rows(out2) |>
  select(any_of(names(out3)))

out <- out3[0,] |>
  bind_rows(out) |>
  select(any_of(names(out3)))

wb <- load_wb_id()
wb$clean_sheet(sheet = "2-proizvodnja", dims = "B1:BB35", styles = FALSE)
wb$add_data(sheet = "2-proizvodnja",  x = t(colnames(out)[-1]),  dims = "B1", colNames = FALSE, na.strings = "")
wb$add_data(sheet = "2-proizvodnja",  x = out[1:4,-1],  dims = "B3", colNames = FALSE, na.strings = "")
wb$add_data(sheet = "2-proizvodnja",  x = out[5:7,-1],  dims = "B8", colNames = FALSE, na.strings = "")
wb$add_data(sheet = "2-proizvodnja",  x = out[8:12,-1],  dims = "B12", colNames = FALSE, na.strings = "")
wb$add_data(sheet = "2-proizvodnja",  x = out[13:16,-1],  dims = "B18", colNames = FALSE, na.strings = "")
wb$add_data(sheet = "2-proizvodnja",  x = out[17:20,-1],  dims = "B23", colNames = FALSE, na.strings = "")
wb$add_data(sheet = "2-proizvodnja",  x = out2[1,-1],  dims = "B28", colNames = FALSE, na.strings = "")
wb$add_data(sheet = "2-proizvodnja",  x = out3[1,-1],  dims = "B30", colNames = FALSE, na.strings = "")
wb$add_data(sheet = "2-proizvodnja",  x = out3[2:6,-1],  dims = "B32", colNames = FALSE, na.strings = "")
try_save_id()

wb <- load_wb_id_en()
wb$clean_sheet(sheet = "2-production", dims = "B1:BB35", styles = FALSE)
wb$add_data(sheet = "2-production",  x = t(colnames(out)[-1]),  dims = "B1", colNames = FALSE, na.strings = "")
wb$add_data(sheet = "2-production",  x = out[1:4,-1],  dims = "B3", colNames = FALSE, na.strings = "")
wb$add_data(sheet = "2-production",  x = out[5:7,-1],  dims = "B8", colNames = FALSE, na.strings = "")
wb$add_data(sheet = "2-production",  x = out[8:12,-1],  dims = "B12", colNames = FALSE, na.strings = "")
wb$add_data(sheet = "2-production",  x = out[13:16,-1],  dims = "B18", colNames = FALSE, na.strings = "")
wb$add_data(sheet = "2-production",  x = out[17:20,-1],  dims = "B23", colNames = FALSE, na.strings = "")
wb$add_data(sheet = "2-production",  x = out2[1,-1],  dims = "B28", colNames = FALSE, na.strings = "")
wb$add_data(sheet = "2-production",  x = out3[1,-1],  dims = "B30", colNames = FALSE, na.strings = "")
wb$add_data(sheet = "2-production",  x = out3[2:6,-1],  dims = "B32", colNames = FALSE, na.strings = "")
try_save_id_en()

raw <- process_codes_vectorized(codes, con)
out <- process_indicators(raw, yoy = TRUE, full = TRUE)

raw2 <- process_codes_vectorized(codes2, con)
out2 <- process_indicators(raw2, full = TRUE)|>
  dplyr::mutate(dplyr::across(-indicator, ~ .x / 1e3))

raw3 <- process_codes_vectorized(codes3, con)
out3 <- process_indicators(raw3, agg_fun = "mean", full = TRUE)


out2 <- out3[0,] |>
  bind_rows(out2) |>
  select(any_of(names(out3)))

out <- out3[0,] |>
  bind_rows(out) |>
  select(any_of(names(out3)))

wb <- load_wb_ex()
wb$clean_sheet(sheet = "2-proizvodnja", dims = "B1:BB35", styles = FALSE)
wb$add_data(sheet = "2-proizvodnja",  x = t(colnames(out)[-1]),  dims = "B1", colNames = FALSE)
wb$add_data(sheet = "2-proizvodnja",  x = out[1:4,-1],  dims = "B3", colNames = FALSE,
            na.strings = "")
wb$add_data(sheet = "2-proizvodnja",  x = out[5:7,-1],  dims = "B8", colNames = FALSE, na.strings = "")
wb$add_data(sheet = "2-proizvodnja",  x = out[8:12,-1],  dims = "B12", colNames = FALSE, na.strings = "")
wb$add_data(sheet = "2-proizvodnja",  x = out[13:16,-1],  dims = "B18", colNames = FALSE, na.strings = "")
wb$add_data(sheet = "2-proizvodnja",  x = out[17:20,-1],  dims = "B23", colNames = FALSE, na.strings = "")
wb$add_data(sheet = "2-proizvodnja",  x = out2[1,-1],  dims = "B28", colNames = FALSE, na.strings = "")
wb$add_data(sheet = "2-proizvodnja",  x = out3[1,-1],  dims = "B30", colNames = FALSE, na.strings = "")
wb$add_data(sheet = "2-proizvodnja",  x = out3[2:6,-1],  dims = "B32", colNames = FALSE, na.strings = "")

try_save_ex()


wb <- load_wb_ex_en()
wb$clean_sheet(sheet = "2-production", dims = "B1:BB35", styles = FALSE)
wb$add_data(sheet = "2-production",  x = t(colnames(out)[-1]),  dims = "B1", colNames = FALSE)
wb$add_data(sheet = "2-production",  x = out[1:4,-1],  dims = "B3", colNames = FALSE,
            na.strings = "")
wb$add_data(sheet = "2-production",  x = out[5:7,-1],  dims = "B8", colNames = FALSE, na.strings = "")
wb$add_data(sheet = "2-production",  x = out[8:12,-1],  dims = "B12", colNames = FALSE, na.strings = "")
wb$add_data(sheet = "2-production",  x = out[13:16,-1],  dims = "B18", colNames = FALSE, na.strings = "")
wb$add_data(sheet = "2-production",  x = out[17:20,-1],  dims = "B23", colNames = FALSE, na.strings = "")
wb$add_data(sheet = "2-production",  x = out2[1,-1],  dims = "B28", colNames = FALSE, na.strings = "")
wb$add_data(sheet = "2-production",  x = out3[1,-1],  dims = "B30", colNames = FALSE, na.strings = "")
wb$add_data(sheet = "2-production",  x = out3[2:6,-1],  dims = "B32", colNames = FALSE, na.strings = "")

try_save_ex_en()
