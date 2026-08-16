# Golden tests

Golden tests live under this directory and cover stable presentation snapshots only.

Guidelines:

- Keep golden tests deterministic and locale/theme explicit.
- Do not use golden tests for domain or repository behavior.
- Review pixel diffs intentionally when Material or Flutter versions change.
- Add feature-specific snapshots under `test/goldens/features/<feature>/`.

## Generating and updating goldens

Golden comparisons are pixel-exact with no tolerance, so the Flutter engine that
renders them must match the engine they were generated on.

- Regenerate snapshots with `flutter test test/goldens --update-goldens`.
- The `.github/workflows/ci.yml` quality job pins the Flutter version to the SDK
  the committed goldens were generated on. **When upgrading Flutter, regenerate
  the goldens on the new SDK and update the pinned CI version in the same
  change** — otherwise CI fails on unrelated pixel diffs.
- Vendored Roboto and MaterialIcons fonts live in `test/goldens/fonts/` (dev-only,
  loaded via `FontLoader` in `golden_test_utils.dart`); they are not part of the
  shipping app bundle.
