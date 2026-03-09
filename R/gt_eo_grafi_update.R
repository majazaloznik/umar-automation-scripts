
# source all gt_ files in grafi
path <- "\\\\192.168.38.7\\public$\\Avtomatizacija\\umar-automation-scripts\\R\\grafi"

list.files(path = path, pattern = ".+\\.R$", full.names = TRUE) |>
  sort() |>
  purrr::walk(\(f) {
    tryCatch(
      source(f),
      error = \(e) message("\n***Failed:*** ", basename(f), " - ", e$message, "***Failed!***\n")
    )
  })
