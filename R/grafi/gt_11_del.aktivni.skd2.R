# source("\\\\192.168.38.7\\public$\\Avtomatizacija\\umar-automation-scripts\\R\\grafi\\00_setup.R")

filename <- "GT_11_del.aktivni_skd2_auto.xlsx"

################################################################################
base::message("\nPreparing data for the chart in ", filename)

codes <- c("SURS--0700928S--A--1--M",
           "SURS--0700928S--B--1--M",
           "SURS--0700928S--C--1--M",
           "SURS--0700928S--D--1--M",
           "SURS--0700928S--E--1--M",
           "SURS--0700928S--F--1--M",
           "SURS--0700928S--G--1--M",
           "SURS--0700928S--H--1--M",
           "SURS--0700928S--I--1--M",
           "SURS--0700928S--J--1--M",
           "SURS--0700928S--K--1--M",
           "SURS--0700928S--L--1--M",
           "SURS--0700928S--M--1--M",
           "SURS--0700928S--N--1--M",
           "SURS--0700928S--O--1--M",
           "SURS--0700928S--P--1--M",
           "SURS--0700928S--Q--1--M",
           "SURS--0700928S--R--1--M",
           "SURS--0700928S--S--1--M",
           "SURS--0700928S--T--1--M",
           "SURS--0700928S--U--1--M",
           "SURS--0700928S--TOT--1--M")
codes2 <- c("SURS--0700928S--TOT--1--M",
            "SURS--0700928S--C--1--M",
            "SURS--0700928S--F--1--M",
            "SURS--0700928S--GO--1--M",
            "SURS--0700928S--PR--1--M",
            "SURS--0700928S--ABDESU--1--M")

################################################################################
raw <- process_codes_vectorized(codes, con) |>
  rowwise() |>
  mutate(`SURS--0700928S--GO--1--M` = sum( `SURS--0700928S--G--1--M`,
                                           `SURS--0700928S--H--1--M`,
                                           `SURS--0700928S--I--1--M`,
                                           `SURS--0700928S--J--1--M`,
                                           `SURS--0700928S--K--1--M`,
                                           `SURS--0700928S--L--1--M`,
                                           `SURS--0700928S--M--1--M`,
                                           `SURS--0700928S--N--1--M`,
                                           `SURS--0700928S--O--1--M`),
         `SURS--0700928S--PR--1--M` = sum(`SURS--0700928S--P--1--M`,
                                          `SURS--0700928S--Q--1--M`,
                                          `SURS--0700928S--R--1--M`),
         `SURS--0700928S--ABDESU--1--M`= sum(`SURS--0700928S--A--1--M`,
                                             `SURS--0700928S--B--1--M`,
                                             `SURS--0700928S--D--1--M`,
                                             `SURS--0700928S--E--1--M`,
                                             `SURS--0700928S--S--1--M`,
                                             `SURS--0700928S--T--1--M`,
                                             `SURS--0700928S--U--1--M`), .keep = "unused") |>
  ungroup() |>
  rebase_multiple_m(value_cols = codes2,
                    base_month = "2020M01") |>
  mutate(crta = 100,
         period_id = as.Date(paste0(substr(period_id, 1, 4), "-",
                                    substr(period_id, 6, 7), "-01")))

wb <- load_wb(filename)

wb <- write_wb(wb, raw)

try_save(filename)
