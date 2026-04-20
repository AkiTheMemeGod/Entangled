# Agent Guidance for `entangled`

## Purpose
This repository is a Flutter application scaffolded with Firebase services and Riverpod state management. The app uses a clean separation between configuration, providers, services, models, screens, widgets, and theme logic.

## What agents should know
- Entry point: `lib/main.dart`.
- App shell: `lib/app.dart`.
- Route definitions: `lib/config/routes.dart`.
- State and dependency injection: `lib/providers/*.dart` using `flutter_riverpod`.
- Firebase services: `lib/services/*.dart`.
- UI layout: `lib/screens/**` and reusable UI components in `lib/widgets/**`.
- Theme customization: `lib/theme/**` and `lib/providers/theme_provider.dart`.

## Build and test commands
Use the Flutter toolchain for this project.

- Install dependencies: `flutter pub get`
- Analyze code: `flutter analyze`
- Run tests: `flutter test`
- Launch app: `flutter run`

## Project conventions
- Prefer Riverpod providers for accessing services and application state.
- Keep screen-level UI inside `lib/screens`, and reusable components inside `lib/widgets`.
- Keep data models inside `lib/models` and service logic inside `lib/services`.
- Use `AppRoutes` for named routes; the chat screen uses a dynamic route via `AppRoutes.generateRoute`.
- Persist theme settings using `SharedPreferences` in `lib/providers/theme_provider.dart`.

## Common maintenance tasks
- Add new screens under `lib/screens/<feature>`.
- Add new providers under `lib/providers` and wire them into screens via `ConsumerWidget`/`ConsumerStatefulWidget`.
- Add Firebase-backed data operations in `lib/services` and expose access through providers.
- Update theme palettes in `lib/theme/theme_variants.dart` and `lib/theme/app_theme.dart`.

## Avoid
- Editing files under `build/` or generated platform folders unless necessary.
- Changing Firebase initialization in `lib/main.dart` without understanding platform-specific config in `lib/config/firebase_options.dart`.

## Useful references
- `README.md` for project context
- `pubspec.yaml` for dependencies
- `analysis_options.yaml` for lint rules
