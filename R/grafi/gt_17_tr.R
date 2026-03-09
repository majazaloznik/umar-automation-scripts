
# source("\\\\192.168.38.7\\public$\\Avtomatizacija\\umar-automation-scripts\\R\\grafi\\00_setup.R")

filename <- "GT_17_tr_auto.xlsx"
################################################################################
message("\nPreparing data for the chart in ", filename)

codes <- c( "BS--i_32_6ms--0--M",
            "BS--i_32_6ms--3--M",
            "BS--i_32_6ms--6--M",
            "BS--i_32_6ms--19--M",
            "BS--i_32_6ms--32--M")


################################################################################
raw <- process_codes_vectorized(codes, con) |>
  rolling_sum(value_col = codes, k = 12) |>
  filter(substr(period_id, 1, 4) > 2021) |>
  mutate(crta = 0,
         period_id = as.Date(paste0(substr(period_id, 1, 4), "-",
                                    substr(period_id, 6, 7), "-01"))) |>
  arrange(period_id)


wb <- load_wb(filename)

wb <- write_wb(wb, raw)

try_save(filename)
