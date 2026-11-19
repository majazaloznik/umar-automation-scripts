################################################################################
# FEEDER: finančna vzdržnost gospodinjstev
#   reads:  data/fin.vzdrznost/FinancialDistress*.xlsx (newest), sheet FinancialDistress
#   writes: umar-data/HM/umar_serije_podatki_HM.xlsx, sheet M
#   source: Helena Mervic updates the input file
################################################################################
UmarDataBotR::log_msg("finan\u010dna vzdr\u017enost | start")
src <- newest_file("\\\\192.168.38.7\\public$\\Avtomatizacija\\umar-automation-scripts\\data\\fin.vzdrznost",
                   "^FinancialDistress.*\\.xlsx$")
UmarDataBotR::log_msg("finan\u010dna vzdr\u017enost: using %s", basename(src))

df <- readxl::read_excel(src, sheet = "FinancialDistress", .name_repair = "unique_quiet")
if (ncol(df) != 9) stop("expected 9 columns in ", basename(src), ", got ", ncol(df))
colnames(df)[1:2] <- c("month", "year")

# insane fill to fix malformed original data...
year_filled <- rep(NA, nrow(df))
year_filled[!is.na(df$year)] <- df$year[!is.na(df$year)]

# Forward fill, incrementing year when month wraps from 12 to lower
for(i in which(!is.na(year_filled))) {
  current_year <- year_filled[i]
  current_month <- df$month[i]

  # Fill forward
  j <- i + 1
  while(j <= nrow(df) && is.na(year_filled[j])) {
    if(df$month[j] < df$month[j-1]) {  # month wrapped
      current_year <- current_year + 1
    }
    year_filled[j] <- current_year
    j <- j + 1
  }

  # Fill backward
  current_year <- year_filled[i]
  j <- i - 1
  while(j >= 1 && is.na(year_filled[j])) {
    if(df$month[j+1] < df$month[j]) {  # month wrapped (going backward)
      current_year <- current_year - 1
    }
    year_filled[j] <- current_year
    j <- j - 1
  }
}
df$year <- year_filled
df$date <- as.Date(paste(year_filled, df$month, "1", sep = "-"))

df <- df |> dplyr::select(-month, -year) |> dplyr::relocate(date)
colnames(df) <- c("period", paste0("SURS-UMAR--HM001--",
                                   c("FDT", "RD", "DS", "1Q", "2Q", "3Q", "4Q"), "--M"))

upsert_umar_data(df, "\\\\192.168.38.7\\public$\\Avtomatizacija\\umar-data\\HM\\umar_serije_podatki_HM.xlsx")
