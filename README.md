# War Crimes Archive — Open-Source Mirror Kit

A **read-only, self-hostable copy** of the archive. The goal is simple: **make the
documentation impossible to erase.** Anyone can run their own mirror, so no single
takedown, host, or country can remove the evidence.

This repo is the **viewer** (front-end + a tiny server). The **footage and gallery data**
are distributed separately as a signed torrent (see [Releases](#getting-the-data)), so the
~hundreds of GB of media travel peer-to-peer and can be re-seeded by anyone.

---

## What it is / isn't

**It is:** a zero-dependency, read-only viewer. Open the footage, search, filter, watch.

**It deliberately has NO:**
- admin panel, login, or any write/edit capability
- **submission or upload form** (see the safety note below — this protects sources)
- tracking, analytics, cookies, or **any outbound network request**

Everything is served from your own machine. It never phones home.

---

## Run your own mirror (3 steps)

1. **Get the code** (this repo):
   ```
   git clone <repo-url>  &&  cd <repo>
   ```
2. **Get the data** — download the released torrent (magnet link on the
   [official releases page]) and extract it so you have:
   ```
   ./data/     gallery_high.json, gallery_rest.json, gallery_meta.json  (+ decisions.json)
   ./media/    <archive>/<files…>   (the footage)
   ```
3. **Run it** (needs only Python 3 — nothing to install):
   ```
   python3 serve.py
   ```
   Open **http://localhost:8000**. To expose it publicly, put it behind any web
   server / CDN you like (nginx, Caddy, a CDN pull-zone, etc.).

That's it. You now have a full, independent mirror.

---

## ⚠️ Verify authenticity before trusting a mirror

Because anyone can copy this, a bad actor could publish a **tampered mirror** (faked or
altered footage) or a **fake submission page** to harvest sources. Protect yourself:

- **Check the signature.** Every official data release is cryptographically signed. Before
  trusting a copy, verify it against the project's public key — see **[`VERIFY.md`](VERIFY.md)**.
- **Never submit footage to a mirror.** Submissions go **only** through the project's
  official, verified channel. No legitimate mirror will ever ask you to upload — this kit
  has no submission form on purpose.
- The **official domains, public key, and release hashes** are the source of truth. A mirror
  can re-host the data; it cannot be the official source.

---

## Getting the data

The media + gallery JSON are published as a **signed torrent** (magnet link + `.torrent`)
plus checksums, on the official releases page. Seed it if you can — every seeder makes the
archive harder to erase.

---

## License

Code: **MIT** (see [`LICENSE`](LICENSE)) — reuse and re-host freely.
The footage is documentary evidence collected for accountability; it is provided as-is for
documentation and the public record.
