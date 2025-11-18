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

bdp_ea <-c("EUROSTAT--teina010--EA20--Q",
           "EUROSTAT--teina011--PCH_Q1_SCA--EA20--Q",
           "EUROSTAT--teina011--PCH_Q4_SCA--EA20--Q",
           "EUROSTAT--teina021--PCH_Q1_SCA--EA20--Q",
           "EUROSTAT--teina021--PCH_Q4_SCA--EA20--Q",
           "EUROSTAT--teina041--PCH_Q1_SCA--EA20--Q",
           "EUROSTAT--teina041--PCH_Q4_SCA--EA20--Q",
           "EUROSTAT--teina500--SCA--EA20--Q",
           "EUROSTAT--teina515--SCA--EA20--Q")

dolg_ea <- c("EUROSTAT--teina200--PC_GDP--EA20--A",
             "EUROSTAT--teina225--PC_GDP--EA20--A")

trade_balance_ea <- c("EUROSTAT--teiet215--EA20--M")

brezposelnost_ea <- c("EUROSTAT--teilm020--T--EA20--M")

zaposlenost_ea <- c("EUROSTAT--teilm310--B-S--EA20--Q",
                    "EUROSTAT--teina310--TOTAL--EA20--Q",
                    "EUROSTAT--teina306--TOTAL--EA20--Q",
                    "EUROSTAT--teilm120--B-S--EA20--Q",
                    "EUROSTAT--teilm130--B-S--EA20--Q")

ind_ea <- c("EUROSTAT--teiis010--PCH_M1_NSA--EA20--M",
            "EUROSTAT--teiis010--PCH_M12_NSA--EA20--M",
            "EUROSTAT--teiis011--PCH_M1_NSA--EA20--M",
            "EUROSTAT--teiis011--PCH_M12_NSA--EA20--M",
            "EUROSTAT--teiis080--PCH_M1_SCA--EA20--M",
            "EUROSTAT--teiis080--PCH_M12_CA--EA20--M",
            "EUROSTAT--teiis500--PCH_M1_SCA--EA20--M",
            "EUROSTAT--teiis500--PCH_M12_CA--EA20--M",
            "EUROSTAT--teiis240--PCH_M1_SCA--EA20--M",
            "EUROSTAT--teiis240--PCH_M12_CA--EA20--M",
            "EUROSTAT--sts_sepr_m--H-N_X_K--SCA--PCH_PRE--EA20--M",
            "EUROSTAT--sts_sepr_m--H-N_X_K--CA--PCH_SM--EA20--M")

houses_ea <- c("EUROSTAT--teicp270--PCH_Q1_NSA--EA--Q",
               "EUROSTAT--teicp270--PCH_Q4_NSA--EA--Q")

building_ea <- c("EUROSTAT--teiis550--PCH_M1_SCA--EA20--M",
                 "EUROSTAT--teiis550--PCH_M12_NSA--EA20--M")

sent_ea <- c("EUROSTAT--teibs010--EA20--M")

money_ea <- c("EUROSTAT--teimf040--EA--M",
              "EUROSTAT--teimf050--EA--M",
              "EUROSTAT--teimf200--USD--M")

print("start preparing Eurostat data from the database")

inflacija <- process_codes_vectorized(inflacija_ea, con)

bdp <- process_codes_vectorized(bdp_ea, con)

dolg <- process_codes_vectorized(dolg_ea,  con)

trade <- process_codes_vectorized(trade_balance_ea, con)

brezposelnost <- process_codes_vectorized(brezposelnost_ea, con)

zaposlenost <- process_codes_vectorized(zaposlenost_ea, con)

ind <- process_codes_vectorized(ind_ea, con)

houses <- process_codes_vectorized(houses_ea, con)

building <- process_codes_vectorized(building_ea, con)

sent <- process_codes_vectorized(sent_ea, con)

money <- process_codes_vectorized(money_ea, con)

print("Eurostat data from the database ready")


################################################################################
# write tto excel table
################################################################################
# load file
wb <- wb_load("\\\\192.168.38.7\\data$\\GT/GT_tabela_EA_auto_update.xlsx")
# clear cells to be updated
wb$clean_sheet(sheet = 1, dims = "C4:D67", styles = FALSE)
wb$clean_sheet(sheet = 1, dims = "F3:K67", styles = FALSE)

# inflacija
wb$add_data(sheet = "tabela-slo",  x = inflacija[2],  dims = "C3")
wb$add_data(sheet = "tabela-slo",  x = inflacija[3:8],  dims = "F3",  na.strings = ":")

# bdp
wb$add_data(sheet = "tabela-slo",  x = bdp[2],  dims = "C8", colNames = FALSE)
wb$add_data(sheet = "tabela-slo",  x = bdp[3:8],  dims = "F7",  na.strings = ":")

# dolg
wb$add_data(sheet = "tabela-slo",  x = dolg[2],  dims = "C19", colNames = FALSE)
wb$add_data(sheet = "tabela-slo",  x = dolg[3:8],  dims = "F18",  na.strings = ":")

# trade
wb$add_data(sheet = "tabela-slo",  x = trade[2],  dims = "C23", colNames = FALSE)
wb$add_data(sheet = "tabela-slo",  x = trade[3:8],  dims = "F22",  na.strings = ":")

# brezposelnost
wb$add_data(sheet = "tabela-slo",  x = brezposelnost[2],  dims = "C30", colNames = FALSE)
wb$add_data(sheet = "tabela-slo",  x = brezposelnost[3:8],  dims = "F29",  na.strings = ":")

# zaposlenost
wb$add_data(sheet = "tabela-slo",  x = zaposlenost[2],  dims = "C33", colNames = FALSE)
wb$add_data(sheet = "tabela-slo",  x = zaposlenost[3:8],  dims = "F32",  na.strings = ":")

# ind
wb$add_data(sheet = "tabela-slo",  x = ind[2],  dims = "C40", colNames = FALSE)
wb$add_data(sheet = "tabela-slo",  x = ind[3:8],  dims = "F39",  na.strings = ":")

# houses
wb$add_data(sheet = "tabela-slo",  x = houses[2],  dims = "C54", colNames = FALSE)
wb$add_data(sheet = "tabela-slo",  x = houses[3:8],  dims = "F53",  na.strings = ":")

# building
wb$add_data(sheet = "tabela-slo",  x = building[2],  dims = "C58", colNames = FALSE)
wb$add_data(sheet = "tabela-slo",  x = building[3:8],  dims = "F57",  na.strings = ":")

# sent
wb$add_data(sheet = "tabela-slo",  x = sent[2],  dims = "C62", colNames = FALSE)
wb$add_data(sheet = "tabela-slo",  x = sent[3:8],  dims = "F61",  na.strings = ":")

# money
wb$add_data(sheet = "tabela-slo",  x = money[2],  dims = "C65", colNames = FALSE)
wb$add_data(sheet = "tabela-slo",  x = money[3:8],  dims = "F64",  na.strings = ":")





# write back to file
wb_save(wb, "\\\\192.168.38.7\\data$\\GT/GT_tabela_EA_auto_update.xlsx")

# First create fallback filename with timestamp
timestamp <- format(Sys.time(), "%Y-%m-%d_%H-%M-%S")
original_path <- "\\\\192.168.38.7\\data$\\GT/GT_tabela_slovenska_auto_update.xlsx"
backup_path <- sub("\\.xlsx$", paste0("_", timestamp, ".xlsx"), original_path)

# Try to save, if fails, use backup path
tryCatch({
  wb_save(wb, original_path)
  message("File saved successfully to original location")
}, error = function(e) {
  message("Could not save to original file, likely opened by another user")
  message("Error was: ", e$message)
  message("Saving to backup location: ", backup_path)
  wb_save(wb, backup_path)
  message("File saved successfully to backup location")
})

print("Writing to file done, now emailing everyone.")


################################################################################
# email success
################################################################################

setwd("\\\\192.168.38.7\\public$\\Avtomatizacija\\umar-automation-scripts\\")
library(gmailr)
gm_auth_configure(path ="data/credentials.json")
gm_auth(email = "umar.data.bot@gmail.com", cache = ".secret")

email_list <- c("maja.zaloznik@gmail.com",
                "maja.zaloznik@gov.si",
                "Bibijana.Cirman-Naglic@gov.si",
                "urska.brodar@gov.si",
                "Tina.Nenadic-Senica@gov.si",
                "Laura.Juznik-Rotar@gov.si",
                "Barbara.Bratuz-Ferk@gov.si")

email_body <- "To je avtomatsko generirano sporo\u010dilo o posodobitvi podatkov v tabeli GT_tabela_slovenska_auto_update.<br><br>Tvoj Umar Data Bot &#129302;"

text_msg <- gmailr::gm_mime() %>% gmailr::gm_bcc(email_list) %>%
  gmailr::gm_subject("Posodobitev slovenske GT tabele") %>%
  gmailr::gm_html_body(email_body)
gmailr::gm_send_message(text_msg)
