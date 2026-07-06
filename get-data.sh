#!/usr/bin/env bash
# One-time setup: fetch the archive's gallery + victims data into ./data/.
# The mirror SERVER itself makes no outbound calls; this helper is the only thing that does,
# and only when you run it. Override the source: ./get-data.sh https://your-mirror.example
cd "$(dirname "$0")" || exit 1
BASE="${1:-https://archivegenocide.com}"
mkdir -p data
ok=1
for f in gallery_high.json gallery_rest.json gallery_meta.json victims.json; do
  echo "downloading $f ..."
  curl -fL --retry 3 -o "data/$f" "$BASE/$f" || { echo "  FAILED: $f"; ok=0; }
done
[ "$ok" = 1 ] && echo "done — data/ ready. Now run the mirror (start-mirror.sh / Start Mirror.cmd / python serve.py)." \
             || { echo "some files failed to download."; exit 1; }
