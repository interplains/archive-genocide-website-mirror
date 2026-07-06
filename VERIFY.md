# Verifying authenticity

Anyone can copy this project, so **don't trust a mirror until you've verified it.** Every
official release is signed with the project's **GPG key**. A tampered mirror — or a fake one
signed by a different key — **cannot** pass this check.

## The project's release-signing key

Fingerprint (also published on the official site's **[verify page](https://archivegenocide.com/verify.html)** and the project's pinned social posts):

```
C24E C92B 12D6 670A 2516  065F 9B4D 5754 99AF A53C
```

**Cross-check this fingerprint** against those sources. It must match all of them. A key you
find *only* on some random mirror means nothing.

## What an official release contains
- **`key.asc`** — the project's public GPG key
- **`SHA256SUMS`** — the SHA-256 of the release files
- **`SHA256SUMS.asc`** — the detached GPG signature over `SHA256SUMS`
- **`archivegenocide-media.torrent`** + **`MAGNET.txt`** — how you get the ~hundreds of GB of footage
- the **gallery data** (`gallery_high.json`, `gallery_rest.json`, `gallery_meta.json`) that this viewer reads

## Verify it (the easy way)
From the folder holding `key.asc`, `SHA256SUMS`, `SHA256SUMS.asc`, and the release files:

```sh
sh verify.sh
```
It checks the key fingerprint, verifies the signature, then checks the file hashes. If any
step fails, **stop** — the release is fake or tampered.

## Verify it (manually, no script)
Requires `gpg` (GnuPG) and `sha256sum` — standard on Linux/macOS.

```sh
# 1. import the key and confirm its fingerprint matches the one above
gpg --import key.asc
gpg --show-keys key.asc          # fingerprint must equal C24E C92B … 99AF A53C

# 2. verify the signature over SHA256SUMS   (expect: "Good signature")
gpg --verify SHA256SUMS.asc SHA256SUMS

# 3. verify your files match the signed hashes
sha256sum -c SHA256SUMS
```

## How the media is trusted
The signed `SHA256SUMS` pins **`archivegenocide-media.torrent`** (and `MAGNET.txt`). Once you
have that verified torrent, **BitTorrent verifies every one of the 167,000+ media files
piece-by-piece** against it as they download — so an altered file simply won't match, and the
magnet itself is inside the signed set. That's the full chain of trust for the footage:

> your trusted key → signed `SHA256SUMS` → authentic `.torrent` → BitTorrent-verified media.

## Two rules that keep you (and sources) safe
- **Never upload footage to a mirror.** Submissions go only through the official, verified
  channel. This kit has no upload form on purpose.
- **The signature is the source of truth**, not how official a mirror looks. Fakes copy the
  design; they can't copy the key.
