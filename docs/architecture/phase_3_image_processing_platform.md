# Comprezza Phase 3 — Core Image Processing Platform

## Scope

Phase 3 establishes the offline image-processing platform inside the existing feature-first Clean Architecture. It adds engine contracts, models, registry, manager, queue, native codec adapter, analysis baseline, estimation, resize planning, metadata policy, benchmarking, and tests.

This phase deliberately does **not** add screens, widgets, Providers, presentation state, theme code, routing changes, or cloud/network behavior.

## Module structure

```text
lib/features/compressor/data/services/image_processing/
├── analyzers/
│   └── heuristic_analyzer_engine.dart
├── benchmarks/
│   └── benchmark_engine.dart
├── compressors/
│   └── flutter_image_compress_engine.dart
├── converters/
│   └── .gitkeep                         # future codec adapters
├── estimators/
│   └── estimation_engine.dart
├── metadata/
│   └── metadata_engine.dart
├── queue/
│   └── priority_processing_queue.dart
├── resizers/
│   └── resize_engine.dart
├── interfaces/
│   ├── engine_manager.dart
│   ├── engine_registry.dart
│   └── processing_engine.dart
├── models/
│   └── image_processing_models.dart
├── engine_manager.dart
└── engine_manager_data_source.dart
```

## Architecture diagram

```text
Future Provider / Use Case
          │
          ▼
ImageProcessingRepository
          │
          ▼
EngineManagerDataSource
          │
          ▼
EngineManager
   ┌──────┼────────┬──────────┐
   ▼      ▼        ▼          ▼
Queue  Registry  Benchmark  Result<T>
          │
          ▼
   Processing Engines
   ├── Native codec compressor
   ├── Resize-capable native codec path
   ├── Format conversion path
   ├── Codec metadata policy path
   ├── Heuristic analyzer
   └── Replaceable future adapters
```

## Dependency diagram

```text
AppDependencies (composition root)
 ├── FileSystemService
 ├── BenchmarkTimer
 ├── EngineRegistry
 │    ├── FlutterImageCompressEngine
 │    ├── HeuristicImageAnalyzerEngine
 │    ├── LocalEstimationEngine
 │    └── LocalBenchmarkEngine
 ├── PriorityProcessingQueue
 ├── DefaultEngineManager
 └── EngineManagerDataSource
      └── ImageProcessingRepositoryImpl
           └── ProcessImageUseCase
```

The only Phase 3 change outside the platform module is lazy composition-root registration in `AppDependencies`. This is the permitted integration seam: it makes the platform available without changing the frozen folder architecture, routing, theme, state management, or presentation code.

## Engine flow

```text
ProcessingRequest
      │
      ▼
Validate request and cancellation token
      │
      ▼
PriorityProcessingQueue
      │
      ▼
EngineRegistry.resolve(request)
      │
      ▼
BenchmarkEngine.measure(...)
      │
      ▼
Selected ProcessingEngine.process(request)
      │
      ├── normal output → ProcessingOutput
      ├── targetBytes → bounded quality search
      │                    ├── benchmark each iteration
      │                    ├── retain best output
      │                    └── safe-delete intermediates
      └── exception → ErrorMapper → Result.failure(AppError)
```

## Implemented capabilities

- JPEG, PNG, and WebP native codec output through `flutter_image_compress`.
- Format model and extension resolution for JPEG, PNG, WebP, HEIC, AVIF, and JPEG XL extension points.
- Quality values and presets: maximum quality, balanced, smallest size, extreme compression, and custom.
- Lossless validation: current native path accepts lossless mode only for PNG.
- Resize planning for percentage, width, height, and explicit dimensions while preserving aspect ratio.
- Native codec resize output when resize options are supplied.
- Native format conversion through the selected output format.
- Codec-level EXIF keep/remove policy through encoder options.
- Local heuristic image categorization baseline with replaceable analyzer interface.
- Deterministic estimation of output bytes, compression ratio, storage savings, upload-time savings, cloud-cost model savings, quality, and compression scores.
- Bounded priority queue with FIFO ordering within priority, pause, resume, retry, and cooperative cancellation.
- Engine registry replacement and specialized-engine lookup.
- Engine manager lifecycle coordination and unified `Result<T>` failures.
- Target-size binary search over quality 1–100 with intermediate cleanup.
- Development-only benchmark timing, RSS delta where available, output metrics, and quality score hooks.
- Existing filesystem abstraction used for app-owned directory resolution, output metadata, and cleanup boundaries.

## Error handling

All public engine and manager operations return `Result<T>`. Raw codec and platform exceptions are caught and mapped through the existing `ErrorMapper` and `ResultErrorAdapter`. Cancellation uses `ErrorCode.cancelled`; unsupported codecs and operations use typed `ErrorCode` values.

## Performance and memory decisions

- Queue concurrency defaults to one operation to protect low-memory Android devices.
- Native codec work is delegated to `flutter_image_compress`; plugin calls are not moved into unsupported background plugin isolates.
- The manager avoids retaining decoded image buffers; the codec handles native decode/encode memory.
- Target-size search deletes non-selected outputs immediately through the filesystem boundary.
- Native output cleanup is attempted on null-output and post-processing failure paths.
- Benchmark timing is local and development-oriented; no analytics or telemetry is emitted.
- Source dimensions and byte counts are optional because transient Photo Picker paths may not be stat-able through app-private roots.

## Test coverage

`test/features/compressor/data/image_processing_platform_test.dart` covers:

- Format resolution and compression presets.
- Estimation bounds and quality scoring.
- Aspect-ratio resize planning.
- Registry resolution and unsupported formats.
- Queue priority, FIFO behavior, pause/resume, retry, and cancellation.
- Engine-manager exception conversion.
- Target-size quality search, repeated iterations, benchmark invocation, and intermediate cleanup.

The full project suite contains 29 passing tests.

## Known limitations and deliberate extension points

1. **Analyzer baseline:** the current analyzer is deterministic filename/size heuristics, not image-content statistics or ML. The `ImageAnalyzerEngine` contract is ready for a future on-device ML adapter.
2. **Metadata semantics:** EXIF keep/remove is codec-level during output encoding. Standalone EXIF rewriting is intentionally unsupported until a dedicated, reviewed local metadata adapter is selected.
3. **Transient source paths:** Android Photo Picker paths may be transient and outside app-private roots. Optional input metrics remain nullable rather than requesting permissions or copying data implicitly.
4. **Filesystem handles:** data-layer adapters may construct `File` handles for codec output cleanup/stat operations, while ownership and permitted operations remain governed by `FileSystemService`. A stricter path-handle abstraction can replace this later.
5. **Legacy behavior:** `LegacyCompressorAdapter` and the original compression service remain isolated for the current UI. They must not become the long-term engine path and are scheduled for the next migration phase.
6. **Android release build:** Java and Android SDK are unavailable in this environment; APK packaging/signing still requires Android-enabled CI.

## Play Store and privacy review

- No network, analytics, tracking, login, or cloud APIs were introduced.
- No Android storage or network permissions were introduced.
- Platform code remains in the data/service boundary.
- Processing is local and output staging remains app-private until explicit export.

## Validation evidence

- `dart format --set-exit-if-changed lib test`: passed.
- `flutter analyze`: passed with no issues.
- `flutter test`: passed; 29 tests passed.
- Relative import and cycle scan: passed.
- Requested module-directory scan: passed.
- Domain platform-import scan: passed.
- Presentation/provider/theme/routing dependency scan: passed.
- Android broad-storage/network permission scan: passed.

## Approval status

Phase 3 is architecturally ready for owner approval and progression to Phase 4. This is not Android production-release approval; release still requires Java/Android SDK build, signing, device, and Play Store checks.
