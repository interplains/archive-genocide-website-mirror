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

REM --- 2. gallery data present? (monolith on first run, or the gallery_high_0000.json chunks serve.py leaves after) ---
if not exist "data\gallery_high.json" if not exist "data\gallery_high_0000.json" (
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
) else (
  REM No sh/gpg. That is the NORMAL state of a clean Windows box, and this used to skip
  REM verification silently -- on the path we advertise as the easiest one. Fall back to
  REM PowerShell, which ships with Windows, and check the hashes at minimum. Say plainly
  REM what was and was not verified.
  if exist "SHA256SUMS" (
    echo  Verifying file hashes with PowerShell ^(gpg not found - signature NOT checked^)...
    powershell -NoProfile -ExecutionPolicy Bypass -Command ^
      "$bad=0;$n=0; Get-Content SHA256SUMS | ForEach-Object { if($_ -match '^([0-9a-fA-F]{64})\s+\*?(.+)$'){ $h=$Matches[1];$f=$Matches[2].Trim(); if(Test-Path -LiteralPath $f){ $a=(Get-FileHash -LiteralPath $f -Algorithm SHA256).Hash; if($a -ieq $h){$n++} else {Write-Host ('   MISMATCH: '+$f);$bad++} } else {Write-Host ('   MISSING:  '+$f);$bad++} } }; if($bad -gt 0){Write-Host ('   ** '+$bad+' file(s) failed **');exit 1}; if($n -eq 0){Write-Host '   ** manifest verified nothing **';exit 1}; Write-Host ('   '+$n+' file(s) match the published hashes.')"
    if errorlevel 1 (
      echo.
      echo  ** HASH VERIFICATION FAILED - this copy may be tampered with. **
      set /p "GOON=  Continue anyway? [y/N]: "
      if /I not "!GOON!"=="y" exit /b 1
    )
    echo   NOTE: hashes checked, but the GPG SIGNATURE was not.
    echo   To verify the signature too, install Gpg4win ^(https://gpg4win.org^) and re-run.
  ) else (
    echo  ** NOT VERIFIED ** - no SHA256SUMS present and gpg/sh are unavailable,
    echo  so this copy could not be checked against the project's signing key.
    echo  See https://archivegenocide.com/verify.html for how to verify manually.
  )
  echo.
)
  echo.
)

REM --- 3. find the footage: honor a caller-set MEDIA_DIR, else auto-detect, else ask ---
if not defined MEDIA_DIR if exist "archivegenocide-media\" set "MEDIA_DIR=%cd%\archivegenocide-media"
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
