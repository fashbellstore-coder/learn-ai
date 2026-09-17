# Learn AI

**From Machine Learning to Agentic AI**

A Flutter learning app: structured courses, interactive lessons, projects, a technology library, interview prep, and an on-device tutor shell.

## Run

```bash
flutter pub get
flutter test
flutter run
```

## Layout

- `lib/core` — theme, routing, providers, learning math
- `lib/data` — seed curriculum and local repositories
- `lib/features` — screens
- `lib/shared` — models and reusable UI
- `assets/content` — content manifest

State: **Riverpod**. Navigation: **GoRouter**. Persistence: **SharedPreferences**. Code runs in the in-app Python sandbox (no API keys).
