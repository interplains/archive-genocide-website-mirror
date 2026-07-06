#!/usr/bin/env python3
"""
Zero-dependency viewer for a MIRROR of the archive.

Serves three things, strictly read-only — NO admin, NO submissions/uploads,
NO tracking, NO outbound network calls:

  web/    the front-end (index.html, css, js, icons)  ->  served at  /
  data/   gallery_*.json + decisions.json             ->  served at  /gallery_high.json ...
  media/  the footage (from the signed torrent)       ->  served at  /<archive>/<file>

Quick start:
    python3 serve.py                 # then open http://localhost:8000
    PORT=9000 python3 serve.py       # custom port

Put the gallery JSON in ./data/ and the media folders in ./media/ (both come from
the released torrent). Nothing here phones home or accepts input.
"""
import http.server, os, posixpath, urllib.parse

ROOT  = os.path.dirname(os.path.abspath(__file__))
WEB   = os.path.join(ROOT, 'web')
DATA  = os.path.join(ROOT, 'data')
def _media_dir():
    # Where the footage lives. MEDIA_DIR env wins; otherwise auto-detect the released
    # torrent folder ("archivegenocide-media") or a plain "media/" next to this script.
    # The signed torrent extracts to  archivegenocide-media/<slug>/<file>  — which is
    # exactly the path the gallery references — so no renaming/moving of the media is needed.
    env = os.environ.get('MEDIA_DIR')
    if env:
        return os.path.abspath(env)
    for cand in ('archivegenocide-media', 'media'):
        p = os.path.join(ROOT, cand)
        if os.path.isdir(p):
            return p
    return os.path.join(ROOT, 'media')

MEDIA = _media_dir()
PORT  = int(os.environ.get('PORT', '8000'))
DATA_FILES = {'gallery_high.json', 'gallery_rest.json', 'gallery_meta.json',
              'decisions.json', 'victims.json'}


def safe_join(base, rel):
    """Join base + rel, guaranteeing the result stays inside base (blocks ../ escape)."""
    rel = urllib.parse.unquote(rel)
    norm = posixpath.normpath('/' + rel).lstrip('/')
    full = os.path.normpath(os.path.join(base, norm.replace('/', os.sep)))
    if full == base or full.startswith(base + os.sep):
        return full
    return None


class Handler(http.server.SimpleHTTPRequestHandler):
    def _resolve(self, path):
        p = path.split('?', 1)[0].split('#', 1)[0].lstrip('/')
        if p == '':
            return os.path.join(WEB, 'index.html')
        if p in DATA_FILES:
            return safe_join(DATA, p)
        web = safe_join(WEB, p)
        if web and os.path.isfile(web):
            return web
        return safe_join(MEDIA, p)          # everything else = media/<archive>/<file>

    def translate_path(self, path):
        return self._resolve(path) or os.path.join(WEB, '__no_such_file__')

    def list_directory(self, path):         # never expose directory listings
        self.send_error(404)
        return None

    def end_headers(self):
        self.send_header('X-Content-Type-Options', 'nosniff')
        self.send_header('Referrer-Policy', 'no-referrer')
        super().end_headers()

    def log_message(self, *a):              # quiet
        pass


if __name__ == '__main__':
    os.chdir(ROOT)
    print(f"Archive mirror running:  http://localhost:{PORT}")
    print(f"  media dir: {MEDIA}")
    print("  (put the released 'archivegenocide-media/' folder here, or set MEDIA_DIR=/path/to/it)")
    print("  read-only viewer — no admin, no submissions, no tracking, no outbound calls")
    try:
        http.server.ThreadingHTTPServer(('0.0.0.0', PORT), Handler).serve_forever()
    except KeyboardInterrupt:
        print("\nstopped.")
