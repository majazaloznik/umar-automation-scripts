# source("\\\\192.168.38.7\\public$\\Avtomatizacija\\umar-automation-scripts\\R\\tabele\\eo_00_setup.R")
codes <- c(
  "UMAR-SURS--DR012--A--M",
  "UMAR-SURS--DR012--B--M",
  "UMAR-SURS--DR012--C--M",
  "UMAR-SURS--DR012--D--M",
  "UMAR-SURS--DR012--E--M",
  "UMAR-SURS--DR012--F--M",
  "UMAR-SURS--DR012--G--M",
  "UMAR-SURS--DR012--H--M",
  "UMAR-SURS--DR012--I--M",
  "UMAR-SURS--DR012--J--M",
  "UMAR-SURS--DR012--K--M",
  "UMAR-SURS--DR012--L--M",
  "UMAR-SURS--DR012--M--M",
  "UMAR-SURS--DR012--N--M",
  "UMAR-SURS--DR012--O--M",
  "UMAR-SURS--DR012--P--M",
  "UMAR-SURS--DR012--Q--M",
  "UMAR-SURS--DR012--R--M",
  "UMAR-SURS--DR012--S--M",
  "UMAR-SURS--DR012--T--M",
  "UMAR-SURS--DR013--A--M",
  "UMAR-SURS--DR013--B--M",
  "UMAR-SURS--DR013--C--M",
  "UMAR-SURS--DR013--D--M",
  "UMAR-SURS--DR013--E--M",
  "UMAR-SURS--DR013--F--M",
  "UMAR-SURS--DR013--G--M",
  "UMAR-SURS--DR013--H--M",
  "UMAR-SURS--DR013--I--M",
  "UMAR-SURS--DR013--J--M",
  "UMAR-SURS--DR013--K--M",
  "UMAR-SURS--DR013--L--M",
  "UMAR-SURS--DR013--M--M",
  "UMAR-SURS--DR013--N--M",
  "UMAR-SURS--DR013--O--M",
  "UMAR-SURS--DR013--P--M",
  "UMAR-SURS--DR013--Q--M",
  "UMAR-SURS--DR013--R--M",
  "UMAR-SURS--DR013--S--M",
  "UMAR-SURS--DR013--T--M")

codes2 <- c(
  "SURS--0701029S--TOT--1--1--M",
  "SURS--0701029S--A--1--1--M",
  "SURS--0701029S--B--1--1--M",
  "SURS--0701029S--C--1--1--M",
  "SURS--0701029S--D--1--1--M",
  "SURS--0701029S--E--1--1--M",
  "SURS--0701029S--F--1--1--M",
  "SURS--0701029S--G--1--1--M",
  "SURS--0701029S--H--1--1--M",
  "SURS--0701029S--I--1--1--M",
  "SURS--0701029S--J--1--1--M",
  "SURS--0701029S--K--1--1--M",
  "SURS--0701029S--L--1--1--M",
  "SURS--0701029S--M--1--1--M",
  "SURS--0701029S--N--1--1--M",
  "SURS--0701029S--O--1--1--M",
  "SURS--0701029S--P--1--1--M",
  "SURS--0701029S--Q--1--1--M",
  "SURS--0701029S--R--1--1--M",
  "SURS--0701029S--S--1--1--M",
  "SURS--0701029S--T--1--1--M")

raw <- process_codes_vectorized(codes, con) |>
  rowwise() |>
  mutate(`AOST` = sum(c(`UMAR-SURS--DR012--A--M`,
                        `UMAR-SURS--DR012--B--M`,
                        `UMAR-SURS--DR012--C--M`,
                        `UMAR-SURS--DR012--D--M`,
                        `UMAR-SURS--DR012--E--M`,
                        `UMAR-SURS--DR012--F--M`,
                        `UMAR-SURS--DR012--G--M`,
                        `UMAR-SURS--DR012--H--M`,
                        `UMAR-SURS--DR012--I--M`,
                        `UMAR-SURS--DR012--J--M`,
                        `UMAR-SURS--DR012--K--M`,
                        `UMAR-SURS--DR012--L--M`,
                        `UMAR-SURS--DR012--M--M`,
                        `UMAR-SURS--DR012--N--M`,
                        `UMAR-SURS--DR012--O--M`,
                        `UMAR-SURS--DR012--S--M`,
                        `UMAR-SURS--DR012--T--M`))/
           sum(c(`UMAR-SURS--DR013--A--M`,
                 `UMAR-SURS--DR013--B--M`,
                 `UMAR-SURS--DR013--C--M`,
                 `UMAR-SURS--DR013--D--M`,
                 `UMAR-SURS--DR013--E--M`,
                 `UMAR-SURS--DR013--F--M`,
                 `UMAR-SURS--DR013--G--M`,
                 `UMAR-SURS--DR013--H--M`,
                 `UMAR-SURS--DR013--I--M`,
                 `UMAR-SURS--DR013--J--M`,
                 `UMAR-SURS--DR013--K--M`,
                 `UMAR-SURS--DR013--L--M`,
                 `UMAR-SURS--DR013--M--M`,
                 `UMAR-SURS--DR013--N--M`,
                 `UMAR-SURS--DR013--O--M`,
                 `UMAR-SURS--DR013--S--M`,
                 `UMAR-SURS--DR013--T--M`)) ,
         `PQR` = sum(c(`UMAR-SURS--DR012--P--M`,
                       `UMAR-SURS--DR012--Q--M`,
                       `UMAR-SURS--DR012--R--M`)) /
           sum(c(`UMAR-SURS--DR013--P--M`,
                 `UMAR-SURS--DR013--Q--M`,
                 `UMAR-SURS--DR013--R--M`)),
         `BE` =  sum(c(`UMAR-SURS--DR012--B--M`,
                       `UMAR-SURS--DR012--C--M`,
                       `UMAR-SURS--DR012--D--M`,
                       `UMAR-SURS--DR012--E--M`)) /
           sum(c(`UMAR-SURS--DR013--B--M`,
                 `UMAR-SURS--DR013--C--M`,
                 `UMAR-SURS--DR013--D--M`,
                 `UMAR-SURS--DR013--E--M`)),
         `GHI` = sum(c(`UMAR-SURS--DR012--G--M`,
                       `UMAR-SURS--DR012--H--M`,
                       `UMAR-SURS--DR012--I--M`)) /
           sum(c(`UMAR-SURS--DR013--G--M`,
                 `UMAR-SURS--DR013--H--M`,
                 `UMAR-SURS--DR013--I--M`)),
         `JOST` = sum(c(`UMAR-SURS--DR012--J--M`,
                        `UMAR-SURS--DR012--K--M`,
                        `UMAR-SURS--DR012--L--M`,
                        `UMAR-SURS--DR012--M--M`,
                        `UMAR-SURS--DR012--N--M`,
                        `UMAR-SURS--DR012--O--M`,
                        `UMAR-SURS--DR012--S--M`,
                        `UMAR-SURS--DR012--T--M`)) /
           sum(c(`UMAR-SURS--DR013--J--M`,
                 `UMAR-SURS--DR013--K--M`,
                 `UMAR-SURS--DR013--L--M`,
                 `UMAR-SURS--DR013--M--M`,
                 `UMAR-SURS--DR013--N--M`,
                 `UMAR-SURS--DR013--O--M`,
                 `UMAR-SURS--DR013--S--M`,
                 `UMAR-SURS--DR013--T--M`))) |>
  select(period_id, AOST, PQR, BE, GHI, JOST) |>
  dplyr::filter(!dplyr::if_all(-period_id, is.na))

raw2 <- process_codes_vectorized(codes2, con)

raw <- full_join(raw, raw2, by = "period_id") |>
  relocate(`SURS--0701029S--TOT--1--1--M`)

out <- process_indicators(raw, n_years = 1, n_quarters = 1, n_months = 1, agg_fun = "mean")|>
  mutate(indicator = 1:26)

n_months <- 23
out2 <- process_indicators(raw, n_years = 2, n_quarters = 9, n_months = n_months, yoy = TRUE)|>
  mutate(indicator = 1:26)



out2ly <- out2 |> tidyr::pivot_longer(-indicator) |>
  dplyr::filter(grepl("^\\d{4}$", name),
                !is.na(value))
max_year <- as.numeric(max(out2ly$name)  )


years <- bind_rows(out2ly) |>
  mutate(name = as.numeric(name)) |>
  arrange(name) |>
  #filter(name > max_year - 3) |>
  tidyr::pivot_wider(names_from = name, values_from = value)


out2qy <- out2 |> tidyr::pivot_longer(-indicator) |>
  dplyr::filter(grepl("^\\d{2} Q\\d{1}$", name),
                !is.na(value))
max_quarter <- max(out2qy$name)


quarters <- bind_rows(out2qy) |>
  arrange(name) |>
  dplyr::slice_tail(n = 234) |> # most recent 9 quarters (*26 categories)
  tidyr::pivot_wider(names_from = name, values_from = value)

months <- out2 |> tidyr::pivot_longer(-indicator) |>
  dplyr::filter(grepl("^\\d{2}-\\d{2}$", name)) |>
  arrange(name) |>
  dplyr::slice_tail(n = n_months *26 ) |># most recent  months (*26 categories)
  tidyr::pivot_wider(names_from = name, values_from = value)


wb <- load_wb_id() |> fix_wb_encoding()
wb$clean_sheet(sheet = "4-place", dims = "B2:BC27", styles = FALSE)
wb$add_data(sheet = "4-place",  x = t(colnames(out)[-1]),  dims = "B1", colNames = FALSE, na.strings = "")
wb$add_data(sheet = "4-place",  x = out[1:26,-1],  dims = "B2", colNames = FALSE, na.strings = "")
wb$add_data(sheet = "4-place",  x = t(colnames(years)[-1]),  dims = "E1", colNames = FALSE, na.strings = "")
wb$add_data(sheet = "4-place",  x = years[-1],  dims = "E2", colNames = FALSE, na.strings = "")
wb$add_data(sheet = "4-place",  x = t(colnames(quarters)[-1]),  dims = "G1", colNames = FALSE, na.strings = "")
wb$add_data(sheet = "4-place",  x = quarters[-1],  dims = "G2", colNames = FALSE, na.strings = "")
wb$add_data(sheet = "4-place",  x = t(colnames(months)[-1]),  dims = "O1", colNames = FALSE, na.strings = "")
wb$add_data(sheet = "4-place",  x = months[-1],  dims = "O2", colNames = FALSE, na.strings = "")
try_save_id()

wb <- load_wb_id_en() |> fix_wb_encoding()
wb$clean_sheet(sheet = "4-wages", dims = "B2:BC27", styles = FALSE)
wb$add_data(sheet = "4-wages",  x = t(colnames(out)[-1]),  dims = "B1", colNames = FALSE, na.strings = "")
wb$add_data(sheet = "4-wages",  x = out[1:26,-1],  dims = "B2", colNames = FALSE, na.strings = "")
wb$add_data(sheet = "4-wages",  x = t(colnames(years)[-1]),  dims = "E1", colNames = FALSE, na.strings = "")
wb$add_data(sheet = "4-wages",  x = years[-1],  dims = "E2", colNames = FALSE, na.strings = "")
wb$add_data(sheet = "4-wages",  x = t(colnames(quarters)[-1]),  dims = "G1", colNames = FALSE, na.strings = "")
wb$add_data(sheet = "4-wages",  x = quarters[-1],  dims = "G2", colNames = FALSE, na.strings = "")
wb$add_data(sheet = "4-wages",  x = t(colnames(months)[-1]),  dims = "O1", colNames = FALSE, na.strings = "")
wb$add_data(sheet = "4-wages",  x = months[-1],  dims = "O2", colNames = FALSE, na.strings = "")
try_save_id_en()
###


out2 <- process_indicators(raw, n_years = 2, n_months = nrow(raw) - 12, yoy = TRUE)|>
  mutate(indicator = 1:26)

out2ly <- out2 |> tidyr::pivot_longer(-indicator) |>
  dplyr::filter(grepl("^\\d{4}$", name),
                !is.na(value))

years <- bind_rows(out2ly) |>
  mutate(name = as.numeric(name)) |>
  arrange(name) |>
  tidyr::pivot_wider(names_from = name, values_from = value)


out2qy <- out2 |> tidyr::pivot_longer(-indicator) |>
  dplyr::filter(grepl("^\\d{2} Q\\d{1}$", name),
                !is.na(value))

quarters <- bind_rows(out2qy) |>
  arrange(name) |>
  tidyr::pivot_wider(names_from = name, values_from = value)

out2ml <- out2 |> tidyr::pivot_longer(-indicator) |>
  dplyr::filter(grepl("^\\d{2}-\\d{2}$", name))

months <- bind_rows(out2ml) |>
  arrange(name) |>
  tidyr::pivot_wider(names_from = name, values_from = value)


final <- bind_cols(years, quarters[-1], months[-1])

wb <- load_wb_ex()  |> fix_wb_encoding()
wb$clean_sheet(sheet = "4-place", dims = "B2:CX27", styles = FALSE)
wb$add_data(sheet = "4-place",  x = t(colnames(out)[-1]),  dims = "B1", colNames = FALSE, na.strings = "")
wb$add_data(sheet = "4-place",  x = out[1:26,-1],  dims = "B2", colNames = FALSE, na.strings = "")
wb$add_data(sheet = "4-place",  x = t(colnames(final)[-1]),  dims = "E1", colNames = FALSE, na.strings = "")
wb$add_data(sheet = "4-place",  x = final[-1],  dims = "E2", colNames = FALSE, na.strings = "")

try_save_ex()


wb <- load_wb_ex_en()  |> fix_wb_encoding()
wb$clean_sheet(sheet = "4-wages", dims = "B2:BC27", styles = FALSE)
wb$add_data(sheet = "4-wages",  x = t(colnames(out)[-1]),  dims = "B1", colNames = FALSE, na.strings = "")
wb$add_data(sheet = "4-wages",  x = out[1:26,-1],  dims = "B2", colNames = FALSE, na.strings = "")
wb$add_data(sheet = "4-wages",  x = t(colnames(final)[-1]),  dims = "E1", colNames = FALSE, na.strings = "")
wb$add_data(sheet = "4-wages",  x = final[-1],  dims = "E2", colNames = FALSE, na.strings = "")

try_save_ex_en()

