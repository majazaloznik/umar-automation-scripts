# ---- configuration: the only place output formats are chosen ---------------
formats   <- c("svg", "png", "pdf")                       # any of "pdf", "png", "svg", "emf"
languages <- c("si", "en")

chart_dir <- function(fmt) file.path("G:/GT/SLIKE", paste0("GT slike ", fmt))
data_dir  <- "G:/GT/SLIKE/GT slike pdf/podatki"

spec_dir  <- "O:/Avtomatizacija/umar-automation-scripts/data/chart_specs"
# ---------------------------------------------------------------------------

con <- make_test_connection()

spec <- UMARvisualisR::read_chart_specs(
  file.path(spec_dir, "GT_charts.csv"),
  file.path(spec_dir, "GT_chart_series.csv"))
charts       <- spec$charts
chart_series <- spec$chart_series

timestamp <- format(Sys.time(), "%Y-%m-%d_%H-%M-%S")

purrr::walk(formats, \(fmt) dir.create(chart_dir(fmt), recursive = TRUE, showWarnings = FALSE))
dir.create(data_dir, recursive = TRUE, showWarnings = FALSE)

failed <- purrr::map(charts$chart_id, \(chart_id) tryCatch({
  chart <- charts[charts$chart_id == chart_id, ]
  rows  <- chart_series[chart_series$chart_id == chart_id, ]
  wide  <- UMARvisualisR::build_chart_data(rows, con,
                                           fetch_fn = UMARaccessR::get_series_table)

  purrr::walk(languages, \(lang) {
    chart_obj <- UMARvisualisR::prep_chart_from_spec(chart, rows, wide, lang)
    purrr::walk(formats, \(fmt) {
      UMARvisualisR::save_chart(
        chart_obj,
        filename = file.path(chart_dir(fmt), paste0(chart_id, "_", lang, ".", fmt)))
    })
  })

  path <- file.path(data_dir, paste0(chart_id, ".xlsx"))
  wb <- openxlsx2::wb_workbook() |>
    openxlsx2::wb_add_worksheet("podatki") |>
    openxlsx2::wb_add_data_table(x = wide, table_name = "datatable") |>
    openxlsx2::wb_add_worksheet("spec") |>
    openxlsx2::wb_add_data(x = rows[order(rows$position), ])
  tryCatch(openxlsx2::wb_save(wb, path, overwrite = TRUE),
           error = \(e) {
             message(basename(path), " could not be written, probably open - saving with timestamp")
             openxlsx2::wb_save(wb, sub("\\.xlsx$", paste0("_", timestamp, ".xlsx"), path))
           })
  NULL
}, error = \(e) conditionMessage(e))) |>
  rlang::set_names(charts$chart_id) |>
  purrr::compact()

DBI::dbDisconnect(con)
if (length(failed)) stop(paste0(names(failed), ": ", failed, collapse = "\n"))
