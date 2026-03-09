# source("\\\\192.168.38.7\\public$\\Avtomatizacija\\umar-automation-scripts\\R\\grafi\\00_setup.R")

filename <- "GT_01_Q-BDP_auto.xlsx"

################################################################################
message("\nPreparing data for the chart in ", filename)

codes <- c("SURS--0300230S--B1GQ--GO4--N--Q",
           "SURS--0300230S--P3_S13--GO4--N--Q",
           "SURS--0300230S--P31_S14_D--GO4--N--Q",
           "SURS--0300230S--P51G--GO4--N--Q",
           "SURS--0300230S--P52--GO4--N--Q",
           "SURS--0300230S--P6--GO4--N--Q",
           "SURS--0300230S--P7--GO4--N--Q",
           "SURS--0300230S--P53--GO4--N--Q")


################################################################################
raw <- process_codes_vectorized(codes, con) |>
  mutate(period_date = lubridate::yq(period_id)) |>
  filter(substr(period_id, 1, 4) > 2021) |>
  mutate(`SURS--0300230S--P3_P5COMBINED--GO4--N--Q` =
           `SURS--0300230S--P52--GO4--N--Q` +
           `SURS--0300230S--P53--GO4--N--Q`,
         `SURS--0300230S--P7--GO4--N--Q` = -`SURS--0300230S--P7--GO4--N--Q`,
         crta = 0,
         .keep = "unused",
         period_id = paste(substr(period_id, 5,6), substr(period_id, 3,4))) |>
  select(-period_date)

# labels <- data.frame(
#   code = names(raw)[-1],  # exclude period_id
#   label_sl = c("BDP, realna rast", "Državna potrošnja", "Zasebna potrošnja",
#                "Bruto investicije v o.s.",
#                "Izvoz proizvodov in storitev",
#                "Uvoz proizvodov in storitev",
#                "Spremembe zalog in v.p"),
#   label_en = c("GDP real growth",
#                "Government consumption", "Private consumption",
#                "Gross fixed capital formation",
#                "Exports of goods and services",
#                "Imports of goods and services",
#                "Changes in inventories and val."))
# # Force UTF-8 encoding
# labels$label_sl <- enc2utf8(labels$label_sl)
# labels$label_en <- enc2utf8(labels$label_en)

wb <- load_wb(filename)

wb <- write_wb(wb, raw)

try_save(filename)

