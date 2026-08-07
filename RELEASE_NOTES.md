# Release Notes

## v1.7.6 — Custom AI prompt, sharing & smarter calculator

_Runtime: 1.7.6 · Build: 11 · Android minSdk 24 / target & compile SDK 36_

### What's new

- **Custom AI instruction** — under Settings → Advanced, you can now set a
  custom system prompt that every AI mode (Solve, Check, Chat and follow-ups)
  must follow, e.g. "always show two solving methods".
- **Share solutions** — from any Solution screen, share the problem and its
  whole solution as **text**, as a formatted **image**, or copy it to the
  clipboard.
- **Smarter offline calculator** — new **scientific functions** (sin, cos, tan,
  ln, log, cbrt and their inverses) and a **history tape** that stores recent
  calculations and lets you tap to reuse a result.

### Under the hood

- `share_plus` added for the system share sheet; the share image is rendered
  on-device with a branded card.

---

## v1.7.5 — Advanced options & layout polish

_Runtime: 1.7.5 · Build: 10 · Android minSdk 24 / target & compile SDK 36_

### What's new

- **Advanced options** — a new collapsible "Advanced options" section in
  Settings groups power-user controls together:
  - **Base URL** — set a custom OpenAI-compatible endpoint (shown for OpenAI,
    OpenRouter and NVIDIA).
  - **Request timeout** — choose how long AI requests may take (10–600 s,
    default 60 s). Useful for slow or reasoning-heavy models.
- **Adjustable AI request timeout** is now applied end-to-end: it persists on
  device and is respected by every request across all providers.

### Fixes

- Theme and text-size toggle rows no longer overflow on narrow screens or at
  large text scales (applied to Settings screen).

---
