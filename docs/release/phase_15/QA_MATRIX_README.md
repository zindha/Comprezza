# Comprezza Manual QA Matrix — 1,040 Cases

- CSV: `COMPREZZA_MANUAL_QA_1000.csv` (filename retains the original 1,000-case count; the matrix now has 1,040 rows)
- Exactly 1,040 data rows, 26 feature groups, 40 scenario dimensions per feature.
- Manual QA only; application code was not changed.
- Status update 2026-08-08: the `Batch compression` block was unblocked (`Implemented; device-validation pending` — batch is integrated and unit-tested; device execution pending) and a new `Camera capture` block (TC-1001..TC-1040) was added for the in-app camera flow. `Statistics and insights`, `History and recent files`, `Benchmark and About routes`, and `Release, security, and Google Play` remain environment- or scope-gated.

## Exact columns

`Test Case ID`, `Feature`, `Scope`, `Priority`, `Android Version`, `Test Category`, `Test Type`, `Scenario`, `Preconditions`, `Manual Steps`, `Expected Result`, `Edge Cases`, `Regression`, `Accessibility`, `Performance`, `Battery`, `Memory`, `Security`, `Google Play`, `Status`, `Evidence`.

`Edge Cases` contains the boundary condition. `Regression` is exactly `Yes` or `No`. The quality columns contain dimension-specific guidance. `Google Play` contains listing/declaration/exact-AAB guidance. `Status` is `Not Run` for executable cases and `BLOCKED - scope/environment gate` for staged, placeholder, or release-environment cases.

## Priority

- P0: blocker, security, privacy, data-loss, or release-critical.
- P1: core workflow, reliability, memory, accessibility, performance, or high-risk regression.
- P2: normal functional, UX, responsive, localization, and lower-risk edge coverage.

## Execution rules

Execute the exact signed AAB for release/security/Google Play cases. Record device model, Android build, app version, result, evidence, and defect ID. Use synthetic fixtures and redact paths/logs. Never mark blocked cases Pass until the corresponding product or environment gate is formally closed. Batch and camera cases require real device execution (picker, camera intent, queue, MediaStore, and share flows).
