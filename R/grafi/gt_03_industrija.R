# source("\\\\192.168.38.7\\public$\\Avtomatizacija\\umar-automation-scripts\\R\\grafi\\00_setup.R")

filename <- "GT_03_industrija_auto.xlsx"
################################################################################
message("\nPreparing data for the chart in ", filename)

codes <- c("SURS--1701111S--sa--C[skd]--M",
           "SURS--1701114S--sa--NTZ--M",
           "SURS--1701114S--sa--SNTZ--M",
           "SURS--1701114S--sa--SVTZ--M",
           "SURS--1701114S--sa--VTZ--M")

################################################################################
raw <- process_codes_vectorized(codes, con) |>
  rebase_multiple(value_cols = codes,
                  base_year = 2021) |>
  filter(substr(period_id, 1, 4) > 2021) |>
  mutate(crta = 100,
         period_id = as.Date(paste0(substr(period_id, 1, 4), "-",
                                    substr(period_id, 6, 7), "-01")))|>
  filter_ten_years()

wb <- load_wb(filename)

wb <- write_wb(wb, raw)

try_save(filename)
