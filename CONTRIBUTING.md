# Contributing to Comprezza

Comprezza is developed by Dzynova Technologies as an offline-first Flutter application.

## Before changing code

1. Read `PROJECT_RULES.md`.
2. Read the latest entry in `PROJECT_CHANGELOG.md`.
3. Check `TECH_DEBT.md`, `BUG_TRACKER.md`, and `ROADMAP.md`.
4. Keep the requested phase scope and non-goals explicit.

## Local checks

```bash
flutter pub get
flutter gen-l10n
dart format --set-exit-if-changed lib test
flutter analyze
flutter test
```

For Android changes, also run a release build in a configured Android environment and inspect the merged manifest.

## Architecture rules

- Keep feature data, domain, and presentation boundaries explicit.
- Keep platform plugins and filesystem implementations in data/adapters.
- Keep domain models platform-neutral.
- Assemble concrete dependencies only in `lib/app/di`.
- Do not add cloud, analytics, tracking, login, or broad storage permissions.
- Do not introduce new features outside the active roadmap phase.

## Pull requests

Describe:

- Scope and non-goals
- Files changed
- Architecture decisions
- Tests and checks run
- Performance and memory considerations
- Privacy/Play Store implications
- Known risks and technical debt
