# source("\\\\192.168.38.7\\public$\\Avtomatizacija\\umar-automation-scripts\\R\\grafi\\00_setup.R")

filename <- "GT_15_PPI_auto.xlsx"
################################################################################
message("\nPreparing data for the chart in ", filename)

codes <- c("SURS--0457201S--B_TO_E--29--M",
           "SURS--0457301S--B_TO_E--29--M",
           "SURS--0457101S--B_TO_E--29--M")

################################################################################
raw <- process_codes_vectorized(codes, con) |>
  mutate(`SURS--0457201S--B_TO_E--29--M` = `SURS--0457201S--B_TO_E--29--M` /
           lag(`SURS--0457201S--B_TO_E--29--M`, 12) * 100 - 100,
         `SURS--0457301S--B_TO_E--29--M` = `SURS--0457301S--B_TO_E--29--M` /
                  lag(`SURS--0457301S--B_TO_E--29--M`, 12) * 100 - 100,
         `SURS--0457101S--B_TO_E--29--M` = `SURS--0457101S--B_TO_E--29--M` /
                         lag(`SURS--0457101S--B_TO_E--29--M`, 12) * 100 - 100,
         crta = 0) |>
  filter(substr(period_id, 1, 4) > 2021) |>
  mutate( period_id = as.Date(paste0(substr(period_id, 1, 4), "-",
                                     substr(period_id, 6, 7), "-01"))) |>
  arrange(period_id)

wb <- load_wb(filename)

wb <- write_wb(wb, raw)

try_save(filename)
