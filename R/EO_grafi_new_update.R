make_test_connection <- function() {
  con <- DBI::dbConnect(RPostgres::Postgres(),
                        dbname = "platform",
                        host = "192.168.38.21",
                        port = 5432,
                        user = "postgres",
                        password = Sys.getenv("PG_PG_PSW"))

}

con <- make_test_connection()

spec <- UMARvisualisR::read_chart_specs(
  "O:/Avtomatizacija/umar-automation-scripts/data/chart_specs/EO_charts.csv",
  "O:/Avtomatizacija/umar-automation-scripts/data/chart_specs/EO_chart_series.csv")
charts <- spec$charts
chart_series <- spec$chart_series

timestamp <- format(Sys.time(), "%Y-%m-%d_%H-%M-%S")

failed <- purrr::map(charts$chart_id, \(chart_id) tryCatch({
  chart <- charts[charts$chart_id == chart_id, ]
  rows  <- chart_series[chart_series$chart_id == chart_id, ]
  out   <- file.path("test", chart$publication)
  dir.create(out, recursive = TRUE, showWarnings = FALSE)
  wide <- build_chart_data(rows, con,
                           fetch_fn = fetch_fn_for_chart(chart, UMARaccessR::get_series_table,
                                                         min_obs = 1))

  purrr::walk(c("si", "en"), \(lang) {
    path <- file.path("G:/EO/EO slike avtomatizirane/EO slike png", paste0(chart_id, "_", lang, ".png"))
    chart_obj <- UMARvisualisR::prep_chart_from_spec(chart, rows, wide, lang)
    tryCatch(UMARvisualisR::save_chart(chart_obj, file = path),
             error = \(e) {
               message(basename(path), " could not be written, probably open — saving with timestamp")
               UMARvisualisR::save_chart(chart_obj, file = sub("\\.png$", paste0("_", timestamp, ".png"), path))
             })
  })

  path <- file.path("G:/EO/EO slike avtomatizirane/EO slike pdf/podatki", paste0(chart_id, ".xlsx"))
  wb <- openxlsx2::wb_workbook() |>
    openxlsx2::wb_add_worksheet("podatki") |>
    openxlsx2::wb_add_data_table(x = wide, table_name = "datatable") |>
    openxlsx2::wb_add_worksheet("spec") |>
    openxlsx2::wb_add_data(x = rows[order(rows$position), ])
  tryCatch(openxlsx2::wb_save(wb, path, overwrite = TRUE),
           error = \(e) {
             message(basename(path), " could not be written, probably open — saving with timestamp")
             openxlsx2::wb_save(wb, sub("\\.xlsx$", paste0("_", timestamp, ".xlsx"), path))
           })
  NULL
}, error = \(e) conditionMessage(e))) |>
  rlang::set_names(charts$chart_id) |>
  purrr::compact()

DBI::dbDisconnect(con)
if (length(failed)) stop(paste0(names(failed), ": ", failed, collapse = "\n"))
