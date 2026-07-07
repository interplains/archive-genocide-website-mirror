# Changelog

All notable changes to the Archive Genocide Website Mirror are recorded here.

## v1.0.0 — 2026-07-08

First public release.

- **Read-only viewer** for the archive: gallery with search and filters (confidence, type,
  source, date), a lightbox with video playback, per-clip shareable deep-links, and a download
  button.
- **Seven pages**: Archive (gallery), Live Map, Sources, Victims (the Killed-in-Gaza list),
  Download, Verify, and About.
- **Zero-dependency local server** (`serve.py`): auto-detects the media, supports video seeking
  (HTTP Range), is path-traversal-safe, serves no directory listings, and makes no outbound calls.
- **Volume auto-discovery**: drop a new volume's media + gallery chunk in and restart — it
  appears automatically, already searchable and sorted.
- **Authenticity**: a GPG verification chain (`verify.sh` / `VERIFY.md`) against the project's
  signed release; the media is then verified piece-by-piece by BitTorrent.
- **Self-host + share tools**: one-command `get-data` (with `.com → .org → .is` fallback and
  Tor / custom-source options) and one-click `share-online` (Cloudflare quick tunnel), plus a
  plain-English `HOSTING.md`.
- Strict same-origin Content-Security-Policy; no external resources, fonts, or trackers.
