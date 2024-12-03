@ECHO OFF
Rem this is for running the tgg-tabela-si-update script, which writes new data into that excel file.
"C:\Program Files\R\R-4.1.3\bin\x64\Rscript.exe"  -e "source('\\\\192.168.38.7\\public$\\Avtomatizacija\\umar-automation-scripts\\R\\tgg-tabela-si-update.R')" > \\192.168.38.7\public$\Avtomatizacija\umar-automation-scripts\logs\tgg-tabela-update.Rout 2>&1
CLS
