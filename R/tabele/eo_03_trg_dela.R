# source("\\\\192.168.38.7\\public$\\Avtomatizacija\\umar-automation-scripts\\R\\tabele\\eo_00_setup.R")

codes <- c(
  "SURS--0700921S--SKD--1--M", # delovno aktivni B = C + D
  "SURS--0700921S--A--1--M",
  "SURS--0700921S--B--1--M", # B+C+D+E+F
  "SURS--0700921S--C--1--M", # keep
  "SURS--0700921S--D--1--M",
  "SURS--0700921S--E--1--M",
  "SURS--0700921S--F--1--M", # keep
  "SURS--0700921S--G--1--M", # GHIJKLMN RST OPQ
  "SURS--0700921S--H--1--M",
  "SURS--0700921S--I--1--M",
  "SURS--0700921S--J--1--M",
  "SURS--0700921S--K--1--M",
  "SURS--0700921S--L--1--M",
  "SURS--0700921S--M--1--M",
  "SURS--0700921S--N--1--M",
  "SURS--0700921S--O--1--M", # keep
  "SURS--0700921S--P--1--M", # keep
  "SURS--0700921S--Q--1--M",
  "SURS--0700921S--R--1--M",
  "SURS--0700921S--S--1--M",
  "SURS--0700921S--T--1--M",
  "SURS--0700915S--0--11--2--M", # zaposleni C
  "SURS--0700915S--0--111--2--M",
  "SURS--0700915S--0--112--2--M",
  "SURS--0700915S--0--12--2--M", # samozaposleni D
  "UMAR-ZRSZ--DR011--8--S--S--M", # reg brezposelni E
  "UMAR-ZRSZ--DR011--8--F--S--M",
  "ZRSZ--BO_SLO_starost--S1--M", # mladi vsota s1 in s2
  "ZRSZ--BO_SLO_starost--S2--M",
  "UMAR-ZRSZ--DR011--850P--S--S--M",
  "ZRSZ--BO_SLO_izob--I1--M",
  "UMAR-ZRSZ--DR011--DBP--S--S--M", # dolgotrajno brezposelni
  "ZRSZ--DN--0--M",
  "DESEZ--RB--ST--N--M", # stopnja brezposelnosti
  "SURS--0700915S--1--1--2--M",  # da moski
  "SURS--0700915S--2--1--2--M", # da zenske
  "UMAR-ZRSZ--DR011--2--S--S--M", #  tok = 2 - (od + de + dd + os)
  "UMAR-ZRSZ--DR011--OD--S--S--M",
  "UMAR-ZRSZ--DR011--DE--S--S--M",
  "UMAR-ZRSZ--DR011--OS--S--S--M",
  "UMAR-ZRSZ--DR011--IPZ--S--S--M", # prva zaposlitev
  "UMAR-ZRSZ--DR010--2--S--S--M",
  "UMAR-ZRSZ--DR011--DD--S--S--M",   # neto odlivi = od + de
  "ZRSZ--TOK--oDE--M",
  "ZRSZ--DD--0--M") # delovna dovoljenja


raw <- process_codes_vectorized(codes, con) |>
  mutate(da = `SURS--0700915S--0--11--2--M` + `SURS--0700915S--0--12--2--M`,
         fa = da + `UMAR-ZRSZ--DR011--8--S--S--M`,
         da_bcdef =  `SURS--0700921S--B--1--M` +
           `SURS--0700921S--C--1--M`+
           `SURS--0700921S--D--1--M`+
           `SURS--0700921S--E--1--M`+
           `SURS--0700921S--F--1--M`,
         da_storitve =
         `SURS--0700921S--G--1--M` +
         `SURS--0700921S--H--1--M` +
         `SURS--0700921S--I--1--M` +
         `SURS--0700921S--J--1--M` +
         `SURS--0700921S--K--1--M` +
         `SURS--0700921S--L--1--M` +
         `SURS--0700921S--M--1--M` +
         `SURS--0700921S--N--1--M` +
         `SURS--0700921S--O--1--M` +
         `SURS--0700921S--P--1--M` +
         `SURS--0700921S--Q--1--M` +
         `SURS--0700921S--R--1--M` +
         `SURS--0700921S--S--1--M` +
         `SURS--0700921S--T--1--M`,
         da_izc = `SURS--0700921S--P--1--M` +
           `SURS--0700921S--Q--1--M`,
         bo_m = `ZRSZ--BO_SLO_starost--S1--M` +
         `ZRSZ--BO_SLO_starost--S2--M`,
         st_mo = 100 * (`UMAR-ZRSZ--DR011--8--S--S--M` - `UMAR-ZRSZ--DR011--8--F--S--M`) /
           (`SURS--0700915S--1--1--2--M` + (`UMAR-ZRSZ--DR011--8--S--S--M` - `UMAR-ZRSZ--DR011--8--F--S--M`)),
         st_ze = 100 * `UMAR-ZRSZ--DR011--8--F--S--M` /
           (`SURS--0700915S--2--1--2--M` + `UMAR-ZRSZ--DR011--8--F--S--M`),
         tok = `UMAR-ZRSZ--DR011--2--S--S--M` - `UMAR-ZRSZ--DR011--OD--S--S--M` -
           `UMAR-ZRSZ--DR011--DE--S--S--M` - `UMAR-ZRSZ--DR011--DD--S--S--M` -
           `UMAR-ZRSZ--DR011--OS--S--S--M`,
         dr_odl = `UMAR-ZRSZ--DR011--OD--S--S--M` + `UMAR-ZRSZ--DR011--DE--S--S--M`,
         dd_del = 100 * `ZRSZ--DD--0--M` / fa) |>
  select(-c(da,
            `SURS--0700921S--G--1--M`,
           `SURS--0700921S--H--1--M`,
           `SURS--0700921S--I--1--M`,
           `SURS--0700921S--J--1--M`,
           `SURS--0700921S--K--1--M`,
           `SURS--0700921S--L--1--M`,
           `SURS--0700921S--M--1--M`,
           `SURS--0700921S--N--1--M`,
           `SURS--0700921S--B--1--M`,
           `SURS--0700921S--D--1--M`,
           `SURS--0700921S--E--1--M`,
           `SURS--0700921S--P--1--M`,
           `SURS--0700921S--Q--1--M`,
           `SURS--0700921S--R--1--M`,
           `SURS--0700921S--S--1--M`,
           `SURS--0700921S--T--1--M`,
           `ZRSZ--BO_SLO_starost--S1--M`,
           `ZRSZ--BO_SLO_starost--S2--M`,
           `SURS--0700915S--1--1--2--M`,
           `SURS--0700915S--2--1--2--M`,
           `ZRSZ--TOK--oDE--M`,
           `UMAR-ZRSZ--DR011--2--S--S--M`,
           `UMAR-ZRSZ--DR011--OD--S--S--M`,
           `UMAR-ZRSZ--DR011--DE--S--S--M`,
           `UMAR-ZRSZ--DR011--OS--S--S--M`)) |>
  arrange(period_id) |>
  relocate(period_id, fa) |>
  relocate(da_bcdef, .after = `SURS--0700921S--A--1--M`) |>
  relocate(da_storitve, .after = `SURS--0700921S--F--1--M`) |>
  relocate(da_izc, .after = `SURS--0700921S--O--1--M`) |>
  relocate(bo_m, .after = `UMAR-ZRSZ--DR011--8--F--S--M`) |>
  relocate(st_mo, st_ze, tok, `UMAR-ZRSZ--DR011--IPZ--S--S--M`,
           `UMAR-ZRSZ--DR010--2--S--S--M`, `UMAR-ZRSZ--DR011--DD--S--S--M`,
            dr_odl, .after = `DESEZ--RB--ST--N--M`)


divK <- function(data, value_cols) {
  data |>
    dplyr::mutate(dplyr::across(
      dplyr::all_of(value_cols),
      \(x) x / 1000
    ))
}

xx <- raw |>
  divK(colnames(raw)[-c(1, 22, 23, 24, 31)])

out <- process_indicators(xx, n_years = 3, n_quarters = 9, n_months = 25, agg_fun = "mean")

wb <- load_wb_id()  |> fix_wb_encoding()
wb$clean_sheet(sheet = 3, dims = "B2:AM31", styles = FALSE)
wb$add_data(sheet = 3,  x = t(colnames(out)[-1]),  dims = "B1", colNames = FALSE, na.strings = "")
wb$add_data(sheet = 3,  x = out[1:30,-1],  dims = "B2", colNames = FALSE, na.strings = "")
try_save_id()


wb <- load_wb_id_en()  |> fix_wb_encoding()
wb$clean_sheet(sheet = 3, dims = "B2:AM31", styles = FALSE)
wb$add_data(sheet = 3,  x = t(colnames(out)[-1]),  dims = "B1", colNames = FALSE, na.strings = "")
wb$add_data(sheet = 3,  x = out[1:30,-1],  dims = "B2", colNames = FALSE, na.strings = "")
try_save_id_en()

out <- process_indicators(xx, full = TRUE)

wb <- load_wb_ex()  |> fix_wb_encoding()
wb$clean_sheet(sheet = 3, dims = "B2:BE31", styles = FALSE)
wb$add_data(sheet = 3,  x = t(colnames(out)[-1]),  dims = "B1", colNames = FALSE, na.strings = "")
wb$add_data(sheet = 3,  x = out[1:30,-1],  dims = "B2", colNames = FALSE, na.strings = "")
try_save_ex()

wb <- load_wb_ex_en()  |> fix_wb_encoding()
wb$clean_sheet(sheet = 3, dims = "B2:BE31", styles = FALSE)
wb$add_data(sheet = 3,  x = t(colnames(out)[-1]),  dims = "B1", colNames = FALSE, na.strings = "")
wb$add_data(sheet = 3,  x = out[1:30,-1],  dims = "B2", colNames = FALSE, na.strings = "")
try_save_ex_en()


