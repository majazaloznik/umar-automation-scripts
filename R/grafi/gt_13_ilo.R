# source("\\\\192.168.38.7\\public$\\Avtomatizacija\\umar-automation-scripts\\R\\grafi\\00_setup.R")

filename <- "GT_13_ilo_auto.xlsx"

################################################################################
message("\nPreparing data for the chart in ", filename)

codes <- c("DESEZ--ILO--ST--Y--Q",
           "DESEZ--ILO--ZP--N--Q")


################################################################################
raw <- process_codes_vectorized(codes, con) |>
   mutate(`DESEZ--ILO--ZP--N--Q` = `DESEZ--ILO--ZP--N--Q` /
           lag(`DESEZ--ILO--ZP--N--Q`, 4) * 100 - 100,
         crta = 0,
         filter = substr(period_id, 1, 4) >= 2015,
         q_id = paste(substr(period_id, 5, 6),
                      substr(period_id, 3, 4)))


wb <- load_wb(filename)

wb <- write_wb(wb, raw)

try_save(filename)
