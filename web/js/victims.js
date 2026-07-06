/* Killed-in-Gaza memorial list. Read-only, same-origin fetch, no external calls. */
'use strict';
let VICT = [], filtered = [], shown = 0;
const PAGE = 300;
const esc = s => (s || '').replace(/[&<>"']/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));

document.addEventListener('DOMContentLoaded', () => {
  document.getElementById('v-more').addEventListener('click', more);
  document.getElementById('v-search').addEventListener('input', e => render(e.target.value.trim().toLowerCase()));
  fetch('victims.json').then(r => r.json()).then(d => {
    VICT = Array.isArray(d) ? d : (d.data || []);
    document.getElementById('v-total').textContent = VICT.length.toLocaleString();
    render('');
  }).catch(() => {
    document.getElementById('v-list').innerHTML =
      '<p class="msg">Could not load <code>victims.json</code> — it ships with the release data (put it in <code>data/</code>).</p>';
  });
});

function render(q) {
  filtered = q ? VICT.filter(v => ((v.en_name || '') + ' ' + (v.name || '')).toLowerCase().includes(q)) : VICT;
  shown = 0;
  document.getElementById('v-count').textContent = filtered.length.toLocaleString() + ' names';
  document.getElementById('v-list').innerHTML = '';
  more();
}

function more() {
  const slice = filtered.slice(shown, shown + PAGE);
  document.getElementById('v-list').insertAdjacentHTML('beforeend', slice.map(v => {
    const age = (v.age !== null && v.age !== undefined && v.age !== '') ? ', age ' + esc(String(v.age)) : '';
    const sx = v.sex === 'm' ? 'Male' : v.sex === 'f' ? 'Female' : '';
    const meta = (sx || age) ? `<div class="dt">${esc(sx)}${age}</div>` : '';
    const ar = (v.name && v.en_name) ? `<div class="ar" dir="rtl">${esc(v.name)}</div>` : '';
    return `<div class="v-card"><div class="nm">${esc(v.en_name || v.name || '—')}</div>${ar}${meta}</div>`;
  }).join(''));
  shown += slice.length;
  const b = document.getElementById('v-more');
  b.style.display = shown < filtered.length ? '' : 'none';
  b.textContent = 'Show more (' + (filtered.length - shown).toLocaleString() + ' remaining)';
}
