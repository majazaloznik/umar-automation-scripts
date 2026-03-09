# source("\\\\192.168.38.7\\public$\\Avtomatizacija\\umar-automation-scripts\\R\\grafi\\00_setup.R")

filename <- "GT_09_tendence_auto.xlsx"

################################################################################
message("\nPreparing data for the chart in ", filename)

codes <- c("SURS--2855901S--1--2--M",
           "SURS--2855901S--2--2--M",
           "SURS--2855901S--3--2--M",
           "SURS--2855901S--4--2--M",
           "SURS--2855901S--5--2--M",
           "SURS--2855901S--6--2--M")

################################################################################
raw <- process_codes_vectorized(codes, con) |>
  filter(substr(period_id, 1, 4) > 2021) |>
  mutate(crta = 0,
         period_id = as.Date(paste0(substr(period_id, 1, 4), "-",
                                    substr(period_id, 6, 7), "-01")))

wb <- load_wb(filename)

wb <- write_wb(wb, raw)

try_save(filename)
