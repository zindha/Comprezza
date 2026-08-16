# Comprezza — Phase 4: Application Layer & State Management

## Scope

This phase adds only the feature application layer. The frozen app folder structure, dependency-injection architecture, routing, theme, branding, and existing platform services remain unchanged. No screens, widgets, animations, or Material components were added.

## Files created

- `lib/features/compressor/domain/entities/application_entities.dart`
- `lib/features/compressor/domain/entities/value_object.dart`
- `lib/features/compressor/domain/entities/entities.dart`
- `lib/features/compressor/domain/repositories/application_repositories.dart`
- `lib/features/compressor/domain/repositories/repositories.dart`
- `lib/features/compressor/domain/usecases/application_use_cases.dart`
- `lib/features/compressor/domain/usecases/usecases.dart`
- `lib/features/compressor/presentation/viewmodels/application_states.dart`
- `lib/features/compressor/presentation/viewmodels/viewmodels.dart`
- `lib/features/compressor/presentation/providers/application_providers.dart`
- `lib/features/compressor/presentation/providers/providers.dart`
- `test/features/compressor/domain/application_layer_test.dart`

The existing `image_processing_*` domain contract remains intact for compatibility. New repository implementations are intentionally not placed in `domain`; concrete adapters belong in `data` and composition belongs in `lib/app/di` in the next wiring step.

## Dependency flow

```text
UI / future screens
        ↓
Provider (immutable state + lifecycle)
        ↓
Use case (one business action, Result<T>)
        ↓
Domain repository contract
        ↓
Data repository implementation
        ↓
EngineManager / FileManager / platform services
        ↓
Processing engines and storage adapters
```

Providers never import or access EngineManager, services, plugins, `dart:io`, or data implementations.

## Provider flow

```text
User intent
   ↓
Provider guards duplicate/in-flight work
   ↓
Provider emits Loading + initial Progress
   ↓
Use case validates and delegates
   ↓
Repository reports Result<T> and progress callbacks
   ↓
Provider emits Progress / Paused / Cancelled
   ↓
Provider emits Completed or friendly Error + retry flag
```

`ChangeNotifier` is used only as the Provider-compatible notification boundary. State itself is immutable and replaced rather than mutated. `notifyStateChanged()` suppresses notifications after disposal, and in-flight operations check lifecycle state before applying results.

## Use-case diagram

```text
SelectImages ────────→ ImageSelectionRepository
RecoverSelection ────→ ImageSelectionRepository
ValidateImage ────────→ ImageSelectionRepository
AnalyzeImages ────────→ CompressionRepository
CompressImages ───────→ CompressionRepository
CompressToTargetSize → CompressionRepository
ConvertImageFormat ───→ CompressionRepository
ResizeImage ──────────→ CompressionRepository
SaveCompressedImage ──→ StorageRepository
ShareCompressedImage ─→ ExportRepository
ExportImages ─────────→ ExportRepository
LoadHistory ──────────→ HistoryRepository
DeleteHistory ────────→ HistoryRepository
LoadStatistics ───────→ AnalysisRepository
LoadSettings ────────→ SettingsRepository
UpdateSettings ──────→ SettingsRepository
ClearCache ──────────→ StorageRepository
```

Every new use case has one public `execute()` method and returns `Result<T>`. Shared request validation covers quality, target size, resize bounds, file limits, supported formats, and duplicate request identities.

## Repository diagram

```text
ImageSelectionRepository  → picker/import/validator data adapters
CompressionRepository     → EngineManager data adapter
HistoryRepository         → local history storage adapter
SettingsRepository        → local settings adapter
StorageRepository         → managed file/cache adapter
AnalysisRepository        → local aggregate/statistics adapter
ExportRepository          → export/share adapter
```

Contracts contain only business operations and domain values. No Flutter-specific APIs are exposed.

## Architecture decisions

- Entities are framework-independent, immutable, and use value equality.
- Lists are defensively copied into unmodifiable collections at entity/state boundaries.
- `ProcessingProgress` carries current file, completed/remaining/total files, per-file and overall progress, speed, ETA, and queue position.
- `OperationControl` provides cooperative cancel/pause/resume without exposing engine types.
- Providers receive use cases through constructors and can be independently mocked.
- Provider rebuilds are minimized by immutable state replacement and no-op equality checks before notification.
- Provider methods reject overlapping requests; compression and batch workflows also protect terminal cancellation state from a late success result.
- Friendly provider messages come from structured `AppError` values; raw exceptions are mapped through existing error infrastructure.
- Settings loading is represented by `LoadSettingsUseCase`, so settings providers do not call repositories directly.
- HEIC/AVIF/JXL remain extension-point values and are rejected by application validation until a supported data adapter is registered.
- Premium and cloud backup settings are represented as inert architectural fields only; no premium entitlement or cloud implementation was added.

## Performance considerations

- No decoded image buffers or platform files are retained by application state.
- Batch operations are bounded by the injected repository/engine queue; providers do not create unbounded futures.
- Progress objects are immutable snapshots and notifications are skipped when state is unchanged.
- Duplicate in-flight requests are suppressed.
- Pause and cancellation are cooperative and do not block the UI isolate.
- Repository calls are not repeated while a provider operation is active.

## Future extension points

- Add `data/repositories` implementations mapping current EngineManager and FileManager models into application entities.
- Register all new use cases/providers in the existing composition root only after owner approval.
- Add target-size feasibility feedback, richer typed recovery actions, and a dedicated benchmark use case when the platform contract supports it.
- Add persistent settings/history adapters and statistics aggregation.
- Add on-device analysis and additional codec adapters without changing the application contracts.
- Add Provider scopes to future screens using `context.select` or narrow `Consumer` regions.

## Known limitations

- Flutter/Dart executables were unavailable in the current shell, so analyzer, formatter, and tests could not be executed here; the added tests are checked in for the Flutter-enabled validation environment.
- New repository contracts are not wired to concrete data adapters yet, by design, because this deliverable implements the application layer only.
- `Settings.copyWith` supports explicit clearing of the optional default preset through `clearDefaultPreset`; nullable copy-with APIs remain intentionally simple elsewhere.
- Application-level messages are safe structured strings but localization remains a presentation concern and is not introduced into domain code.
- Android codec, Photo Picker lifecycle, SAF, MediaStore, and low-memory behavior remain integration concerns.

## Phase completion checklist

- [x] Immutable domain entities created.
- [x] Value equality implemented.
- [x] Framework-independent repository contracts created.
- [x] Dedicated use cases created with `execute()` and `Result<T>`.
- [x] Immutable Home, Compression, Batch, History, Settings, Statistics, and Benchmark states created.
- [x] Loading, success, error, empty, cancelled, paused, completed, and progress state paths represented.
- [x] Progress includes current file, completed/remaining files, percentage, speed, ETA, and queue position.
- [x] Constructor-injected Provider classes created.
- [x] Duplicate request and lifecycle guards added.
- [x] Validation for quality, target size, resize, formats, file limits, and duplicates added.
- [x] Friendly error and retry state exposed.
- [x] No UI screens/widgets/animations/material components added.
- [ ] Flutter formatting/analyzer/tests run in an available Flutter-enabled environment.
- [ ] Concrete data repository wiring and composition-root registration await approval/application-layer review.

## Approval gate

Phase 4 application-layer work is ready for review. Phase 5 must not begin until the owner approves this architecture and the Flutter-enabled validation run passes.
