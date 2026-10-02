// Loads a third-party map ONLY when the reader asks for it: the mirror makes no outside request by
// itself. The iframe is sandboxed so the embedded site cannot navigate or script this page.
document.querySelectorAll('.geo-embed .geo-load').forEach(function (btn) {
  btn.addEventListener('click', function () {
    var box = btn.closest('.geo-embed');
    var f = document.createElement('iframe');
    f.src = box.getAttribute('data-src');
    f.title = box.getAttribute('data-title');
    f.setAttribute('sandbox', 'allow-scripts allow-same-origin allow-popups allow-popups-to-escape-sandbox');
    f.setAttribute('referrerpolicy', 'no-referrer');
    f.setAttribute('allow', 'fullscreen');
    f.className = 'geo-frame';
    btn.replaceWith(f);
  });
});
