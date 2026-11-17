@ECHO OFF
REM Weekly davcne update:
REM   1. furs_weekly_update.R        newest FURS csv -> davcne.davcni_racuni
REM   2. davcne_update_platform.R   complete months -> platform (idempotent, runs regardless)
SET RSCRIPT="C:\Program Files\R\R-4.5.2\bin\x64\Rscript.exe"
SET REPO1=\\192.168.38.7\public$\Avtomatizacija\furs-surs-soap
SET REPO2=\\192.168.38.7\public$\Avtomatizacija\umar-automation-scripts

%RSCRIPT% -e "source('%REPO1:\=/%/R/furs_weekly_update.R')" > %REPO2%\logs\furs_weekly_update.txt 2>&1
SET RC1=%ERRORLEVEL%

%RSCRIPT% -e "source('%REPO2:\=/%/R/davcne/davcne_update_platform.R')" > %REPO2%\logs\davcne_update_platform.txt 2>&1
SET RC2=%ERRORLEVEL%

pushd %REPO2%
git config --global http.proxy http://proxy.gov.si:80
git add logs\furs_weekly_update.txt logs\davcne_update_platform.txt
git commit -m "Umar data bot :robot: - weekly davcne update (furs=%RC1%, platform=%RC2%)"
git push
popd

IF NOT %RC1%==0 EXIT /B %RC1%
EXIT /B %RC2%
