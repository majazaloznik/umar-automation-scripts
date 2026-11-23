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

email_list_failure <- "maja.zaloznik@gmail.com"
max_stale_days <- 6   # weekend + holidays; longer gaps mean ICE has stopped updating

table_id <- function(code) {
  id <- UMARaccessR::sql_get_table_id_from_table_code(con, code)
  if (is.na(id)) stop("Table ", code, " not found", call. = FALSE)
  id
}

################################################################################
# run
################################################################################
result <- tryCatch({
  # raw contracts
  contracts <- ICEfetchR::ice_get_contracts()
  ICEfetchR::ICE_import_structure("GASOIL_RAW", con = con, contracts = contracts)
  raw_res <- ICEfetchR::ICE_import_data_points("GASOIL_RAW", con = con, contracts = contracts)

  pos_res <- NULL
  if (!is.null(raw_res)) {
    UMARimportR::vintage_cleanup(con, table_id = table_id("GASOIL_RAW"), schema = "platform")

    # derived positions: only change when raw data changes
    ICEfetchR::ICE_import_pos_structure("GASOIL_RAW", con = con)
    pos_res <- ICEfetchR::ICE_import_positions("GASOIL_RAW", con = con)
    if (!is.null(pos_res))
      UMARimportR::vintage_cleanup(con, table_id = table_id("GASOIL_POS"), schema = "platform")
  }

  # staleness check: always runs, since it exists for the no-new-data days
  last_date <- DBI::dbGetQuery(con, sprintf(
    "SELECT max(dp.period_id) AS last
       FROM platform.data_points dp
       JOIN platform.vintage v ON dp.vintage_id = v.id
       JOIN platform.series s  ON v.series_id = s.id
      WHERE s.table_id = %s", table_id("GASOIL_RAW")))$last
  if (as.numeric(Sys.Date() - as.Date(last_date)) > max_stale_days)
    stop("No new ICE data since ", last_date, call. = FALSE)

  # refresh views only if something was inserted
  if (!is.null(raw_res) || !is.null(pos_res))
    DBI::dbExecute(con, "REFRESH MATERIALIZED VIEW views.mat_latest_data_points")

  "ok"
}, error = function(e) e)

DBI::dbDisconnect(con)

if (inherits(result, "error")) {
  cat("Run FAILED:", conditionMessage(result), "\n")
  send_status_email(
    "NAPAKA: Posodobitev ICE terminskih cen NI uspela",
    paste0("Avtomatska posodobitev ICE terminskih cen (GASOIL_RAW, GASOIL_POS) je spodletela.",
           "<br><br>Napaka: ", conditionMessage(result),
           "<br><br>Tvoj Umar Data Bot &#129302;"),
    recipients = email_list_failure)
  quit(save = "no", status = 1)
} else {
  cat("Run OK, latest data:", last_date,
      if (is.null(raw_res)) "(no new data)" else "(new data imported)", "\n")
}
