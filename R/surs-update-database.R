# devtools::install_github("majazaloznik/SURSfetchR")
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

# # check you're connected ok and see how many series are in the series table
# tbl( con, "series") %>%
#   summarise(n = n()) %>%
#   pull()

# get list of all surs tables that are to be updated
tbl(con, "table") %>%
  filter(source_id  == 1 & update == TRUE) |>
  select(code) |>
  collect() -> df

# update all SURS tables
system.time(purrr::walk(df$code, ~insert_new_data(.x, con)))

# # # insert table structures for a single matrix
# add_new_table("0701015S", con)

# # insert data for single matrix
# out <- insert_new_data("0300230S", con)

# # update series selection list
# df <- UMARaccessR::get_all_series_wtable_names(con)
# UMARaccessR::create_selection_excel(df, outfile = "O:\\Avtomatizacija\\indikatorji_porocilo\\navodila_za_avtorje\\seznam_serij")

#
source("\\\\192.168.38.7\\public$\\Avtomatizacija\\umar-automation-scripts\\R\\update_indicator_report.R")


