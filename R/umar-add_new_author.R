# package
# devtools::install_github("majazaloznik/UMARfetchR", dependencies = FALSE)
library(UMARfetchR)

# setup
con <- DBI::dbConnect(RPostgres::Postgres(),
                      dbname = "platform",
                      host = "localhost",
                      port = 5432,
                      user = "majaz",
                      password = Sys.getenv("PG_MZ_PSW"),
                      client_encoding = "utf8")
DBI::dbExecute(con, "set search_path to platform")

data_location <- "O:/Avtomatizacija/umar-data"

# new author info
name = "DR"
initials = "DR"
email = "denis.rogan@gov.si"
schema = "platform"

# add new author
add_new_author(name,
               initials = initials,
               email = email,
               con = con,schema = schema,
               data_location = data_location)
