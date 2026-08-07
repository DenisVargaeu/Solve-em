# Release Notes

## v1.7.0 — Green refresh, language picker & polish

_Runtime: 1.7.0 · Build: 9 · Android minSdk 24 / target & compile SDK 36_

### What's new

- **AI response language** — choose the language the tutor writes in. Searchable
  picker with 10 languages: English, Slovak, Czech, German, Spanish, French,
  Italian, Portuguese, Polish and Hungarian. Applies to AI Mode, Control Mode,
  Chat and follow-up questions. (More coming soon.)
- **Fresh brand identity** — the whole app now uses a calm **green** theme, and
  the new **π logo** appears on the splash screen and as the Android launcher
  icon.
- **Redesigned home screen** — a clearer hero with two actions (Solve / Ask
  tutor), a capability strip, and a reshaped tool grid.

### What changed under the hood

- Centralized Material 3 design tokens (spacing, shape) across every screen.
- Green accent palette applied to all gradient cards and screens.
- Added the app logo to `README.md` and the repository.

### Fixes

- Release build now minifies with R8 successfully — ML Kit's optional
  per-language OCR option classes are excluded from the warnings so the
  default Latin-text recognition keeps working.

### Attachments

- `app-release.apk` — signed with the **debug** key (release keystore still to
  be configured).

---