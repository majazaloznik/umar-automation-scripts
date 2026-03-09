# source("\\\\192.168.38.7\\public$\\Avtomatizacija\\umar-automation-scripts\\R\\grafi\\00_setup.R")

filename <- "GT_11_del.aktivni_auto.xlsx"

################################################################################
message("\nPreparing data for the chart in ", filename)

codes <- c("SURS--0700921S--A--1--M",
           "SURS--0700921S--B--1--M",
           "SURS--0700921S--C--1--M",
           "SURS--0700921S--D--1--M",
           "SURS--0700921S--E--1--M",
           "SURS--0700921S--F--1--M",
           "SURS--0700921S--G--1--M",
           "SURS--0700921S--H--1--M",
           "SURS--0700921S--I--1--M",
           "SURS--0700921S--J--1--M",
           "SURS--0700921S--K--1--M",
           "SURS--0700921S--L--1--M",
           "SURS--0700921S--M--1--M",
           "SURS--0700921S--N--1--M",
           "SURS--0700921S--O--1--M",
           "SURS--0700921S--P--1--M",
           "SURS--0700921S--Q--1--M",
           "SURS--0700921S--R--1--M",
           "SURS--0700921S--S--1--M",
           "SURS--0700921S--T--1--M",
           "SURS--0700921S--SKD--1--M")
codes2 <- c("SURS--0700921S--SKD--1--M",
            "SURS--0700921S--C--1--M",
            "SURS--0700921S--F--1--M",
            "SURS--0700921S--GN--1--M",
            "SURS--0700921S--OQ--1--M",
            "SURS--0700921S--ABDERT--1--M")

################################################################################
raw <- process_codes_vectorized(codes, con) |>
  rowwise() |>
  mutate(`SURS--0700921S--GN--1--M` = sum( `SURS--0700921S--G--1--M`,
                                           `SURS--0700921S--H--1--M`,
                                           `SURS--0700921S--I--1--M`,
                                           `SURS--0700921S--J--1--M`,
                                           `SURS--0700921S--K--1--M`,
                                           `SURS--0700921S--L--1--M`,
                                           `SURS--0700921S--M--1--M`,
                                           `SURS--0700921S--N--1--M`),
         `SURS--0700921S--OQ--1--M` = sum(`SURS--0700921S--O--1--M`,
                                          `SURS--0700921S--P--1--M`,
                                          `SURS--0700921S--Q--1--M`),
         `SURS--0700921S--ABDERT--1--M`= sum(`SURS--0700921S--A--1--M`,
                                             `SURS--0700921S--B--1--M`,
                                             `SURS--0700921S--D--1--M`,
                                             `SURS--0700921S--E--1--M`,
                                             `SURS--0700921S--R--1--M`,
                                             `SURS--0700921S--S--1--M`,
                                             `SURS--0700921S--T--1--M`), .keep = "unused") |>
  ungroup() |>
  rebase_multiple_m(value_cols = codes2,
                  base_month = "2019M01") |>
  mutate(crta = 100,
         period_id = as.Date(paste0(substr(period_id, 1, 4), "-",
                                    substr(period_id, 6, 7), "-01")))

wb <- load_wb(filename)

wb <- write_wb(wb, raw)

try_save(filename)
