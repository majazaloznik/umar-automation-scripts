@ECHO OFF
Rem this is for running the zrsz-update-database.R script which updates all the zrsz series in the platform database.
"C:\Program Files\R\R-4.1.3\bin\x64\Rscript.exe" -e "source('\\\\192.168.38.7\\public$\\Avtomatizacija\\umar-automation-scripts\\R\\zrsz-update-database.R')" > \\192.168.38.7\public$\Avtomatizacija\umar-automation-scripts\logs\zrsz-update-database.Rout 2>&1
pushd \\192.168.38.7\public$\Avtomatizacija\umar-automation-scripts\
git config --global http.proxy http://proxy.gov.si:80
git add  logs\zrsz-update-database.Rout
git commit -m "Umar data bot :robot: - monthly ZRSZ data platform update."
git push
CLS
