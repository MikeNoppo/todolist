# AGENTS.md
Practical guide for coding agents working in this repository.

## 1) Repository Overview
- App type: Flutter mobile app (with Android-focused native integration).
- Dart SDK constraint: `^3.8.1` (`pubspec.yaml`).
- Lint baseline: `flutter_lints` via `analysis_options.yaml`.
- Data storage: `SharedPreferences` in `lib/repositories/todo_repository.dart`.
- JSON model generation: `json_serializable` + `build_runner`.
- Main model pair: `lib/models/todo_model.dart` and `lib/models/todo_model.g.dart`.
- Native bridge channel: `app_blocker/permissions`.
- Dart channel client: `lib/services/permission_service.dart`.
- Android channel host: `android/app/src/main/kotlin/com/example/todolist/MainActivity.kt`.

## 2) Build / Lint / Test Commands
Run commands from repository root.

### Environment setup
- Install dependencies: `flutter pub get`

### Run app
- Default run: `flutter run`
- Android target: `flutter run -d android`
- Chrome target: `flutter run -d chrome`

### Lint and static analysis
- Analyze project: `flutter analyze`

### Formatting
- Apply formatting: `dart format .`
- Check only (CI style): `dart format --output=none --set-exit-if-changed .`

### Tests
- Run all tests: `flutter test`
- Run one file: `flutter test test/path/to/file_test.dart`
- Run one test by exact name:
  - `flutter test test/path/to/file_test.dart --plain-name "shows error when title is empty"`
- Run tests by name pattern:
  - `flutter test test/path/to/file_test.dart --name "title is empty"`
Single-test workflow recommendation:
1. Run one file while iterating.
2. Narrow to one case with `--plain-name`.
3. Run full `flutter test` before finishing.
Current repo note: there is no committed `test/` directory yet.

### Code generation
- Generate once: `dart run build_runner build --delete-conflicting-outputs`
- Watch mode: `dart run build_runner watch --delete-conflicting-outputs`
- Derry alias: `dart run derry build`
`derry build` currently does:
1. `flutter clean`
2. `dart pub get`
3. `dart run build_runner build --delete-conflicting-outputs`

### Other useful commands
- Clean artifacts: `flutter clean`
- Regenerate launcher icon: `dart run flutter_launcher_icons`

## 3) Code Style Guidelines
Follow existing conventions in `lib/` and Android Kotlin sources.

### Imports
- Use import order: `dart:` -> `package:` -> relative project imports.
- Keep one blank line between import groups.
- Prefer relative imports for app-local modules (current project convention).
- Avoid unused imports; keep imports minimal and explicit.

### Formatting and structure
- Use `dart format` as source of truth.
- Use 2-space indentation.
- Keep trailing commas in multiline widget/argument lists.
- Break large `build()` methods into small private widget builders.
- Keep comments short and only for non-obvious logic.

### Types and null safety
- Prefer explicit types on public methods, fields, and return values.
- Use `final` for immutable references and `const` wherever possible.
- Avoid `dynamic` unless required at JSON/plugin boundaries.
- Use nullable types deliberately (`Type?`) and guard before dereference.
- Prefer typed callbacks (`VoidCallback`, `ValueChanged<T>`) over broad `Function`.

### Naming conventions
- Files: `snake_case.dart`.
- Classes and enums: `PascalCase`.
- Variables, fields, methods: `lowerCamelCase`.
- Private members: leading underscore (`_loadData`, `_isLoading`).
- Keep constants as `const`; private constants should use leading underscore.

### State and widget patterns
- Current UI state style is `StatefulWidget` + `setState`; keep this unless asked to refactor.
- After `await`, verify `mounted` before navigation, dialogs, snackbar, or `setState`.
- Dispose controllers/listeners in `dispose()`.
- Keep user feedback with `ScaffoldMessenger` for important actions.

### Error handling
- Wrap platform/storage calls in `try/catch` (`MethodChannel`, `SharedPreferences`).
- Do not silently swallow errors; at least log with `debugPrint`.
- Use safe fallback behavior on failures (for example empty data or false permissions).
- Reset loading flags in `finally` blocks where relevant.
- Keep user-facing errors concise and actionable.

### Data and serialization
- Do not edit generated files (`*.g.dart`) manually.
- Change annotated model source files, then re-run build_runner.
- Keep storage key strings centralized as `static const` fields.
- Preserve JSON compatibility unless a migration is intentional.

### Navigation and async flow
- Existing pattern: `Navigator.push(...)` and inspect return value (`result == true`) to refresh.
- Keep confirmation dialogs before destructive actions.
- Keep custom transitions consistent in screens already using `PageRouteBuilder`.

### Android native interoperability
- Keep MethodChannel name and method strings identical in Dart and Kotlin.
- For new channel methods, update both Dart service and `MainActivity` handler.
- Keep Android manifest/service permissions aligned with native + Dart behavior.

## 4) Repository Layout Conventions
- `lib/models/`: serializable domain models.
- `lib/repositories/`: persistence and data access.
- `lib/services/`: platform and app services.
- `lib/screens/`: UI screens and feature widgets.
- `android/app/src/main/kotlin/...`: native Android integration.
When adding files, place them in the nearest matching feature folder.

## 5) Done Checklist For Agents
Before finalizing non-trivial code changes:
1. `dart format .`
2. `flutter analyze`
3. `flutter test` (or targeted test command while iterating)
4. `dart run build_runner build --delete-conflicting-outputs` if models changed
5. Optional smoke test with `flutter run` for UI/platform work
If local tooling is unavailable in the execution environment, still provide exact commands and expected checks.

## 6) Test Authoring Notes
- Place tests under `test/` and mirror source structure where practical.
- Use `*_test.dart` suffix for all test files.
- Keep unit tests deterministic; avoid time/network dependence.
- For widget tests, use explicit pumps and clear `find` matchers.
- Name tests with behavior-focused phrases (what should happen).
- Prefer adding a focused regression test when fixing bugs.
- During iteration, run only the changed file, then one case, then full suite.
