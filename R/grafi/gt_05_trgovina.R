# source("\\\\192.168.38.7\\public$\\Avtomatizacija\\umar-automation-scripts\\R\\grafi\\00_setup.R")
filename <- "GT_05_trgovina_auto.xlsx"
################################################################################
message("\nPreparing data for the chart in ", filename)


codes <- c("SURS--2001303S--2--2--G--M",
           "SURS--2001303S--2--2--45--M",
           "SURS--2001303S--2--2--46--M",
           "SURS--2001303S--2--2--47--M",
           "SURS--2001303S--2--2--47 brez 47.3--M")

################################################################################
raw <- process_codes_vectorized(codes, con) |>
  rebase_multiple(value_cols = codes,
                  base_year = 2021) |>
  rolling_mean(value_col = codes) |>
  filter(substr(period_id, 1, 4) > 2021) |>
  mutate(crta = 100,
         period_id = as.Date(paste0(substr(period_id, 1, 4), "-",
                                    substr(period_id, 6, 7), "-01")))

# remove any rows where G doesn't have data yet.
last_valid <- max(which(!is.na(raw$`SURS--2001303S--2--2--G--M`)))
raw <- raw[1:last_valid, ]

wb <- load_wb(filename)

wb <- write_wb(wb, raw)

try_save(filename)
