# Archive Genocide Website Mirror

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
2. **the data files** → run **`get-data`** to fetch them into `data/` (once):
   - Windows: double-click `get-data.cmd` · Mac/Linux: `bash get-data.sh`
   - grabs `gallery_high.json`, `gallery_rest.json`, `gallery_meta.json`, `victims.json` (~95 MB) from the
     official mirrors — it tries **archivegenocide.com → .org → .is** in turn, so one being down or blocked
     doesn't stop you. This is the *only* step that touches the network; the server never does.
   - **Privacy / blocked networks:** fetch it your own way instead — `bash get-data.sh https://a-mirror-you-trust.example`,
     or route the default fetch through Tor with `torsocks bash get-data.sh`. *(These are just a plain HTTPS download
     of public, edge-cached files — the same thing your browser does visiting the site.)*
3. **the footage** → the **`archivegenocide-media/`** folder  *(from the signed torrent)*

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
*(To let **other people** see your mirror, see **"Share it online"** just below.)*

---

## 📢 Share it online (let other people see your mirror)
By default the mirror is visible only on your own computer. To share it — easiest first:

- **Just want to help it survive?** Keep the footage **torrent seeding** in your torrent app.
  That alone re-shares the footage so it can't be wiped out — no website needed.
- **Want to give people a link right now?** One click:
  - **Windows:** double-click **`share-online.cmd`** · **Mac/Linux:** run **`share-online.sh`**

  It prints a public link (ending in `.trycloudflare.com`) you can paste to anyone. It's free,
  needs no account, and **keeps your home IP address hidden.** Your computer serves it, so the
  link works while your PC is on and that window stays open.
- **Want a permanent, always-on mirror?** Rent a small cheap server — see **[`HOSTING.md`](HOSTING.md)**.

Full details and trade-offs, in plain English: **[`HOSTING.md`](HOSTING.md)**.

---

## Adding future releases (Volume 2, 3, …)
The archive grows in **additive volumes**, all sharing the one `archivegenocide-media/` folder
(so nothing is ever re-downloaded). Adding one is drop-in:

1. Download the new volume's torrent into your existing **`archivegenocide-media/`** folder.
2. If its gallery chunk wasn't bundled in the torrent, drop `gallery_<vol>.json` into `data/`.
3. **Restart.** On startup the server auto-discovers every chunk (from `data/` *and* a bundled
   `archivegenocide-media/_index/`), rebuilds `data/index.json`, and the new footage appears —
   **already searchable and sorted**, its source added to the filter dropdown.

You never hand-edit a manifest, and a mirror holding only *some* volumes just shows those (no
broken cards). Static host? run `python serve.py --reindex` to regenerate the manifest, then redeploy.

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
