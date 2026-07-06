/* Read-only mirror viewer.
   No admin, no submissions/uploads, no tracking, no external hosts, no cookies.
   Media is served from THIS server (same origin) out of ./media/. Only change
   MEDIA_HOST if you deliberately serve media from another host YOU control. */
'use strict';

const MEDIA_HOST = '';          // '' = serve media from this same mirror (recommended)
const PAGE_SIZE  = 48;

const encPath   = p => (p || '').split('/').map(encodeURIComponent).join('/');
const mediaBase = e => e.media_base || '/';
const mediaUrl  = e => MEDIA_HOST + mediaBase(e) + encPath(e.file);
const thumbUrl  = e => e.thumbnail ? MEDIA_HOST + mediaBase(e) + encPath(e.thumbnail) : '';
const esc = s => (s || '').replace(/[&<>"']/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
const truncate = (s, n) => s.length > n ? s.slice(0, n).trim() + '…' : s;

let allEntries = [], filtered = [], page = 1, restLoaded = false, modalIndex = -1;

// ===== DEEP LINKS (#v=<id>) + SHARE =====
// Additive: with no #v= in the URL, nothing here changes the viewer's behaviour.
let pendingId = null, modalEntryId = null;
function parseDeep() { const m = (location.hash || '').match(/[#&]v=([^&]+)/); pendingId = m ? decodeURIComponent(m[1]) : null; }
function setHash(id) { try { history.replaceState(history.state, '', location.pathname + location.search + '#v=' + encodeURIComponent(id)); } catch (e) {} }
function clearHash() { try { if (/[#&]v=/.test(location.hash)) history.replaceState(history.state, '', location.pathname + location.search); } catch (e) {} }
function tryOpenPending() {
  if (!pendingId) return;
  const cw = document.getElementById('cw');
  if (cw && cw.style.display !== 'none' && !sessionStorage.getItem('cw-ok')) return; // wait for consent
  if (!allEntries.length) return;
  const entry = allEntries.find(e => String(e.id) === String(pendingId));
  if (!entry) { if (!restLoaded) return; pendingId = null; return; }
  pendingId = null;
  let i = filtered.findIndex(e => String(e.id) === String(entry.id));
  if (i < 0) {                                   // hidden by the current filter -> widen it, then find
    const g = id => document.getElementById(id);
    if (g('f-search')) g('f-search').value = '';
    if (g('f-conf')) g('f-conf').value = 'all';
    if (g('f-type')) g('f-type').value = '';
    if (g('f-archive')) g('f-archive').value = '';
    if (g('f-from')) g('f-from').value = '';
    if (g('f-to')) g('f-to').value = '';
    applyFilters();
    i = filtered.findIndex(e => String(e.id) === String(entry.id));
  }
  if (i >= 0) openModal(i);
}
function shareCurrent() {
  const e = filtered[modalIndex]; if (!e) return;
  const url = location.origin + location.pathname + '#v=' + encodeURIComponent(e.id);
  if (navigator.share) navigator.share({ url }).catch(() => {});
  else if (navigator.clipboard && navigator.clipboard.writeText) navigator.clipboard.writeText(url).then(() => toast('Link copied')).catch(() => fallbackCopy(url));
  else fallbackCopy(url);
}
function fallbackCopy(url) {
  try { const ta = document.createElement('textarea'); ta.value = url; ta.style.position = 'fixed'; ta.style.opacity = '0';
    document.body.appendChild(ta); ta.focus(); ta.select(); const ok = document.execCommand('copy'); document.body.removeChild(ta);
    toast(ok ? 'Link copied' : url); } catch (e) { toast(url); }
}
function toast(msg) { const t = document.createElement('div'); t.className = 'toast'; t.textContent = msg; document.body.appendChild(t); setTimeout(() => t.remove(), 2200); }

// English-only text: drop the "--- Original ---" (source-language) section.
function enText(e) {
  const raw = e.description_en || e.description || '';
  const i = raw.indexOf('\n--- Original ---');
  return (i !== -1 ? raw.slice(0, i) : raw).trim();
}
// Short, clean card caption: English lines only, no URLs/@handles.
function cardText(e) {
  return enText(e).split('\n').map(s => s.trim())
    .filter(s => s && !/^https?:\/\//.test(s) && !/^@\w/.test(s) && s.replace(/[^a-zA-Z]/g, '').length >= 6)
    .join(' ');
}

document.addEventListener('DOMContentLoaded', () => {
  parseDeep();
  setupContentWarning();
  setupFilters();
  setupModal();
  loadData();
});

// Hide broken thumbnails gracefully (no inline handlers, CSP-friendly).
document.addEventListener('error', e => {
  const t = e.target;
  if (t && t.tagName === 'IMG' && t.classList.contains('thumb')) {
    t.style.display = 'none';
    if (t.parentElement) t.parentElement.classList.add('no-thumb');
  }
}, true);

function setupContentWarning() {
  const ov = document.getElementById('cw');
  if (!ov) return;
  if (sessionStorage.getItem('cw-ok')) { ov.style.display = 'none'; tryOpenPending(); return; }
  document.getElementById('cw-enter').addEventListener('click', () => {
    ov.style.display = 'none'; sessionStorage.setItem('cw-ok', '1'); tryOpenPending();
  });
  document.getElementById('cw-leave').addEventListener('click', () => { location.href = 'about:blank'; });
}

async function loadData() {
  try {
    const [high, meta] = await Promise.all([
      fetch('gallery_high.json').then(r => r.json()),
      fetch('gallery_meta.json').then(r => r.ok ? r.json() : null).catch(() => null),
    ]);
    allEntries = high;
    fillArchives(meta);
    const _q = new URLSearchParams(location.search).get('q');
    if (_q) { const s = document.getElementById('f-search'); if (s) s.value = _q; }
    applyFilters();
    tryOpenPending();
    // Load the rest (non-high) in the background so first paint is fast.
    fetch('gallery_rest.json').then(r => r.ok ? r.json() : []).then(rest => {
      if (Array.isArray(rest) && rest.length) { allEntries = allEntries.concat(rest); restLoaded = true; applyFilters(); tryOpenPending(); }
    }).catch(() => {});
  } catch (err) {
    document.getElementById('grid').innerHTML =
      '<p class="msg">Could not load the gallery data. Make sure <code>gallery_high.json</code> is in <code>data/</code> (from the released torrent).</p>';
  }
}

function fillArchives(meta) {
  const sel = document.getElementById('f-archive');
  const names = (meta && meta.archives) || [...new Set(allEntries.map(e => e.source_archive).filter(Boolean))].sort();
  names.forEach(n => { const o = document.createElement('option'); o.value = n; o.textContent = n; sel.appendChild(o); });
}

function setupFilters() {
  const ids = ['f-search', 'f-conf', 'f-type', 'f-archive', 'f-from', 'f-to'];
  let t;
  ids.forEach(id => document.getElementById(id).addEventListener(
    id === 'f-search' ? 'input' : 'change',
    () => { clearTimeout(t); t = setTimeout(applyFilters, id === 'f-search' ? 200 : 0); }));
  document.getElementById('f-reset').addEventListener('click', () => {
    document.getElementById('f-search').value = '';
    document.getElementById('f-conf').value = 'high';
    document.getElementById('f-type').value = 'video';
    document.getElementById('f-archive').value = '';
    document.getElementById('f-from').value = '';
    document.getElementById('f-to').value = '';
    applyFilters();
  });
}

function applyFilters() {
  const q = document.getElementById('f-search').value.trim().toLowerCase();
  const conf = document.getElementById('f-conf').value;
  const type = document.getElementById('f-type').value;
  const arch = document.getElementById('f-archive').value;
  const from = document.getElementById('f-from').value, to = document.getElementById('f-to').value;

  filtered = allEntries.filter(e => {
    if (conf === 'high' && e.confidence !== 'high') return false;
    if (type && e.type !== type) return false;
    if (arch && e.source_archive !== arch) return false;
    if (from || to) {
      if (!e.timestamp) return false;
      const d = e.timestamp.slice(0, 10);
      if (from && d < from) return false;
      if (to && d > to) return false;
    }
    if (q) {
      const hay = ((e.description || '') + ' ' + (e.source_archive || '') + ' ' + (e.forwarded_from || '')).toLowerCase();
      if (!hay.includes(q)) return false;
    }
    return true;
  });
  // keep an open modal pinned to its entry across re-filtering
  if (modalEntryId != null) {
    const mo = document.getElementById('modal');
    if (mo && mo.style.display === 'flex') {
      const j = filtered.findIndex(e => String(e.id) === String(modalEntryId));
      if (j >= 0) modalIndex = j;
    }
  }
  page = 1;
  render();
}

function render() {
  const grid = document.getElementById('grid');
  const total = filtered.length;
  const pages = Math.max(1, Math.ceil(total / PAGE_SIZE));
  page = Math.min(page, pages);
  const slice = filtered.slice((page - 1) * PAGE_SIZE, page * PAGE_SIZE);

  document.getElementById('count').textContent =
    total.toLocaleString() + ' item' + (total === 1 ? '' : 's') + (restLoaded ? '' : ' (loading more…)');

  grid.innerHTML = slice.map((e, i) => {
    const idx = (page - 1) * PAGE_SIZE + i;
    const cap = truncate(cardText(e), 120);
    const badge = e.type === 'video' ? '▶' : '▣';
    const t = thumbUrl(e);
    return `<div class="card" data-i="${idx}">
      <div class="thumb-wrap">
        ${t ? `<img class="thumb" loading="lazy" src="${esc(t)}" alt="">` : ''}
        <span class="badge">${badge}${e.duration ? ' ' + esc(e.duration) : ''}</span>
      </div>
      ${cap ? `<div class="cap">${esc(cap)}</div>` : ''}
    </div>`;
  }).join('') || '<p class="msg">No items match your filters.</p>';

  grid.querySelectorAll('.card').forEach(c =>
    c.addEventListener('click', () => openModal(+c.dataset.i)));

  renderPager(pages);
}

function renderPager(pages) {
  const p = document.getElementById('pager');
  if (pages <= 1) { p.innerHTML = ''; return; }
  p.innerHTML =
    `<button ${page <= 1 ? 'disabled' : ''} data-p="${page - 1}">‹ Prev</button>
     <span>Page ${page} of ${pages}</span>
     <button ${page >= pages ? 'disabled' : ''} data-p="${page + 1}">Next ›</button>`;
  p.querySelectorAll('button[data-p]').forEach(b => b.addEventListener('click', () => {
    page = +b.dataset.p; render(); window.scrollTo({ top: 0, behavior: 'smooth' });
  }));
}

function setupModal() {
  document.getElementById('m-close').addEventListener('click', closeModal);
  const sb = document.getElementById('m-share'); if (sb) sb.addEventListener('click', shareCurrent);
  document.getElementById('modal').addEventListener('click', e => { if (e.target.id === 'modal') closeModal(); });
  document.addEventListener('keydown', e => {
    if (document.getElementById('modal').style.display !== 'flex') return;
    if (e.key === 'Escape') closeModal();
    if (e.key === 'ArrowRight') openModal(modalIndex + 1);
    if (e.key === 'ArrowLeft') openModal(modalIndex - 1);
  });
}

function openModal(i) {
  if (i < 0 || i >= filtered.length) return;
  modalIndex = i;
  const e = filtered[i];
  modalEntryId = e ? e.id : null;
  const box = document.getElementById('m-media');
  if (e.type === 'video') {
    box.innerHTML = `<video controls autoplay playsinline ${e.poster ? `poster="${esc(MEDIA_HOST + mediaBase(e) + encPath(e.poster))}"` : ''} src="${esc(mediaUrl(e))}"></video>`;
  } else {
    box.innerHTML = `<img src="${esc(mediaUrl(e))}" alt="">`;
  }
  const meta = [];
  if (e.source_archive) meta.push('Source: ' + esc(e.source_archive));
  if (e.timestamp) meta.push('Date: ' + esc(e.timestamp.slice(0, 10)));
  document.getElementById('m-meta').innerHTML = meta.join(' &nbsp;·&nbsp; ');
  document.getElementById('m-desc').textContent = enText(e) || '—';
  const link = document.getElementById('m-link');
  if (e.post_url && /^https?:\/\//.test(e.post_url)) { link.href = e.post_url; link.style.display = ''; }
  else link.style.display = 'none';
  document.getElementById('modal').style.display = 'flex';
  if (e) setHash(e.id);
}

function closeModal() {
  document.getElementById('m-media').innerHTML = '';   // stop video
  document.getElementById('modal').style.display = 'none';
  modalEntryId = null;
  clearHash();
}
