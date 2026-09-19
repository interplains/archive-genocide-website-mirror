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
# STAGE, VERIFY, THEN ACTIVATE.
# These files used to be written straight into data/ and verified afterwards, so an interrupted
# download destroyed the previous good copy, and a failed hash or signature left the rejected
# download sitting in the directory the viewer reads next. serve.py would then chunk the rejected
# JSON. Nothing touches data/ now until the whole set has been verified together, which also stops
# one run assembling files from different releases across the three mirrors.
STAGE="data/.new.$$"
rm -rf "$STAGE"; mkdir -p "$STAGE" || exit 1
trap 'rm -rf "$STAGE"' EXIT INT TERM

ok=1
for f in gallery_high.json gallery_rest.json gallery_meta.json victims.json decisions.json; do
  echo "downloading $f ..."
  got=0
  for base in "${SOURCES[@]}"; do
    if curl -fL --compressed --retry 2 --connect-timeout 15 --remove-on-error -o "$STAGE/$f" "$base/$f"; then
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
    curl -fsL --compressed --retry 2 --connect-timeout 15 -o "$STAGE/SHA256SUMS-data" "$base/SHA256SUMS-data" || continue
    curl -fsL --retry 2 --connect-timeout 15 -o "$STAGE/SHA256SUMS-data.asc" "$base/SHA256SUMS-data.asc" || continue
    break
  done
  if [ -s "$STAGE/SHA256SUMS-data" ]; then
    # A fresh clone has no key.asc (it is fetched, not committed), which used to drop us to
    # hashes-only on the very first run -- the run that matters most.
    if [ ! -f key.asc ] && command -v gpg >/dev/null 2>&1; then
      for base in "${SOURCES[@]}"; do
        curl -fsL --retry 2 --connect-timeout 15 -o key.asc "$base/key.asc" && break
      done
      [ -s key.asc ] || rm -f key.asc
    fi
    # Same bound-to-the-pinned-key check verify.sh uses -- see verify-sig.sh for why the old
    # "grep for Good signature" version accepted an attacker's signature.
    . "$(dirname "$0")/verify-sig.sh"
    FPR="C24EC92B12D6670A2516065F9B4D575499AFA53C"
    if command -v gpg >/dev/null 2>&1 && [ -f key.asc ] && [ -s "$STAGE/SHA256SUMS-data.asc" ]; then
      if verify_signed "$STAGE/SHA256SUMS-data" "$STAGE/SHA256SUMS-data.asc" key.asc "$FPR"; then
        echo "  signature OK"
      else
        echo "  WARNING: data manifest is NOT correctly signed by the archive's key."
        ok=0
      fi
    else
      echo "  (gpg or key.asc unavailable -- checking hashes only, signature UNVERIFIED)"
    fi
    if [ "$ok" = 1 ]; then
      CHK=$(cd "$STAGE" && sha256sum -c SHA256SUMS-data 2>&1); RC=$?
      printf '%s\n' "$CHK" | sed 's/^/    /'
      if [ "$RC" -ne 0 ] || ! printf '%s' "$CHK" | grep -q ': OK'; then
        echo "  WARNING: downloaded metadata does NOT match the signed hashes."
        ok=0
      fi
    fi
  else
    # FAIL CLOSED, same reason as verify-data.ps1: leaving ok=1 here meant a missing
    # manifest activated the download and reported success, so "verified" covered data
    # that nothing had checked.
    echo "  [FAIL] no signed data manifest (SHA256SUMS-data) was published or downloaded."
    echo "         The metadata has NOT been verified."
    if [ "${ALLOW_UNVERIFIED:-}" = 1 ]; then
      echo "         ALLOW_UNVERIFIED=1 set -- continuing anyway, at your own risk."
    else
      echo "         To use the data anyway, set ALLOW_UNVERIFIED=1 and re-run."
      ok=0
    fi
  fi
fi

if [ "$ok" = 1 ]; then
  # Activate by SWAPPING DIRECTORIES, not by moving files one at a time.
  #
  # The old sequence deleted the previous chunks and then moved each new file individually,
  # so an interruption anywhere in that loop -- Ctrl-C, a full disk, a dropped session --
  # left data/ holding part of the new release and part of the old, with nothing recording
  # it. A mirror silently serving two releases at once is the exact failure this download
  # exists to prevent.
  #
  # Two renames instead: the live directory steps aside, the fully verified staging directory
  # takes its place, and only then is the old one discarded. An interruption now leaves
  # either the old release or the new one, never a blend.
  if ! mv -f data "data.old.$$" 2>/dev/null; then
    echo "  [FAIL] could not move data/ aside; nothing was changed."; exit 1
  fi
  if ! mv -f "$STAGE" data 2>/dev/null; then
    mv -f "data.old.$$" data 2>/dev/null
    echo "  [FAIL] could not activate new data; previous release restored."; exit 1
  fi
  for f in "data.old.$$"/*; do
    [ -e "$f" ] || continue
    base=$(basename "$f")
    case "$base" in
      gallery_high_*.json|gallery_rest_*.json|index.json) continue ;;
    esac
    [ -e "data/$base" ] || mv -f "$f" data/ 2>/dev/null
  done
  rm -rf "data.old.$$" 2>/dev/null
fi


[ "$ok" = 1 ] && echo "done — data/ ready. Now run the mirror (start-mirror.sh / Start Mirror.cmd / python serve.py)." \
             || { echo "some files failed to download from every mirror."; exit 1; }
