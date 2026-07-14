#!/usr/bin/env bash
# One-time setup: fetch the archive's gallery + victims data into ./data/.
# The mirror SERVER makes no outbound calls; this helper is the only thing that does, when you run it.
# By default it tries the official mirrors in order (.com, then .org, then .is), so one being down
# or blocked doesn't stop you.
#
# Fetch from your own mirror / over Tor instead (for privacy, or if all three domains are blocked):
#     ./get-data.sh https://a-mirror-you-trust.example    # any source you trust
#     torsocks ./get-data.sh                              # route the default fetch through Tor
#     ./get-data.sh http://<onion-address>.onion          # from the Tor onion mirror (run via torsocks)
cd "$(dirname "$0")" || exit 1

if [ -n "$1" ]; then
  SOURCES=("$1")
else
  SOURCES=("https://archivegenocide.com" "https://archivegenocide.org" "https://archivegenocide.is")
fi

mkdir -p data
ok=1
for f in gallery_high.json gallery_rest.json gallery_meta.json victims.json; do
  echo "downloading $f ..."
  got=0
  for base in "${SOURCES[@]}"; do
    if curl -fL --retry 2 --connect-timeout 15 --remove-on-error -o "data/$f" "$base/$f"; then
      got=1; break
    else
      echo "  ...$base failed, trying next mirror"
    fi
  done
  [ "$got" = 1 ] || { echo "  FAILED: $f (all mirrors)"; ok=0; }
done

[ "$ok" = 1 ] && echo "done — data/ ready. Now run the mirror (start-mirror.sh / Start Mirror.cmd / python serve.py)." \
             || { echo "some files failed to download from every mirror."; exit 1; }
