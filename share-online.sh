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

# 2. Make sure OUR mirror is the thing we are about to publish.
#
# This used to decide "the mirror is already running" from a bare TCP connect to port 8000. If any
# unrelated local service held that port -- a dev server, a dashboard, a database admin UI -- Share
# Online created a public Cloudflare tunnel to THAT, and told the user it was their archive. The
# check now asks the listener what it is, and refuses to tunnel anything that does not identify
# itself as this mirror.
PORT_TRY="${PORT:-8000}"
identify() {  # $1 = port; 0 when an archive mirror answers there
  command -v curl >/dev/null 2>&1 || return 1
  curl -fsS --max-time 3 "http://127.0.0.1:$1/srv/identity" 2>/dev/null     | grep -q 'archive-genocide-mirror'
}
port_free() { ! (exec 3<>/dev/tcp/127.0.0.1/"$1") 2>/dev/null; }

SERVE_PID=""
if identify "$PORT_TRY"; then
  PORT_USE="$PORT_TRY"
  echo "Found the archive mirror already running on port $PORT_USE."
else
  if ! port_free "$PORT_TRY"; then
    echo "Something else is already using port $PORT_TRY, and it is not the archive mirror."
    echo "Starting our own mirror on a free port instead, so we never publish someone"
    echo "else's service to the internet."
    PORT_USE=""
    for p in 8801 8802 8803 8804 8805 8806; do
      if port_free "$p"; then PORT_USE="$p"; break; fi
    done
    [ -n "$PORT_USE" ] || { echo "No free port found in 8801-8806."; read -r -p "Press Enter to close. " _ ; exit 1; }
  else
    PORT_USE="$PORT_TRY"
  fi
  PY=""; for c in python3 python py; do command -v "$c" >/dev/null 2>&1 && "$c" -c 'import sys' >/dev/null 2>&1 && { PY="$c"; break; }; done
  if [ -z "$PY" ]; then
    echo "The mirror isn't running, and Python 3 wasn't found to start it."
    echo "Run  bash start-mirror.sh  first, then run this again."
    read -r -p "Press Enter to close. " _ ; exit 1
  fi
  [ -d archivegenocide-media ] && export MEDIA_DIR="$PWD/archivegenocide-media"
  echo "Starting the mirror in the background on port $PORT_USE..."
  PORT="$PORT_USE" "$PY" serve.py >/tmp/agmirror-serve.log 2>&1 &
  SERVE_PID=$!
  trap 'kill "$SERVE_PID" >/dev/null 2>&1' EXIT INT TERM   # stop our server when this window closes
  # Wait for it to actually answer as OURS, rather than sleeping and hoping.
  ok=0
  for _ in 1 2 3 4 5 6 7 8 9 10; do
    sleep 1
    if identify "$PORT_USE"; then ok=1; break; fi
  done
  if [ "$ok" != 1 ]; then
    echo "The mirror did not start (see /tmp/agmirror-serve.log). Not creating a public link."
    read -r -p "Press Enter to close. " _ ; exit 1
  fi
fi

# --http-host-header keeps serve.py's DNS-rebinding protection intact: without it the tunnel
# forwards a *.trycloudflare.com Host, which the localhost-only allowlist correctly refuses.
# Rewriting the Host to the local one is the supported path; globally allowing every Host
# would throw the protection away to fix a symptom.
cloudflared tunnel --url "http://127.0.0.1:$PORT_USE" \n  --http-host-header "127.0.0.1:$PORT_USE"
