# Comprezza — Project Rules

This file is mandatory project context for every development phase.

## Phase protocol

Before every phase:

1. Read this file completely.
2. Read the latest `PROJECT_CHANGELOG.md` entry.
3. Read relevant entries in `TECH_DEBT.md` and `BUG_TRACKER.md`.
4. Review the current `ROADMAP.md` status.
5. State the phase scope, non-goals, and approval gate.

Every phase must follow this order:

1. Planning
2. Design Decisions
3. Generate Code
4. Self Review
5. Bug Hunt
6. Performance Review
7. Play Store Compliance Check
8. Flutter Best Practices Review
9. Senior Engineer Review
10. Wait for Approval

The Senior Engineer Review must happen after implementation and before requesting approval. It must review the current implementation only and must not introduce new features.

## Senior Engineer Review prompt

Use this review after every phase:

> Act as a Principal Flutter Architect reviewing this code.
>
> Perform a rigorous code review.
>
> Check for:
>
> - Architecture violations
> - SOLID violations
> - DRY violations
> - Memory leaks
> - UI rebuild issues
> - Performance bottlenecks
> - Race conditions
> - Null safety issues
> - Exception handling
> - State management improvements
> - Material 3 compliance
> - Accessibility
> - Play Store policy issues
> - Scalability
> - Readability
> - Testability
>
> Suggest improvements before moving to the next phase.
>
> Do not generate new features.
>
> Only review the current implementation.

## Phase record requirements

After each completed phase, append—not overwrite—an entry to `PROJECT_CHANGELOG.md` containing:

- Version
- Date
- Files Added
- Files Modified
- Architecture Decisions
- Breaking Changes
- Future TODOs
- Known Risks
- Performance Improvements
- Technical Debt
- Senior Engineer Review status
- Validation status
- Approval status

## Architecture rules

- Product identity is Comprezza, published by Dzynova Technologies.
- Use feature-first Clean Architecture.
- Keep `data`, `domain`, and `presentation` boundaries explicit inside each feature.
- Domain code must not import Flutter UI, platform plugins, Android code, localization, or filesystem implementations.
- Presentation code must call use cases, not data sources or platform plugins.
- Repository interfaces belong in `domain/repositories`.
- Repository implementations belong in `data/repositories`.
- Data sources and plugin adapters belong in `data/datasources`.
- Assemble concrete dependencies only in `lib/app/di`.
- Keep the dependency graph acyclic.
- Do not introduce a service locator without an architecture review.
- Keep transitional legacy code behind an explicit adapter and track its removal in `TECH_DEBT.md`.

## Coding standards

- Dart null safety is mandatory.
- Use readable, small, single-purpose classes and methods.
- Add concise documentation comments to public APIs.
- Prefer immutable data structures and `final` fields.
- Avoid hidden global state.
- Avoid business logic in widgets.
- Never silently swallow errors; convert them to `AppError`/`Result<T>` or document best-effort cleanup.
- Use package imports for new code where practical.
- Run formatting and analyzer checks before phase review.
- Do not use deprecated APIs.
- Do not add packages without reviewing maintenance, API stability, license, and platform impact.

## Naming conventions

- Files: `snake_case.dart`.
- Classes/enums: `UpperCamelCase`.
- Methods/fields/variables: `lowerCamelCase`.
- Use cases: imperative names such as `ProcessImageUseCase`.
- Repository contracts: noun plus `Repository`.
- Implementations: descriptive names, using `Impl` only where useful.
- Providers: explicit state responsibility, such as `CompressorProvider`.
- Avoid generic dumping-ground names such as `common.dart`, `misc.dart`, or `utils.dart`.

## Folder structure

```text
lib/
├── app/                       # Composition, routing, theme, localization, DI
├── l10n/                      # ARB localization resources
├── core/                      # Feature-agnostic contracts, services, tokens, widgets
└── features/<feature>/        # Feature-owned data/domain/presentation
```

Feature-specific code must not be placed in `core` merely for convenience.

## Dependency rules

Allowed direction:

```text
app → presentation → domain ← data
core ← app/domain/data/presentation as appropriate
```

More precisely:

- Domain may depend on pure core models/utilities and repository interfaces.
- Data may depend on domain contracts and core infrastructure.
- Presentation may depend on domain use cases/entities and core presentation infrastructure.
- App composition may depend on all layers to assemble them.
- Core must not depend on feature code.
- Domain must not depend on presentation or data implementations.

## State management rules

- Use Provider with scoped `ChangeNotifier` or immutable view-state objects.
- Scope providers as close as practical to their consumers.
- Prefer `context.select` and narrow `Consumer` scopes to minimize rebuilds.
- Providers delegate business actions to use cases.
- Every owned controller, subscription, timer, animation controller, stream, and notifier must be disposed.
- Async operations must guard lifecycle and stale-operation races.

## Theme rules

- Use Material 3.
- Support system, light, and dark modes.
- Keep colors, typography, dimensions, radii, elevation, and motion tokens centralized.
- Do not hard-code repeated values such as `padding: 16`, `radius: 12`, or `quality = 80`.
- Use `AppConstants`, `AppDimensions`, `AppRadius`, and related token classes for shared values.
- Add a token migration entry to `TECH_DEBT.md` when migrating existing UI rather than bypassing the token system.
- Custom themes must extend the theme architecture rather than bypass it.
- Test important UI states in both light and dark themes.

## Localization rules

- All user-visible strings belong in ARB resources.
- Domain and data layers must not contain localized strings.
- English is the template locale.
- New locales must be added through ARB files and validated with generated localization code.
- Golden tests must specify locale explicitly.
- Avoid string concatenation when placeholders/plurals are required.

## Performance rules

- Never block the UI isolate with heavy image processing or large synchronous file operations.
- Establish explicit image decode, memory, queue, and cache budgets before batch features.
- Bound concurrency; do not start unbounded compression tasks.
- Release native image buffers and temporary outputs promptly.
- Instrument development performance with local hooks only; do not add analytics.
- Measure before optimizing and record meaningful improvements in the changelog.

## Security and Play Store rules

- Offline-only: no cloud uploads, tracking, analytics, login, or network dependency.
- Do not add broad storage permissions as a shortcut.
- Use Android Photo Picker, MediaStore, and user-mediated SAF access where appropriate.
- Never use `MANAGE_EXTERNAL_STORAGE` for convenience.
- Do not expose local file paths or sensitive data in release logs.
- Review Android manifest changes in every relevant phase.
- Document data retention and deletion behavior before implementing destructive actions.

## Testing rules

- Unit-test domain rules and pure core utilities.
- Test repositories with fake data sources.
- Test Providers/state transitions independently from widgets.
- Use widget tests for semantics, interaction, and layout behavior.
- Use golden tests for intentional stable visual states only.
- Use integration tests for Photo Picker, MediaStore, SAF, lifecycle recovery, and large-image behavior.
- Do not mark a phase complete solely because code looks correct; record validation limitations.

## Review checklist

Every phase must explicitly report:

- Scope and non-goals
- Architecture decisions
- Files added/modified
- Self-review findings
- Bug-hunt findings
- Performance findings
- Play Store/privacy findings
- Flutter best-practice findings
- Senior Engineer Review findings
- Tests/analyzer/formatting status
- Known risks and technical debt
- Approval request
