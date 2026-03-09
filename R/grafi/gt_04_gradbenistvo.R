# source("\\\\192.168.38.7\\public$\\Avtomatizacija\\umar-automation-scripts\\R\\grafi\\00_setup.R")

filename <- "GT_04_gradbenistvo_auto.xlsx"
################################################################################
message("\nPreparing data for the chart in ", filename)

codes <- c("SURS--1957408S--SA--CC--M")

################################################################################
raw <- process_codes_vectorized(codes, con) |>
  rebase_multiple(value_cols = codes,
                  base_year = 2021) |>

  mutate(`SURS--1957408S--SA--CC--M-smooth` = zoo::rollmean(`SURS--1957408S--SA--CC--M`,
                                                        k = 3, fill = NA, align = "right"),
         crta = 100)  |>
  filter(substr(period_id, 1, 4) > 2021) |>
  mutate(period_id = as.Date(paste0(substr(period_id, 1, 4), "-",
                                    substr(period_id, 6, 7), "-01")))

wb <- load_wb(filename)

wb <- write_wb(wb, raw)

try_save(filename)
