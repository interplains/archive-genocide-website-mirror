#!/bin/sh
# Verify that a release of this archive is authentic and untampered.
#
#   sh verify.sh
#
# From a folder containing:  key.asc  SHA256SUMS  SHA256SUMS.asc  archivegenocide-media.torrent
# It (1) checks the public key's fingerprint, (2) verifies the GPG signature over
# SHA256SUMS, then (3) checks that your files match those signed hashes. The media itself
# is then verified piece-by-piece by BitTorrent as you download the magnet in the torrent.
#
# Requires: gpg (GnuPG) and sha256sum (coreutils) -- standard on Linux/macOS.
set -eu

# ---- The project's release-signing GPG key fingerprint.
# CROSS-CHECK it against the official site (https://archivegenocide.com/verify.html) and the
# project's pinned social posts. If it differs anywhere, do NOT trust the copy.
FPR="C24E C92B 12D6 670A 2516  065F 9B4D 5754 99AF A53C"
FPR_NOSPACE="C24EC92B12D6670A2516065F9B4D575499AFA53C"
# -------------------------------------------------------------------------------------

need() { command -v "$1" >/dev/null 2>&1 || { echo "missing required tool: $1"; exit 2; }; }
need gpg; need sha256sum

# Fetch the official signing files if they aren't already here (same trusted sources as get-data).
# This is only a convenience — the fingerprint check below is the real trust anchor: a wrong or
# forged key.asc is rejected no matter where it came from.
SOURCES="https://archivegenocide.com https://archivegenocide.org https://archivegenocide.is"
for f in key.asc SHA256SUMS SHA256SUMS.asc; do
  if [ ! -f "$f" ] && command -v curl >/dev/null 2>&1; then
    for base in $SOURCES; do
      curl -fsS -o "$f" "$base/$f" 2>/dev/null && break
    done
    [ -s "$f" ] || rm -f "$f"
  fi
  [ -f "$f" ] || { echo "could not obtain $f — are you online? (or download it from https://archivegenocide.com/$f)"; exit 2; }
done

echo "1) Checking the public key's fingerprint..."
GOTFPR=$(gpg --with-colons --show-keys key.asc 2>/dev/null | awk -F: '/^fpr:/{print $10; exit}')
if [ "$GOTFPR" != "$FPR_NOSPACE" ]; then
  echo "   [FAIL] key.asc fingerprint is $GOTFPR"
  echo "          expected                $FPR_NOSPACE  -- do NOT trust this copy."
  exit 1
fi
echo "   [OK] fingerprint matches:  $FPR"
gpg --quiet --import key.asc 2>/dev/null || true

echo "2) Verifying the SHA256SUMS signature..."
if gpg --verify SHA256SUMS.asc SHA256SUMS 2>&1 | grep -q "Good signature"; then
  echo "   [OK] SHA256SUMS is authentically signed by the project's key"
else
  echo "   [FAIL] signature is INVALID -- this copy is fake or tampered. Do NOT trust it."
  exit 1
fi

echo "3) Checking your files against the signed hashes..."
CHECK=$(sha256sum -c SHA256SUMS 2>&1 || true)
printf '%s\n' "$CHECK" | sed 's/^/   /'
if printf '%s' "$CHECK" | grep -q 'FAILED'; then
  echo "   [FAIL] a file does NOT match its signed hash -- tampered. Do NOT trust it."
  exit 1
fi

echo
echo "Authentic. Load the .torrent / magnet next -- BitTorrent verifies every one of the"
echo "media files piece-by-piece against the (now-verified) torrent as it downloads."
