@ECHO OFF
Rem this is for moving MF ata to O and parsing into database:
"C:\Program Files\R\R-4.1.3\bin\x64\Rscript.exe"  -e "source('\\\\192.168.38.7\\public$\\Avtomatizacija\\umar-automation-scripts\\R\\mf-database_update_new.R')" > \\192.168.38.7\public$\Avtomatizacija\umar-automation-scripts\logs\mf_update.Rout 2>&1
CLS
