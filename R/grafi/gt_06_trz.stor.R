# source("\\\\192.168.38.7\\public$\\Avtomatizacija\\umar-automation-scripts\\R\\grafi\\00_setup.R")

filename <- "GT_06_trz.stor_auto.xlsx"

################################################################################
message("\nPreparing data for the chart in ", filename)

codes <- c("SURS--2080006S--2--H+I+J+L+M+N--M",
           "SURS--2080006S--2--H--M",
           "SURS--2080006S--2--I--M",
           "SURS--2080006S--2--J--M",
           "SURS--2080006S--2--M--M",
           "SURS--2080006S--2--N--M")

################################################################################
raw <- process_codes_vectorized(codes, con) |>
  rebase_multiple(value_cols = codes,
                  base_year = 2019) |>
  rolling_mean(value_col = codes) |>
  filter(substr(period_id, 1, 4) > 2021) |>
  mutate(crta = 100,
         period_id = as.Date(paste0(substr(period_id, 1, 4), "-",
                                    substr(period_id, 6, 7), "-01")))



wb <- load_wb(filename)

wb <- write_wb(wb, raw)

try_save(filename)
