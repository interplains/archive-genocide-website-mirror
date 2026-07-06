/* Caption-derived choropleth. The archive has no GPS data, so we count clips whose
   captions name each governorate. Read-only, same-origin, no external calls. */
'use strict';
const REGIONS = {
  'north-gaza':    { q: 'jabalia',       keys: ['beit hanoun', 'beit lahia', 'jabalia', 'jabaliya'] },
  'gaza-city':     { q: 'gaza city',     keys: ['gaza city', 'shujaiya', 'zeitoun', 'al-shati', 'tuffah'] },
  'deir-al-balah': { q: 'deir al-balah', keys: ['deir al-balah', 'deir el-balah', 'nuseirat', 'bureij', 'maghazi'] },
  'khan-younis':   { q: 'khan younis',   keys: ['khan younis', 'khan yunis', 'bani suheila', 'abasan'] },
  'rafah':         { q: 'rafah',         keys: ['rafah'] },
  'west-bank':     { q: 'west bank',     keys: ['jenin', 'nablus', 'hebron', 'tulkarem', 'ramallah', 'tubas', 'west bank'] },
};

document.addEventListener('DOMContentLoaded', () => {
  fetch('gallery_high.json').then(r => r.json()).then(compute).catch(() => {
    const n = document.getElementById('map-note'); if (n) n.textContent = 'Could not load the gallery data (from the release).';
  });
});

function compute(g) {
  const cnt = {}; for (const k in REGIONS) cnt[k] = 0;
  for (const e of g) {
    const t = (e.description_en || e.description || '').toLowerCase();
    for (const k in REGIONS) if (REGIONS[k].keys.some(kw => t.includes(kw))) cnt[k]++;
  }
  const max = Math.max(1, ...Object.values(cnt));
  let total = 0;
  for (const k in REGIONS) {
    total += cnt[k];
    const el = document.getElementById('r-' + k);
    const lbl = document.getElementById('c-' + k);
    const f = cnt[k] / max;
    if (el) {
      el.style.fill = 'rgba(214,69,69,' + (0.12 + f * 0.85).toFixed(2) + ')';
      el.classList.add('clickable');
      el.addEventListener('click', () => { location.href = 'index.html?q=' + encodeURIComponent(REGIONS[k].q); });
    }
    if (lbl) lbl.textContent = cnt[k].toLocaleString();
  }
  const tot = document.getElementById('map-total'); if (tot) tot.textContent = total.toLocaleString();
}
