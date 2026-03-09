@ECHO OFF
Rem this is for running the gt ea script which updates the GT EA excel tables.
"C:\Program Files\R\R-4.5.2\bin\x64\Rscript.exe" -e "source('\\\\192.168.38.7\\public$\\Avtomatizacija\\umar-automation-scripts\\R\\gt-tabela-ea-update.R')" > \\192.168.38.7\public$\Avtomatizacija\umar-automation-scripts\logs\gt-tabela-ea-update.Rout 2>&1
pushd \\192.168.38.7\public$\Avtomatizacija\umar-automation-scripts\
git config --global http.proxy http://proxy.gov.si:80
git add  logs\gt-tabela-ea-update.Rout
git commit -m "Umar data bot :robot: - GT EA table update."
git push
CLS
