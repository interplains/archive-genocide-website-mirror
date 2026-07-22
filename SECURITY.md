# Security Policy

Thank you for helping keep this project, its users, and its sources safe.

## Reporting a vulnerability

If you find a security problem with the mirror — a way to leak data, execute code, break out
of the read-only viewer, deanonymize a visitor, or otherwise put people at risk —
**please report it privately. Do not open a public issue or pull request.**

Reach the admins through our official Telegram:

**https://t.me/+t9gq13mSKcE4NGI0**

Please include enough detail to reproduce it. We'll confirm the report, work on a fix, and —
if you'd like — credit you once it's resolved. Please give us reasonable time to patch before
disclosing publicly.

## Scope

This repository is the **read-only viewer** (a small local server + front-end). By design it
has no accounts, uploads, database, or outbound network calls. The reports that matter most:

- path traversal or file exposure in the server
- cross-site scripting (XSS) in the viewer
- Content-Security-Policy bypass
- anything that could deanonymize a visitor or a source

## Please do NOT

- Post exploit details publicly before a fix is released.
- Submit footage or source material through a security report. Sources are protected **only**
  through the official submission channel above — never through this repository or any form on
  a mirror.
