# Solve-em

<p align="center">
  <img src=".github/logo.png" alt="Solve-em logo" width="160" />
</p>

[![Flutter](https://img.shields.io/badge/Flutter-UI-blue.svg)](https://flutter.dev/)
[![Language](https://img.shields.io/badge/Dart-67%25-blue.svg)](https://dart.dev/)
[![License](https://img.shields.io/badge/License-Add--your--license--here-lightgrey.svg)](#license)

AI-powered math helper for Android phones — solve problems, get step-by-step explanations, and learn faster.

> Note: Solve-em does not include an API key. Please provide your own API key for the AI service you prefer.

## Features

- Solve arithmetic, algebra, calculus, and other math problems using an AI backend
- Step-by-step explanations to help you learn
- Clean, mobile-first UI built with Flutter (Dart)
- Lightweight and easy to run on Android devices

## Screenshots

Replace these with your actual screenshots in the `assets/` folder and update the paths.

![Home Screen](docs/screenshots/home.png)
![Solution View](docs/screenshots/solution.png)

## Getting started

Prerequisites:
- Flutter (>= 2.10) installed — https://flutter.dev/docs/get-started/install
- Android SDK and an Android device or emulator
- An API key for the AI service you want to use (e.g., OpenAI, your own server)

1. Clone the repo
   git clone https://github.com/DenisVargaeu/Solve-em.git
   cd Solve-em

2. Install dependencies
   flutter pub get

## Configuration — supplying your API key

This project intentionally doesn't include an API key. Pick one of the options below to provide your key locally (do not commit your key to Git).

Option A — dart-define (recommended for local builds)
- Run the app with:
  flutter run --dart-define=OPENAI_API_KEY="your_api_key_here"

- Or for release builds:
  flutter build apk --dart-define=OPENAI_API_KEY="your_api_key_here"

Option B — local file (quick & dirty)
- Create a file `lib/api_key.dart` (gitignored) with:
  ```dart
  // lib/api_key.dart
  const String OPENAI_API_KEY = 'your_api_key_here';
  ```
- Import `OPENAI_API_KEY` where needed.

Option C — flutter_dotenv (if you prefer environment files)
- Add and configure `flutter_dotenv`, create a `.env` file, and load it in main.dart.
- Ensure `.env` is in `.gitignore`.

Whichever method you choose, the app expects the key to be available as `OPENAI_API_KEY` (adjust the code if you use a different name).

## Running

- Start an emulator or connect your Android device.
- Run:
  flutter run --dart-define=OPENAI_API_KEY="your_api_key_here"

## Development

- Code is primarily in Dart (Flutter). Other languages present in the repo are for native integrations or build tooling.
- To add features: create a new branch, implement, test on device/emulator, and open a pull request.

Suggested code layout:
- lib/ — Flutter source
- assets/ — images and other static assets
- android/ and ios/ — native platform code
- docs/ — screenshots and notes

## Contributing

Contributions are welcome! If you'd like to help:
- Open an issue for large changes or feature requests
- Fork, add your changes on a feature branch, and open a pull request
- Keep API keys and secrets out of commits

Coding style: follow Dart/Flutter idioms and run `flutter analyze` before opening a PR.

## Privacy & API costs

- Using an external AI API may send user input to third-party servers. Make this clear to end users.
- API usage may incur costs. Provide guidance in-app or in the Play Store listing so users know about potential charges on their API accounts.

## Troubleshooting

- If the app fails to connect to the AI service: check that your API key is set correctly and your network connection is active.
- If you see build errors: run `flutter doctor` and resolve any issues shown there.

## Roadmap / Ideas

- Add offline fallback heuristics for basic arithmetic
- Support image input (camera) for handwritten problems
- Add more granular explanation steps and practice mode
- Publish to Google Play with an optional in-app configuration screen for API keys

## License

Add a LICENSE file to the repository and replace this section with the chosen license. For example, to use MIT, add an `LICENSE` file with MIT text and update the badge above.

## Contact

Created by Denis Vargaeu. If you want help improving this README or want me to commit it into the repo, tell me and I can create/update the file for you.
