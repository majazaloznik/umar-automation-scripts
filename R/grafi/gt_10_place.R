# source("\\\\192.168.38.7\\public$\\Avtomatizacija\\umar-automation-scripts\\R\\grafi\\00_setup.R")

filename <- "GT_10_place_auto.xlsx"

################################################################################
message("\nPreparing data for the chart in ", filename)

codes <- c( "SURS--0701015S--1--1--10--M",
            "SURS--0701015S--2--1--10--M",
            "SURS--0701015S--TOT--1--10--M",
            "SURS--0701054S--1--1--10--M",
            "SURS--0701054S--2--1--10--M",
            "SURS--0701054S--TOT--1--10--M",
            "SURS--0400608S--TOT--2--M")

################################################################################
raw <- process_codes_vectorized(codes, con) |>
  arrange(period_id) |>
  deflate(value_col = codes[1:6]) |>
  rolling_mean_m100(value_col = codes[1:6], k = 3) |>
  select(-`SURS--0400608S--TOT--2--M`) |>
  filter(substr(period_id, 1, 4) > 2021) |>
  mutate(crta = 0,
         period_id = as.Date(paste0(substr(period_id, 1, 4), "-",
                                    substr(period_id, 6, 7), "-01")),
         vertikala = ifelse(period_id == as.Date("2024-03-01"), 0, NA)) |>
  arrange(period_id) |>
  filter(!if_all(2:7, is.na))


wb <- load_wb(filename)

wb <- write_wb(wb, raw)

try_save(filename)

