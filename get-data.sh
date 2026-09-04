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
# --compressed asks for gzip. Without it curl downloads the gallery UNCOMPRESSED: 146 MB instead
# of 32 MB per person. Same files on disk either way -- curl decompresses -- so this is a pure
# 4.5x saving on the download, on our bandwidth bill, and on how long a slow connection waits.
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
    if curl -fL --compressed --retry 2 --connect-timeout 15 --remove-on-error -o "data/$f" "$base/$f"; then
      got=1; break
    else
      echo "  ...$base failed, trying next mirror"
    fi
  done
  [ "$got" = 1 ] || { echo "  FAILED: $f (all mirrors)"; ok=0; }
done


# Verify the metadata against the project's signed manifest. Without this you would have
# BitTorrent-verified footage paired with completely unverified descriptions, dates,
# classifications and source links -- the fields research actually depends on.
if [ "$ok" = 1 ]; then
  echo "verifying the signed data manifest ..."
  for base in "${SOURCES[@]}"; do
    curl -fsL --compressed --retry 2 --connect-timeout 15 -o data/SHA256SUMS-data "$base/SHA256SUMS-data" || continue
    curl -fsL --retry 2 --connect-timeout 15 -o data/SHA256SUMS-data.asc "$base/SHA256SUMS-data.asc" || continue
    break
  done
  if [ -s data/SHA256SUMS-data ]; then
    if command -v gpg >/dev/null 2>&1 && [ -f key.asc ] && [ -s data/SHA256SUMS-data.asc ]; then
      gpg --quiet --import key.asc 2>/dev/null || true
      if gpg --verify data/SHA256SUMS-data.asc data/SHA256SUMS-data 2>&1 | grep -q "Good signature"; then
        echo "  signature OK"
      else
        echo "  WARNING: data manifest is NOT correctly signed -- do not trust this metadata."
        ok=0
      fi
    else
      echo "  (gpg or key.asc unavailable -- checking hashes only, signature unverified)"
    fi
    if [ "$ok" = 1 ]; then
      CHK=$(cd data && sha256sum -c SHA256SUMS-data 2>&1); RC=$?
      printf '%s\n' "$CHK" | sed 's/^/    /'
      if [ "$RC" -ne 0 ] || ! printf '%s' "$CHK" | grep -q ': OK'; then
        echo "  WARNING: downloaded metadata does NOT match the signed hashes."
        ok=0
      fi
    fi
  else
    echo "  (no signed data manifest published yet -- metadata unverified)"
  fi
fi


[ "$ok" = 1 ] && echo "done — data/ ready. Now run the mirror (start-mirror.sh / Start Mirror.cmd / python serve.py)." \
             || { echo "some files failed to download from every mirror."; exit 1; }
