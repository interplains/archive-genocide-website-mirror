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
import http.server, os, posixpath, urllib.parse, json

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

# Bundled release artifacts that live at the repo root (not in web/ or the media dir).
# Served so the download page's ".torrent file" button and the magnet/checksum links work
# from the mirror itself. Any that a user fetches for verification (key.asc, SHA256SUMS*)
# are served too, if present.
ROOT_FILES = {'archivegenocide-media.torrent', 'MAGNET.txt',
              'key.asc', 'SHA256SUMS', 'SHA256SUMS.asc'}


def safe_join(base, rel):
    """Join base + rel, guaranteeing the result stays inside base (blocks ../ escape)."""
    rel = urllib.parse.unquote(rel)
    norm = posixpath.normpath('/' + rel).lstrip('/')
    full = os.path.normpath(os.path.join(base, norm.replace('/', os.sep)))
    if full == base or full.startswith(base + os.sep):
        return full
    return None


def _list_chunks():
    """Gallery index chunks: data/gallery_*.json (minus meta) + <media>/_index/*.json (bundled in volume torrents)."""
    chunks = []
    if os.path.isdir(DATA):
        for fn in sorted(os.listdir(DATA)):
            if fn.startswith('gallery_') and fn.endswith('.json') and fn != 'gallery_meta.json':
                chunks.append(fn)                       # fetched at  /<fn>
    idx = os.path.join(MEDIA, '_index')
    if os.path.isdir(idx):
        for fn in sorted(os.listdir(idx)):
            if fn.endswith('.json'):
                chunks.append('_index/' + fn)           # fetched at  /_index/<fn>  (via the media route)
    return chunks


def build_index():
    """Auto-discover gallery chunks and write data/index.json (the viewer's manifest). Adding a volume =
    drop its media + gallery chunk, then restart -- this finds it. The operator never hand-edits a manifest."""
    chunks = _list_chunks()
    primary = 'gallery_high.json' if 'gallery_high.json' in chunks else (chunks[0] if chunks else None)
    manifest = {'primary': primary, 'rest': [c for c in chunks if c != primary], 'chunks': chunks,
                'meta': 'gallery_meta.json' if os.path.isfile(os.path.join(DATA, 'gallery_meta.json')) else None,
                'generated_by': 'serve.py'}
    try:
        os.makedirs(DATA, exist_ok=True)
        with open(os.path.join(DATA, 'index.json'), 'w', encoding='utf-8') as f:
            json.dump(manifest, f, ensure_ascii=False, indent=1)
    except OSError:
        pass
    return manifest


class Handler(http.server.SimpleHTTPRequestHandler):
    def _resolve(self, path):
        p = path.split('?', 1)[0].split('#', 1)[0].lstrip('/')
        if p == '':
            return os.path.join(WEB, 'index.html')
        # data files: the fixed set + the generated manifest + any gallery_*.json chunk
        if '/' not in p and (p in DATA_FILES or p == 'index.json'
                             or (p.startswith('gallery_') and p.endswith('.json'))):
            j = safe_join(DATA, p)
            if j and os.path.isfile(j):
                return j
        # bundled release artifacts at the repo root (.torrent, MAGNET.txt, signing files)
        if '/' not in p and p in ROOT_FILES:
            j = safe_join(ROOT, p)
            if j and os.path.isfile(j):
                return j
        web = safe_join(WEB, p)
        if web and os.path.isfile(web):
            return web
        return safe_join(MEDIA, p)          # everything else = media/<archive>/<file> (incl. _index/*.json)

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

    def guess_type(self, path):
        # .mov/.quicktime/.m4v are QuickTime/H.264 containers browsers play as mp4; the default
        # guess (octet-stream / video/mov) + nosniff makes them refuse to play. Force video/mp4.
        if str(path).lower().endswith(('.mov', '.quicktime', '.m4v')):
            return 'video/mp4'
        return super().guess_type(path)

    def send_head(self):
        # Range-aware (video seeking); the stdlib handler ignores Range and always sends 200.
        path = self.translate_path(self.path)
        if os.path.isdir(path):
            self.send_error(404); return None
        ctype = self.guess_type(path)
        try:
            f = open(path, 'rb')
        except OSError:
            self.send_error(404, "File not found"); return None
        try:
            fs = os.fstat(f.fileno())
            size = fs[6]
            rng = self.headers.get('Range')
            if rng and rng.startswith('bytes='):
                try:
                    s, e = rng[6:].split('-', 1)
                    if s == '':
                        start = max(0, size - int(e)); end = size - 1
                    else:
                        start = int(s); end = int(e) if e else size - 1
                    end = min(end, size - 1)
                    if start > end or start >= size:
                        self.send_response(416)
                        self.send_header('Content-Range', 'bytes */%d' % size)
                        self.send_header('Content-Length', '0'); self.end_headers()
                        f.close(); return None
                    self._send_len = end - start + 1
                    self.send_response(206)
                    self.send_header('Content-Type', ctype)
                    self.send_header('Content-Range', 'bytes %d-%d/%d' % (start, end, size))
                    self.send_header('Content-Length', str(self._send_len))
                    self.send_header('Accept-Ranges', 'bytes')
                    self.send_header('Last-Modified', self.date_time_string(fs.st_mtime))
                    self.end_headers()
                    f.seek(start); return f
                except (ValueError, IndexError):
                    pass                                  # malformed Range -> full 200
            self._send_len = size
            self.send_response(200)
            self.send_header('Content-Type', ctype)
            self.send_header('Content-Length', str(size))
            self.send_header('Accept-Ranges', 'bytes')
            self.send_header('Last-Modified', self.date_time_string(fs.st_mtime))
            self.end_headers()
            return f
        except Exception:
            f.close(); raise

    def copyfile(self, source, outputfile):
        remaining = getattr(self, '_send_len', None)
        if remaining is None:
            return super().copyfile(source, outputfile)
        self._send_len = None
        while remaining > 0:
            chunk = source.read(min(65536, remaining))
            if not chunk:
                break
            outputfile.write(chunk); remaining -= len(chunk)


if __name__ == '__main__':
    import sys
    os.chdir(ROOT)
    manifest = build_index()            # auto-discover gallery chunks -> data/index.json
    nchunks = len(manifest.get('chunks') or [])
    if '--reindex' in sys.argv:          # for static hosts: regenerate the manifest and exit (no serving)
        print(f"Wrote data/index.json: {nchunks} gallery chunk(s) discovered.")
        sys.exit(0)
    print(f"Archive mirror running:  http://localhost:{PORT}")
    print(f"  media dir: {MEDIA}")
    print(f"  gallery chunks: {nchunks}" + (f" (primary: {manifest['primary']})" if manifest.get('primary') else "  -- none found; put gallery data in data/"))
    print("  (drop a new volume's media + gallery chunk here, then restart, to add it)")
    print("  read-only viewer — no admin, no submissions, no tracking, no outbound calls")
    try:
        http.server.ThreadingHTTPServer(('0.0.0.0', PORT), Handler).serve_forever()
    except KeyboardInterrupt:
        print("\nstopped.")
