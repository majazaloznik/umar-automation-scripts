################################################################################
# FEEDER: poraba elektrike po odjemnih skupinah
#   reads:  data/elektrika/Poraba el. po odjemnih skupinah*.xlsx (newest)
#   writes: umar-data/AK/umar_serije_podatki_AK.xlsx, sheet M
#   source: Anrej Kuštrin updates the input file
################################################################################
UmarDataBotR::log_msg("elektrika | start")

src <- newest_file("\\\\192.168.38.7\\public$\\Avtomatizacija\\umar-automation-scripts\\data\\elektrika",
                   "^Poraba el\\. po odjemnih skupinah.*\\.xlsx$")

UmarDataBotR::log_msg("elektrika: using %s", basename(src))

df <- readxl::read_excel(src, sheet = 1, .name_repair = "unique_quiet")

if (ncol(df) != 5) stop("expected 5 columns in ", basename(src), ", got ", ncol(df))

colnames(df) <- c("period", "UMAR-SODO--AK001--IND--M",
                  "UMAR-SODO--AK001--GOSP--M",
                  "UMAR-SODO--AK001--MPO--M",
                  "UMAR-SODO--AK001--SKUP--M")

upsert_umar_data(df, "\\\\192.168.38.7\\public$\\Avtomatizacija\\umar-data\\AK\\umar_serije_podatki_AK.xlsx")
