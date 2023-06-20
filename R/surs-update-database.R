#devtools::install_github("majazaloznik/SURSfetchR")
library(dplyr)
library(SURSfetchR)
# logging in as  maintainer
con <- DBI::dbConnect(RPostgres::Postgres(),
                      dbname = "platform",
                      host = "localhost",
                      port = 5432,
                      user = "majaz",
                      password = Sys.getenv("PG_MZ_PSW"),
                      client_encoding = "utf8")
# set schema search path
DBI::dbExecute(con, "set search_path to platform")

# # # check you're connected ok and see how many series are in the series table
# # tbl( con, "series") %>%
# #   summarise(n = n())
#
# get list of all surs tables
tbl(con, "table") %>%
  filter(source_id  == 1) |>
  select(code) |>
  collect() -> df
#
# update all SURS tables
system.time(purrr::walk(df$code, ~insert_new_data(.x, con)))


# # # insert table structures for a single matrix
# add_new_table("0301925S", con)
# # # insert data for single matrix
# out <- insert_new_data("0301925S", con)


# # # update series selection list
# df <- UMARaccessR::get_all_series_wtable_names(con)
# UMARaccessR::create_selection_excel(df, outfile = "O:\\Avtomatizacija\\data-platform\\seznam_serij")

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

