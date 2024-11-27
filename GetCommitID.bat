@echo off
:: Check if we're in a git repository
git rev-parse --is-inside-work-tree >nul 2>&1
if %errorlevel% neq 0 (
    echo Not a git repository. No commit ID will be generated.
    exit /b
)

:: Get the latest commit ID (full SHA)
for /f "tokens=*" %%a in ('git rev-parse HEAD') do set COMMIT_ID=%%a

:: Extract only the first 7 characters of the commit ID
set COMMIT_ID_SHORT=%COMMIT_ID:~0,7%

:: Write the shortened commit ID to a Delphi .pas file (LemVersionCommitID.pas)
echo unit LemVersionCommitID; > LemVersionCommitID.pas
echo. >> LemVersionCommitID.pas
echo interface >> LemVersionCommitID.pas
echo. >> LemVersionCommitID.pas
echo const COMMIT_ID = '%COMMIT_ID_SHORT%'; >> LemVersionCommitID.pas
echo. >> LemVersionCommitID.pas
echo implementation >> LemVersionCommitID.pas
echo. >> LemVersionCommitID.pas
echo end. >> LemVersionCommitID.pas