@ECHO OFF
Rem this is for running the gt SI script which updates the GT SI excel tables.
"C:\Program Files\R\R-4.5.2\bin\x64\Rscript.exe" -e "source('\\\\192.168.38.7\\public$\\Avtomatizacija\\umar-automation-scripts\\R\\gt-tabela-si-update.R')" > \\192.168.38.7\public$\Avtomatizacija\umar-automation-scripts\logs\gt-tabela-si-update.Rout 2>&1
pushd \\192.168.38.7\public$\Avtomatizacija\umar-automation-scripts\
git config --global http.proxy http://proxy.gov.si:80
git add  logs\gt-tabela-si-update.Rout
git commit -m "Umar data bot :robot: - GT SI table update."
git push
CLS
