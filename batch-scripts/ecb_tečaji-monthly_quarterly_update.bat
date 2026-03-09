@ECHO OFF
Rem this is for running the update_daily.R script for changes on the tečaji schema of the produktivnost database
"C:\Program Files\R\R-4.1.3\bin\x64\Rscript.exe"  -e "source('\\\\192.168.38.7\\public$\\Avtomatizacija\\umar_tecaji\\R\\update_monthly_quarterly.R')" > \\192.168.38.7\public$\Avtomatizacija\umar-automation-scripts\logs\tecaji-update_monthly_quarterly.Rout 2>&1
git config --global http.proxy http://proxy.gov.si:80
git add  logs\tecaji-update_monthly_quarterly.Rout
git commit -m "Umar data bot :robot: - monthly tecaji data platform update."
git push
CLS
