# source("\\\\192.168.38.7\\public$\\Avtomatizacija\\umar-automation-scripts\\R\\grafi\\00_setup.R")

filename <- "GT_08_cestni.zelez_auto.xlsx"

################################################################################
message("\nPreparing data for the chart in ", filename)

codes <- c("DESEZ--PR--CB--Y--Q",
           "DESEZ--PR--CBn--Y--Q",
           "DESEZ--PR--Ex--Y--Q",
           "DESEZ--PR--Im--Y--Q",
           "DESEZ--PR--Tuj--Y--Q",
           "DESEZ--PR--ZB--Y--Q")

################################################################################
raw <- process_codes_vectorized(codes, con) |>
  mutate(Exim = `DESEZ--PR--Ex--Y--Q` + `DESEZ--PR--Im--Y--Q`,
         Exim_not = Exim + `DESEZ--PR--CBn--Y--Q`) |>
  rebase_multiple(value_cols =  c(codes, "Exim", "Exim_not"),
                  base_year = 2019) |>
  filter(substr(period_id, 1, 4) > 2018) |>
  mutate(crta = 100,
         q_id = paste(substr(period_id, 5, 6),
                      substr(period_id, 3, 4)))


wb <- load_wb(filename)

wb <- write_wb(wb, raw)

try_save(filename)
