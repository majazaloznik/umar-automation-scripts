# pak::pkg_install("majazaloznik/BSfetchR")
# pak::pkg_install("majazaloznik/UMARimportR")
# pak::pkg_install("majazaloznik/UMARaccessR")
library(dplyr)
library(BSfetchR)
cat("Run started:", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "\n")
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

con <- DBI::dbConnect(RPostgres::Postgres(),
                      dbname = "platform",
                      host = "localhost",
                      port = 5432,
                      user = "postgres",
                      password = Sys.getenv("PG_PG_PSW"),
                      client_encoding = "utf8")

update_tables <- UMARaccessR::sql_get_tables_from_source(con, "platform", 5, TRUE)

results <- purrr::map(update_tables$code,
                      ~BS_import_data_points(.x, con, schema = "platform"))

names(results) <- update_tables$code

# collect errors
errors <- purrr::keep(results, ~!is.null(.x$data_error)) |>
  purrr::imap_chr(~paste0("<b>", .y, "</b><br>Data error: ", .x$data_error))

if (length(errors) > 0) {
  send_status_email(
    subject = paste("BS import errors", Sys.Date()),
    body = paste(c("<h3>The following tables had errors:</h3>", errors),
                 collapse = "<br>"),
    recipients = email_list_failure
  )
}

table_ids <- c(220, 222, 233, 234, 235, 236, 237, 238, 239, 240, 241, 242, 243,
               244, 245, 246, 247, 248, 249, 401, 403, 404, 405, 610)
purrr::map(table_ids, ~UMARimportR::vintage_cleanup(con, .x, schema = "platform"))

DBI::dbExecute(con, "set search_path to views")
DBI::dbExecute(con, "REFRESH MATERIALIZED VIEW mat_latest_data_points")





# # delete most recent vintages for single table
# idz  <- UMARaccessR::sql_get_latest_vintages_for_table_id( 536, con)$vintage_id
# UMARimportR::delete_vintage(con, idz)

# # # # add single table, selecting levels
# BS_import_structure("i_32_6ms", con, "platform", all_levels = FALSE, keep_vintage = FALSE)
# #
#
# # # # update single table
# BS_import_data_points("i_32_6ms", con, "platform")
# UMARimportR::vintage_cleanup(con, 257, schema = "platform")

# if data point import failed but vintages were created, run
# UMARimportR::remove_empty_vintages(con, "platform")

# # remove specific table
# UMARimportR::delete_table(con, 219, "platform")

# # update series selection list
# df <- UMARaccessR::sql_get_all_series_wtable_names(con, "platform")
# UMARaccessR::create_selection_excel(df, outfile = "O:\\Avtomatizacija\\indikatorji_porocilo\\navodila_za_avtorje\\seznam_serij")
