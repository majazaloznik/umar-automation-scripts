@ECHO OFF
Rem this is for running the employee_table_maintenance_script, which updates the spicka database from the excel file.
"C:\Program Files\R\R-4.1.3\bin\x64\Rscript.exe"  -e "source('D:\\umar_dd\\R\\employee_table_maintenance_script.R')" > D:\umar_dd\logs\batch.Rout 2>&1
CLS
