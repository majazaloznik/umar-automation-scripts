@ECHO OFF
Rem this is for running the employee_table_maintenance_script, which updates the spicka database from the excel file.
"C:\Program Files\R\R-4.1.3\bin\x64\Rscript.exe"  -e "source('D:\\umar_dd\\R\\employee_table_maintenance_script.R')" > D:\umar_dd\logs\batch.Rout 2>&1
pushd \\192.168.38.7\public$\Avtomatizacija\umar-automation-scripts\
git config --global http.proxy http://proxy.gov.si:80
git add  D:\umar_dd\logs\batch.Rout
git commit -m "Umar data bot :robot: - spicka employee table update."
git push
CLS

