@echo off
setlocal enabledelayedexpansion
title Archive Genocide - Share Online
cd /d "%~dp0"

echo ============================================================
echo    Archive Genocide - share online
echo ============================================================
echo.

REM --- 1. cloudflared makes the public link AND keeps your home IP hidden ---
where cloudflared >nul 2>&1
if errorlevel 1 (
  echo  This needs a small, free tool called "cloudflared" ^(from Cloudflare^).
  echo  It creates the public link and keeps your home IP address hidden.
  echo.
  echo  Install it, then run this again. Easiest on Windows 10/11:
  echo      winget install --id Cloudflare.cloudflared
  echo.
  echo  Or download "cloudflared-windows-amd64.exe" from
  echo      https://github.com/cloudflare/cloudflared/releases
  echo  rename it to  cloudflared.exe  and drop it in this folder.
  echo.
  pause & exit /b 1
)

REM --- 2. make sure the mirror is running on :8000; start it in the background if not ---
set "RUNNING="
netstat -an | find ":8000" | find "LISTENING" >nul 2>&1 && set "RUNNING=1"
if not defined RUNNING (
  set "PY="
  for %%P in (python py python3) do ( if not defined PY ( where %%P >nul 2>&1 && set "PY=%%P" ) )
  if not defined PY (
    echo  The mirror isn't running, and Python 3 wasn't found to start it.
    echo  Double-click "Start Mirror.cmd" first, then run this again.
    echo.
    pause & exit /b 1
  )
  if exist "archivegenocide-media\" set "MEDIA_DIR=%cd%\archivegenocide-media"
  echo  Starting the mirror in the background...
  start "Archive Genocide mirror (server)" /min cmd /c "!PY! serve.py"
  ping -n 3 127.0.0.1 >nul
)

echo.
echo  Creating your public link... ^(this takes a few seconds^)
echo.
echo   ^>^>^> Below, find the line ending in   .trycloudflare.com
echo   ^>^>^> THAT web address is your public link - copy it and share it.
echo.
echo   Keep this window OPEN while people use the link. Close it to stop sharing.
echo   Your home IP address stays hidden ^(traffic goes through Cloudflare^).
echo ------------------------------------------------------------
cloudflared tunnel --url http://localhost:8000
echo.
echo  Sharing stopped. ^(If a small minimized "server" window is still open, close it too.^)
pause
