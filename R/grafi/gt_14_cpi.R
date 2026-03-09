# source("\\\\192.168.38.7\\public$\\Avtomatizacija\\umar-automation-scripts\\R\\grafi\\00_setup.R")

filename <- "GT_14_CPI_auto.xlsx"
################################################################################
message("\nPreparing data for the chart in ", filename)

codes <- c("SURS--H281S--2--M",
           "EUROSTAT--prc_hicp_minr--RCH_A--TOTAL--EA--M")

################################################################################
raw <- process_codes_vectorized(codes, con) |>
  filter(substr(period_id, 1, 4) > 2021) |>
  mutate(crta = 0,
         `SURS--H281S--2--M` = `SURS--H281S--2--M` - 100,
         period_id = as.Date(paste0(substr(period_id, 1, 4), "-",
                                    substr(period_id, 6, 7), "-01"))) |>
  arrange(period_id)

wb <- load_wb(filename)

wb <- write_wb(wb, raw)

try_save(filename)

