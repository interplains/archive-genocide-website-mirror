#!/usr/bin/env bash
# Double-click it, or run:  bash start-mirror.sh
# (macOS: you can rename it to "Start Mirror.command" to double-click from Finder.)
cd "$(dirname "$0")" || exit 1

echo "============================================================"
echo "   War Crimes Archive - local mirror"
echo "============================================================"
echo

# 1. Python 3
PY=""
for c in python3 python; do command -v "$c" >/dev/null 2>&1 && { PY="$c"; break; }; done
if [ -z "$PY" ]; then
  echo "Python 3 is required and was not found."
  echo "Install it from https://www.python.org/downloads/ then run this again."
  read -r -p "Press Enter to close. " _ ; exit 1
fi

# 2. gallery data present?
if [ ! -f "data/gallery_high.json" ]; then
  echo "The gallery data is not here yet (data/gallery_high.json)."
  echo "Download the release data files into the 'data' folder, then run this again."
  read -r -p "Press Enter to close. " _ ; exit 1
fi

# 3. find the footage, or ask
if [ -d "archivegenocide-media" ]; then
  export MEDIA_DIR="$PWD/archivegenocide-media"
else
  echo "Where is the archive's FOOTAGE folder?"
  echo "(the 'archivegenocide-media' folder you downloaded from the torrent)"
  echo
  read -r -p "Drag the folder here, or paste its path, then press Enter: " MEDIA_DIR
  MEDIA_DIR="${MEDIA_DIR%\"}"; MEDIA_DIR="${MEDIA_DIR#\"}"
  MEDIA_DIR="${MEDIA_DIR%\'}"; MEDIA_DIR="${MEDIA_DIR#\'}"
  export MEDIA_DIR
fi

echo
echo "Starting the mirror... opening http://localhost:8000"
echo "Keep this window open while you use it; close it (or press Ctrl-C) to stop."
( sleep 2
  if command -v open >/dev/null 2>&1; then open http://localhost:8000
  elif command -v xdg-open >/dev/null 2>&1; then xdg-open http://localhost:8000
  fi ) >/dev/null 2>&1 &
"$PY" serve.py
