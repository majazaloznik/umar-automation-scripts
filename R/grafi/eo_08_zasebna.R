# source("\\\\192.168.38.7\\public$\\Avtomatizacija\\umar-automation-scripts\\R\\grafi\\00_setup.R")

filename <- "EO_08_zasebna_potrosnja_auto.xlsx"

################################################################################
message("\nPreparing data for the chart in ", filename)

codesQ <- c("SURS--0300230S--P31_S14_D--L--Y--Q")

codesM1 <- c("SURS--2001303S--2--2--47.19+47.4+47.5+47.6+47.7+47.8+47.9--M",
           "SURS--2001303S--2--2--47.11+47.2--M",
           "SURS--2001303S--2--2--G--M")

codesM2 <- c("SURS--2080006S--2--I--M",
           "SURS--2222101S--2--M")

codesM <- c(codesM1[1:2], codesM2)

# labels <- data.frame(
#   code = names(raw)[-1],  # exclude period_id
#   label_sl = c("Potrošnja gospodinjstev",
#                "Realni prihodek v trgovini z neživili",
#                "Realni prihodek v trgovini z živili in pijačami",
#                "Realni prihodek v gostinstvu",
#                "Prve registracije novih osebnih avtov"
# ),
#   label_en = c("Household consumption",
#                "Real turnover in the sale of non-food products",
#                "Real turnover in the sale of food and beverages",
#                "Real turnover in accomodation and food service",
#                "First time registrations of new passenger cars"))
# # Force UTF-8 encoding
# labels$label_sl <- enc2utf8(labels$label_sl)
# labels$label_en <- enc2utf8(labels$label_en)
#
# wb <- openxlsx2::wb_workbook() |>
#   openxlsx2::wb_add_worksheet("podatki") |>
#   openxlsx2::wb_add_data_table(x = raw, table_name = "datatable") |>
#   openxlsx2::wb_add_worksheet("sifrant") |>
#   openxlsx2::wb_add_data_table(sheet = "sifrant", x = labels, table_name = "labelstable") |>
#   openxlsx2::wb_set_col_widths(sheet = "sifrant", cols = 1:ncol(labels), widths = "auto") |>
#   openxlsx2::wb_save("G:\\EO\\EO slike avtomatizirane\\EO_08_zasebna_potrosnja_auto.xlsx")
#

################################################################################
# rebase q
rawQ <- process_codes_vectorized(codesQ, con) |>
  rebase_multiple(value_cols = codesQ,
                  base_year = 2010)


rawM1 <- process_codes_vectorized(codesM1, con)

# remove any rows where G doesn't have data yet.
last_valid <- max(which(!is.na(rawM1$`SURS--2001303S--2--2--G--M`)))
rawM1 <- rawM1[1:last_valid, ] |>
  select(-`SURS--2001303S--2--2--G--M`) |>
  rebase_multiple(value_cols = codesM1[1:2],
                  base_year = 2010)

rawM2 <- process_codes_vectorized(codesM2, con) |>
  rebase_multiple(value_cols = codesM2,
                  base_year = 2010)

# remove last car registration datapoint if the other three series don't have
# data for that period
rawM <- full_join(rawM1, rawM2, by = "period_id") |>
  arrange(period_id) |>
  (\(x) if(!is.na(x[nrow(x), 5]) && all(is.na(x[nrow(x), 2:4]))) x[-nrow(x), ] else x)()

allM <- rawM |>
  aggregate_to_quarters(codesM)

all <- full_join(rawQ, allM, by = "period_id") |>
  mutate(crta = 100,
         q_id = paste(substr(period_id, 5, 6),
                      substr(period_id, 3, 4))) |>
  arrange(period_id) |>
  filter(period_id > "2014Q4")

#' because we removed the SURS--2222101S--2--M datapoint if it was the only one for the
#' most recent month, we have three options: all four monthly series have a complete
#' final quarter, or they all have an incomplete final quarter with one or two months
#' worth of data. the following code prepares a note to this effect, covering all three
#' options, but also depending on whether the quarterly data is already available
#' for SURS--0300230S--P31_S14_D--L--Y--Q

months <- incomplete_quarters_note(rawM, codesM)

quarter <- paste0(substr(max(allM$period_id), 5,6), " ",
                 substr(max(allM$period_id), 1,4))

if(is.na(last(all$`SURS--0300230S--P31_S14_D--L--Y--Q`))){
  if (length(unique(months)) == 1) {
    if (length(months[[1]]) == 1 && is.na(months[[1]])) {
      note <- ""
    }  else if (length(unique(months)[[1]]) == 1){ # vsi isti mesec
      note <- paste0("Opomba: Podatek za ", quarter, " je vrednost za ", months[[1]], ".")
    }  else if (length(unique(months)[[1]]) == 2){ # vsi ista dva meseca
      note <- paste0("Opomba: Podatek za ", quarter, " je povprečje vrednosti za ",
                     months[[1]][1], " in ", months[[1]][2], ".")
    }
  }
} else {
  if (length(unique(months)) == 1) {
    if (length(months[[1]]) == 1 && is.na(months[[1]])) {
      note <- ""
    }  else if (length(unique(months)[[1]]) == 1){ # vsi isti mesec
      note <- paste0("Opomba: Podatek za ", quarter, " je vrednost za ", months[[1]],
                     ", razen pri potrošnji gospodinjstev.")
    }  else if (length(unique(months)[[1]]) == 2){ # vsi ista dva meseca
      note <- paste0("Opomba: Podatek za ", quarter, " je povprečje vrednosti za ",
                     months[[1]][1], " in ", months[[1]][2],
                     ", razen pri potrošnji gospodinjstev.")
    }
  }
}

note_slo <- paste("Vir: SURS, preračuni UMAR.", note)
note_slo<- enc2utf8(note_slo)
months <- incomplete_quarters_note(rawM, codesM, lang = "en")

if(is.na(last(all$`SURS--0300230S--P31_S14_D--L--Y--Q`))){
  if (length(unique(months)) == 1) {
    if (length(months[[1]]) == 1 && is.na(months[[1]])) {
      note <- ""
    }  else if (length(unique(months)[[1]]) == 1){ # vsi isti mesec
      note <- paste0("Note: The ", quarter, " turnover figure is the value for ", months[[1]], ".")
    }  else if (length(unique(months)[[1]]) == 2){ # vsi ista dva meseca
      note <- paste0("Note: The ", quarter, " turnover figure is the average value for ",
                     months[[1]][1], " and ", months[[1]][2],
                     ", except for household consumption.")
    }
  }
} else {
  if (length(unique(months)) == 1) {
    if (length(unique(months)) == 1) {
      if (length(months[[1]]) == 1 && is.na(months[[1]])) {
        note <- ""
      }  else if (length(unique(months)[[1]]) == 1){ # vsi isti mesec
        note <- paste0("Note: The ", quarter, " turnover figure is the value for ", months[[1]],
                       ", except for household consumption.")
      }  else if (length(unique(months)[[1]]) == 2){ # vsi ista dva meseca
        note <- paste0("Note: The ", quarter, " turnover figure is the average value for ",
                       months[[1]][1], " and ", months[[1]][2],
                       ", except for household consumption.")
      }
    }
  }
}

note_angl <- paste("Source: SURS, calculations by UMAR.", note)

wb <- load_wb_eo(filename)

wb <- write_wb(wb, all)

wb <- wb |>
  openxlsx2::wb_add_data(sheet = "graf slo", x = note_slo, dims = "A24") |>
  openxlsx2::wb_add_data(sheet = "graf angl", x = note_angl, dims = "A24")

try_save_eo(filename)
