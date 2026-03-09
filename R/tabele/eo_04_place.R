# source("\\\\192.168.38.7\\public$\\Avtomatizacija\\umar-automation-scripts\\R\\tabele\\eo_00_setup.R")
codes <- c(
  "UMAR-SURS--DR005--A--M",
  "UMAR-SURS--DR005--B--M",
  "UMAR-SURS--DR005--C--M",
  "UMAR-SURS--DR005--D--M",
  "UMAR-SURS--DR005--E--M",
  "UMAR-SURS--DR005--F--M",
  "UMAR-SURS--DR005--G--M",
  "UMAR-SURS--DR005--H--M",
  "UMAR-SURS--DR005--I--M",
  "UMAR-SURS--DR005--J--M",
  "UMAR-SURS--DR005--K--M",
  "UMAR-SURS--DR005--L--M",
  "UMAR-SURS--DR005--M--M",
  "UMAR-SURS--DR005--N--M",
  "UMAR-SURS--DR005--O--M",
  "UMAR-SURS--DR005--P--M",
  "UMAR-SURS--DR005--Q--M",
  "UMAR-SURS--DR005--R--M",
  "UMAR-SURS--DR005--S--M",
  "UMAR-SURS--DR006--A--M",
  "UMAR-SURS--DR006--B--M",
  "UMAR-SURS--DR006--C--M",
  "UMAR-SURS--DR006--D--M",
  "UMAR-SURS--DR006--E--M",
  "UMAR-SURS--DR006--F--M",
  "UMAR-SURS--DR006--G--M",
  "UMAR-SURS--DR006--H--M",
  "UMAR-SURS--DR006--I--M",
  "UMAR-SURS--DR006--J--M",
  "UMAR-SURS--DR006--K--M",
  "UMAR-SURS--DR006--L--M",
  "UMAR-SURS--DR006--M--M",
  "UMAR-SURS--DR006--N--M",
  "UMAR-SURS--DR006--O--M",
  "UMAR-SURS--DR006--P--M",
  "UMAR-SURS--DR006--Q--M",
  "UMAR-SURS--DR006--R--M",
  "UMAR-SURS--DR006--S--M")

codes2 <- c(
  "SURS--0701007S--TOT--1--1--M",
  "SURS--0701007S--A--1--1--M",
  "SURS--0701007S--B--1--1--M",
  "SURS--0701007S--C--1--1--M",
  "SURS--0701007S--D--1--1--M",
  "SURS--0701007S--E--1--1--M",
  "SURS--0701007S--F--1--1--M",
  "SURS--0701007S--G--1--1--M",
  "SURS--0701007S--H--1--1--M",
  "SURS--0701007S--I--1--1--M",
  "SURS--0701007S--J--1--1--M",
  "SURS--0701007S--K--1--1--M",
  "SURS--0701007S--L--1--1--M",
  "SURS--0701007S--M--1--1--M",
  "SURS--0701007S--N--1--1--M",
  "SURS--0701007S--O--1--1--M",
  "SURS--0701007S--P--1--1--M",
  "SURS--0701007S--Q--1--1--M",
  "SURS--0701007S--R--1--1--M",
  "SURS--0701007S--S--1--1--M")

raw <- process_codes_vectorized(codes, con) |>
  rowwise() |>
  mutate(`ANRS` = sum(c(`UMAR-SURS--DR005--A--M`,
                        `UMAR-SURS--DR005--B--M`,
                        `UMAR-SURS--DR005--C--M`,
                        `UMAR-SURS--DR005--D--M`,
                        `UMAR-SURS--DR005--E--M`,
                        `UMAR-SURS--DR005--F--M`,
                        `UMAR-SURS--DR005--G--M`,
                        `UMAR-SURS--DR005--H--M`,
                        `UMAR-SURS--DR005--I--M`,
                        `UMAR-SURS--DR005--J--M`,
                        `UMAR-SURS--DR005--K--M`,
                        `UMAR-SURS--DR005--L--M`,
                        `UMAR-SURS--DR005--M--M`,
                        `UMAR-SURS--DR005--N--M`,
                        `UMAR-SURS--DR005--R--M`,
                        `UMAR-SURS--DR005--S--M`))/
           sum(c(`UMAR-SURS--DR006--A--M`,
                 `UMAR-SURS--DR006--B--M`,
                 `UMAR-SURS--DR006--C--M`,
                 `UMAR-SURS--DR006--D--M`,
                 `UMAR-SURS--DR006--E--M`,
                 `UMAR-SURS--DR006--F--M`,
                 `UMAR-SURS--DR006--G--M`,
                 `UMAR-SURS--DR006--H--M`,
                 `UMAR-SURS--DR006--I--M`,
                 `UMAR-SURS--DR006--J--M`,
                 `UMAR-SURS--DR006--K--M`,
                 `UMAR-SURS--DR006--L--M`,
                 `UMAR-SURS--DR006--M--M`,
                 `UMAR-SURS--DR006--N--M`,
                 `UMAR-SURS--DR006--R--M`,
                 `UMAR-SURS--DR006--S--M`)) ,
         `OPQ` = sum(c(`UMAR-SURS--DR005--O--M`,
                       `UMAR-SURS--DR005--P--M`,
                       `UMAR-SURS--DR005--Q--M`)) /
           sum(c(`UMAR-SURS--DR006--O--M`,
                 `UMAR-SURS--DR006--P--M`,
                 `UMAR-SURS--DR006--Q--M`)),
         `BE` =  sum(c(`UMAR-SURS--DR005--B--M`,
                       `UMAR-SURS--DR005--C--M`,
                       `UMAR-SURS--DR005--D--M`,
                       `UMAR-SURS--DR005--E--M`)) /
           sum(c(`UMAR-SURS--DR006--B--M`,
                 `UMAR-SURS--DR006--C--M`,
                 `UMAR-SURS--DR006--D--M`,
                 `UMAR-SURS--DR006--E--M`)),
         `GHI` = sum(c(`UMAR-SURS--DR005--G--M`,
                       `UMAR-SURS--DR005--H--M`,
                       `UMAR-SURS--DR005--I--M`)) /
           sum(c(`UMAR-SURS--DR006--G--M`,
                 `UMAR-SURS--DR006--H--M`,
                 `UMAR-SURS--DR006--I--M`)),
         `JNRS` = sum(c(`UMAR-SURS--DR005--J--M`,
                        `UMAR-SURS--DR005--K--M`,
                        `UMAR-SURS--DR005--L--M`,
                        `UMAR-SURS--DR005--M--M`,
                        `UMAR-SURS--DR005--N--M`,
                        `UMAR-SURS--DR005--R--M`,
                        `UMAR-SURS--DR005--S--M`)) /
           sum(c(`UMAR-SURS--DR006--J--M`,
                 `UMAR-SURS--DR006--K--M`,
                 `UMAR-SURS--DR006--L--M`,
                 `UMAR-SURS--DR006--M--M`,
                 `UMAR-SURS--DR006--N--M`,
                 `UMAR-SURS--DR006--R--M`,
                 `UMAR-SURS--DR006--S--M`))) |>
  select(period_id, ANRS, OPQ, BE, GHI, JNRS) |>
  dplyr::filter(!dplyr::if_all(-period_id, is.na))

raw2 <- process_codes_vectorized(codes2, con)

raw <- full_join(raw, raw2, by = "period_id") |>
  relocate(`SURS--0701007S--TOT--1--1--M`)

out <- process_indicators(raw, n_years = 1, n_quarters = 1, n_months = 1, agg_fun = "mean")|>
  mutate(indicator = 1:25)

out2 <- process_indicators(raw, n_years = 1, n_quarters = 9, n_months = 21, yoy = TRUE)|>
  mutate(indicator = 1:25)


# pre 2024
codes <- c(
  "UMAR-SURS--DR007--TOT--M",
  "UMAR-SURS--DR007--A--M",
  "UMAR-SURS--DR007--B--M",
  "UMAR-SURS--DR007--C--M",
  "UMAR-SURS--DR007--D--M",
  "UMAR-SURS--DR007--E--M",
  "UMAR-SURS--DR007--F--M",
  "UMAR-SURS--DR007--G--M",
  "UMAR-SURS--DR007--H--M",
  "UMAR-SURS--DR007--I--M",
  "UMAR-SURS--DR007--J--M",
  "UMAR-SURS--DR007--K--M",
  "UMAR-SURS--DR007--L--M",
  "UMAR-SURS--DR007--M--M",
  "UMAR-SURS--DR007--N--M",
  "UMAR-SURS--DR007--O--M",
  "UMAR-SURS--DR007--P--M",
  "UMAR-SURS--DR007--Q--M",
  "UMAR-SURS--DR007--R--M",
  "UMAR-SURS--DR007--S--M",
  "UMAR-SURS--DR008--TOT--M",
  "UMAR-SURS--DR008--A--M",
  "UMAR-SURS--DR008--B--M",
  "UMAR-SURS--DR008--C--M",
  "UMAR-SURS--DR008--D--M",
  "UMAR-SURS--DR008--E--M",
  "UMAR-SURS--DR008--F--M",
  "UMAR-SURS--DR008--G--M",
  "UMAR-SURS--DR008--H--M",
  "UMAR-SURS--DR008--I--M",
  "UMAR-SURS--DR008--J--M",
  "UMAR-SURS--DR008--K--M",
  "UMAR-SURS--DR008--L--M",
  "UMAR-SURS--DR008--M--M",
  "UMAR-SURS--DR008--N--M",
  "UMAR-SURS--DR008--O--M",
  "UMAR-SURS--DR008--P--M",
  "UMAR-SURS--DR008--Q--M",
  "UMAR-SURS--DR008--R--M",
  "UMAR-SURS--DR008--S--M")

codes2 <- c(
  "UMAR-SURS--DR009--TOT--M",
  "UMAR-SURS--DR009--A--M",
  "UMAR-SURS--DR009--B--M",
  "UMAR-SURS--DR009--C--M",
  "UMAR-SURS--DR009--D--M",
  "UMAR-SURS--DR009--E--M",
  "UMAR-SURS--DR009--F--M",
  "UMAR-SURS--DR009--G--M",
  "UMAR-SURS--DR009--H--M",
  "UMAR-SURS--DR009--I--M",
  "UMAR-SURS--DR009--J--M",
  "UMAR-SURS--DR009--K--M",
  "UMAR-SURS--DR009--L--M",
  "UMAR-SURS--DR009--M--M",
  "UMAR-SURS--DR009--N--M",
  "UMAR-SURS--DR009--O--M",
  "UMAR-SURS--DR009--P--M",
  "UMAR-SURS--DR009--Q--M",
  "UMAR-SURS--DR009--R--M",
  "UMAR-SURS--DR009--S--M")

raw <- process_codes_vectorized(codes, con) |>
  rowwise() |>
  mutate(`ANRS` = sum(c(`UMAR-SURS--DR007--A--M`,
                        `UMAR-SURS--DR007--B--M`,
                        `UMAR-SURS--DR007--C--M`,
                        `UMAR-SURS--DR007--D--M`,
                        `UMAR-SURS--DR007--E--M`,
                        `UMAR-SURS--DR007--F--M`,
                        `UMAR-SURS--DR007--G--M`,
                        `UMAR-SURS--DR007--H--M`,
                        `UMAR-SURS--DR007--I--M`,
                        `UMAR-SURS--DR007--J--M`,
                        `UMAR-SURS--DR007--K--M`,
                        `UMAR-SURS--DR007--L--M`,
                        `UMAR-SURS--DR007--M--M`,
                        `UMAR-SURS--DR007--N--M`,
                        `UMAR-SURS--DR007--R--M`,
                        `UMAR-SURS--DR007--S--M`))/
           sum(c(`UMAR-SURS--DR008--A--M`,
                 `UMAR-SURS--DR008--B--M`,
                 `UMAR-SURS--DR008--C--M`,
                 `UMAR-SURS--DR008--D--M`,
                 `UMAR-SURS--DR008--E--M`,
                 `UMAR-SURS--DR008--F--M`,
                 `UMAR-SURS--DR008--G--M`,
                 `UMAR-SURS--DR008--H--M`,
                 `UMAR-SURS--DR008--I--M`,
                 `UMAR-SURS--DR008--J--M`,
                 `UMAR-SURS--DR008--K--M`,
                 `UMAR-SURS--DR008--L--M`,
                 `UMAR-SURS--DR008--M--M`,
                 `UMAR-SURS--DR008--N--M`,
                 `UMAR-SURS--DR008--R--M`,
                 `UMAR-SURS--DR008--S--M`)) ,
         `OPQ` = sum(c(`UMAR-SURS--DR007--O--M`,
                       `UMAR-SURS--DR007--P--M`,
                       `UMAR-SURS--DR007--Q--M`)) /
           sum(c(`UMAR-SURS--DR008--O--M`,
                 `UMAR-SURS--DR008--P--M`,
                 `UMAR-SURS--DR008--Q--M`)),
         `BE` =  sum(c(`UMAR-SURS--DR007--B--M`,
                       `UMAR-SURS--DR007--C--M`,
                       `UMAR-SURS--DR007--D--M`,
                       `UMAR-SURS--DR007--E--M`)) /
           sum(c(`UMAR-SURS--DR008--B--M`,
                 `UMAR-SURS--DR008--C--M`,
                 `UMAR-SURS--DR008--D--M`,
                 `UMAR-SURS--DR008--E--M`)),
         `GHI` = sum(c(`UMAR-SURS--DR007--G--M`,
                       `UMAR-SURS--DR007--H--M`,
                       `UMAR-SURS--DR007--I--M`)) /
           sum(c(`UMAR-SURS--DR008--G--M`,
                 `UMAR-SURS--DR008--H--M`,
                 `UMAR-SURS--DR008--I--M`)),
         `JNRS` = sum(c(`UMAR-SURS--DR007--J--M`,
                        `UMAR-SURS--DR007--K--M`,
                        `UMAR-SURS--DR007--L--M`,
                        `UMAR-SURS--DR007--M--M`,
                        `UMAR-SURS--DR007--N--M`,
                        `UMAR-SURS--DR007--R--M`,
                        `UMAR-SURS--DR007--S--M`)) /
           sum(c(`UMAR-SURS--DR008--J--M`,
                 `UMAR-SURS--DR008--K--M`,
                 `UMAR-SURS--DR008--L--M`,
                 `UMAR-SURS--DR008--M--M`,
                 `UMAR-SURS--DR008--N--M`,
                 `UMAR-SURS--DR008--R--M`,
                 `UMAR-SURS--DR008--S--M`)),
         # 19 individual ratios A-S
         A = `UMAR-SURS--DR007--A--M` / `UMAR-SURS--DR008--A--M`,
         B = `UMAR-SURS--DR007--B--M` / `UMAR-SURS--DR008--B--M`,
         C = `UMAR-SURS--DR007--C--M` / `UMAR-SURS--DR008--C--M`,
         D = `UMAR-SURS--DR007--D--M` / `UMAR-SURS--DR008--D--M`,
         E = `UMAR-SURS--DR007--E--M` / `UMAR-SURS--DR008--E--M`,
         F = `UMAR-SURS--DR007--F--M` / `UMAR-SURS--DR008--F--M`,
         G = `UMAR-SURS--DR007--G--M` / `UMAR-SURS--DR008--G--M`,
         H = `UMAR-SURS--DR007--H--M` / `UMAR-SURS--DR008--H--M`,
         I = `UMAR-SURS--DR007--I--M` / `UMAR-SURS--DR008--I--M`,
         J = `UMAR-SURS--DR007--J--M` / `UMAR-SURS--DR008--J--M`,
         K = `UMAR-SURS--DR007--K--M` / `UMAR-SURS--DR008--K--M`,
         L = `UMAR-SURS--DR007--L--M` / `UMAR-SURS--DR008--L--M`,
         M = `UMAR-SURS--DR007--M--M` / `UMAR-SURS--DR008--M--M`,
         N = `UMAR-SURS--DR007--N--M` / `UMAR-SURS--DR008--N--M`,
         O = `UMAR-SURS--DR007--O--M` / `UMAR-SURS--DR008--O--M`,
         P = `UMAR-SURS--DR007--P--M` / `UMAR-SURS--DR008--P--M`,
         Q = `UMAR-SURS--DR007--Q--M` / `UMAR-SURS--DR008--Q--M`,
         R = `UMAR-SURS--DR007--R--M` / `UMAR-SURS--DR008--R--M`,
         S = `UMAR-SURS--DR007--S--M` / `UMAR-SURS--DR008--S--M`,
         TOT = `UMAR-SURS--DR007--TOT--M` / `UMAR-SURS--DR008--TOT--M`) |>
  ungroup() |>
  dplyr::select(period_id, ANRS, OPQ, BE, GHI, JNRS, A:S, TOT) |>
  dplyr::filter(!dplyr::if_all(-period_id, is.na)) |>
  relocate(TOT, .after=period_id)

out3 <- process_indicators(raw, yoy = TRUE, full = TRUE) |>
  mutate(indicator = 1:25)

out2ly <- out2 |> tidyr::pivot_longer(-indicator) |>
  dplyr::filter(grepl("^\\d{4}$", name),
                !is.na(value))
max_year <- as.numeric(max(out2ly$name)  )
out3ly <- out3 |> tidyr::pivot_longer(-indicator) |>
  dplyr::filter(grepl("^\\d{4}$", name))

years <- bind_rows(out2ly, out3ly) |>
  mutate(name = as.numeric(name)) |>
  arrange(name) |>
  filter(name > max_year - 3) |>
  tidyr::pivot_wider(names_from = name, values_from = value)


out2qy <- out2 |> tidyr::pivot_longer(-indicator) |>
  dplyr::filter(grepl("^\\d{2} Q\\d{1}$", name),
                !is.na(value))
max_quarter <- max(out2qy$name)
out3qy <- out3 |> tidyr::pivot_longer(-indicator) |>
  dplyr::filter(grepl("^\\d{2} Q\\d{1}$", name),
                name != "24 Q1")

quarters <- bind_rows(out2qy, out3qy) |>
  arrange(name) |>
  dplyr::slice_tail(n = 225) |> # most recent 9 quarters (*25 categories)
  tidyr::pivot_wider(names_from = name, values_from = value)

months <- out2 |> tidyr::pivot_longer(-indicator) |>
  dplyr::filter(grepl("^\\d{2}-\\d{2}$", name)) |>
  arrange(name) |>
  dplyr::slice_tail(n = 525) |># most recent 21 months (*25 categories)
  tidyr::pivot_wider(names_from = name, values_from = value)


wb <- load_wb_id() |> fix_wb_encoding()
wb$clean_sheet(sheet = "4-place", dims = "B2:BC26", styles = FALSE)
wb$add_data(sheet = "4-place",  x = t(colnames(out)[-1]),  dims = "B1", colNames = FALSE, na.strings = "")
wb$add_data(sheet = "4-place",  x = out[1:25,-1],  dims = "B2", colNames = FALSE, na.strings = "")
wb$add_data(sheet = "4-place",  x = t(colnames(years)[-1]),  dims = "E1", colNames = FALSE, na.strings = "")
wb$add_data(sheet = "4-place",  x = years[-1],  dims = "E2", colNames = FALSE, na.strings = "")
wb$add_data(sheet = "4-place",  x = t(colnames(quarters)[-1]),  dims = "H1", colNames = FALSE, na.strings = "")
wb$add_data(sheet = "4-place",  x = quarters[-1],  dims = "H2", colNames = FALSE, na.strings = "")
wb$add_data(sheet = "4-place",  x = t(colnames(months)[-1]),  dims = "Q1", colNames = FALSE, na.strings = "")
wb$add_data(sheet = "4-place",  x = months[-1],  dims = "Q2", colNames = FALSE, na.strings = "")
try_save_id()

wb <- load_wb_id_en() |> fix_wb_encoding()
wb$clean_sheet(sheet = "4-wages", dims = "B2:BC26", styles = FALSE)
wb$add_data(sheet = "4-wages",  x = t(colnames(out)[-1]),  dims = "B1", colNames = FALSE, na.strings = "")
wb$add_data(sheet = "4-wages",  x = out[1:25,-1],  dims = "B2", colNames = FALSE, na.strings = "")
wb$add_data(sheet = "4-wages",  x = t(colnames(years)[-1]),  dims = "E1", colNames = FALSE, na.strings = "")
wb$add_data(sheet = "4-wages",  x = years[-1],  dims = "E2", colNames = FALSE, na.strings = "")

wb$add_data(sheet = "4-wages",  x = t(colnames(quarters)[-1]),  dims = "H1", colNames = FALSE, na.strings = "")
wb$add_data(sheet = "4-wages",  x = quarters[-1],  dims = "H2", colNames = FALSE, na.strings = "")

wb$add_data(sheet = "4-wages",  x = t(colnames(months)[-1]),  dims = "Q1", colNames = FALSE, na.strings = "")
wb$add_data(sheet = "4-wages",  x = months[-1],  dims = "Q2", colNames = FALSE, na.strings = "")

try_save_id_en()
###


out2ly <- out2 |> tidyr::pivot_longer(-indicator) |>
  dplyr::filter(grepl("^\\d{4}$", name),
                !is.na(value))
out3ly <- out3 |> tidyr::pivot_longer(-indicator) |>
  dplyr::filter(grepl("^\\d{4}$", name))

years <- bind_rows(out2ly, out3ly) |>
  mutate(name = as.numeric(name)) |>
  arrange(name) |>
  tidyr::pivot_wider(names_from = name, values_from = value)


out2qy <- out2 |> tidyr::pivot_longer(-indicator) |>
  dplyr::filter(grepl("^\\d{2} Q\\d{1}$", name),
                !is.na(value))
out3qy <- out3 |> tidyr::pivot_longer(-indicator) |>
  dplyr::filter(grepl("^\\d{2} Q\\d{1}$", name),
                name != "24 Q1")

quarters <- bind_rows(out2qy, out3qy) |>
  arrange(name) |>
  tidyr::pivot_wider(names_from = name, values_from = value)

out2ml <- out2 |> tidyr::pivot_longer(-indicator) |>
  dplyr::filter(grepl("^\\d{2}-\\d{2}$", name))
out3ml <- out3 |> tidyr::pivot_longer(-indicator) |>
  dplyr::filter(grepl("^\\d{2}-\\d{2}$", name),
                !name %in% c("24-01", "24-02", "24-03"))

months <- bind_rows(out2ml, out3ml) |>
  arrange(name) |>
  tidyr::pivot_wider(names_from = name, values_from = value)


final <- bind_cols(years, quarters[-1], months[-1])

wb <- load_wb_ex()  |> fix_wb_encoding()
wb$clean_sheet(sheet = "4-place", dims = "B2:BC26", styles = FALSE)
wb$add_data(sheet = "4-place",  x = t(colnames(out)[-1]),  dims = "B1", colNames = FALSE, na.strings = "")
wb$add_data(sheet = "4-place",  x = out[1:25,-1],  dims = "B2", colNames = FALSE, na.strings = "")
wb$add_data(sheet = "4-place",  x = t(colnames(final)[-1]),  dims = "E1", colNames = FALSE, na.strings = "")
wb$add_data(sheet = "4-place",  x = final[-1],  dims = "E2", colNames = FALSE, na.strings = "")

try_save_ex()


wb <- load_wb_ex_en()  |> fix_wb_encoding()
wb$clean_sheet(sheet = "4-wages", dims = "B2:BC26", styles = FALSE)
wb$add_data(sheet = "4-wages",  x = t(colnames(out)[-1]),  dims = "B1", colNames = FALSE, na.strings = "")
wb$add_data(sheet = "4-wages",  x = out[1:25,-1],  dims = "B2", colNames = FALSE, na.strings = "")
wb$add_data(sheet = "4-wages",  x = t(colnames(final)[-1]),  dims = "E1", colNames = FALSE, na.strings = "")
wb$add_data(sheet = "4-wages",  x = final[-1],  dims = "E2", colNames = FALSE, na.strings = "")

try_save_ex_en()
