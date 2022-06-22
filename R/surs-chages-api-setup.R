###############################################################################
## SURS DB change API reporting - Setup script
###############################################################################
#
#' This script was run at the start of this automation run. It was necessary
#' because a small number of changes were already reported and didn't have a
#' publication date (the publication date doesn't exist on the API, so going
#' forward we just infer it from the day they appear. But to start things
#' off, the existing changes had to be captured somehow. Do not rerun this
#' script unless you really know what you are doing. Cannot think of a reason
#' you would though, this is here just for transparency purposes.
#
###############################################################################
## Preliminaries
###############################################################################
library(dplyr)
devtools::install_github("majazaloznik/SURSfetchR")
library(SURSfetchR)

###############################################################################
## Reconstruct original table
###############################################################################
url <- paste0("https://pxweb.stat.si/SiStat/sl/Api/GetNotifications")

request <- httr::GET(url= url,
                     httr::content_type("application/json"))

parsed_request <- jsonlite::fromJSON(httr::content(request, as = "text"))

parsed_request[[3]] %>%
  tidyr::unnest(podrocja) %>%
  dplyr::left_join(parsed_request[[2]]) %>%
  dplyr::select(-dplyr::ends_with("Ang")) -> test_request

# this is used because regular ifelse fucks up the dates.
safe.ifelse <- function(cond, yes, no) structure(ifelse(cond, yes, no), class = class(yes))

# manually set the publication dates for the changes I know were made today
# and yesterday. The others I don't know when they were done, so they get the
# standard begining of time timestamp.
test_request %>%
  mutate(verjetniDatumObjave = safe.ifelse(grepl("1817607S", sporociloSlo) | grepl("05L2012S", sporociloSlo)
                                           | grepl("05J1027S", sporociloSlo),
                                           as.Date("2022-06-21", format = "%Y-%m-%d"),
                                           safe.ifelse(grepl("0861104S", sporociloSlo),
                                                       as.Date("2022-06-22", format = "%Y-%m-%d"),
                                                       as.Date("1970-01-01", format = "%Y-%m-%d")))) -> original

# pretend first day to initialise old_df
# first get changes
changes <- extract_new_changes(surs_change_api(), original)
# then add them to the old table
current <- update_change_table(original, changes)

###############################################################################
## Wrap up
###############################################################################
# save starting point table and current (which are right now the the same,
# but current will keep updating and diverge of course
saveRDS(original, here::here("data/original.rds"))
saveRDS(current, here::here("data/current.rds"))


