@ECHO OFF
Rem this is for running the umar-add_new_series_metadata.R script for a particular author, which checks, parses and imports their metadata into the database.
"C:\Program Files\R\R-4.1.3\bin\x64\Rscript.exe"  -e "source('\\\\192.168.38.7\\public$\\Avtomatizacija\\umar-automation-scripts\\R\\umar-add_new_series_metadata.R'); args <- commandArgs(trailingOnly = TRUE)" %1> \\192.168.38.7\public$\Avtomatizacija\umar-automation-scripts\logs\umar-add_new_series_metadata.Rout 2>&1
pushd \\192.168.38.7\public$\Avtomatizacija\umar-automation-scripts\
git config --global http.proxy http://proxy.gov.si:80
git add  logs\umar-add_new_series_metadata.Rout
git commit -m "Umar data bot :robot: - manual UMAR metadata update."
git push
CLS
