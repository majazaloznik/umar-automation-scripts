@ECHO OFF
Rem this is for running the ice-update-database.R script which updates donosnosti Blooomberg series in the platform database.
"C:\Program Files\R\R-4.5.2\bin\x64\Rscript.exe" -e "source('\\\\192.168.38.7\\public$\\Avtomatizacija\\umar-automation-scripts\\R\\donosnosti-update-database.R')" > \\192.168.38.7\public$\Avtomatizacija\umar-automation-scripts\logs\donosnosti-update-database.log 2>&1
pushd \\192.168.38.7\public$\Avtomatizacija\umar-automation-scripts\
git config --global http.proxy http://proxy.gov.si:80
git add  logs\donosnosti-update-database.log
git commit -m "Umar data bot :robot: - weekly donosnosti Bloomberg data platform update."
git push
CLS
