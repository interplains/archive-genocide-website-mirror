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

REM --- 2. make sure OUR mirror is what we are about to publish ---
REM This used to accept ANY listener on :8000 (a bare netstat match), so an unrelated dev
REM server or local dashboard holding that port was tunnelled to the internet instead of the
REM archive. Ask the listener what it is; refuse to tunnel anything that does not answer.
set "PORT_USE=8000"
set "ISOURS="
curl -fsS --max-time 3 "http://127.0.0.1:8000/srv/identity" 2>nul | findstr /C:"archive-genocide-mirror" >nul 2>&1 && set "ISOURS=1"

if not defined ISOURS (
  set "INUSE="
  netstat -an | find ":8000" | find "LISTENING" >nul 2>&1 && set "INUSE=1"
  if defined INUSE (
    echo  Something else is using port 8000, and it is NOT the archive mirror.
    echo  Starting our own mirror on port 8801 instead, so we never publish
    echo  someone else^'s service to the internet.
    set "PORT_USE=8801"
  )
  set "PY="
  for %%P in (py python python3) do ( if not defined PY ( %%P -c "import sys" >nul 2>&1 && set "PY=%%P" ) )
  if not defined PY (
    echo  The mirror isn^'t running, and Python 3 wasn^'t found to start it.
    echo  Double-click "Start Mirror.cmd" first, then run this again.
    echo.
    goto :nolink
  )
  if exist "archivegenocide-media\" set "MEDIA_DIR=%cd%rchivegenocide-media"
  echo  Starting the mirror in the background on port !PORT_USE!...
  start "Archive Genocide mirror (server)" /min cmd /c "set PORT=!PORT_USE!&& !PY! serve.py"
  REM wait until it answers as OURS, rather than sleeping and hoping
  set "READY="
  for /l %%i in (1,1,10) do (
    if not defined READY (
      ping -n 2 127.0.0.1 >nul
      curl -fsS --max-time 3 "http://127.0.0.1:!PORT_USE!/srv/identity" 2>nul | findstr /C:"archive-genocide-mirror" >nul 2>&1 && set "READY=1"
    )
  )
  if not defined READY (
    echo  The mirror did not start. Not creating a public link.
    goto :nolink
  )
)

goto :share

:nolink
REM Reached only when we refused to publish. `exit /b` inside the nested blocks above did
REM NOT terminate the script -- it printed the refusal and then created a link anyway.
pause
exit /b 1

:share
echo.
echo  Creating your public link... ^(this takes a few seconds^)
echo.
echo   ^>^>^> Below, find the line ending in   .trycloudflare.com
echo   ^>^>^> THAT web address is your public link - copy it and share it.
echo.
echo   Keep this window OPEN while people use the link. Close it to stop sharing.
echo   Your home IP address stays hidden ^(traffic goes through Cloudflare^).
echo ------------------------------------------------------------
cloudflared tunnel --url "http://127.0.0.1:!PORT_USE!" --http-host-header "127.0.0.1:!PORT_USE!"
echo.
echo  Sharing stopped. ^(If a small minimized "server" window is still open, close it too.^)
pause
