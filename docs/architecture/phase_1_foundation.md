# Photo Compressor Pro — Phase 1 Architecture

## Purpose

This document defines the production architecture for Photo Compressor Pro before feature/business logic is introduced.

Phase 1 intentionally creates boundaries only. Existing prototype files remain in place until a later migration phase. No new compression, persistence, queue, history, folder, or UI business logic belongs in this phase.

## Architectural goals

- Feature-first organization with Clean Architecture boundaries inside each feature.
- Offline-only execution with no network, analytics, tracking, login, or cloud dependency.
- Explicit dependency direction and testable business rules.
- Provider-based presentation state without putting business logic in widgets.
- Permission-minimal Android integration using user-selected content and scoped storage.
- Safe foundations for single-image, batch, folder, history, presets, statistics, and premium capabilities.
- Small, replaceable abstractions rather than premature framework complexity.

## Target project tree

```text
lib/
├── main.dart                         # Process entry point; bootstrap only.
├── app.dart                          # Root application composition.
├── app/
│   ├── di/                           # Manual dependency composition and lifetimes.
│   ├── localization/                 # Locale configuration and localization adapters.
│   ├── routing/                      # Application route names and router configuration.
│   └── theme/                        # App-level ThemeData composition and theme mode.
├── l10n/                             # ARB source files for generated localizations.
├── core/
│   ├── animations/                   # Reusable, feature-agnostic motion primitives.
│   ├── bottom_sheets/                # Reusable, feature-agnostic bottom-sheet shells.
│   ├── constants/                    # App-wide immutable values and policy constants.
│   ├── dialogs/                      # Reusable, feature-agnostic dialog shells.
│   ├── errors/                       # Shared failures, exceptions, and error mapping types.
│   ├── extensions/                   # Small, generic Dart/Flutter extensions.
│   ├── helpers/                      # Shared orchestration helpers with no feature rules.
│   ├── models/                       # Shared value objects used across multiple features.
│   ├── services/                     # Cross-feature platform/system services.
│   ├── theme/                        # Design tokens, colors, typography, spacing, shapes.
│   ├── utilities/                    # Pure functions and stateless utilities.
│   └── widgets/                      # Shared accessible UI primitives.
└── features/
    └── compressor/
        ├── data/
        │   ├── datasources/           # Plugin/platform/local data access implementations.
        │   ├── models/                # Serialization and data-transfer representations.
        │   └── repositories/          # Concrete implementations of domain contracts.
        ├── domain/
        │   ├── entities/              # Business entities and value semantics.
        │   ├── repositories/          # Abstract contracts consumed by use cases.
        │   └── usecases/              # One business action per use-case class.
        └── presentation/
            ├── animations/            # Compressor-specific transitions and motion.
            ├── bottom_sheets/         # Compressor-specific sheets and settings flows.
            ├── dialogs/               # Compressor-specific confirmations and errors.
            ├── providers/             # Provider ChangeNotifiers and view state.
            ├── screens/                # Route-level screen composition.
            └── widgets/               # Reusable compressor-only widgets.

test/
├── core/                              # Unit/widget tests for shared code.
└── features/compressor/
    ├── data/                          # Datasource and repository implementation tests.
    ├── domain/                        # Entity and use-case tests.
    └── presentation/                  # Provider and widget tests.

integration_test/                      # Device-level picker, export, and lifecycle tests.
docs/architecture/                     # Architecture decisions and phase documents.
```

## Folder responsibilities

### `lib/main.dart`

Contains only process bootstrap concerns:

- Flutter binding initialization.
- Error-zone/bootstrap configuration.
- Construction of the root app through the composition boundary.

It must not contain feature logic, service implementations, route definitions, or widget trees.

### `lib/app.dart`

Owns the root `MaterialApp`/`MaterialApp.router` composition. It connects app-level dependencies, theme, localization, and routing without implementing feature rules.

### `lib/app/di`

Contains manual dependency injection. This is the only place where concrete implementations should be assembled for production.

Responsibilities:

- Construct repositories and datasources.
- Construct use cases from repository contracts.
- Construct Provider instances.
- Define object lifetimes and disposal ownership.

A DI framework is intentionally deferred. Manual composition keeps dependencies visible and minimizes package risk.

### `lib/app/routing`

Owns application navigation policy:

- Route names and route locations.
- Router configuration.
- Deep-link policy if introduced later.
- Route-level dependency/provider placement.

Screens remain in feature presentation folders; routing must not contain screen business logic.

### `lib/app/theme`

Owns application-wide theme assembly:

- Light, dark, and system modes.
- Material 3 `ThemeData` construction.
- Dynamic color integration point.
- Theme persistence integration point.

Design tokens belong in `core/theme`; app theme composition belongs here.

### `lib/app/localization` and `lib/l10n`

`lib/l10n` contains localization source files such as ARB files and generated localization output when configured. `lib/app/localization` contains locale selection/configuration and app-level localization policy. These are intentionally separate: `l10n` is resource input/output, while `app/localization` is runtime composition.

The localization generator configuration file is deferred until the first localization implementation phase. Domain entities and use cases must never depend on localized strings. Presentation maps domain outcomes to localized copy.

### `lib/core/constants`

Contains stable cross-feature constants only, such as:

- Supported image extensions.
- Application limits.
- Cache naming prefixes.
- Platform-channel names.
- Default configuration values.

Feature-specific values belong inside the feature.

### `lib/core/errors`

Defines shared error vocabulary and safe boundaries between layers:

- Domain failures.
- Data-source exceptions.
- Platform errors.
- User-facing error mapping helpers.

Raw plugin exceptions must not leak into widgets or domain rules.

### `lib/core/extensions`

Contains narrowly scoped extensions that are generic and independently testable. Avoid placing business policy here; an extension must not hide meaningful side effects.

### `lib/core/helpers`

Contains shared coordination helpers that do not belong to one feature, such as lifecycle-safe callback helpers or platform capability checks. A helper may be added only when it has a specific, documented responsibility and is used by at least two boundaries. Helpers must not become a dumping ground for business logic.

### `lib/core/models`

Contains shared value objects used by multiple features. Compressor-only entities belong under `features/compressor/domain/entities` instead. Data-transfer models belong under the owning feature's `data/models`; `core/models` must not become a second feature-model directory.

### `lib/core/services`

Contains cross-feature system services, for example:

- App lifecycle observation.
- Temporary-file cleanup orchestration.
- Clock abstraction.
- Device capability inspection.
- Safe platform-channel wrapper foundations.

Services should expose small interfaces where they need to be mocked.

### `lib/core/theme`

Contains design-system primitives:

- Color tokens.
- Typography tokens.
- Spacing scale.
- Corner radii.
- Elevation and motion tokens.
- Accessibility-conscious component defaults.

This folder must not depend on compressor feature code.

### `lib/core/utilities`

Contains pure, stateless utilities. Examples include byte formatting, hash formatting, duration formatting, and mathematical helpers. Utilities must be deterministic and easy to unit test. A utility belongs here only when it is feature-agnostic; compressor-specific calculations stay inside the compressor domain.

### `lib/core/widgets`, `animations`, `dialogs`, and `bottom_sheets`

These are reusable presentation primitives shared by multiple features. They must remain feature-agnostic. A compressor-specific dialog or sheet belongs under the compressor feature instead. These folders are intentionally empty placeholders until a genuinely shared implementation exists; they should not be populated speculatively.

## Feature layer boundaries

### `features/compressor/data`

The data layer knows about Flutter plugins, Android channels, filesystem APIs, serialization, and local persistence implementations.

It may depend on:

- Domain contracts.
- Core errors and models.
- Approved platform packages.

It must not depend on presentation providers or screens.

### `features/compressor/domain`

The domain layer contains business meaning and is the most stable layer.

It may depend only on:

- Dart core libraries where necessary.
- Shared pure core models/utilities.
- Abstract repository contracts.

It must not import Flutter UI libraries, Android code, package plugins, `BuildContext`, or localized strings.

### `features/compressor/presentation`

The presentation layer contains screens, widgets, dialogs, animations, and Provider state objects.

It may depend on:

- Domain entities.
- Domain use cases.
- Core presentation utilities and widgets.
- App routing/theme/localization.

It must not directly call image-picker, compression, filesystem, or MediaStore APIs.

## Dependency direction

```text
main.dart
   ↓
app / DI / routing / theme
   ↓
presentation providers and screens
   ↓
domain use cases
   ↓
domain repository contracts
   ↑
data repository implementations
   ↑
data sources and platform/plugin APIs
```

The arrow into a repository contract represents dependency inversion: domain defines the contract, while data supplies the implementation.

## Naming rules

- Files use `snake_case.dart`.
- Classes use `UpperCamelCase`.
- Methods, fields, and variables use `lowerCamelCase`.
- Providers end in `Provider` or use a clearly documented `ChangeNotifier` name.
- Use cases use an imperative verb, such as `CompressImageUseCase`.
- Repository contracts use nouns ending in `Repository`.
- Concrete repository implementations use an `Impl` suffix only when it improves clarity.
- Datasources identify their boundary, such as `PhotoPickerDataSource` or `MediaStoreDataSource`.
- Do not create generic files named `utils.dart`, `helpers.dart`, or `common.dart` without a specific responsibility.

## Decisions before business logic

### State management

Use `provider` with scoped `ChangeNotifier` providers. Providers should expose immutable view state where practical and delegate actions to use cases. Widgets should use `context.select` or small `Consumer` scopes to avoid unnecessary rebuilds.

### Dependency injection

Use manual constructor injection initially. Add a service locator only if the object graph becomes demonstrably difficult to maintain and after profiling/testability review.

### Routing

Keep routing behind an app-level abstraction. A declarative router may be added after confirming the final package choice and current Flutter compatibility; routing should not be coupled to domain logic.

### Persistence

Do not choose a history/preset database in the architecture-only phase. First define domain persistence requirements and data retention rules. The eventual persistence implementation must remain local and replaceable.

### Folder compression

Folder access must use Android's user-mediated Storage Access Framework/DocumentFile approach or an actively maintained equivalent. Do not add broad storage permissions as a shortcut.

### Monetization

Ads and premium entitlements are deferred. The architecture may later expose capability/policy interfaces, but no ad SDK, tracking, billing, or network dependency belongs in this offline foundation.

## Recommended improvements before business logic

1. **Generate the Android project with the official Flutter toolchain.** The current manually assembled Android tree lacks standard wrapper/generated files. Before release work, run the matching stable Flutter SDK's project generation and preserve reviewed custom platform code.
2. **Pin and audit package versions.** Use `flutter pub outdated` and verify Android compatibility before locking a release. Do not call a package “actively maintained” without checking its current release history and issue status.
3. **Add a CI matrix before feature expansion.** At minimum: formatting check, analyzer with fatal warnings, unit tests, widget tests, and Android release compilation.
4. **Define memory budgets explicitly.** Establish preview decode limits, maximum simultaneous native operations, cache quotas, and cancellation behavior before batch/folder work.
5. **Define data retention policies.** Specify when temporary files, history thumbnails, deleted originals, and failed outputs are removed.
6. **Define capability boundaries for Android versions.** MediaStore export, Photo Picker, SAF folder access, and trash behavior need explicit minimum API behavior and graceful fallbacks.
7. **Keep privacy claims testable.** Add a release checklist that verifies no network permissions/dependencies, no analytics initialization, no tracking identifiers, and no uploaded image bytes.
8. **Add accessibility acceptance criteria.** Every screen should be tested with TalkBack, large text, high contrast, keyboard/navigation semantics where applicable, and minimum touch targets.

## Existing prototype status

The pre-existing prototype files under `lib/core`, `lib/features/compressor`, and `test/` were intentionally preserved and not migrated in this architecture-only phase. They remain the legacy implementation surface until Phase 2. New code must use the target boundaries documented here; Phase 2 will migrate or remove the legacy files after analyzer/test coverage is in place.

## Explicitly out of scope for this phase

- Compression implementation.
- Image analysis/classification.
- Batch queue behavior.
- Folder selection or traversal.
- Hashing and duplicate detection.
- History or statistics persistence.
- Preset CRUD.
- Screens and feature widgets.
- Provider implementations.
- Repository implementations.
- Platform-channel business operations.

## Phase 1 completion criteria

- [x] Architecture directories created.
- [x] Existing prototype source preserved for later migration.
- [x] Layer responsibilities documented.
- [x] Dependency direction documented.
- [x] Provider, routing, localization, persistence, and folder-access decisions documented.
- [x] No feature/business logic added.
- [ ] Architecture reviewed and approved before Phase 2 migration.
