@ECHO OFF
Rem this is for running the surs-changes-api-update script and saving the outputs. And then commiting and pushing the changes to github.
"C:\Program Files\R\R-4.1.3\bin\x64\Rscript.exe" -e "source('\\\\192.168.38.7\\public$\\Avtomatizacija\\umar-automation-scripts\\R\\surs-changes-api-update.R')" > \\192.168.38.7\public$\Avtomatizacija\umar-automation-scripts\logs\surs-changes-api-update.Rout 2>&1
pushd \\192.168.38.7\public$\Avtomatizacija\umar-automation-scripts\
git add data\surs-changes-api-changes.rds data\surs-changes-api-current.rds data\surs-changes-api-tomorrow.rds logs\log.rds logs\log_surs-changes-api-update.rds logs\surs-changes-api-update.Rout
git commit -m "Umar data bot :robot: - daily SURS change API update."
git push
CLS
