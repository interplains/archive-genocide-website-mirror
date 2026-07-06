@echo off
REM One-time setup: fetch the archive's gallery + victims data into data\.
REM The mirror server itself makes no outbound calls; only this helper does, when you run it.
setlocal
cd /d "%~dp0"
set "BASE=https://archivegenocide.com"
if not "%~1"=="" set "BASE=%~1"
if not exist data mkdir data
set "FAIL="
for %%f in (gallery_high.json gallery_rest.json gallery_meta.json victims.json) do call :fetch %%f
if defined FAIL (
  echo.
  echo Some files failed to download. Check your connection and run this again.
  pause & exit /b 1
)
echo.
echo done - data\ ready. Now double-click "Start Mirror.cmd".
pause
exit /b 0

:fetch
echo downloading %~1 ...
curl -fL --retry 3 -o "data\%~1" "%BASE%/%~1"
if errorlevel 1 ( echo   FAILED: %~1 & set "FAIL=1" )
goto :eof
