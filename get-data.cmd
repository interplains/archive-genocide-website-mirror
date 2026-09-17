@echo off
REM One-time setup: fetch the archive's gallery + victims data into data\.
REM The mirror server itself makes no outbound calls; only this helper does, when you run it.
REM By default it tries the official mirrors in order (.com, then .org, then .is).
REM Fetch from your own mirror instead (privacy, or if the domains are blocked):
REM     get-data.cmd https://a-mirror-you-trust.example
REM
REM This used to download the four files and print "data ready" the moment curl succeeded --
REM no manifest, no hash, no signature. The launcher checks the separate TORRENT release, which
REM is a different thing, so on Windows the descriptions, dates, classifications and source links
REM were never authenticated at all, even with GPG installed. They are now, by verify-data.ps1,
REM and the download is staged so a failed or interrupted run cannot destroy a good copy.
setlocal enabledelayedexpansion
cd /d "%~dp0"
if not "%~1"=="" (
  set "SOURCES=%~1"
) else (
  set "SOURCES=https://archivegenocide.com https://archivegenocide.org https://archivegenocide.is"
)
if not exist data mkdir data
set "STAGE=data\.new"
if exist "%STAGE%" rmdir /s /q "%STAGE%"
mkdir "%STAGE%"

set "FAIL="
for %%f in (gallery_high.json gallery_rest.json gallery_meta.json victims.json) do call :fetch %%f
if defined FAIL goto :failed

echo.
echo verifying the signed data manifest ...
call :fetchq SHA256SUMS-data
call :fetchq SHA256SUMS-data.asc
if not exist "key.asc" call :fetchkey

powershell -NoProfile -ExecutionPolicy Bypass -File "verify-data.ps1" -Stage "%STAGE%" -Key "key.asc"
if errorlevel 1 (
  echo.
  echo The downloaded metadata did NOT verify. Your existing data\ has been left untouched.
  rmdir /s /q "%STAGE%"
  pause & exit /b 1
)

REM Activate only now. Chunks generated from the OLD release are removed first, so a refresh
REM cannot serve old chunks alongside new metadata.
del /q "data\gallery_high_*.json" 2>nul
del /q "data\gallery_rest_*.json" 2>nul
del /q "data\index.json" 2>nul
move /y "%STAGE%\*" "data\" >nul
rmdir /s /q "%STAGE%" 2>nul

echo.
echo done - data\ ready and verified. Now double-click "Start Mirror.cmd".
pause
exit /b 0

:failed
echo.
echo Some files failed to download from every mirror. Check your connection and run again.
echo Your existing data\ has been left untouched.
if exist "%STAGE%" rmdir /s /q "%STAGE%"
pause & exit /b 1

:fetch
echo downloading %~1 ...
for %%b in (%SOURCES%) do (
  curl -fL --compressed --retry 2 --connect-timeout 15 --remove-on-error -o "%STAGE%\%~1" "%%b/%~1"
  if not errorlevel 1 goto :eof
  echo    ...%%b failed, trying next mirror
)
echo    FAILED: %~1 ^(all mirrors^)
set "FAIL=1"
goto :eof

:fetchq
for %%b in (%SOURCES%) do (
  curl -fsL --retry 2 --connect-timeout 15 -o "%STAGE%\%~1" "%%b/%~1"
  if not errorlevel 1 goto :eof
)
goto :eof

:fetchkey
for %%b in (%SOURCES%) do (
  curl -fsL --retry 2 --connect-timeout 15 -o "key.asc" "%%b/key.asc"
  if not errorlevel 1 goto :eof
)
goto :eof
