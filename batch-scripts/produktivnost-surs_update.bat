@ECHO OFF
Rem this is for running the update_eurostat.R script for changes on the produktivnost database
"C:\Program Files\R\R-4.1.3\bin\x64\Rscript.exe"  -e "source('\\\\192.168.38.7\\public$\\Avtomatizacija\\umar_produktivnost\\R\\update_surs.R')" > \\192.168.38.7\public$\Avtomatizacija\umar-automation-scripts\logs\produktivnost-surs_update.Rout 2>&1
CLS
