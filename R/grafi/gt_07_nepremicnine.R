# source("\\\\192.168.38.7\\public$\\Avtomatizacija\\umar-automation-scripts\\R\\grafi\\00_setup.R")

filename <- "GT_07_nepremicnine_auto.xlsx"

################################################################################
message("\nPreparing data for the chart in ", filename)

codes <- c("SURS--0419001S--1.2--4--Q",
           "SURS--0419001S--1.1--4--Q",
           "SURS--0419030S--1.2--1--Q",
           "SURS--0419030S--1.1--1--Q")

################################################################################
raw <- process_codes_vectorized(codes, con) |>
  rebase_multiple(value_cols = codes,
                  base_year = 2021) |>
  rolling_mean(value_col = codes, k = 4) |>
  filter(substr(period_id, 1, 4) > 2021) |>
  mutate(crta = 100,
        q_id = paste(substr(period_id, 5, 6),
                           substr(period_id, 3, 4)))


wb <- load_wb(filename)

wb <- write_wb(wb, raw)

try_save(filename)
