# Phase 4 — File Management Platform

## Scope

Phase 4 adds the feature-owned file-management platform for Comprezza. It does not add UI, screens, Widgets, Providers, routing, theme changes, or image-compression behavior.

## Directory structure

```text
lib/features/compressor/data/services/file_management/
├── cleanup/
│   └── file_cleanup_service.dart
├── exports/
│   └── export_service.dart
├── history/
│   └── history_storage.dart
├── imports/
│   └── import_service.dart
├── interfaces/
│   └── file_management_interfaces.dart
├── models/
│   └── file_management_models.dart
├── naming/
│   └── file_naming_strategy.dart
├── permissions/
│   └── permission_service.dart
├── pickers/
│   ├── folder_picker_service.dart
│   └── image_picker_service.dart
├── storage/
│   └── storage_manager.dart
├── utilities/
│   └── file_utilities.dart
├── validators/
│   └── file_validator.dart
└── file_manager.dart
```

## Storage architecture

```text
User picker / future SAF adapter
          ↓
    ImportService
          ↓
App-private temporary storage
          ↓
 FileValidator + checksum + decode probe
          ↓
      FileManager
       ↙   ↓   ↘
  History Export Cleanup
          ↓
 Existing FileSystemService
          ↓
  cache / history / thumbnails / exports / compression / backup
```

All app-owned writes use the existing `FileSystemService`. External picker files are copied into app-private temporary storage before validation and future processing. Generated writes use temporary `.part` files and rename finalization with best-effort cleanup.

## Design decisions

- Android image selection uses `image_picker` with Android Photo Picker enabled where available.
- Camera selection remains single-image; gallery supports single and multiple selection.
- Lost picker data is recovered through `retrieveLostData()` and routed through the same import/validation path.
- No broad storage permission is requested. `PermissionService` reports per-selection readability and explicitly reports that no broad permission grant is performed.
- File validation checks existence, regular-file type, non-zero size, configured maximum size, supported extension, SHA-256 identity, and a bounded native decode probe. Native `ImmutableBuffer` and `ImageDescriptor` instances are disposed in `finally`.
- Duplicate detection uses content checksum and byte size; perceptual hashing remains an extension point.
- Storage locations are app-private and include a distinct backup directory for future use.
- Exports and share copies use collision-safe sanitized names and managed atomic copying.
- History is stored locally as JSON through atomic filesystem writes. Malformed JSON or records return structured corruption failures rather than silently becoming an empty history.
- Cleanup applies age and byte policies, never touches the history directory, and protects compressed paths referenced by history plus caller-provided active paths.
- Folder scanning is an architecture foundation with recursive traversal, hidden-file/directory exclusion, supported-extension filtering, and no UI. Android SAF/DocumentFile integration is intentionally deferred.
- All public service boundaries return `Result<T>`; plugin and filesystem exceptions are mapped into `AppError`.

## Dependency registration

`AppDependencies` lazily registers:

- `FileManager`
- `ImportService`
- `ImagePickerService`
- `FolderPickerService`
- `FileValidator`
- `StorageManager`
- `FileNamingStrategy`
- `HistoryStorage`
- `ExportService`
- `FileCleanupService`
- `PermissionService`
- `FileUtilities`

The composition root remains the only place that binds concrete implementations.

## Performance and memory

- SHA-256 uses chunked file input rather than loading an entire file into a byte array.
- Imports and exports use streamed copies.
- Decode probes dispose native buffers/descriptors immediately.
- Cleanup is bounded by age/bytes and processes files sequentially.
- No unbounded batch concurrency was introduced.

## Validation

- Dart formatting: passed.
- `flutter analyze`: passed with no issues.
- `flutter test`: passed; 38 tests.
- Import/cycle/boundary audit: passed.
- Legacy Android storage permission audit: passed; no `READ_EXTERNAL_STORAGE`, `WRITE_EXTERNAL_STORAGE`, or `MANAGE_EXTERNAL_STORAGE` declarations detected.

## Known limitations

- Android SAF folder selection and persisted URI permissions require device/integration implementation in a later phase.
- Native Photo Picker lifecycle, MediaStore export, large-image memory pressure, malformed-image behavior, and OEM codec differences require Android-enabled integration testing.
- Collision-safe naming is deterministic and uses managed atomic finalization; a future multi-process export coordinator may be needed if concurrent writers are introduced.
- The decode probe is a validation gate, not full semantic image inspection.
