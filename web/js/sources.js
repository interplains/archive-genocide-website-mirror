// Sources page: live count badges + search filter.
// Extracted from an inline <script> so the page can enforce a strict CSP (script-src 'self').
(function () {
  function countVisible(containerId, badgeId) {
    const items = document.querySelectorAll('#' + containerId + ' [data-search]');
    const badge = document.getElementById(badgeId);
    const visible = [...items].filter(el => !el.classList.contains('src-hidden')).length;
    if (badge) badge.textContent = visible;
  }

  function updateCounts() {
    countVisible('ig-grid',     'count-ig');
    countVisible('tw-grid',     'count-tw');
    countVisible('tg-list',     'count-tg');
    countVisible('reddit-grid', 'count-rd');
    countVisible('news-grid',   'count-news');
    countVisible('web-grid',    'count-web');
  }

  updateCounts();

  const search = document.getElementById('src-search');
  if (search) search.addEventListener('input', function () {
    const q = this.value.trim().toLowerCase();
    document.querySelectorAll('[data-search]').forEach(el => {
      if (!q || el.dataset.search.includes(q) || el.textContent.toLowerCase().includes(q)) {
        el.classList.remove('src-hidden');
      } else {
        el.classList.add('src-hidden');
      }
    });
    ['sec-instagram', 'sec-twitter', 'sec-telegram', 'sec-reddit', 'sec-news', 'sec-websites'].forEach(id => {
      const sec = document.getElementById(id);
      if (!sec) return;
      const anyVisible = [...sec.querySelectorAll('[data-search]')].some(el => !el.classList.contains('src-hidden'));
      sec.style.display = anyVisible ? '' : 'none';
    });
    updateCounts();
  });
})();
