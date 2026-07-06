ARCHIVE GENOCIDE WEBSITE MIRROR  —  run your own copy
==================================================

This is a read-only copy of the archive that you can run on your own computer.
The point: make the documentation impossible to erase. Anyone can host a copy, so
no single takedown, host, or country can remove the evidence.

You need three things together in this folder:
   1) this code            (you already have it)
   2) the DATA files    ->  run  get-data  (below) to fetch them into  data\
   3) the FOOTAGE       ->  the  "archivegenocide-media"  folder   (from the torrent)

GET THE DATA (do this once):
   Windows:      double-click   get-data.cmd
   Mac / Linux:  run            bash get-data.sh
   It downloads the gallery + victims files (~95 MB) into  data\  from
   https://archivegenocide.com  (gallery_high.json, gallery_rest.json,
   gallery_meta.json, victims.json). That's the only step that touches the network;
   the mirror server itself never does.


--------------------------------------------------------------------
EASIEST WAY  —  let Claude Code set it up for you
--------------------------------------------------------------------
If you have Claude Code (https://claude.ai/code), open it in this folder and say:

      read claudeinstall.md and set up the mirror for me

It checks everything, asks where your footage is, starts the server, and opens it
in your browser. You don't have to touch any code.


--------------------------------------------------------------------
NO CLAUDE?  —  just double-click
--------------------------------------------------------------------
   Windows:      double-click   Start Mirror.cmd
   Mac / Linux:  run            start-mirror.sh    (or:  bash start-mirror.sh)

It asks you to point to your footage folder, then opens the archive in your browser at
   http://localhost:8000
Keep the window open while you use it; close it to stop.

Tip: if you put the "archivegenocide-media" folder right next to this file, it's found
automatically and you won't even be asked.


--------------------------------------------------------------------
MANUAL (advanced)  —  needs Python 3
--------------------------------------------------------------------
From this folder:

      python serve.py

If your footage is somewhere else, point to it:

      Windows:    set "MEDIA_DIR=D:\path\to\archivegenocide-media" && python serve.py
      Mac/Linux:  MEDIA_DIR="/path/to/archivegenocide-media" python3 serve.py

(To let OTHER PEOPLE see your mirror, see "SHARE IT ONLINE" below.)


--------------------------------------------------------------------
SHARE IT ONLINE  (let other people see your mirror)
--------------------------------------------------------------------
By default the mirror is only on your own computer. To share it:

  * Just want to help it survive?
    Keep the footage TORRENT seeding in your torrent app. That alone
    re-shares the footage so it can't be wiped out - no website needed.

  * Want to give people a link right now?  One click:
      Windows:    double-click  share-online.cmd
      Mac/Linux:  run           share-online.sh
    It prints a public link (ending in .trycloudflare.com) you can send
    to anyone. Free, no account, and your home IP address stays hidden.
    Your computer serves it, so the link works while your PC is on and
    that window stays open.

  * Want a permanent, always-on mirror?
    Rent a small cheap server - see  HOSTING.md.

  Full details, in plain English:  HOSTING.md


--------------------------------------------------------------------
ADDING FUTURE RELEASES (Volume 2, 3, ...)
--------------------------------------------------------------------
The archive grows in "volumes." Adding one is drop-in:

   1) Download the new volume's torrent into the SAME  archivegenocide-media  folder
      (all volumes share it -- nothing is re-downloaded).
   2) If its gallery chunk wasn't inside the torrent, drop  gallery_<vol>.json  into  data/.
   3) Restart (double-click / re-run). The server auto-detects everything and the new
      footage appears -- already searchable and sorted, its source in the filter list.

You never edit a config file. (Static host? run  python serve.py --reindex  then redeploy.)


--------------------------------------------------------------------
IS IT REAL / IS IT SAFE?
--------------------------------------------------------------------
Anyone can copy this, so VERIFY a download before trusting it — see VERIFY.md, or run:

      sh verify.sh

Two rules that keep you and sources safe:
   * NEVER upload footage to a mirror. This copy has no upload form on purpose.
   * The cryptographic SIGNATURE is what proves a copy is genuine — not how it looks.

This viewer is read-only: no admin, no login, no uploads, no tracking, and it makes no
connection to the internet. Everything is served from your own computer.

License: MIT (see LICENSE).
