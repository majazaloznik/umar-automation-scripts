##
#' Script for reading the masa plač data from Denis' file on the network
#' drive and writing it to his umar data file for automated ingestion
#'
#' the first part of the script is the regular update. the second part is commented
#' out for archival purposes and was the one off run to ingest the
#' old data series before the break in 2023/4.

# masa plač nova read
################################################################################
path <- "\\\\192.168.38.7\\public$\\Users\\DRogan\\EO\\Pla\u010de (nove SKD skupine).xlsx"

df <- readxl::read_excel(path,
                         col_names = FALSE)

df <- df[-2, ]  # remove row 2
df <- df[1:22,]
df <- df[, !sapply(df, function(x) all(is.na(x[-1])))]
# Set proper column names
names(df)[1] <- "category"
names(df)[-1] <- format(as.Date(as.numeric(df[1, -1]), origin = "1899-12-30"), "%Y-%m-%d")
# Remove the header row from data
df <- df[-1, ]
df_transposed <- df |>
  tidyr::pivot_longer(cols = -category,
                      names_to = "period",
                      values_to = "value") |>
  tidyr::pivot_wider(names_from = category,
                     values_from = value) |>
  dplyr::mutate(period = as.Date(period))

colnames(df_transposed) <- c("period",
                             "UMAR-SURS--DR012--A--M",
                             "UMAR-SURS--DR012--B--M",
                             "UMAR-SURS--DR012--C--M",
                             "UMAR-SURS--DR012--D--M",
                             "UMAR-SURS--DR012--E--M",
                             "UMAR-SURS--DR012--F--M",
                             "UMAR-SURS--DR012--G--M",
                             "UMAR-SURS--DR012--H--M",
                             "UMAR-SURS--DR012--I--M",
                             "UMAR-SURS--DR012--J--M",
                             "UMAR-SURS--DR012--K--M",
                             "UMAR-SURS--DR012--L--M",
                             "UMAR-SURS--DR012--M--M",
                             "UMAR-SURS--DR012--N--M",
                             "UMAR-SURS--DR012--O--M",
                             "UMAR-SURS--DR012--P--M",
                             "UMAR-SURS--DR012--Q--M",
                             "UMAR-SURS--DR012--R--M",
                             "UMAR-SURS--DR012--S--M",
                             "UMAR-SURS--DR012--T--M",
                             "UMAR-SURS--DR012--TOT--M")

path <- "\\\\192.168.38.7\\public$\\Avtomatizacija\\umar-data\\DR\\umar_serije_podatki_DR.xlsx"
# Read existing file
existing <- readxl::read_excel(path)|>
  dplyr::mutate(dplyr::across(-1, as.numeric))

# Update/merge with new data
updated <- existing |>
  dplyr::rows_upsert(df_transposed, by = "period")

# Write back
openxlsx::write.xlsx(updated,
                     file = path,
                     sheetName = "M",
                     overwrite = TRUE)

# prejemniki plač novi read
################################################################################
path <- "\\\\192.168.38.7\\public$\\Users\\DRogan\\EO\\Pla\u010de (nove SKD skupine).xlsx"

 df <- readxl::read_excel(path,
                         col_names = FALSE)

df <- df[-(2:25), ]  # remove row 2
df <- df[1:22,]
df <- df[, !sapply(df, function(x) all(is.na(x[-1])))]
# Set proper column names
names(df)[1] <- "category"
names(df)[-1] <- format(as.Date(as.numeric(df[1, -1]), origin = "1899-12-30"), "%Y-%m-%d")

# Remove the header row from data
df <- df[-1, ]
df_transposed <- df |>
  tidyr::pivot_longer(cols = -category,
                      names_to = "period",
                      values_to = "value") |>
  tidyr::pivot_wider(names_from = category,
                     values_from = value) |>
  dplyr::mutate(period = as.Date(period))

colnames(df_transposed) <- c("period",
                             "UMAR-SURS--DR013--A--M",
                             "UMAR-SURS--DR013--B--M",
                             "UMAR-SURS--DR013--C--M",
                             "UMAR-SURS--DR013--D--M",
                             "UMAR-SURS--DR013--E--M",
                             "UMAR-SURS--DR013--F--M",
                             "UMAR-SURS--DR013--G--M",
                             "UMAR-SURS--DR013--H--M",
                             "UMAR-SURS--DR013--I--M",
                             "UMAR-SURS--DR013--J--M",
                             "UMAR-SURS--DR013--K--M",
                             "UMAR-SURS--DR013--L--M",
                             "UMAR-SURS--DR013--M--M",
                             "UMAR-SURS--DR013--N--M",
                             "UMAR-SURS--DR013--O--M",
                             "UMAR-SURS--DR013--P--M",
                             "UMAR-SURS--DR013--Q--M",
                             "UMAR-SURS--DR013--R--M",
                             "UMAR-SURS--DR013--S--M",
                             "UMAR-SURS--DR013--T--M",
                             "UMAR-SURS--DR013--TOT--M")

path <- "\\\\192.168.38.7\\public$\\Avtomatizacija\\umar-data\\DR\\umar_serije_podatki_DR.xlsx"
# Read existing file
existing <- readxl::read_excel(path)|>
  dplyr::mutate(dplyr::across(-1, as.numeric))

# Update/merge with new data
updated <- existing |>
  dplyr::rows_upsert(df_transposed, by = "period")

# Write back
openxlsx::write.xlsx(updated,
                     file = path,
                     sheetName = "M",
                     overwrite = TRUE)

#
#
# # masa plač stara read - one off
# ################################################################################
# path <- "\\\\192.168.38.7\\public$\\Users\\DRogan\\EO\\Plače (SKD skupine) - podatki do marca 2024.xlsx"
#
# df <- readxl::read_excel(path,
#                          col_names = FALSE)
#
# df <- df[-2, ]  # remove row 2
# df <- df[1:21,]
# df <- df[, !sapply(df, function(x) all(is.na(x[-1])))]
# # Set proper column names
# names(df)[1] <- "category"
# names(df)[-1] <- format(as.Date(as.numeric(df[1, -1]), origin = "1899-12-30"), "%Y-%m-%d")
# # Remove the header row from data
# df <- df[-1, ]
# df_transposed <- df |>
#   tidyr::pivot_longer(cols = -category,
#                       names_to = "period",
#                       values_to = "value") |>
#   tidyr::pivot_wider(names_from = category,
#                      values_from = value) |>
#   dplyr::mutate(period = as.Date(period))
#
# colnames(df_transposed) <- c("period", "UMAR-SURS--DR007--A--M",
#                              "UMAR-SURS--DR007--B--M",
#                              "UMAR-SURS--DR007--C--M",
#                              "UMAR-SURS--DR007--D--M",
#                              "UMAR-SURS--DR007--E--M",
#                              "UMAR-SURS--DR007--F--M",
#                              "UMAR-SURS--DR007--G--M",
#                              "UMAR-SURS--DR007--H--M",
#                              "UMAR-SURS--DR007--I--M",
#                              "UMAR-SURS--DR007--J--M",
#                              "UMAR-SURS--DR007--K--M",
#                              "UMAR-SURS--DR007--L--M",
#                              "UMAR-SURS--DR007--M--M",
#                              "UMAR-SURS--DR007--N--M",
#                              "UMAR-SURS--DR007--O--M",
#                              "UMAR-SURS--DR007--P--M",
#                              "UMAR-SURS--DR007--Q--M",
#                              "UMAR-SURS--DR007--R--M",
#                              "UMAR-SURS--DR007--S--M",
#                              "UMAR-SURS--DR007--TOT--M")
#
# path <- "\\\\192.168.38.7\\public$\\Avtomatizacija\\umar-data\\DR\\umar_serije_podatki_DR.xlsx"
# # Read existing file
# existing <- readxl::read_excel(path)
#
# # Update/merge with new data
# updated <- existing |>
#   dplyr::rows_upsert(df_transposed, by = "period")
#
# # Write back
# openxlsx::write.xlsx(updated,
#                      file = path,
#                      sheetName = "M",
#                      overwrite = TRUE)

# # prejemniki plač novi read
# ################################################################################
# path <- "\\\\192.168.38.7\\public$\\Users\\DRogan\\EO\\Plače (SKD skupine) - podatki do marca 2024.xlsx"
#
# df <- readxl::read_excel(path,
#                          col_names = FALSE)
#
# df <- df[-(2:24), ]  # remove row 2
# df <- df[1:21,]
# df <- df[, !sapply(df, function(x) all(is.na(x[-1])))]
# # Set proper column names
# names(df)[1] <- "category"
# names(df)[-1] <- format(as.Date(as.numeric(df[1, -1]), origin = "1899-12-30"), "%Y-%m-%d")
#
# # Remove the header row from data
# df <- df[-1, ]
# df_transposed <- df |>
#   tidyr::pivot_longer(cols = -category,
#                       names_to = "period",
#                       values_to = "value") |>
#   tidyr::pivot_wider(names_from = category,
#                      values_from = value) |>
#   dplyr::mutate(period = as.Date(period))
#
# colnames(df_transposed) <- c("period", "UMAR-SURS--DR008--A--M",
#                              "UMAR-SURS--DR008--B--M",
#                              "UMAR-SURS--DR008--C--M",
#                              "UMAR-SURS--DR008--D--M",
#                              "UMAR-SURS--DR008--E--M",
#                              "UMAR-SURS--DR008--F--M",
#                              "UMAR-SURS--DR008--G--M",
#                              "UMAR-SURS--DR008--H--M",
#                              "UMAR-SURS--DR008--I--M",
#                              "UMAR-SURS--DR008--J--M",
#                              "UMAR-SURS--DR008--K--M",
#                              "UMAR-SURS--DR008--L--M",
#                              "UMAR-SURS--DR008--M--M",
#                              "UMAR-SURS--DR008--N--M",
#                              "UMAR-SURS--DR008--O--M",
#                              "UMAR-SURS--DR008--P--M",
#                              "UMAR-SURS--DR008--Q--M",
#                              "UMAR-SURS--DR008--R--M",
#                              "UMAR-SURS--DR008--S--M",
#                              "UMAR-SURS--DR008--TOT--M")
#
# path <- "\\\\192.168.38.7\\public$\\Avtomatizacija\\umar-data\\DR\\umar_serije_podatki_DR.xlsx"
# # Read existing file
# existing <- readxl::read_excel(path)
#
# # Update/merge with new data
# updated <- existing |>
#   dplyr::rows_upsert(df_transposed, by = "period")
#
# # Write back
# openxlsx::write.xlsx(updated,
#                      file = path,
#                      sheetName = "M",
#                      overwrite = TRUE)
#
# ################################################################################
# one off - get archived data from sistat for table 0701098S
# cannot use the sursfetchr package, because surs removes the time dimension flag
# from archived data, so i cannot use the package. it's a one off anyway. here
# for posterity
# ################################################################################
# library(pxR)
#
# get_px_data <- function(id) {
#   checkmate::qassert(id, "S[5,11]")
#   id <- sub(".PX$", "", id)
#   id <- sub(".px$", "", id)
#   url <- paste0("https://pxweb.stat.si/SiStatData/Resources/PX/Databases/Data/", id, ".px")
#   l <- pxR::read.px(url,
#                     encoding = "CP1250",
#                     na.strings = c('"."', '".."', '"..."', '"...."')
#   )
#   list(l$DATA$value, l$VALUES, l$CODES)
# }
#
# l <- get_px_data("0701098S")
# df <- l[[1]]
#
# df <- df |>
#   dplyr::filter(MERITVE == "Bruto plača za mesec (EUR)") |>
#   dplyr::select(-MERITVE) |>
#   dplyr::rename(period = MESEC) |>
#   tidyr::pivot_wider(names_from = SKD.DEJAVNOST, values_from = value) |>
#   mutate(period = as.character(period)) |>
#   mutate(period = as.Date(paste0(substr(period, 1, 4), "-", substr(period, 6, 7), "-01")))
#
# colnames(df) <- c("period", "UMAR-SURS--DR009--A--M",
#                   "UMAR-SURS--DR009--B--M",
#                   "UMAR-SURS--DR009--C--M",
#                   "UMAR-SURS--DR009--D--M",
#                   "UMAR-SURS--DR009--E--M",
#                   "UMAR-SURS--DR009--F--M",
#                   "UMAR-SURS--DR009--G--M",
#                   "UMAR-SURS--DR009--H--M",
#                   "UMAR-SURS--DR009--I--M",
#                   "UMAR-SURS--DR009--J--M",
#                   "UMAR-SURS--DR009--K--M",
#                   "UMAR-SURS--DR009--L--M",
#                   "UMAR-SURS--DR009--M--M",
#                   "UMAR-SURS--DR009--N--M",
#                   "UMAR-SURS--DR009--O--M",
#                   "UMAR-SURS--DR009--P--M",
#                   "UMAR-SURS--DR009--Q--M",
#                   "UMAR-SURS--DR009--R--M",
#                   "UMAR-SURS--DR009--S--M",
#                   "UMAR-SURS--DR009--TOT--M")
#
# path <- "\\\\192.168.38.7\\public$\\Avtomatizacija\\umar-data\\DR\\umar_serije_podatki_DR.xlsx"
# # Read existing file
# existing <- readxl::read_excel(path)
#
# # Update/merge with new data
# updated <- existing |>
#   dplyr::rows_upsert(df, by = "period")
#
# # Write back
# openxlsx::write.xlsx(updated,
#                      file = path,
#                      sheetName = "M",
#                      overwrite = TRUE)
