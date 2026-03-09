################################################################################
#'
#'   script for extracting new data from the
#'   O:\Avtomatizacija\umar-automation-scripts\data\brezposelni\MIN tabele
#'   folder with ZRSZ data on razlogi prijave v evidenco brezposelnih
#'
#'
#'
#'
################################################################################


#' the following code was used as a one off to import the archival series into
#' the database. here for posterity and if i ever need to add any similar
#' series.
# min6  <- ZRSZfetchR::extract_min6_series("O:\\Avtomatizacija\\umar-automation-scripts\\data\\brezposelni\\MIN tabele")
#
# min1 <- ZRSZfetchR::extract_min1_series("O:\\Avtomatizacija\\umar-automation-scripts\\data\\brezposelni\\MIN tabele")

# devtools::install_github("majazaloznik/ZRSZfetchR")

library(ZRSZfetchR)

# logging in as  maintainer
con <- DBI::dbConnect(RPostgres::Postgres(),
                      dbname = "platform",
                      host = "localhost",
                      port = 5432,
                      user = "postgres",
                      password = Sys.getenv("PG_PG_PSW"),
                      client_encoding = "utf8")

# upsert
x <- update_min6_series(con)
x <- update_min1_series(con)
