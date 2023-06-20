# devtools::install_github("majazaloznik/ZRSZfetchR")
library(ZRSZfetchR)
schema = "platform"
# logging in as  maintainer
con <- DBI::dbConnect(RPostgres::Postgres(),
                      dbname = "platform",
                      host = "localhost",
                      port = 5432,
                      user = "majaz",
                      password = Sys.getenv("PG_MZ_PSW"),
                      client_encoding = "utf8")
# set schema search path
DBI::dbExecute(con, paste("set search_path to", schema))

# update BO table
zrsz_bo_script(con, schema)


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
