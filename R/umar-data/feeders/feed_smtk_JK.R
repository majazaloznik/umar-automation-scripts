################################################################################
# FEEDER: kratkoročni model (smtk) - nowcast BDP, četrtletni in mesečni
#   reads:  Users/AKuštrin/Dinamični_faktorski_model/smtk_YYYY_qN.xlsx (newest),
#           sheets Q and M
#   writes: umar-data/JK/umar_serije_podatki_JK.xlsx, sheets Q (JK002) and M (JK001)
#   owner:  JK (model: AK)
#
# The model is re-estimated, so past values are revised: rows are upserted,
# and the count reported is new periods only.
################################################################################
UmarDataBotR::log_msg("smtk | start")
src <- newest_file("\\\\192.168.38.7\\public$\\Users\\AKuštrin\\Dinamični_faktorski_model",
                   "^smtk_\\d{4}_q\\d\\.xlsx$")
target <- "\\\\192.168.38.7\\public$\\Avtomatizacija\\umar-data\\JK\\umar_serije_podatki_JK.xlsx"
UmarDataBotR::log_msg("smtk: using %s", basename(src))

#' Read one sheet of the smtk file: period + two series, renamed by position
#' @param sheet "Q" or "M"
#' @param codes the two series codes, in column order
#' @param parse function turning the period labels into Dates
read_smtk_sheet <- function(sheet, codes, parse) {
  df <- openxlsx2::read_xlsx(src, sheet = sheet)
  if (ncol(df) < 3) stop("sheet ", sheet, ": expected at least 3 columns, got ", ncol(df))
  df <- df[1:3]                         # extra columns are sometimes tacked on the end
  names(df) <- c("period", codes)
  df$period <- parse(df$period)
  if (anyNA(df$period)) stop("sheet ", sheet, ": unparseable period labels, e.g. ",
                             toString(utils::head(df$period[is.na(df$period)], 3)))
  df
}

# "1996 Q1" -> 1996-01-01
parse_quarter <- function(x) {
  ok <- grepl("^\\d{4} Q[1-4]$", x)
  y <- substr(x, 1, 4)
  m <- (as.integer(ifelse(ok, substr(x, 7, 7), "1")) - 1) * 3 + 1
  as.Date(ifelse(ok, sprintf("%s-%02d-01", y, m), NA_character_))
}
# "Jan 1996" -> 1996-01-01
parse_month <- function(x) lubridate::my(x, quiet = TRUE)

upsert_umar_data(read_smtk_sheet("Q", c("UMAR-SURS--JK002--V--Q", "UMAR-SURS--JK002--M--Q"),
                                 parse_quarter), target, sheet = "Q") +
  upsert_umar_data(read_smtk_sheet("M", c("UMAR-SURS--JK001--V--M", "UMAR-SURS--JK001--M--M"),
                                   parse_month), target, sheet = "M")
