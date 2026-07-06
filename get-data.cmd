@echo off
REM One-time setup: fetch the archive's gallery + victims data into data\.
REM The mirror server itself makes no outbound calls; only this helper does, when you run it.
setlocal
cd /d "%~dp0"
set "BASE=https://archivegenocide.com"
if not "%~1"=="" set "BASE=%~1"
if not exist data mkdir data
for %%f in (gallery_high.json gallery_rest.json gallery_meta.json victims.json) do (
  echo downloading %%f ...
  curl -fL --retry 3 -o "data\%%f" "%BASE%/%%f" || ( echo   FAILED: %%f & pause & exit /b 1 )
)
echo done - data\ ready. Now double-click "Start Mirror.cmd".
pause
