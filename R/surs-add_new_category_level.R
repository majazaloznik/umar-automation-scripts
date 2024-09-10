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


# add new category to existing table
# use this code to add a new category level to a table
# that is already in the database
code_no <- "1700102S"
level <- "12"
# i don't understand what i did here, i can't get the data from the table and then
# insert it there as well? so i need to insert them manually
# aAH, OK, this only works if the metadata is already public in the px file.
# so not if you are preparing this earlier
dim_levels <- prepare_dimension_levels_table(code_no, con)
dim_levels <- dim_levels %>%
  filter(level_value == level)
res <- list()
res[[6]] <- sql_function_call(con, "insert_new_dimension_levels",
                              as.list(dim_levels),
                              schema = "platform")

# this part then uses the correct levels in the db to prepare names of series
# to be added
series_table <- prepare_series_table(code_no, con)
series_table <- series_table %>%
  filter(grepl(paste0("--",level, "--"), series_code ))
res[[7]] <- sql_function_call(con, "insert_new_series",
                              unname(as.list(series_table)),
                              schema = "platform")

# and this one does the same for the series level table.
series_levels <- prepare_series_levels_table(code_no, con)
series_levels <- series_levels %>%
   group_by(series_id) %>%
  filter(any(value == level )) %>%
   ungroup()
res[[8]] <- sql_function_call(con, "insert_new_series_levels",
                              unname(as.list(series_levels)),
                              schema = "platform")
