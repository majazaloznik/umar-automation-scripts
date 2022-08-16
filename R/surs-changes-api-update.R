###############################################################################
## SURS DB change API reporting - Update script
###############################################################################
#
###############################################################################
## Preliminaries
###############################################################################
setwd("\\\\192.168.38.7\\public$\\Avtomatizacija\\umar-automation-scripts\\")
library(dplyr)
devtools::install_github("majazaloznik/SURSfetchR", dependencies = FALSE)
library(SURSfetchR)
library(gmailr)
options(gargle_oauth_email = TRUE)
gm_auth_configure(path ="data/credentials.json")
gm_auth(email = TRUE, cache = ".secret")

email_list <- c("maja.zaloznik@gmail.com",
                "maja.zaloznik@gov.si",
                "matevz.hribernik@gov.si",
                "katarina.ivas@gov.si",
                "janez.kusar@gov.si",
                "mojca.koprivnikar@gov.si",
                "bibijana.cirman-naglic@gov.si",
                "peter.wostner@gov.si",
                "dragica.suc@gov.si",
                "janja.pecar@gov.si",
                "andreja.kokalj@gov.si",
                "andrej.kustrin@gov.si",
                "marta.gregorcic@gov.si",
                "barbara.bratuz-ferk@gov.si",
                "polona.osrajnik@gov.si",
                "natasa.todorovic-jemec@gov.si",
                "tanja.celebic@gov.si",
                "mitja.perko@gov.si")

###############################################################################
##
###############################################################################

# get existing table as we know it
current <- readRDS("data/surs-changes-api-current.rds")

# get live data
live <- surs_change_api()

# check what changes have been published since current table was last updated
changes <- extract_new_changes(live, current)

# check what changes are due today
tomorrow <- extract_tomorrows_changes(live)

# prepare email body
body <- email_surs_changes_body(changes, tomorrow)

# update current table with newly found changes and give them today's date
current <- update_change_table(current, changes)

# email changes to list of recipients
email_surs_changes(body, recipient = email_list)

###############################################################################
## Wrap up
###############################################################################
# save these objects
saveRDS(current, "data/surs-changes-api-current.rds")
saveRDS(changes, "data/surs-changes-api-changes.rds")
saveRDS(tomorrow, "data/surs-changes-api-tomorrow.rds")

log_script_run()
