@ECHO OFF
Rem this is for running the mf-database_update_and_excel_tables script and saving the outputs. And then commiting and pushing the changes to github.
"C:\Program Files\R\R-4.1.3\bin\x64\Rscript.exe" -e "source('\\\\192.168.38.7\\public$\\Avtomatizacija\\umar-automation-scripts\\R\\mf-database_update_and_excel_tables.R')" > \\192.168.38.7\public$\Avtomatizacija\umar-automation-scripts\logs\mf-database_update_and_excel_tables.Rout 2>&1
pushd \\192.168.38.7\public$\Avtomatizacija\umar-automation-scripts\
git config --global http.proxy http://proxy.gov.si:80
git add data\mf_bilance\raw_data\* data\mf_bilance\output_tables\*  logs\mf-database_update_and_excel_tables.Rout logs\mf_last_update.txt
git commit -m "Umar data bot :robot: - monthly MF update."
git push
PAUSE
