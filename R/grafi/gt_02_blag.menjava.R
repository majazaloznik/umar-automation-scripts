# source("\\\\192.168.38.7\\public$\\Avtomatizacija\\umar-automation-scripts\\R\\grafi\\00_setup.R")

filename <- "GT_02_blag.menjava_auto.xlsx"
################################################################################
# Data series from the platform database
################################################################################
message("\nPreparing data for the chart in ", filename)
codes <- c( "UMAR-SURS--MH003--OSNO--REA--EX--SKUP--SKUP--M",
            "UMAR-SURS--MH003--OSNO--REA--IM--SKUP--SKUP--M")


################################################################################
raw <- process_codes_vectorized(codes, con) |>
  mutate(`UMAR-SURS--MH003--OSNO--REA--EX--SKUP--SKUP--M-smooth` =
           zoo::rollmean(`UMAR-SURS--MH003--OSNO--REA--EX--SKUP--SKUP--M`, 3, fill = NA, align = "right"),
         `UMAR-SURS--MH003--OSNO--REA--IM--SKUP--SKUP--M-smooth` =
           zoo::rollmean(`UMAR-SURS--MH003--OSNO--REA--IM--SKUP--SKUP--M`, 3, fill = NA, align = "right"),
         crta = 100) |>
  rebase_multiple(value_cols = c(codes,
                                 "UMAR-SURS--MH003--OSNO--REA--EX--SKUP--SKUP--M-smooth",
                                 "UMAR-SURS--MH003--OSNO--REA--IM--SKUP--SKUP--M-smooth"),
                  base_year = 2021) |>
  filter(substr(period_id, 1, 4) > 2021) |>
  mutate(period_id = as.Date(paste0(substr(period_id, 1, 4), "-",
                                    substr(period_id, 6, 7), "-01"))) |>
  filter_ten_years()


wb <- load_wb(filename)

wb <- write_wb(wb, raw)

try_save(filename)
