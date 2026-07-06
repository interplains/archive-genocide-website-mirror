# War Crimes Archive — Open-Source Mirror Kit

A **read-only, self-hostable copy** of the archive. The goal is simple: **make the
documentation impossible to erase.** Anyone can run their own mirror, so no single
takedown, host, or country can remove the evidence.

This repo is the **viewer** (a tiny server + front-end). The **footage and gallery data**
are distributed separately as a signed torrent (they're huge and travel peer-to-peer, so
anyone can re-seed them).

> 📄 Prefer plain text? Everything below is also in **[`README.txt`](README.txt)**.

---

## You need three things together in one folder
1. **this code** — you have it
2. **the data files** → put them in `data/`  *(from the release)*
3. **the footage** → the **`archivegenocide-media/`** folder  *(from the torrent)*

---

## Run it — three ways, easiest first

### 🟢 Easiest — let Claude Code set it up
If you have [Claude Code](https://claude.ai/code), open it in this folder and say:

> **read `claudeinstall.md` and set up the mirror for me**

It checks everything, asks where your footage is, starts the server, and opens it in your
browser — you never touch any code.

### 🖱️ No Claude — just double-click
- **Windows:** double-click **`Start Mirror.cmd`**
- **Mac / Linux:** run **`start-mirror.sh`** (double-click, or `bash start-mirror.sh`)

It asks you to point to your footage folder, then opens the archive at
**http://localhost:8000**. Keep the window open while you use it; close it to stop.
*(If you drop `archivegenocide-media/` right next to these files, it's found automatically
and won't even ask.)*

### ⌨️ Manual (advanced) — needs Python 3
```sh
python serve.py                                   # footage auto-detected next to serve.py
MEDIA_DIR="/path/to/archivegenocide-media" python3 serve.py   # or point it anywhere
```
To expose a mirror publicly, put it behind a normal web server / CDN (nginx, Caddy, a CDN
pull-zone) rather than exposing this server directly.

---

## What it is / isn't
**It is:** a zero-dependency, read-only viewer. Open the footage, search, filter, watch.

**It deliberately has NO:**
- admin panel, login, or any write/edit capability
- **submission or upload form** — this protects sources; no legitimate mirror will ever ask
  you to upload
- tracking, analytics, cookies, or **any outbound network request**

Everything is served from your own machine. It never phones home.

---

## ⚠️ Verify authenticity before trusting a mirror
Anyone can copy this, so a bad actor could publish a **tampered** copy. Protect yourself:

- **Check the signature.** Every official data release is signed with the project's GPG key.
  Before trusting a copy, verify it — see **[`VERIFY.md`](VERIFY.md)** or run `sh verify.sh`.
- **Never submit footage to a mirror.** Submissions go only through the project's official,
  verified channel.
- The **official domains, public key, and release hashes** are the source of truth. A mirror
  can re-host the data; it cannot *be* the official source.

---

## License
Code: **MIT** (see [`LICENSE`](LICENSE)) — reuse and re-host freely. The footage is documentary
evidence collected for accountability; provided as-is for documentation and the public record.
