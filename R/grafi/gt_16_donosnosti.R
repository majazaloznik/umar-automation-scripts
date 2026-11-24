
# source("\\\\192.168.38.7\\public$\\Avtomatizacija\\umar-automation-scripts\\R\\grafi\\00_setup.R")

filename <- "GT_16_donosnosti_auto.xlsx"
################################################################################
base::message("\nPreparing data for the chart in ", filename)

codes <- c( "BLOOMBERG-UMAR--UDB002--AT--M",
            "BLOOMBERG-UMAR--UDB002--DE--M",
            "BLOOMBERG-UMAR--UDB002--ES--M",
            "BLOOMBERG-UMAR--UDB002--FR--M",
            "BLOOMBERG-UMAR--UDB002--IT--M",
            "BLOOMBERG-UMAR--UDB002--PT--M",
            "BLOOMBERG-UMAR--UDB002--SI--M")


################################################################################
raw <- process_codes_vectorized(codes, con) |>
  mutate(crta = 0,
         period_id = as.Date(paste0(substr(period_id, 1, 4), "-",
                                    substr(period_id, 6, 7), "-01"))) |>
  arrange(period_id)


wb <- load_wb(filename)

wb <- write_wb(wb, raw)

try_save(filename)

