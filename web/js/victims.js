/* Killed-in-Gaza list — mirrors the live site: dense tiles, 1000/page, youngest-first,
   "en_name (Age: X, sex)", search by name. Read-only, same-origin fetch of victims.json. */
'use strict';
const PAGE = 1000;
let paged = {}, filtered = null;
const esc = s => (s || '').replace(/[&<>"']/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));

function chunk(arr, size) {
  const c = {};
  for (let i = 0; i < arr.length; i += size) c[Math.floor(i / size) + 1] = arr.slice(i, i + size);
  return c;
}

document.addEventListener('DOMContentLoaded', () => {
  const g = document.getElementById('v-grid');
  document.getElementById('v-search').addEventListener('input', e => {
    const q = e.target.value.toLowerCase();
    if (!q) { filtered = null; render(1); return; }
    const flat = Object.values(paged).flat().filter(p => (p.en_name || p.name || '').toLowerCase().includes(q));
    filtered = chunk(flat, PAGE); render(1);
  });
  // one delegated handler for the numbered page buttons (CSP-friendly, no inline onclick)
  g.closest('.page').addEventListener('click', ev => {
    const b = ev.target.closest('button[data-p]'); if (b) render(+b.dataset.p);
  });
  g.innerHTML = '<p class="msg">Loading…</p>';
  fetch('victims.json').then(r => r.json()).then(data => {
    const arr = Array.isArray(data) ? data : (data.data || []);
    document.getElementById('v-total').textContent = arr.length.toLocaleString();
    const ageNum = p => { const n = parseFloat(p.age); return isNaN(n) ? Infinity : n; };
    arr.sort((a, b) => ageNum(a) - ageNum(b));   // youngest first; unknown ages last
    paged = chunk(arr, PAGE); render(1);
  }).catch(() => { g.innerHTML = '<p class="msg">Could not load <code>victims.json</code> (from the release data).</p>'; });
});

function render(page) {
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
