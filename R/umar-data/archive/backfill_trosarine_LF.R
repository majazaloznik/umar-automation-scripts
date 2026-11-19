

# # # trosarine read - one off
# # ################################################################################
# library(dplyr)
# library(tidyr)
# path <- "\\\\192.168.38.7\\public$\\Avtomatizacija\\umar-automation-scripts\\data\\trosarine\\stare"
# filename <- "trosarine_stare_raw.xlsx"
# df <- readxl::read_excel(paste(path, filename, sep = "\\")) |>
#   filter(datum < "2025-09-01") |>
#   mutate(num_value = as.numeric(num_value))
#
# kolicine <- df |>
#   filter(meritev != "trošarina") |>
#   select(Izdelek, datum, num_value) |>
#   pivot_wider(names_from = Izdelek,
#               values_from = num_value)
#
# colnames(kolicine) <- c("period",
#                       "MF-UMAR--LF001--K--B9X--M",
#                       "MF-UMAR--LF001--K--BDIZ--M",
#                       "MF-UMAR--LF001--K--CGT--M",
#                       "MF-UMAR--LF001--K--ALK--M",
#                       "MF-UMAR--LF001--K--DIZ--M",
#                       "MF-UMAR--LF001--K--ELN--M",
#                       "MF-UMAR--LF001--K--ELP--M",
#                       "MF-UMAR--LF001--K--KOEL--M",
#                       "MF-UMAR--LF001--K--VIN--M",
#                       "MF-UMAR--LF001--K--PIV--M",
#                       "MF-UMAR--LF001--K--VPIJ--M",
#                       "MF-UMAR--LF001--K--ZPO--M",
#                       "MF-UMAR--LF001--K--ZPP--M",
#                       "MF-UMAR--LF001--K--ZPPV--M",
#                       "MF-UMAR--LF001--K--TOB--M",
#                       "MF-UMAR--LF001--K--ECG--M")
# zneski <- df |>
#   filter(meritev == "trošarina") |>
#   select(Izdelek, datum, num_value) |>
#   pivot_wider(names_from = Izdelek,
#               values_from = num_value)
#
# colnames(zneski) <- c("period",
#                         "MF-UMAR--LF001--Z--B9X--M",
#                         "MF-UMAR--LF001--Z--BDIZ--M",
#                         "MF-UMAR--LF001--Z--CGT--M",
#                         "MF-UMAR--LF001--Z--ALK--M",
#                         "MF-UMAR--LF001--Z--DIZ--M",
#                         "MF-UMAR--LF001--Z--ELN--M",
#                         "MF-UMAR--LF001--Z--ELP--M",
#                         "MF-UMAR--LF001--Z--KOEL--M",
#                         "MF-UMAR--LF001--Z--VIN--M",
#                         "MF-UMAR--LF001--Z--PIV--M",
#                         "MF-UMAR--LF001--Z--VPIJ--M",
#                         "MF-UMAR--LF001--Z--ZPO--M",
#                         "MF-UMAR--LF001--Z--ZPP--M", # zp za pogon vozil nima zneskov!
#                         "MF-UMAR--LF001--Z--TOB--M",
#                         "MF-UMAR--LF001--Z--ECG--M")
#
# final <- zneski |>
#   left_join(kolicine)
#
#
# path <- "\\\\192.168.38.7\\public$\\Avtomatizacija\\umar-data\\LF\\umar_serije_podatki_LF.xlsx"
# # Read existing file
# existing <- readxl::read_excel(path) |>
#   mutate(period = as.POSIXct(period, tz = "UTC"))
#
# # every other column: logical NA -> numeric NA
# other <- setdiff(names(existing), "period")
# existing[other] <- lapply(existing[other], as.numeric)
#
# # Update/merge with new data
# updated <- existing |>
#   dplyr::rows_upsert(final, by = "period")
#
# # Write back
# openxlsx::write.xlsx(updated,
#                      file = path,
#                      sheetName = "M",
#                      overwrite = TRUE)
#
