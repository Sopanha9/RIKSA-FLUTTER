# Riksa

Riksa is a mobile learning app for Grade 12 students in Cambodia preparing for the Bac II exam. It gives each student a clear path through the STEM syllabus: short lessons they read and reflect on, a study buddy that keeps them company, and a community to learn with.

Available in **Khmer** and **English**, on Android, iOS and the web.

## Features

- **Subject roadmaps**: Mathematics, Physics, Chemistry, Biology and Computer Science, split into units and 5–15 minute lessons. The roadmap always shows where you started, where you are, and where it ends.
- **Read and reflect lessons**: students read a short explanation, then write what they understood in their own words. Short-answer practice checks are included, with math rendered as LaTeX.
- **Study buddy**: an animated companion (Rive) that reacts to progress. Buddies can wear hats and glasses bought in the **Market** with XP and chosen in the **Wardrobe**.
- **Quests and streaks**: daily and weekly quests, a weekly chest, XP, streak reminders, and achievements.
- **AI tutor**: ask questions about a lesson and get guided explanations.
- **Community and blog**: a feed, communities, posts with up to four photos, and student-written articles, with moderation built in.
- **Leaderboards**: national and provincial rankings.
- **Guest mode**: browse subjects and try lessons before creating an account.
- **Sign-in**: email and password, Google, or Telegram.

## Tech stack

| Area | Choice |
| --- | --- |
| Framework | Flutter (Dart 3) |
| State management | Riverpod 3 |
| Navigation | go_router with a stateful bottom-tab shell |
| Networking | Dio for REST and GraphQL, with automatic token refresh |
| Models | Plain Dart classes with hand-written JSON parsing |
| Storage | flutter_secure_storage (session), shared_preferences (settings) |
| Animation | Rive |
| Localization | Flutter gen-l10n (`lib/l10n/app_en.arb`, `app_km.arb`) |

## Getting started

Requirements: Flutter 3.44 (stable channel) and a running Riksa backend.

```bash
flutter pub get
flutter run
```

By default the app talks to a local backend: `http://10.0.2.2:8080` on the Android emulator and `http://localhost:8080` elsewhere. To use another server:

```bash
flutter run --dart-define=API_BASE_URL=https://api.example.com
```

See `.env.example` for all the build-time settings.

### Building

```bash
flutter build apk --release --dart-define=API_BASE_URL=<server>
flutter build appbundle --release --dart-define=API_BASE_URL=<server>
flutter build web --release --dart-define=API_BASE_URL=<server>
```

Release builds for Android and iOS are also produced by GitHub Actions (`.github/workflows/build-apps.yml`).

## Testing

```bash
flutter analyze
flutter test
```

The suite has over 600 tests: unit tests, widget tests, end-to-end flows such as first run through to the first lesson, and golden (screenshot) tests in light and dark themes. The backend is faked in tests, so no server is needed.

## Project structure

```
lib/
├── main.dart          App entry point
├── app/               App root, router, and tab shell
├── core/              Network, storage, theme, and shared widgets
├── features/          One folder per feature: data / domain / providers / presentation
│   ├── auth/          Sign-in, onboarding, language and province setup
│   ├── learning/      Catalog, roadmaps, lessons, results
│   ├── mascot/        Study buddy
│   ├── market/        Market and wardrobe
│   ├── quests/        Daily and weekly quests
│   ├── ai/            AI tutor
│   ├── social/        Community feed and communities
│   ├── blog/          Articles
│   ├── leaderBoard/   Rankings
│   ├── notifications/ Activity inbox
│   ├── resources/     Extra lesson materials
│   └── userProfile/   Profiles, progress, and settings
└── l10n/              Khmer and English strings
test/                  Mirrors lib/, plus fixtures and golden images
```

For the full list of routes, screens and backend endpoints, see [docs/CODEBASE_MAP.md](docs/CODEBASE_MAP.md). Product and design principles are in [PRODUCT.md](PRODUCT.md) and [DESIGN.md](DESIGN.md).
