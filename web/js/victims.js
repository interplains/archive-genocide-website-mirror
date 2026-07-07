/* Killed-in-Gaza list — dense tiles, 1000/page, youngest-first, "en_name (Age: X, sex)", search by name.
   Read-only, same-origin. Progressive: serve.py pre-sorts + splits victims.json into victims_NNNN.json
   (+ victims_index.json) so the first page paints after one small chunk; falls back to a single
   victims.json (sorted client-side) if the data hasn't been split. */
'use strict';
const PAGE = 1000;
let all = [], paged = {}, filtered = null, curPage = 1;
const esc = s => (s || '').replace(/[&<>"']/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));

function chunk(arr, size) {
  const c = {};
  for (let i = 0; i < arr.length; i += size) c[Math.floor(i / size) + 1] = arr.slice(i, i + size);
  return c;
}

function applySearch() {
  const q = document.getElementById('v-search').value.trim().toLowerCase();
  if (!q) { filtered = null; return false; }
  filtered = chunk(all.filter(p => (p.en_name || p.name || '').toLowerCase().includes(q)), PAGE);
  return true;
}

document.addEventListener('DOMContentLoaded', () => {
  const g = document.getElementById('v-grid');
  document.getElementById('v-search').addEventListener('input', () => { applySearch(); render(1); });
  // one delegated handler for the numbered page buttons (CSP-friendly, no inline onclick)
  g.closest('.page').addEventListener('click', ev => {
    const b = ev.target.closest('button[data-p]'); if (b) render(+b.dataset.p);
  });
  g.innerHTML = '<p class="msg">Loading…</p>';
  load();
});

async function load() {
  try {
    const m = await fetch('victims_index.json').then(r => r.ok ? r.json() : null).catch(() => null);
    if (m && m.primary) return loadChunks(m);
    return loadLegacy();
  } catch (e) { fail(); }
}

// robust chunk fetch: abort a hung request + retry so one bad chunk can't stall the load
function fetchJson(url, timeout = 30000, tries = 3) {
  return (async () => {
    for (let k = 0; k < tries; k++) {
      const ctrl = new AbortController();
      const t = setTimeout(() => ctrl.abort(), timeout);
      try { const r = await fetch(url, { signal: ctrl.signal }); clearTimeout(t); if (r.ok) return await r.json(); }
      catch (e) { clearTimeout(t); }
    }
    return [];
  })();
}

// Pre-sorted chunks: primary first (fast paint), then the rest ONE AT A TIME in manifest order,
// re-rendering after each so the list GROWS as it arrives (data is youngest-first, so order holds).
async function loadChunks(m) {
  if (m.total != null) document.getElementById('v-total').textContent = m.total.toLocaleString();
  const first = await fetchJson(m.primary);
  if (Array.isArray(first)) all = all.concat(first);
  paged = chunk(all, PAGE); render(1);
  for (const u of (m.rest || [])) {
    const p = await fetchJson(u);
    if (Array.isArray(p) && p.length) {
      all = all.concat(p); paged = chunk(all, PAGE);
      if (applySearch()) render(1); else render(curPage);   // re-apply an in-progress search over the full list
    }
  }
}

// Legacy: a single victims.json, sorted client-side (older data packs with no split).
async function loadLegacy() {
  const data = await fetch('victims.json').then(r => r.json()).catch(() => null);
  if (!data) return fail();
  const arr = Array.isArray(data) ? data : (data.data || []);
  document.getElementById('v-total').textContent = arr.length.toLocaleString();
  const ageNum = p => { const n = parseFloat(p.age); return isNaN(n) ? Infinity : n; };
  arr.sort((a, b) => ageNum(a) - ageNum(b));   // youngest first; unknown ages last
  all = arr; paged = chunk(all, PAGE); render(1);
}

function fail() {
  document.getElementById('v-grid').innerHTML =
    '<p class="msg">Could not load the victims list (from the release data).</p>';
}

function render(page) {
  curPage = page;
  const ds = filtered || paged, pd = ds[page], g = document.getElementById('v-grid');
  g.innerHTML = '';
  if (!pd) return;
  g.insertAdjacentHTML('beforeend', pd.map(p => {
    const age = (p.age != null && p.age !== '') ? p.age : '?';
    return `<div class="v-tile">${esc((p.en_name || p.name || '—') + ' (Age: ' + age + ', ' + (p.sex || '?') + ')')}</div>`;
  }).join(''));
  paginate(page);
}

function paginate(active) {
  const ds = filtered || paged, total = Object.keys(ds).length;
  let html = '';
  for (let i = 1; i <= total; i++) html += `<button data-p="${i}"${i === active ? ' class="active"' : ''}>${i}</button>`;
  document.querySelectorAll('.v-pagination').forEach(p => { p.innerHTML = html; });
}
