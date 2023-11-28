# add new category to existing table
# use this code to add a new category level to a table
# that is already in the database
code_no <- "0300230S"
level <- "P31_S1M"


dim_levels <- prepare_dimension_levels_table(code_no, con)
dim_levels <- dim_levels %>%
  filter(level_value == level)
res <- list()
res[[6]] <- sql_function_call(con, "insert_new_dimension_levels",
                              as.list(dim_levels),
                              schema = "platform")
series_table <- prepare_series_table(code_no, con)
series_table <- series_table %>%
  filter(grepl(level, series_code ))
res[[8]] <- sql_function_call(con, "insert_new_series",
                              unname(as.list(series_table)),
                              schema = "platform")
series_levels <- prepare_series_levels_table(code_no, con)
series_levels <- series_levels %>%
   group_by(series_id) %>%
  filter(any(value == level )) %>%
   ungroup()


res[[9]] <- sql_function_call(con, "insert_new_series_levels",
                              unname(as.list(series_levels)),
                              schema = "platform")
