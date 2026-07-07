# Contributing

Thanks for helping keep the archive alive and accessible.

## Ways to help

- **Found a bug, or have an idea?** Open an **Issue**.
- **Want to fix or improve something?** Open a **Pull Request** — keep it focused, and check
  that the site still loads and the pages render.
- **Just want to help it survive?** You don't need to touch the code at all — run a mirror and
  seed the torrent. See the [`README`](README.md) and [`HOSTING.md`](HOSTING.md).

## Ground rules

- This is a **strictly read-only viewer**. It deliberately has **no** admin panel, login,
  upload/submission form, tracking, analytics, or outbound network calls. Please don't add any
  of these — they would put sources and visitors at risk. Changes that keep the mirror
  self-contained and offline are very welcome.
- Keep changes small and easy to review.
- **Never commit** media, gallery data, or any credentials/keys (see [`.gitignore`](.gitignore)).
- **Test before submitting:** run `python serve.py` and confirm the pages and a video load.

## Reporting security issues

Not through a public issue — see **[`SECURITY.md`](SECURITY.md)**.

## Review

Maintainers review every contribution. Not every change will be merged, and that's okay —
thank you for offering it regardless.
