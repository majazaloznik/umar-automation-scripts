# umar-automation-scripts

Collection of R scripts for automating Umar data pipelines.

### SURS API reporting changes on the Si-Stat database

Scripts for automatically keeping track of the newly published changes on the Si-Stat database that SURS reports on their website, but has given us access to an API. Because the API doesn't have a publication date we keep track of the changes that have already been published (`data/surs-changes-api-current.rds`), the ones that were published today (`data/surs-changes-api-changes.rds`) and the changes that are due today (`data/surs-changes-api-today.rds`)

The setup script `R/surs-changes-api-setup.R` was run only once, to get the original list of change (`data/surs-changes-api-original.rds`).


The update script `R/surs-changes-api-update.R` sends emails to the listed recipients informing them of the newly published changes and the changes due tomorrow. To be sent at the end of bussiness hours every day. 


