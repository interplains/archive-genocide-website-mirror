# Putting your mirror online (sharing it with others)

Running the mirror normally shows it only on **your own computer** (`http://localhost:8000`).
This guide is how to let **other people** see it too.

Pick the level that fits you. They go easiest → hardest, and **you do not need the hard ones.**

---

## Level 0 — Just seed the torrent  *(recommended for almost everyone)*
You don't have to host a website at all. The single most useful thing you can do is
**keep the footage torrent open in your torrent app.** That re-shares the footage to everyone
else, so it can never be wiped out.

- No setup, no cost, nothing about you is exposed.
- **If you just want to help the archive survive, this is it — you're done.**

---

## Level 1 — A quick public link  *(share it for a while)*
Turns your running mirror into a normal web link — like `https://blue-tree-1234.trycloudflare.com` —
that you can send to friends or post online.

**How — one click:**
- **Windows:** double-click **`share-online.cmd`**
- **Mac / Linux:** run **`share-online.sh`**  (`bash share-online.sh`)

It gets everything ready and prints your link. **Copy the line ending in `.trycloudflare.com`
and share it.** (The first time, it may ask you to install one small free tool, `cloudflared` —
it tells you exactly how.)

**In plain English:**
- ✅ Free, no account, ready in seconds.
- ✅ **Your home IP address stays hidden** — visitors reach it through Cloudflare, not directly.
- ⚠️ **Your computer does the work.** The link only lives while your PC is on and that window is
  open. Close the window (or shut down) and the link stops — that's normal.
- ⚠️ Great for a handful of viewers or a temporary share; not built for a huge sudden crowd.

---

## Level 2 — Always online  *(a real, permanent mirror)*
Want a mirror that stays up 24/7 even when your computer is off? Rent a small, cheap server
(a "VPS", a few dollars a month) and run the mirror there instead.

This one is for someone comfortable with a command line. The short version:

1. Rent a small VPS (Debian or Ubuntu). Free-speech-friendly hosts are the safest choice.
2. On the VPS: install Python, copy this code over, and **download the footage torrent onto the
   VPS itself** — it pulls from the swarm, so you never upload the huge folder yourself.
3. Run `python serve.py` behind a normal web server (**nginx** or **Caddy**) so it has HTTPS.
4. Point a domain at it — ideally through **Cloudflare (free)**, which adds HTTPS, hides the
   server's IP, and caches pages so the box isn't overloaded.

Money-saving tip: the footage is large, so either use a VPS with a big disk, or serve the media
from cheap object storage (Backblaze B2 / Cloudflare R2) — the same split the official site uses.

**Shortcut:** open **Claude Code** in this folder and ask it to *"walk me through setting up a
permanent VPS mirror."* It can do most of the steps for you.

---

## Which should I pick?
| You want to… | Do this |
|---|---|
| Just help the archive survive | **Level 0** — seed the torrent. Truly enough. |
| Show some people right now | **Level 1** — run `share-online`. |
| Have a permanent public mirror on its own web address | **Level 2** — a small VPS. |

Whatever you choose, **your IP stays hidden** as long as you use a tunnel (Level 1) or put
Cloudflare in front (Level 2) — never expose your home connection directly.
