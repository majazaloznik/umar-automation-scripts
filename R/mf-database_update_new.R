################################################################################
#'                       SKRIPTA OBDELAVO MF PODATKOV
#'
################################################################################
cat("\nRun started:", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "\n")
# devtools::install_github("majazaloznik/MFfetchR")
library(MFfetchR)
Sys.setenv(LANG = "en_US.UTF-8")
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

# Check if files already exist at destination
bjf_dest <- paste0(file_destination, basename(files$bjf))
ek_dest <- paste0(file_destination, basename(files$ek))

copy_verified <- function(src, dest) {
  file.copy(src, dest, overwrite = TRUE)
  if (is.na(file.size(dest)) || file.size(dest) != file.size(src)) {
    stop("Copy failed or truncated: ", dest)
  }
}

dest_paths <- c(bjf_dest, ek_dest)
src_paths  <- c(files$bjf, files$ek)

already_synced <- (file.exists(dest_paths) & (file.size(dest_paths) == file.size(src_paths))) |>
  all()

if (already_synced) {
  cat("Files already at destination - no update needed\n")
  quit(save = "no")
}

Map(copy_verified, src_paths, dest_paths)


# zajem in obdelava podatkov
################################################################################
################################################################################
# setup
################################################################################
con <- DBI::dbConnect(RPostgres::Postgres(),
                      dbname = "platform",
                      host = "localhost",
                      port = 5432,
                      user = "postgres",
                      password = Sys.getenv("PG_PG_PSW"),
                      client_encoding = "utf8")

blagajne_ids <- c(KBJF = 296, OB = 297, DP = 298, ZZZS = 299, ZPIZ = 300)

send_status_email <- function(subject, body, recipients) {
  setwd("\\\\192.168.38.7\\public$\\Avtomatizacija\\umar-automation-scripts\\")
  gmailr::gm_auth_configure(path = "data/gmailr/credentials.json")
  gmailr::gm_auth(email = "umar.data.bot@gmail.com", cache = ".secret")
  gmailr::gm_mime() |>
    gmailr::gm_bcc(recipients) |>
    gmailr::gm_subject(subject) |>
    gmailr::gm_html_body(body) |>
    gmailr::gm_send_message()
}

email_list_success <- c("maja.zaloznik@gmail.com", "lejla.fajic@gov.si",
                        "Barbara.Bratuz-Ferk@gov.si", "Mojca.Koprivnikar@gov.si",
                        "janez.kusar@gov.si", "dejan.guduras@gov.si")
email_list_failure <- "maja.zaloznik@gmail.com"

result <- tryCatch({
  folder <- "\\\\192.168.38.7\\public$\\Avtomatizacija\\umar-automation-scripts\\data\\mf_bilance\\new_data\\"

  # check for structural changes
  purrr::walk(names(blagajne_ids), ~MF_import_structure_new(folder, table_name = .x, con = con,
                                                            schema = "platform"))
  # import new data points
  purrr::walk(names(blagajne_ids), ~MF_import_data_points_new(folder, table_name = .x, con = con,
                                                              schema = "platform"))
  # clean up vintages
  purrr::walk(blagajne_ids, ~UMARimportR::vintage_cleanup(con, .x, schema = "platform"))

  # refresh views.
  DBI::dbExecute(con, "set search_path to views")
  purrr::walk(c("mat_latest_data_points", "mat_annual_yoy", "mat_quarterly_yoy", "mat_kumulative"),
              ~DBI::dbExecute(con, paste("REFRESH MATERIALIZED VIEW", .x)))

  "ok"
}, error = function(e) e)

DBI::dbDisconnect(con)

if (inherits(result, "error")) {
  cat("Run FAILED:", conditionMessage(result), "\n")
  send_status_email(
    "NAPAKA: Posodobitev podatkov javnih blagajn NI uspela",
    paste0("Avtomatska posodobitev je spodletela.<br><br>Napaka: ", conditionMessage(result),
           "<br><br>Tvoj Umar Data Bot &#129302;"),
    recipients = email_list_failure)
  quit(save = "no", status = 1)
} else {
  send_status_email(
    "Posodobitev podatkov javnih blagajn na bazi",
    "To je avtomatsko generirano sporo\u010dilo o posodobitvi podatkov blagajn javnega finaciranja na bazi.<br><br>Tvoj Umar Data Bot &#129302;",
    recipients = email_list_success)
}
