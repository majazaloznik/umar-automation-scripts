# source("\\\\192.168.38.7\\public$\\Avtomatizacija\\umar-automation-scripts\\R\\tabele\\eo_00_setup.R")

codes <- c(
  "SURS--0700928S--TOT--1--M", # delovno aktivni B = C + D
  "SURS--0700928S--A--1--M",
  "SURS--0700928S--B--1--M", # B+C+D+E+F
  "SURS--0700928S--C--1--M", # keep
  "SURS--0700928S--D--1--M",
  "SURS--0700928S--E--1--M",
  "SURS--0700928S--F--1--M", # keep
  "SURS--0700928S--G--1--M", # GHIJKLMN PQR STU
  "SURS--0700928S--H--1--M",
  "SURS--0700928S--I--1--M",
  "SURS--0700928S--J--1--M",
  "SURS--0700928S--K--1--M",
  "SURS--0700928S--L--1--M",
  "SURS--0700928S--M--1--M",
  "SURS--0700928S--N--1--M",
  "SURS--0700928S--O--1--M",
  "SURS--0700928S--P--1--M", # keep
  "SURS--0700928S--Q--1--M", # QR
  "SURS--0700928S--R--1--M",
  "SURS--0700928S--S--1--M",
  "SURS--0700928S--T--1--M",
  "SURS--0700928S--U--1--M",
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
         da_bcdef =  `SURS--0700928S--B--1--M` +
           `SURS--0700928S--C--1--M`+
           `SURS--0700928S--D--1--M`+
           `SURS--0700928S--E--1--M`+
           `SURS--0700928S--F--1--M`,
         da_storitve =
           `SURS--0700928S--G--1--M` +
           `SURS--0700928S--H--1--M` +
           `SURS--0700928S--I--1--M` +
           `SURS--0700928S--J--1--M` +
           `SURS--0700928S--K--1--M` +
           `SURS--0700928S--L--1--M` +
           `SURS--0700928S--M--1--M` +
           `SURS--0700928S--N--1--M` +
           `SURS--0700928S--O--1--M` +
           `SURS--0700928S--P--1--M` +
           `SURS--0700928S--Q--1--M` +
           `SURS--0700928S--R--1--M` +
           `SURS--0700928S--S--1--M` +
           `SURS--0700928S--T--1--M` +
           `SURS--0700928S--U--1--M`,
         da_izc = `SURS--0700928S--Q--1--M` +
           `SURS--0700928S--R--1--M`,
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
            `SURS--0700928S--G--1--M`,
            `SURS--0700928S--H--1--M`,
            `SURS--0700928S--I--1--M`,
            `SURS--0700928S--J--1--M`,
            `SURS--0700928S--K--1--M`,
            `SURS--0700928S--L--1--M`,
            `SURS--0700928S--M--1--M`,
            `SURS--0700928S--N--1--M`,
            `SURS--0700928S--O--1--M`,
            `SURS--0700928S--B--1--M`,
            `SURS--0700928S--D--1--M`,
            `SURS--0700928S--E--1--M`,
            `SURS--0700928S--Q--1--M`,
            `SURS--0700928S--R--1--M`,
            `SURS--0700928S--S--1--M`,
            `SURS--0700928S--T--1--M`,
            `SURS--0700928S--U--1--M`,
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
  relocate(da_bcdef, .after = `SURS--0700928S--A--1--M`) |>
  relocate(da_storitve, .after = `SURS--0700928S--F--1--M`) |>
  relocate(da_izc, .after = `SURS--0700928S--P--1--M`) |>
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

new_data <- process_indicators(xx, n_years = 3, n_quarters = 9, n_months = 25, agg_fun = "mean")


wb <- load_wb_id()  |> fix_wb_encoding()

existing <- openxlsx2::wb_to_df(wb, sheet = "3-trg dela")[1:nrow(new_data), ]
existing <- existing[, !vapply(existing, \(x) all(is.na(x)), logical(1))] # remove NA columns

common <- intersect(names(new_data), names(existing))
new_only <- setdiff(names(new_data), names(existing))

# overwrite only non-NA values from new_data
merged <- cbind(
  as.data.frame(Map(
    \(new, old) { out <- old; out[!is.na(new)] <- new[!is.na(new)]; out },
    new_data[common],
    existing[common]
  ), check.names = FALSE),
  new_data[new_only]
)[names(new_data)]  # restore original column order




wb$clean_sheet(sheet = 3, dims = "B2:AL31", styles = FALSE)
wb$add_data(sheet = 3,  x = t(colnames(merged)[-1]),  dims = "B1", colNames = FALSE, na.strings = "")
wb$add_data(sheet = 3,  x = merged[1:30,-1],  dims = "B2", colNames = FALSE, na.strings = "")
try_save_id()


wb <- load_wb_id_en()  |> fix_wb_encoding()
wb$clean_sheet(sheet = 3, dims = "B2:AL31", styles = FALSE)
wb$add_data(sheet = 3,  x = t(colnames(merged)[-1]),  dims = "B1", colNames = FALSE, na.strings = "")
wb$add_data(sheet = 3,  x = merged[1:30,-1],  dims = "B2", colNames = FALSE, na.strings = "")
try_save_id_en()

new_data <- process_indicators(xx, full = TRUE, agg_fun = "mean")



wb <- load_wb_ex()  |> fix_wb_encoding()

existing <- openxlsx2::wb_to_df(wb, sheet = "3-trg dela")[1:nrow(new_data), ]
existing <- existing[, !vapply(existing, \(x) all(is.na(x)), logical(1))] # remove NA columns

common <- intersect(names(new_data), names(existing))
new_only <- setdiff(names(new_data), names(existing))

# overwrite only non-NA values from new_data
merged <- cbind(
  as.data.frame(Map(
    \(new, old) { out <- old; out[!is.na(new)] <- new[!is.na(new)]; out },
    new_data[common],
    existing[common]
  ), check.names = FALSE),
  new_data[new_only]
)[names(new_data)]  # restore original column order


wb$clean_sheet(sheet = 3, dims = "B2:DD31", styles = FALSE)
wb$add_data(sheet = 3,  x = t(colnames(merged)[-1]),  dims = "B1", colNames = FALSE, na.strings = "")
wb$add_data(sheet = 3,  x = merged[1:30,-1],  dims = "B2", colNames = FALSE, na.strings = "")
try_save_ex()

wb <- load_wb_ex_en()  |> fix_wb_encoding()
wb$clean_sheet(sheet = 3, dims = "B2:BE31", styles = FALSE)
wb$add_data(sheet = 3,  x = t(colnames(merged)[-1]),  dims = "B1", colNames = FALSE, na.strings = "")
wb$add_data(sheet = 3,  x = merged[1:30,-1],  dims = "B2", colNames = FALSE, na.strings = "")
try_save_ex_en()


