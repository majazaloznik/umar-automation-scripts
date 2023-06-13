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

#
# # debugonce(insert_new_data)
# # out <- insert_new_data("0300260S", con)
#
# # # update series selection list
# df <- UMARaccessR::get_all_series_wtable_names(con)
# UMARaccessR::create_selection_excel(df, outfile = "O:\\Avtomatizacija\\data-platform\\seznam_serij")

# # update html report
rmarkdown::render("\\\\192.168.38.7\\user_home\\mzaloznik\\analysis\\umar_master_report\\docs\\html_test.Rmd",
                  output_file = "\\\\192.168.38.7\\public$\\Avtomatizacija\\data-platform\\indikatorji_test.html")

