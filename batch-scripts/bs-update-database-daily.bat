@ECHO OFF
Rem this is for running the surs-update-database.R script which updates all the surs series in the platform database.
"C:\Program Files\R\R-4.1.3\bin\x64\Rscript.exe" -e "source('\\\\192.168.38.7\\public$\\Avtomatizacija\\umar-automation-scripts\\R\\bs-update-database-daily.R')" > \\192.168.38.7\public$\Avtomatizacija\umar-automation-scripts\logs\bs-update-database-daily.Rout 2>&1
pushd \\192.168.38.7\public$\Avtomatizacija\umar-automation-scripts\
git config --global http.proxy http://proxy.gov.si:80
git add  logs\bs-update-database-daily.Rout
git commit -m "Umar data bot :robot: - daily BS data platform update."
git push
CLS
