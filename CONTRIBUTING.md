# Contributing

Thanks for helping keep the archive alive and accessible.

This project is hosted on **GitHub** — the website where the code lives and where people report
problems or suggest changes. The first two ways below use GitHub (a free account is needed); the
third needs nothing at all.

## Ways to help

- **Found a bug, or have an idea?** Open an **Issue**. That's just a public message on the
  project's GitHub page: go to the **Issues** tab near the top → click **New issue** → describe
  the problem or idea in plain words. **No coding needed** — we get notified and reply right there.
- **Want to fix or improve something yourself?** Open a **Pull Request** — a proposed change to
  the code that maintainers review and merge. (This one is for people comfortable editing code.)
  Keep it focused, and check that the site still loads and the pages render.
- **Just want to help it survive?** You don't need GitHub or any code at all — run a mirror and
  seed the torrent. See the [`README`](README.md) and [`HOSTING.md`](HOSTING.md).

> **New to GitHub?** It's free to join at github.com. Think of an *Issue* as leaving a ticket or
> comment on the project — you don't need to know any code, just write what's wrong or what you'd
> like and submit it. A *Pull Request* is the more technical option for people editing the code.
> GitHub has short beginner guides if you want them.

## Ground rules

- This is a **strictly read-only viewer**. It deliberately has **no** admin panel, login,
  upload/submission form, tracking, analytics, or outbound network calls. Please don't add any of
  these — they would put sources and visitors at risk. Changes that keep the mirror self-contained
  and offline are very welcome.
- Keep changes small and easy to review.
- **Never commit** media, gallery data, or any credentials/keys (see [`.gitignore`](.gitignore)).
- **Test before submitting:** run `python serve.py` and confirm the pages and a video load.

## Reporting security issues

Not through a public issue — see **[`SECURITY.md`](SECURITY.md)**.

## Review

Maintainers review every contribution. Not every change will be merged, and that's okay — thank
you for offering it regardless.
