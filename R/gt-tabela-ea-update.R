library(UMARaccessR)
library(purrr)
library(dplyr)
library(lubridate)
library(tidyr)
library(openxlsx2)

################################################################################
# Data series from the platform database
################################################################################
# connect to database
con <- DBI::dbConnect(RPostgres::Postgres(),
                      dbname = "platform",
                      host = "192.168.38.21",
                      port = 5432,
                      user = "majaz",
                      password = Sys.getenv("PG_MZ_PSW"),
                      client_encoding = "utf8")
# set schema search path
DBI::dbExecute(con, "set search_path to platform")



process_codes_vectorized <- function(codes, con, schema = "platform", stotka = FALSE) {
  # Process all codes at once using map
  results <- codes %>%
    map(~{
      vin <- sql_get_vintage_from_series_code(con, .x, schema = schema)
      list(
        df = sql_get_data_points_from_vintage(con, vin, schema) %>%
          rename(!!.x := value),
        date = sql_get_date_published_from_vintage(vin, con, schema)
      )
    })
  # Extract all dates
  dates <- map(results, "date") |>
    unlist() |>
    as_datetime(tz = "CET") |>
    as_date()

  # Extract and combine all dataframes
  combined_df <- results |>
    map("df") |>
    reduce(full_join, by = "period_id") |>
    arrange(period_id) |>
    slice_tail(n = 6) |>
    mutate(period_id = sub("Q", " Q", period_id),
           period_id = sub("M0", "M", period_id),
           period_id = sub("M", " m ", period_id)) |>
    pivot_longer(-period_id, names_to = "code", values_to = "value") |>
    ({if(stotka) \(x) x |> mutate(value = value - 100) else \(x) x})() |>
    pivot_wider(names_from = "period_id", values_from = "value") |>
    mutate(Zadnja = as.Date(dates)) |>
    relocate(Zadnja, .after = code)

}

# setup series that we need for different sections
inflacija_ea <-  c("EUROSTAT--teicp000--PCH_M1--EA--M",
                   "EUROSTAT--teicp000--PCH_M12--EA--M")

bdp_ea <-c("EUROSTAT--teina010--EA21--Q", #
           "EUROSTAT--teina011--PCH_Q1_SCA--EA21--Q",#
           "EUROSTAT--teina011--PCH_Q4_SCA--EA21--Q",#
           "EUROSTAT--teina021--PCH_Q1_SCA--EA21--Q",#
           "EUROSTAT--teina021--PCH_Q4_SCA--EA21--Q",#
           "EUROSTAT--teina041--PCH_Q1_SCA--EA21--Q",#
           "EUROSTAT--teina041--PCH_Q4_SCA--EA21--Q",#
           "EUROSTAT--teina500--SCA--EA20--Q", # no new series for EA21 yet
           "EUROSTAT--teina515--SCA--EA20--Q")# no new series for EA21 yet

dolg_ea <- c("EUROSTAT--teina200--PC_GDP--EA20--A",# no new series for EA21 yet
             "EUROSTAT--teina225--PC_GDP--EA20--A")# no new series for EA21 yet

trade_balance_ea <- c("EUROSTAT--teiet215--EA20--M") # no new series EA21

bps_ecb <- c("ECB--BPS--N--I9--W1--S1--S1--T--B--CA--_Z--_Z--_Z--EUR_R_B1GQ--_T--_X--N--ALL--Q",
             "ECB--BPS--N--I9--W1--S1--S1--LE--N--FA--_T--F--_Z--EUR--_T--_X--N--ALL--Q")

brezposelnost_ea <- c("EUROSTAT--teilm020--T--EA21--M") #

zaposlenost_ea <- c("EUROSTAT--teilm310--B-S--EA21--Q", #
                    "EUROSTAT--teina310--TOTAL--EA21--Q", #
                    "EUROSTAT--teina306--TOTAL--EA21--Q",#
                    "EUROSTAT--teilm120--B-S--EA21--Q", #
                    "EUROSTAT--teilm130--B-S--EA21--Q") #

ind_ea <- c("EUROSTAT--teiis010--PCH_M1_NSA--EA21--M", #
            "EUROSTAT--teiis010--PCH_M12_NSA--EA21--M", #
            "EUROSTAT--teiis011--PCH_M1_NSA--EA21--M", #
            "EUROSTAT--teiis011--PCH_M12_NSA--EA21--M", #
            "EUROSTAT--teiis080--PCH_M1_SCA--EA21--M", #
            "EUROSTAT--teiis080--PCH_M12_CA--EA21--M", #
            "EUROSTAT--teiis500--PCH_M1_SCA--EA21--M", #
            "EUROSTAT--teiis500--PCH_M12_CA--EA21--M", #
            "EUROSTAT--teiis240--PCH_M1_SCA--EA21--M", #
            "EUROSTAT--teiis240--PCH_M12_CA--EA21--M", #
            "EUROSTAT--sts_sepr_m--H-N_X_K--SCA--PCH_PRE--EA21--M", #
            "EUROSTAT--sts_sepr_m--H-N_X_K--CA--PCH_SM--EA21--M") #

houses_ea <- c("EUROSTAT--teicp270--PCH_Q1_NSA--EA--Q",
               "EUROSTAT--teicp270--PCH_Q4_NSA--EA--Q")

building_ea <- c("EUROSTAT--teiis550--PCH_M1_SCA--EA21--M", #
                 "EUROSTAT--teiis550--PCH_M12_NSA--EA21--M") #

sent_ea <- c("EUROSTAT--teibs010--EA21--M")

money_ea <- c("EUROSTAT--teimf040--EA--M",
              "EUROSTAT--teimf050--EA--M",
              "EUROSTAT--teimf200--USD--M")

print("start preparing Eurostat data from the database")

inflacija <- process_codes_vectorized(inflacija_ea, con)
print(inflacija[,c(1,8)])

bdp <- process_codes_vectorized(bdp_ea, con)
print(bdp[,c(1,8)])

dolg <- process_codes_vectorized(dolg_ea,  con)
print(dolg[,c(1,8)])

trade <- process_codes_vectorized(trade_balance_ea, con)
print(trade[,c(1,8)])

bps <- process_codes_vectorized(bps_ecb, con)
print(bps[,c(1,8)])

brezposelnost <- process_codes_vectorized(brezposelnost_ea, con)
print(brezposelnost[,c(1,8)])

zaposlenost <- process_codes_vectorized(zaposlenost_ea, con)
print(zaposlenost[,c(1,8)])

ind <- process_codes_vectorized(ind_ea, con)
print(ind[,c(1,8)])

houses <- process_codes_vectorized(houses_ea, con)
print(houses[,c(1,8)])

building <- process_codes_vectorized(building_ea, con)
print(building[,c(1,8)])

sent <- process_codes_vectorized(sent_ea, con)
print(sent[,c(1,8)])

money <- process_codes_vectorized(money_ea, con)
print(money[,c(1,8)])

print("Eurostat data from the database ready")

inflacija <- sent[0,] |>
  bind_rows(inflacija) |>
  select(any_of(names(sent)))

trade <- sent[0,] |>
  bind_rows(trade) |>
  select(any_of(names(sent)))

brezposelnost <- sent[0,] |>
  bind_rows(brezposelnost) |>
  select(any_of(names(sent)))

ind <- sent[0,] |>
  bind_rows(ind) |>
  select(any_of(names(sent)))

building <- sent[0,] |>
  bind_rows(building) |>
  select(any_of(names(sent)))

money <- sent[0,] |>
  bind_rows(money) |>
  select(any_of(names(sent)))


# Find which df has the most recent period
get_period_cols <- function(df) {
  names(df)[!names(df) %in% c("code", "Zadnja")]
}

all_periods <- list(
  bdp = get_period_cols(bdp),
  bps = get_period_cols(bps),
  zaposlenost = get_period_cols(zaposlenost),
  houses = get_period_cols(houses)
)

# Get the df with most recent data (last 6 periods lexicographically)
last_periods <- sapply(all_periods, tail, 1)
ref_df_name <- names(last_periods)[which.max(match(last_periods, sort(unique(unlist(all_periods)))))]
ref_cols <- c("code", "Zadnja", all_periods[[ref_df_name]])

# Align all dfs - adds missing columns as NA
align_all <- function(df, target_cols) {
  missing_cols <- setdiff(target_cols, names(df))
  df[missing_cols] <- NA
  df |> dplyr::select(dplyr::all_of(target_cols))
}

bdp <- align_all(bdp, ref_cols)
bps <- align_all(bps, ref_cols)
zaposlenost <- align_all(zaposlenost, ref_cols)
houses <- align_all(houses, ref_cols)

################################################################################
# write tto excel table
################################################################################
# load file
file_configs <- list(
  list(
    path = "\\\\192.168.38.7\\data$\\GT/GT_tabele_ZA WORD_ne spreminjaj/GT_tabela_EA_angl.xlsx",
    lang = "en",
    update_text = "Last updated:"
  ),
  list(
    path = "\\\\192.168.38.7\\data$\\GT/GT_tabele_ZA WORD_ne spreminjaj/GT_tabela_EA_slo.xlsx",
    lang = "sl",
    update_text = "Zadnja posodobitev:"
  )
)

purrr::walk(file_configs, \(config) {
  wb <- openxlsx2::wb_load(config$path)
  # clear cells to be updated
  wb$clean_sheet(sheet = 1, dims = "B2:B54", styles = FALSE)
  wb$clean_sheet(sheet = 1, dims = "D2:I54", styles = FALSE)

  # inflacija
  wb$add_data(sheet = "tabela",  x = inflacija[2],  dims = "B2", colNames = FALSE)
  wb$add_data(sheet = "tabela",  x = inflacija[3:8],  dims = "D1",  na.strings = ":")

  # bdp
  wb$add_data(sheet = "tabela",  x = bdp[2],  dims = "B5", colNames = FALSE)
  wb$add_data(sheet = "tabela",  x = bdp[3:8],  dims = "D4",  na.strings = ":")

  # dolg
  wb$add_data(sheet = "tabela",  x = dolg[2],  dims = "B15", colNames = FALSE)
  wb$add_data(sheet = "tabela",  x = dolg[3:8],  dims = "D14",  na.strings = ":")

  # trade
  wb$add_data(sheet = "tabela",  x = trade[2],  dims = "B18", colNames = FALSE)
  wb$add_data(sheet = "tabela",  x = trade[3:8],  dims = "D17",  na.strings = ":")

  # bps
  wb$add_data(sheet = "tabela",  x = bps[2],  dims = "B20", colNames = FALSE)
  wb$add_data(sheet = "tabela",  x = bps[3:8],  dims = "D19",  na.strings = ":")


  # brezposelnost
  wb$add_data(sheet = "tabela",  x = brezposelnost[2],  dims = "B23", colNames = FALSE)
  wb$add_data(sheet = "tabela",  x = brezposelnost[3:8],  dims = "D22",  na.strings = ":")

  # zaposlenost
  wb$add_data(sheet = "tabela",  x = zaposlenost[2],  dims = "B25", colNames = FALSE)
  wb$add_data(sheet = "tabela",  x = zaposlenost[3:8],  dims = "D24",  na.strings = ":")

  # ind
  wb$add_data(sheet = "tabela",  x = ind[2],  dims = "B31", colNames = FALSE)
  wb$add_data(sheet = "tabela",  x = ind[3:8],  dims = "D30",  na.strings = ":")

  # houses
  wb$add_data(sheet = "tabela",  x = houses[2],  dims = "B44", colNames = FALSE)
  wb$add_data(sheet = "tabela",  x = houses[3:8],  dims = "D43",  na.strings = ":")

  # building
  wb$add_data(sheet = "tabela",  x = building[2],  dims = "B47", colNames = FALSE)
  wb$add_data(sheet = "tabela",  x = building[3:8],  dims = "D46",  na.strings = ":")

  # sent
  wb$add_data(sheet = "tabela",  x = sent[2],  dims = "B50", colNames = FALSE)
  wb$add_data(sheet = "tabela",  x = sent[3:8],  dims = "D49",  na.strings = ":")

  # money
  wb$add_data(sheet = "tabela",  x = money[2],  dims = "B52", colNames = FALSE)
  wb$add_data(sheet = "tabela",  x = money[3:8],  dims = "D51",  na.strings = ":")

  wb$add_data(sheet = "tabela", dims = "A55",
              x = paste(config$update_text, format(Sys.Date(), "%d/%m/%Y")))


  # # write back to file
  # wb_save(wb, config$path)

  # First create fallback filename with timestamp
  timestamp <- format(Sys.time(), "%Y-%m-%d_%H-%M-%S")

  backup_path <- sub("\\.xlsx$", paste0("_", timestamp, ".xlsx"), config$path)

  # Try to save, if fails, use backup path
  tryCatch({
    wb_save(wb, config$path)
    message("File saved successfully to original location")
  }, error = function(e) {
    message("Could not save to original file, likely opened by another user")
    message("Error was: ", e$message)
    message("Saving to backup location: ", backup_path)
    wb_save(wb, backup_path)
    message("File saved successfully to backup location")
  })
})

print("Writing to file done, now emailing everyone.")


################################################################################
# email success
################################################################################

setwd("\\\\192.168.38.7\\public$\\Avtomatizacija\\umar-automation-scripts\\")
library(gmailr)
gm_auth_configure(path ="data/gmailr/credentials.json")
gm_auth(email = "umar.data.bot@gmail.com", cache = ".secret")

email_list <- c("maja.zaloznik@gmail.com",
                "maja.zaloznik@gov.si",
                "urska.brodar@gov.si",
                "Tina.Nenadic-Senica@gov.si",
                "Barbara.Bratuz-Ferk@gov.si")

email_body <- "To je avtomatsko generirano sporo\u010dilo o posodobitvi podatkov v tabelah GT_tabela_EA.<br><br>Tvoj Umar Data Bot &#129302;"

text_msg <- gmailr::gm_mime() %>% gmailr::gm_bcc(email_list) %>%
  gmailr::gm_subject("Posodobitev GT EA tabel") %>%
  gmailr::gm_html_body(email_body)
gmailr::gm_send_message(text_msg)
