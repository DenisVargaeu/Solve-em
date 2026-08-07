# Solve 'em

<p align="center">
  <img src="logo.png" alt="Solve 'em logo" width="160" />
</p>

An AI-powered math learning assistant. Point your camera at a math problem and
get a step-by-step solution, or get your own working checked against a scored
rubric — with a fully offline fallback mode for when you have no network.

## Features

- **AI Mode** — photograph a problem, OCR it, and get a structured,
  step-by-step solution from an AI provider (OpenAI, OpenRouter, or Google
  Gemini).
- **Control Mode** — let the AI check *your* answer and mark each step, then
  score it and reveal hints for the steps you missed.
- **No AI Mode** — works entirely offline: a scientific-style calculator, a
  formula library with rendered LaTeX, and sticky math notes.
- **Ask a follow-up** on any AI solution and keep the whole conversation in
  context.
- **History** — every solved/checked problem is stored locally and can be
  reopened or deleted.
- **Settings** — choose provider and model, set your API key, switch dark/light
  theme, toggle OCR on/off, and test the connection before you solve.

## Architecture

Clean architecture with manual dependency injection (no codegen):

```
lib/
├── core/          constants, theme, exceptions, prompts, shared widgets
├── domain/        entities, repositories, use cases, expression evaluator
├── data/          Hive/local datasources, repository impls, OCR + AI gateways
└── presentation/  DI container, controllers, screens, widgets
```

- OCR: Google ML Kit `TextRecognizer`
- Storage: Hive (problems, notes), SharedPreferences (settings)
- Math rendering: `flutter_math_fork`

## Getting started

```sh
flutter pub get
flutter run
```

No API key is bundled. Open **Settings** in the app and enter your own key for
one of the supported providers:

| Provider   | Model example                          |
| ---------- | -------------------------------------- |
| OpenAI     | `gpt-4o`                               |
| OpenRouter | `meta-llama/llama-3.1-8b-instruct`     |
| Gemini     | `gemini-1.5-flash`                     |
| NVIDIA NIM | `qwen/qwen2-vl-72b-instruct`           |

Then use **Test connection** in Settings to verify before solving.

## Platform notes

- **Android**: camera and gallery permissions are declared in
  `android/app/src/main/AndroidManifest.xml`. Requires minSdk 24 (Flutter
  default) to satisfy CameraX and ML Kit.
- **iOS**: `NSCameraUsageDescription` and `NSPhotoLibraryUsageDescription`
  are set in `ios/Runner/Info.plist`.

## Checks

```sh
flutter analyze
flutter test
```
