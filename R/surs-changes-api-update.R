###############################################################################
## SURS DB change API reporting - Update script
###############################################################################
#
###############################################################################
## Preliminaries
###############################################################################
setwd("\\\\192.168.38.7\\public$\\Avtomatizacija\\umar-automation-scripts\\")
library(dplyr)
# devtools::install_github("majazaloznik/SURSfetchR", dependencies = FALSE)
library(SURSfetchR)
library(gmailr)
gm_auth_configure(path ="data/gmailr/credentials.json")
gm_auth(email = "umar.data.bot@gmail.com", cache = ".secret")

email_list <- c("maja.zaloznik@gmail.com",
                "maja.zaloznik@gov.si",
                "matevz.hribernik@gov.si",
                "janez.kusar@gov.si",
                "mojca.koprivnikar@gov.si",
                "peter.wostner@gov.si",
                "janja.pecar@gov.si",
                "andreja.kokalj@gov.si",
                "andrej.kustrin@gov.si",
                "marta.gregorcic@gov.si",
                "barbara.bratuz-ferk@gov.si",
                "polona.osrajnik@gov.si",
                "tanja.celebic@gov.si",
                "mitja.perko@gov.si",
                "tina.kocjancic@gov.si",
                "Tina.Nenadic-Senica@gov.si",
                "Lidija.Breskvar-Zaucer@gov.si")

###############################################################################
##
###############################################################################

# get existing table as we know it
current <- readRDS("data/surs_api/surs-changes-api-current.rds")

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
saveRDS(current, "data/surs_api/surs-changes-api-current.rds")
saveRDS(changes, "data/surs_api/surs-changes-api-changes.rds")
saveRDS(tomorrow, "data/surs_api/surs-changes-api-tomorrow.rds")

log_script_run()
