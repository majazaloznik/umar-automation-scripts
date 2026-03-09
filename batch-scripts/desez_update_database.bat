@ECHO OFF
Rem this is for reading desezoniranje data and parsing into database:
  "C:\Program Files\R\R-4.5.2\bin\x64\Rscript.exe"  -e "source('\\\\192.168.38.7\\public$\\Avtomatizacija\\umar-automation-scripts\\R\\desez-update-database.R')" > \\192.168.38.7\public$\Avtomatizacija\umar-automation-scripts\logs\desez_update.Rout 2>&1
git config --global http.proxy http://proxy.gov.si:80
git add  logs\desez-update-database-daily.Rout
git add  logs\DESEZ_import_log.txt
git commit -m "Umar data bot :robot: - DESEZONIRANJE data platform update."
git push
CLS
