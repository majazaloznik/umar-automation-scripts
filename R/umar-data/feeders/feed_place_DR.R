################################################################################
# FEEDER: masa plač in prejemniki plač po SKD
#   reads:  Users/DRogan/EO/Plače (nove SKD skupine).xlsx
#   writes: umar-data/DR/umar_serije_podatki_DR.xlsx, sheet M (DR012 masa, DR013 prejemniki)
################################################################################
UmarDataBotR::log_msg("pla\u010de | start")
src    <- "\\\\192.168.38.7\\public$\\Users\\DRogan\\EO\\Pla\u010de (nove SKD skupine).xlsx"
target <- "\\\\192.168.38.7\\public$\\Avtomatizacija\\umar-data\\DR\\umar_serije_podatki_DR.xlsx"
skd    <- c(LETTERS[1:20], "TOT")   # A..T + total
expected <- c("A KMETIJSTVO IN LOV, GOZDARSTVO, RIBIŠTVO",
              "B RUDARSTVO",
              "C PREDELOVALNE DEJAVNOSTI",
              "D OSKRBA Z ELEKTRIČNO ENERGIJO, PLINOM, PARO IN HLADNIM ZRAKOM",
              "E OSKRBA Z VODO, RAVNANJE Z ODPLAKAMI IN ODPADKI, SANIRANJE OKOLJA",
              "F GRADBENIŠTVO",
              "G TRGOVINA",
              "H PREVOZ IN SKLADIŠČENJE",
              "I NASTANITVENE IN GOSTINSKE DEJAVNOSTI",
              "J ZALOŽNIŠTVO, RADIODIFUZIJA TER PRODUKCIJA IN DISTRIBUCIJA VSEBIN",
              "K DEJAVNOSTI V ZVEZI S TELEKOMUNIKACIJAMI, RAČUNALNIŠKIM PROGRAMIRANJEM, SVETOVANJEM, RAČUNALNIŠKO INFRASTRUKTURO IN DRUGIMI INFORMACIJSKIMI STORITVAMI",
              "L FINANČNE IN ZAVAROVALNIŠKE DEJAVNOSTI",
              "M POSLOVANJE Z NEPREMIČNINAMI",
              "N STROKOVNE, ZNANSTVENE IN TEHNIČNE DEJAVNOSTI",
              "O DRUGE RAZNOVRSTNE POSLOVNE DEJAVNOSTI",
              "P DEJAVNOST JAVNE UPRAVE IN OBRAMBE, DEJAVNOST OBVEZNE SOCIALNE VARNOSTI",
              "Q IZOBRAŽEVANJE",
              "R ZDRAVSTVO IN SOCIALNO VARSTVO",
              "S KULTURNE, ŠPORTNE IN REKREACIJSKE DEJAVNOSTI",
              "T DRUGE DEJAVNOSTI",
              "SKUPAJ")

#' Read one block of Denis' sheet: `drop` = rows to remove below the date header
read_place_block <- function(drop, table) {
  df <- suppressWarnings(   # row 1 holds dates, parsed as numbers below on purpose
    readxl::read_excel(src, col_names = FALSE, .name_repair = "unique_quiet"))
  df <- df[-drop, ][1:22, ]
  df <- df[, !sapply(df, \(x) all(is.na(x[-1])))]
  names(df)[1] <- "category"
  names(df)[-1] <- format(as.Date(as.numeric(df[1, -1]), origin = "1899-12-30"), "%Y-%m-%d")
  df <- df[-1, ]
  stopifnot(identical(df$category, expected))
  if (nrow(df) != length(skd))
    stop(table, ": expected ", length(skd), " SKD rows, got ", nrow(df))
  out <- df |>
    tidyr::pivot_longer(-category, names_to = "period", values_to = "value") |>
    tidyr::pivot_wider(names_from = category, values_from = value) |>
    dplyr::mutate(period = as.Date(period))
  colnames(out) <- c("period", paste0("UMAR-SURS--", table, "--", skd, "--M"))
  out
}

upsert_umar_data(read_place_block(2, "DR012"), target) +
  upsert_umar_data(read_place_block(2:25, "DR013"), target)
