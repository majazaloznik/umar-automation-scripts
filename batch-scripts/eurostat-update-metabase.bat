@ECHO OFF
Rem this is for checking the eurostat metabase changes and writing them to the database:
  "C:\Program Files\R\R-4.5.2\bin\x64\Rscript.exe"  -e "source('\\\\192.168.38.7\\public$\\Avtomatizacija\\umar-automation-scripts\\R\\eurostat-update-metabase.R')" > \\192.168.38.7\public$\Avtomatizacija\umar-automation-scripts\logs\eurostat_metabase.Rout 2>&1
pushd \\192.168.38.7\public$\Avtomatizacija\umar-automation-scripts\
git config --global http.proxy http://proxy.gov.si:80
git add  logs\eurostat_metabase.Rout
git commit -m "Umar data bot :robot: - Eurostat metabase update "
git push
CLS
