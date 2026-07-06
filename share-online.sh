#!/usr/bin/env bash
# Put your local mirror online with a temporary public link (no account needed).
# Double-click, or run:  bash share-online.sh
# (macOS: rename it to "Share Online.command" to double-click from Finder.)
cd "$(dirname "$0")" || exit 1

echo "============================================================"
echo "   Archive Genocide - share online"
echo "============================================================"
echo

# 1. cloudflared makes the public link AND keeps your home IP hidden
if ! command -v cloudflared >/dev/null 2>&1; then
  echo "This needs a small, free tool called 'cloudflared' (from Cloudflare)."
  echo "It creates the public link and keeps your home IP address hidden."
  echo
  echo "Install it, then run this again:"
  echo "   macOS:  brew install cloudflared"
  echo "   Linux:  https://pkg.cloudflare.com/   (or grab a binary from"
  echo "           https://github.com/cloudflare/cloudflared/releases )"
  echo
  read -r -p "Press Enter to close. " _ ; exit 1
fi

# 2. make sure the mirror is running on localhost:8000; start it in the background if not
mirror_up() { (exec 3<>/dev/tcp/127.0.0.1/8000) 2>/dev/null; }
if ! mirror_up; then
  PY=""; for c in python3 python; do command -v "$c" >/dev/null 2>&1 && { PY="$c"; break; }; done
  if [ -z "$PY" ]; then
    echo "The mirror isn't running, and Python 3 wasn't found to start it."
    echo "Run  bash start-mirror.sh  first, then run this again."
    read -r -p "Press Enter to close. " _ ; exit 1
  fi
  [ -d archivegenocide-media ] && export MEDIA_DIR="$PWD/archivegenocide-media"
  echo "Starting the mirror in the background..."
  "$PY" serve.py >/tmp/agmirror-serve.log 2>&1 &
  SERVE_PID=$!
  trap 'kill "$SERVE_PID" >/dev/null 2>&1' EXIT INT TERM   # stop our server when this window closes
  sleep 2
fi

echo
echo "Creating your public link... (this takes a few seconds)"
echo
echo "  >>> Below, find the line ending in   .trycloudflare.com"
echo "  >>> THAT web address is your public link - copy it and share it."
echo
echo "  Keep this window OPEN while people use the link. Close it to stop sharing."
echo "  Your home IP address stays hidden (traffic goes through Cloudflare)."
echo "------------------------------------------------------------"
cloudflared tunnel --url http://localhost:8000
