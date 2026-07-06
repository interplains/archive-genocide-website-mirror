@echo off
setlocal enabledelayedexpansion
title War Crimes Archive - Mirror
cd /d "%~dp0"

echo ============================================================
echo    War Crimes Archive - local mirror
echo ============================================================
echo.

REM --- 1. Python 3 required ---
set "PY="
for %%P in (python py python3) do ( if not defined PY ( where %%P >nul 2>&1 && set "PY=%%P" ) )
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
  echo  Download the release data files into the "data" folder, then run this again.
  echo.
  pause & exit /b 1
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
