@echo off
setlocal enabledelayedexpansion
title Archive Genocide Website Mirror
cd /d "%~dp0"

echo ============================================================
echo    Archive Genocide - local mirror
echo ============================================================
echo.

REM --- 1. Python 3 required ---
set "PY="
for %%P in (py python python3) do ( if not defined PY ( %%P -c "import sys" >nul 2>&1 && set "PY=%%P" ) )
if not defined PY (
  echo  Python 3 is required and was not found on this computer.
  echo  Install it from  https://www.python.org/downloads/
  echo  ^(on the first screen, tick "Add python.exe to PATH"^), then run this again.
  echo.
  pause & exit /b 1
)

REM --- 2. gallery data present? ---
if not exist "data\gallery_high.json" (
  echo  The gallery data is not here yet ^(data\gallery_high.json^).
  echo  Run  get-data.cmd  first to download it ^(~95 MB^), then run this again.
  echo.
  pause & exit /b 1
)

REM --- 2b. auto-verify the release signature (verify.sh fetches the signing files if needed) ---
set "CANVERIFY="
where sh >nul 2>&1 && where gpg >nul 2>&1 && set "CANVERIFY=1"
if defined CANVERIFY (
  echo  Verifying release signature...
  call sh verify.sh
  if errorlevel 2 (
    echo   ^(couldn't fetch the signing files - offline? skipping verification for now^)
  ) else if errorlevel 1 (
    echo.
    echo  ** VERIFICATION FAILED - this copy may be tampered with. **
    set /p "GOON=  Continue anyway? [y/N]: "
    if /I not "!GOON!"=="y" exit /b 1
  ) else (
    echo   release verified OK.
  )
  echo.
)

REM --- 3. find the footage, or ask ---
set "MEDIA_DIR="
if exist "archivegenocide-media\" set "MEDIA_DIR=%cd%\archivegenocide-media"
if not defined MEDIA_DIR (
  echo  Where is the archive's FOOTAGE folder?
  echo  ^(the "archivegenocide-media" folder you downloaded from the torrent^)
  echo.
  set /p "MEDIA_DIR=  Drag the folder onto this window, or paste its path, then press Enter: "
  set "MEDIA_DIR=!MEDIA_DIR:"=!"
)

echo.
echo  Starting the mirror... a browser will open at  http://localhost:8000
echo  Keep this window OPEN while you use it. Close it to stop the mirror.
echo.
start "" /min cmd /c "ping -n 3 127.0.0.1 >nul & start "" http://localhost:8000"
%PY% serve.py
echo.
echo  Mirror stopped.
pause
