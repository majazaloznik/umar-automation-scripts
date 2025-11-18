# devtools::install_github("majazaloznik/DESEZONIRANJEfetchR")
library(DESEZONIRANJEfetchR)
library(gmailr)

# Gmail authentication
setwd("\\\\192.168.38.7\\public$\\Avtomatizacija\\umar-automation-scripts\\")
gm_auth_configure(path = "data/credentials.json")
gm_auth(email = "umar.data.bot@gmail.com", cache = ".secret")
email_list <- c("maja.zaloznik@gmail.com",
                "denis.rogan@gov.si",
                "andrej.kustrin@gov.si",
                "mojca.koprivnikar@gov.si")

# Setup logging
log_dir <- "logs"
if (!dir.exists(log_dir)) dir.create(log_dir)
log_file <- file.path(log_dir, paste0("DESEZ_import_log", Sys.Date(), ".txt"))

# Open connection and capture both stdout and stderr
log_con <- file(log_file, open = "wt")
sink(log_con, split = TRUE)
sink(log_con, type = "message")

tryCatch({
  con <- DBI::dbConnect(RPostgres::Postgres(),
                        dbname = "platform",
                        host = "localhost",
                        port = 5432,
                        user = "postgres",
                        password = Sys.getenv("PG_PG_PSW"),
                        client_encoding = "utf8")

  # Import data
  result <- DESEZ_import_data_points(con)

  if (!is.null(result)) {
    # Get table names and IDs
    config_table_names <- desezoniranje_config |>
      purrr::map_chr("table_name") |>
      unique()

    table_ids <- 319:322

    # Clean up vintages and add new hashes
    purrr::walk(table_ids, ~UMARimportR::vintage_cleanup(con, .x, schema = "platform"))

    # Update materialised view
    DBI::dbExecute(con, "SET search_path TO views")
    DBI::dbExecute(con, "REFRESH MATERIALIZED VIEW mat_latest_data_points")

    # Build email body
    tables_with_inserts <- result$datapoints |>
      purrr::keep(~.x$datapoints_inserted > 0)

    if (length(tables_with_inserts) > 0) {
      datapoints_text <- paste0(
        "<strong>Uvo\u017eeni podatki:</strong><br>",
        paste0(
          "&bull; ", names(tables_with_inserts), ": ",
          purrr::map_int(tables_with_inserts, ~.x$datapoints_inserted),
          " datapoint-ov",
          collapse = "<br>"
        ),
        "<br><br>"
      )

      # check if trg dela table needs to be updated
      trg_dela_tables_updated <- c("BP_Orig", "DA_Orig", "ILO_Orig", "RB_Orig")

      if (any(trg_dela_tables_updated %in% names(tables_with_inserts))) {
        base::message("Trg dela series updated, running trg dela za špegu script...")
        source("R/spegu_trg_dela_tabela.R")
      }

    } else {
      datapoints_text <- "<strong>Ni novih podatkov za uvoz.</strong><br><br>"
    }

    email_body <- paste0(
      "To je avtomatsko generirano sporo\u010dilo o posodobitvi podatkov iz mape DESEZONIRANJE.<br><br>",
      datapoints_text,
      "Podrobnosti najde\u0161 v prilo\u017eenem log fajlu.<br><br>",
      "Tvoj Umar Data Bot &#129302;"
    )

    base::message("Import completed successfully")

    DBI::dbDisconnect(con)
    sink(type = "message")
    sink()
    close(log_con)


    # Send success email with log attachment
    text_msg <- gmailr::gm_mime() |>
      gmailr::gm_bcc(email_list) |>
      gmailr::gm_subject("Posodobitev DESEZONIRANJE podatkov") |>
      gmailr::gm_html_body(email_body) |>
      gmailr::gm_attach_file(log_file)

    gmailr::gm_send_message(text_msg)

  } else {
    # No new data - just log, no email
    base::message("No new data to import")
    DBI::dbDisconnect(con)
    sink(type = "message")
    sink()
    close(log_con)

  }},
  error = function(e) {
    base::message("Import failed: ", e$message)
    sink(type = "message")
    sink()
    close(log_con)

    # Send failure email with log attachment
    email_body <- paste0(
      "To je avtomatsko generirano sporočilo o <strong>neuspešni</strong> posodobitvi podatkov DESEZONIRANJE.<br><br>",
      "<strong>Napaka:</strong> ", e$message, "<br><br>",
      "<strong>Čas:</strong> ", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "<br><br>",
      "Prosim preveri priloženo log datoteko za podrobnosti.<br><br>",
      "Tvoj Umar Data Bot &#129302;")

    text_msg <- gmailr::gm_mime() |>
      gmailr::gm_bcc("maja.zaloznik@gmail.com") |>
      gmailr::gm_subject("NAPAKA: Posodobitev DESEZONIRANJE podatkov") |>
      gmailr::gm_html_body(email_body) |>
      gmailr::gm_attach_file(log_file)

    gmailr::gm_send_message(text_msg)},
  finally = {
    # Ensure sinks are always closed
    if (sink.number() > 0) sink()
    if (sink.number("message") > 0) sink(type = "message")
  })

# vz <- UMARaccessR::sql_get_latest_vintages_for_table_id(322, con)$vintage_id
# UMARimportR::delete_vintage(con, vz)



# # FIRST TIME ONLY! OR RATHER THE STRUCTURE MIGHT NEED TO BE RUN AGAIN IF
# # MORE ELEMENTS ARE ADDED TO THE CONFIG LIST.
# # First, insert the source
# source_table <- prepare_source_table(con)
# UMARimportR::insert_new_source(con, source_table)
# then insert all the structures
# result <- DESEZ_import_structure(con)
#
# series <- dplyr::bind_rows(UMARaccessR::sql_get_series_from_table_id(319, con),
#                            UMARaccessR::sql_get_series_from_table_id(320, con),
#                            UMARaccessR::sql_get_series_from_table_id(321, con),
#                            UMARaccessR::sql_get_series_from_table_id(322, con),
#                            UMARaccessR::sql_get_series_from_table_id(324, con),
#                            UMARaccessR::sql_get_series_from_table_id(333, con),
#                            UMARaccessR::sql_get_series_from_table_id(337, con),
#                            UMARaccessR::sql_get_series_from_table_id(339, con),
#                            UMARaccessR::sql_get_series_from_table_id(342, con))
# openxlsx::write.xlsx(series, "desez_serije.xlsx")
