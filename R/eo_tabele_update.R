cat("Run started:", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "\n")
# source all  files in tabele
path <- "\\\\192.168.38.7\\public$\\Avtomatizacija\\umar-automation-scripts\\R\\tabele"

list.files(path = path, pattern = ".+\\.R$", full.names = TRUE) |>
  sort() |>
  purrr::walk(source)
