@ECHO OFF
Rem this is for running the umar-add_new_data_full.R script for all the data files and imports any new stuff into the database.
"C:\Program Files\R\R-4.5.2\bin\x64\Rscript.exe"  -e "source('\\\\192.168.38.7\\public$\\Avtomatizacija\\umar-automation-scripts\\R\\umar-data\\umar_data_update.R')" > \\192.168.38.7\public$\Avtomatizacija\umar-automation-scripts\logs\umar-data_update.log 2>&1
pushd \\192.168.38.7\public$\Avtomatizacija\umar-automation-scripts\
git config --global http.proxy http://proxy.gov.si:80
git add  logs\umar-data_update.log
git commit -m "Umar data bot :robot: - automatic UMAR data update."
git push
CLS
