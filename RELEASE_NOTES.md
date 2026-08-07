# Release Notes

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
