# script to render the single html indicator report file

# report outputs
time <- format(Sys.time(), "%d.%b%Y_%H%m")
outfile <- paste0("\\\\192.168.38.7\\public$\\Avtomatizacija\\data-platform\\indikatorji_test",
                  time, ".html")
origfile <- paste0("\\\\192.168.38.7\\public$\\Avtomatizacija\\data-platform\\indikatorji_test.html")

# # update html report
rmarkdown::render("\\\\192.168.38.7\\user_home\\mzaloznik\\analysis\\umar_master_report\\docs\\html_test.Rmd",
                  output_file = outfile)

# in case someone has the report open in a preview pane, this should prevent the code from failing.
tryCatch({
  # Try to rename the file
  file.rename(outfile, origfile)
}, warning = function(w) {
  # Handle warnings here
  print(paste("Warning: ", w))
}, error = function(e) {
  # Handle errors here
  print(paste("Error: ", e))
})
