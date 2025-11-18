################################################################################
#'                       SKRIPTA OBDELAVO MF PODATKOV
#'
################################################################################
# devtools::install_github("majazaloznik/MFfetchR")
library(MFfetchR)
# prenos MF fajlov iz sharepointa na mrežo
################################################################################
get_balance_files <- function() {
  # po potrebi zamenjaj s Petrovim, če rabi on pognat?
  sync_path <- "C:/Users/mzaloznik/Ministrstvo za digitalno preobrazbo/APPrA - Odlaganje datotek"

  # Get most recent of each type
  result <- list(
    bjf = get_most_recent_file_from_pattern(sync_path,"^Export_4BJF.*\\.csv$"),
    ek = get_most_recent_file_from_pattern(sync_path,"^Export_EK.*\\.csv$"))

  cat("4BJF file:", basename(result$bjf),
      "modified:", format(file.mtime(result$bjf)), "\n")
  cat("EK file:", basename(result$ek),
      "modified:", format(file.mtime(result$ek)), "\n")

  return(result)
}

# get most recent
files <- get_balance_files()

file_destination <- "\\\\192.168.38.7\\public$\\Avtomatizacija\\umar-automation-scripts\\data\\mf_bilance\\new_data\\"

# Copy to working directory on network drive
file.copy(files$bjf, paste0(file_destination, basename(files$bjf)), overwrite = TRUE)
file.copy(files$ek, paste0(file_destination, basename(files$ek)), overwrite = TRUE)

# zajem in obdelava podatkov
################################################################################


# setup
con <- DBI::dbConnect(RPostgres::Postgres(),
                      dbname = "platform",
                      host = "localhost",
                      port = 5432,
                      user = "postgres",
                      password = Sys.getenv("PG_PG_PSW"),
                      client_encoding = "utf8")

folder <- "O:\\Avtomatizacija\\umar-automation-scripts\\data\\mf_bilance\\new_data\\"
file_path <- get_most_recent_file_from_pattern(folder,"^Export_4BJF.*\\.csv$")
blagajne <- c("KBJF", "OB", "DP", "ZZZS", "ZPIZ")
table_ids <- c(296:300)

# check if structure needs to be updated
if(check_for_extra_kontos(folder, con=con)) {
  purrr::map(blagajne, ~MF_import_structure_new(folder, table_name = .x, con = con,
                                                schema = "platform"))
}

# update data points
purrr::map(blagajne, ~MF_import_data_points_new(folder, table_name = .x, con = con,
                                                schema = "platform"))

# clean up vintages and add new hashes
purrr::map(table_ids, ~UMARimportR::vintage_cleanup(con, .x,
                                                    schema = "platform"))

DBI::dbExecute(con, "set search_path to views")
DBI::dbExecute(con, "REFRESH MATERIALIZED VIEW mat_latest_data_points")
DBI::dbExecute(con, "REFRESH MATERIALIZED VIEW mat_annual_yoy")
DBI::dbExecute(con, "REFRESH MATERIALIZED VIEW mat_quarterly_yoy")
DBI::dbExecute(con, "REFRESH MATERIALIZED VIEW mat_kumulative")





################################################################################
# email success
################################################################################

setwd("\\\\192.168.38.7\\public$\\Avtomatizacija\\umar-automation-scripts\\")
library(gmailr)
gm_auth_configure(path ="data/credentials.json")
gm_auth(email = "umar.data.bot@gmail.com", cache = ".secret")

email_list <- c("maja.zaloznik@gmail.com",
"lejla.fajic@gov.si",
"Barbara.Bratuz-Ferk@gov.si",
"Mojca.Koprivnikar@gov.si",
"janez.kusar@gov.si")

email_body <- "To je avtomatsko generirano sporo\u010dilo o posodobitvi podatkov blagajn javnega finaciranja na bazi.<br><br>Tvoj Umar Data Bot &#129302;"

text_msg <- gmailr::gm_mime() |>  gmailr::gm_bcc(email_list)  |>
  gmailr::gm_subject("Posodobitev podatkov javnih blagajn na bazi") |>
  gmailr::gm_html_body(email_body)
gmailr::gm_send_message(text_msg)
