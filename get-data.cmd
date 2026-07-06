@echo off
REM One-time setup: fetch the archive's gallery + victims data into data\.
REM The mirror server itself makes no outbound calls; only this helper does, when you run it.
REM By default it tries the official mirrors in order (.com, then .org, then .is).
REM Fetch from your own mirror instead (privacy, or if the domains are blocked):
REM     get-data.cmd https://a-mirror-you-trust.example
setlocal enabledelayedexpansion
cd /d "%~dp0"
if not "%~1"=="" (
  set "SOURCES=%~1"
) else (
  set "SOURCES=https://archivegenocide.com https://archivegenocide.org https://archivegenocide.is"
)
if not exist data mkdir data
set "FAIL="
for %%f in (gallery_high.json gallery_rest.json gallery_meta.json victims.json) do call :fetch %%f
if defined FAIL (
  echo.
  echo Some files failed to download from every mirror. Check your connection and run again.
  pause & exit /b 1
)
echo.
echo done - data\ ready. Now double-click "Start Mirror.cmd".
pause
exit /b 0

:fetch
echo downloading %~1 ...
for %%b in (%SOURCES%) do (
  curl -fL --retry 2 --connect-timeout 15 -o "data\%~1" "%%b/%~1"
  if not errorlevel 1 goto :eof
  echo    ...%%b failed, trying next mirror
)
echo    FAILED: %~1 ^(all mirrors^)
set "FAIL=1"
goto :eof
