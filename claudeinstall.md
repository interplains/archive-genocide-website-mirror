# Set up this mirror — instructions for Claude Code

**You are Claude Code, helping a non-technical user run a local, read-only mirror of the
War Crimes Archive from *this* folder.** Be friendly and do the work for them. Walk through
these steps, explaining briefly as you go. Do not modify the code, do not expose anything to
the internet, and do not send any data anywhere — this is a fully local, offline viewer.

## Steps

1. **Check Python 3.** Run `python3 --version` (or `python --version`). If it's missing, tell
   the user to install Python 3 from https://www.python.org/downloads/ (on Windows, tick
   "Add python.exe to PATH"), then stop and ask them to re-run you afterward.

2. **Check the gallery data.** Confirm `data/gallery_high.json` exists.
   - If it's missing, offer to fetch it: run **`bash get-data.sh`** (or `get-data.cmd` on Windows),
     which downloads `gallery_high.json`, `gallery_rest.json`, `gallery_meta.json`, `victims.json`
     (~95 MB) into `data/` from `https://archivegenocide.com`. Then continue.

3. **Find the footage.** The media lives in a folder named **`archivegenocide-media/`** (from
   the signed torrent). Each `<slug>/<file>` inside it matches what the gallery references.
   - If `archivegenocide-media/` (or a non-empty `media/`) already sits next to `serve.py`,
     use it as-is.
   - Otherwise, **ask the user**: "Where did you download/extract the archive's footage folder
     (`archivegenocide-media`)?" Take their answer and use it as `MEDIA_DIR`.

4. **(Optional) Verify authenticity.** If `SHA256SUMS`, `SHA256SUMS.asc`, and `key.asc` are in
   the folder, offer to run `sh verify.sh` so they know the release is genuine (the signing-key
   fingerprint is `C24E C92B 12D6 670A 2516 065F 9B4D 5754 99AF A53C`). If it fails, warn them
   the copy may be tampered and stop.

5. **Start the server.** Run `serve.py`, passing `MEDIA_DIR` if you got a path in step 3:
   - Windows: `set "MEDIA_DIR=<their path>" && python serve.py`
   - macOS/Linux: `MEDIA_DIR="<their path>" python3 serve.py`
   - If the media was already found next to `serve.py`, just run `python serve.py`.
   It listens on **http://localhost:8000**. Run it in the background/a separate process so you
   can keep talking to the user.

6. **Open it.** Open **http://localhost:8000** in their browser and confirm the gallery loads
   (thumbnails may take a moment). If media doesn't play, re-check the `MEDIA_DIR` path from step 3.

7. **Explain & hand off.** Tell them plainly:
   - It's running **locally and read-only** — no admin, no login, no uploads, no tracking, no
     outbound connections.
   - To **stop** it: close that terminal / stop the `serve.py` process.
   - To **run it again** later: just launch you again and say "start the mirror", or double-click
     `Start Mirror.cmd` (Windows) / `start-mirror.sh` (Mac/Linux).

## Adding a new volume later
When a new release volume (Vol 2, Vol 3 …) comes out, the archive grows. To add one:
1. **Get its media** — download that volume's torrent into the **same** `archivegenocide-media/`
   folder (all volumes share that one folder; nothing is re-downloaded). Its `<slug>/` folders —
   and, if bundled, a small `_index/<vol>.json` — land alongside the existing ones.
2. **Get its gallery chunk** if it wasn't bundled in the torrent — drop `gallery_<vol>.json` into
   `data/`.
3. **Verify** (`sh verify.sh`) — the signed `SHA256SUMS` covers each volume.
4. **Restart the server** — on startup it auto-discovers every chunk and rebuilds `data/index.json`;
   the new footage appears, already searchable and sorted, with its source in the filter dropdown.
   (Static host? run `python serve.py --reindex` to regenerate `data/index.json`, then redeploy.)
Do **not** hand-edit any manifest and do **not** add un-official, unsigned media — mirrors stay
faithful copies; curation and signing happen upstream.

## Safety rules (tell the user)
- **Never upload footage to a mirror.** This kit has no upload form on purpose; submissions go
  only through the archive's official verified channel.
- **The signature is what proves a copy is real** — not how official it looks.
