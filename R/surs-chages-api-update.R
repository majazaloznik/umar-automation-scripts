###############################################################################
## SURS DB change API reporting - Update script
###############################################################################
#
###############################################################################
## Preliminaries
###############################################################################
library(dplyr)
devtools::install_github("majazaloznik/SURSfetchR")
library(SURSfetchR)
library(gmailr)
gm_auth_configure(path ="data/credentials.json")
gm_auth(email = TRUE, cache = ".secret")

###############################################################################
##
###############################################################################

# get current table as we know it
current <- readRDS( here::here("data/current.rds"))

# check what changes have happened since current table was last updated
changes <- extract_new_changes(surs_change_api(), current)

# update current table with newly found changes and give them today's date
current <- update_change_table(current, changes)

# email changes to list of recipients
email_surs_changes(changes, recipient = "maja.zaloznik@gov.si")

###############################################################################
## Wrap up
###############################################################################
# save starting point table and current (which are right now the the same,
# but current will keep updating and diverge of course
saveRDS(current, here::here("data/current.rds"))


