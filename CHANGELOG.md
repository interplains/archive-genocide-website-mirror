# Changelog

All notable changes to the Archive Genocide Website Mirror are recorded here.

## v1.2.0 — 2026-10-02

- **Daily Reports page** (`reports.html`): the live site's 516 day-by-day reports, searchable, with each day linking to
  its footage in the gallery (`index.html?from=…&to=…`, now read by the gallery).
- **Geolocation page** (`geolocation.html`): the three maps shown on the main site — genocide.live's documented footage
  map, the before/after satellite map from trackaipac (with their permission), and Abu Location's map. They are hosted
  by those sites, so each loads only when you press its button; nothing is fetched from outside before that.
- Both pages are in the menu of every page. Iris and the Node Map are not part of the mirror: they need the live server.

## v1.1.0 — 2026-10-01

- **Volume 3** (144.1 GB, 58,730 media files, infohash `7515dd4dc4b16b3a2c35d8e1cc992d18e19c63df`): on the download
  page, in `MAGNET.txt`, and bundled as `archivegenocide-media-volume3.torrent`. Same `archivegenocide-media` folder, so
  it merges with Volumes 1 and 2. Checksum + signature: `https://archivegenocide.com/SHA256SUMS-torrent3` (+ `.asc`).
- **Text posts view.** The archive now marks news graphics, quote/statistic cards and screenshots of text as
  `text_card`. They appear only under the new "Text posts" view, never in "Verified" or "All footage".
- **Fix:** the server now serves the bundled Volume 2 and Volume 3 `.torrent` files (the Volume 2 button returned 404).
- Download page: "Website & Source Code" listed first; figures refreshed (205,215 entries).

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
