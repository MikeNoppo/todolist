# AGENTS.md
Practical operating guide for coding agents in this repository.

## 1) Scope and Project Snapshot
- Project type: Flutter app with Android-native integration.
- Primary focus: Todo + intervention flow (app blocking with urgency-based policy).
- Language/toolchain: Dart SDK `^3.8.1`, Flutter, Kotlin (Android host/service).
- Persistence: `SharedPreferences` (`flutter.` prefix on Android native side).
- Serialization: `json_serializable` + `build_runner`.
- Main domain model: `lib/models/todo_model.dart` (`todo_model.g.dart` is generated).
- MethodChannel: `app_blocker/permissions`.
- Dart side channel client: `lib/services/permission_service.dart`.
- Android side channel host: `android/app/src/main/kotlin/com/example/todolist/MainActivity.kt`.
- Accessibility hard-block service: `android/app/src/main/kotlin/com/example/todolist/AppBlockerAccessibilityService.kt`.

## 2) Quick Start Commands
Run all commands from repo root (`D:\Mikel Stuff\TA\todolist`) unless stated otherwise.

### Dependency setup
- Install packages: `flutter pub get`

### Run app
- Default: `flutter run`
- Android device/emulator: `flutter run -d android`
- Chrome (if needed): `flutter run -d chrome`

### Static checks
- Analyze: `flutter analyze`
- Format all: `dart format .`
- Format check only: `dart format --output=none --set-exit-if-changed .`

### Tests (important)
- Run all tests: `flutter test`
- Run one file: `flutter test test/path/to/file_test.dart`
- Run one exact test case:
  - `flutter test test/path/to/file_test.dart --plain-name "shows error when title is empty"`
- Run test(s) by name pattern:
  - `flutter test test/path/to/file_test.dart --name "title is empty"`
- Current repository note: `test/` may not exist yet; add tests under `test/` when introducing test coverage.

### Code generation
- One-time generation: `dart run build_runner build --delete-conflicting-outputs`
- Watch mode: `dart run build_runner watch --delete-conflicting-outputs`
- Derry alias: `dart run derry build`
  - Current sequence in `derry build`:
    1. `flutter clean`
    2. `dart pub get`
    3. `dart run build_runner build --delete-conflicting-outputs`

### Useful maintenance
- Clean artifacts: `flutter clean`
- Regenerate launcher icon: `dart run flutter_launcher_icons`

## 3) Single-Test Workflow (Recommended)
1. Run one changed file first (`flutter test test/that_file_test.dart`).
2. Narrow to one exact case with `--plain-name` while iterating.
3. Re-run changed file after fix.
4. Run full `flutter test` before finalizing.
5. Always run `flutter analyze` + `dart format .` before handoff.

## 4) Code Style Rules (Dart/Flutter)

### Imports
- Order groups: `dart:` -> `package:` -> relative project imports.
- Keep one blank line between groups.
- Prefer relative imports for app-local modules.
- Remove unused imports.

### Formatting and structure
- `dart format` is source of truth.
- Use 2-space indentation.
- Keep trailing commas in multiline widget and parameter lists.
- Break large widgets into small private builders.
- Keep comments minimal; only explain non-obvious intent.

### Types and null-safety
- Use explicit types for public APIs and important state fields.
- Prefer `final`, and `const` where possible.
- Avoid `dynamic` except at plugin/channel boundaries.
- Guard nullable usage intentionally (`Type?` + checks).
- Prefer typed callbacks (`VoidCallback`, `ValueChanged<T>`).

### Naming conventions
- Files: `snake_case.dart`.
- Classes/enums: `PascalCase`.
- Members/locals/functions: `lowerCamelCase`.
- Private members: prefix with `_`.
- Constants: `const`; private constants should also be private by naming.

### Stateful UI and async flow
- Existing pattern is `StatefulWidget` + `setState`; follow it unless refactor is requested.
- After `await`, check `mounted` before:
  - `setState`
  - navigation
  - showing dialogs/snackbars
- Dispose controllers/listeners in `dispose()`.
- Use `ScaffoldMessenger` for user feedback.

### Error handling and logging
- Wrap platform/storage calls in `try/catch`.
- Never silently swallow errors; log them.
- Prefer `AppLogger` for structured logging in app code.
- Provide safe fallback behavior (empty list/false/null) on failures.
- Keep user-facing error messages concise and actionable.

## 5) Android/Kotlin Interop Rules
- Keep channel name/method strings identical across Dart and Kotlin.
- If adding a channel method, update both:
  - `PermissionService` (Dart)
  - `MainActivity` method handler (Kotlin)
- Keep `AndroidManifest.xml` permissions/queries aligned with feature behavior.
- Preserve hard-block behavior in accessibility service unless explicitly changing product behavior.

## 6) Intervention and Blocking Domain Conventions
- Block toggles are stored as `block_<packageName>`.
- Always-allow whitelist keys use `allow_<packageName>`.
- Urgency windows are stored as hour values:
  - `intervention_window_low_hours`
  - `intervention_window_medium_hours`
  - `intervention_window_high_hours`
- Current defaults:
  - Low: `2` hours
  - Medium: `8` hours
  - High: `24` hours
- Whitelist overrides blocking (if app is whitelisted, do not block).
- Do not introduce conflicting key names; reuse centralized constants in `AppBlockerService`.

## 7) Data and Generated Files
- Do not edit generated files manually (`*.g.dart`).
- Update annotated source files and rerun build_runner.
- Preserve JSON compatibility unless migration is intentional and documented.

## 8) Repository Layout Guidance
- `lib/models/`: models and value types.
- `lib/repositories/`: persistence/data access.
- `lib/services/`: platform services and app-level logic.
- `lib/screens/`: UI screens and view composition.
- `android/app/src/main/kotlin/...`: Android host/native services.
- Put new files in the nearest feature folder (prefer cohesion over broad shared dumping).

## 9) Cursor / Copilot Rules
- Checked paths:
  - `.cursor/rules/`
  - `.cursorrules`
  - `.github/copilot-instructions.md`
- Result: no repository-specific Cursor/Copilot instruction files were found.
- Therefore, follow this `AGENTS.md` and existing in-code conventions as the primary agent policy.

## 10) Completion Checklist for Agents
Before finalizing non-trivial changes:
1. `dart format .`
2. `flutter analyze`
3. `flutter test` (or targeted test + full suite if tests exist)
4. `dart run build_runner build --delete-conflicting-outputs` (if model/serialization changed)
5. Optional smoke run on Android for UI/native-interaction changes

If a tool is unavailable locally, still provide exact commands and expected outcomes in your handoff.
