# Phase 11 — Sharing, Export, Premium Foundation & App Ecosystem

## Scope and frozen-architecture boundary

Phase 11 adds feature-owned, platform-neutral sharing/export contracts and local coordinators. The existing architecture remains frozen: repositories, use cases, providers, dependency injection, routing/navigation, Settings architecture, design-system APIs, and branding were not changed.

The implementation intentionally stops at the approved file-management and platform gateway boundaries. Existing `ExportService` owns app-managed copies and collision-safe names; the Phase 11 coordinator adds validated request models, reports, share-copy staging, and a `ShareDispatcher` adapter backed by `share_plus`.

## Sharing architecture diagram

```text
Approved caller (future result/history surface)
        │ ShareRequest / ShareAsset
        ▼
LocalShareExportService
        ├── LocalExportSecurityPolicy (fail closed)
        ├── ExportService.prepareShareCopy (app-private temporary copy)
        ├── SharePayloadBundle (content-safe local paths + MIME)
        └── ShareDispatcher
              └── SharePlusDispatcher → Android Sharesheet

Temporary share files remain under managed cleanup ownership.
They are not deleted immediately after dispatch because receiving apps may
consume the granted content URI asynchronously.
```

## Export architecture diagram

```text
ExportRequest
   │ bounded assets + naming options + destination contract
   ▼
ExportSecurityPolicy
   │ local path, size, dimension, name, and destination validation
   ▼
LocalShareExportService.export
   │ app-managed destination only in this phase
   ▼
Existing ExportService.export
   │ FileNamingStrategy + FileSystemService atomic/collision-safe copy
   ▼
ExportOutcome
   ├── collision-safe output paths
   └── versioned ExportReport
       ├── original/compressed size
       ├── saved bytes/ratio
       ├── processing time
       ├── format/resolution/preset
       ├── metadata status
       └── destination kind
```

Folder export is represented by a platform-neutral `userSelectedFolder` destination but is fail-closed until a reviewed Android SAF/DocumentFile adapter is approved. The current naming policy requires managed folder creation and collision-safe versioning; overwrite is deliberately rejected. ZIP/CSV/JSON report contracts can consume `ExportReport`; PDF generation is intentionally not implemented.

## Sharing workflow

1. The approved caller supplies one or more already-processed local assets.
2. `ExportSecurityPolicy` rejects remote URIs, NUL bytes, invalid metadata, oversized selections, and unsupported destinations.
3. Each selected asset is copied once into managed temporary share storage by the existing streaming/atomic export boundary.
4. The dispatcher passes local files to the Android Sharesheet through `share_plus`.
5. Temporary files remain available for the platform recipient and are reclaimed by the existing managed startup cleanup policy after the configured TTL, not immediately after the share call.
6. The outcome returns a detailed report and the platform status (`shared`, `dismissed`, or `unavailable`). Comparison sharing reports the compressed asset once; the original remains a second payload without double-counting compression savings.

Single, multiple, selected, and original-plus-compressed payloads are represented by `ShareRequest.scope` and `ShareRequest.payload`. The Android Sharesheet decides which target apps are available; no target-specific integrations or cloud links are added.

## Premium architecture

```text
PremiumFeature ──► PremiumManager ──► SubscriptionStatus
                          │
                          └── future billing adapter (not implemented)

AdPlacement ──► AdManager
                  └── NoOpAdManager (ads disabled until separate review)
```

`LocalPremiumManager` is fail-closed and always returns the free baseline. Premium status cannot be injected by an arbitrary caller; a future verified billing adapter must own entitlement state. No payment SDK, account, billing, or ad network is included. `NoOpAdManager` is explicit and cannot interrupt compression, export, sharing, settings, history, or startup.

## Security notes

- Only local file paths are accepted; HTTP(S), content URIs, and NUL-containing inputs are rejected by the feature policy.
- User-visible names are reduced to a safe basename before entering the existing `FileNamingStrategy`; path traversal cannot select an arbitrary export destination.
- Every source path must be under a trusted app-managed temporary, compression, or export root resolved from the existing `StorageManager`; feature callers cannot supply arbitrary authorization roots. Missing managed storage fails closed. Canonical symlink resolution is asynchronous so validation never blocks the UI isolate.
- File copies continue through the existing app-owned `FileSystemService` boundary and atomic/collision-safe `ExportService`.
- Export selection and file size are bounded to prevent unbounded work.
- Reports contain image metadata and generated names, not source paths, tokens, logs, or network identifiers.
- Sharing remains offline. The OS Sharesheet/receiving application is responsible for the user's chosen destination after the user explicitly shares.
- Partial staging failures invoke a best-effort managed cleanup callback; successful temporary-share files use the managed `comprezza_` prefix and remain under the existing startup TTL cleanup after dispatch.
- Temporary files are not deleted immediately after dispatch; cleanup is TTL/ownership based to avoid asynchronous recipient failures.

## Performance and memory notes

- Existing `copyFromExternal` streams bytes and uses a managed `.part` file; no full image byte buffer is introduced.
- Assets and reports are bounded immutable lists. No decoded pixels are retained.
- Each share/export asset is copied once for its selected purpose. Original-plus-compressed intentionally requires two payload files.
- The coordinator is synchronous per asset to preserve bounded memory and predictable failure reporting; future batch orchestration can add bounded concurrency after profiling.
- Cleanup remains a separate policy operation and does not run synchronously after the share sheet opens.

## Accessibility and Material 3 integration boundary

The contracts carry no visible strings and do not introduce UI. Future Share Preview and Export Summary screens must use the existing Material 3 components, semantic labels for thumbnails/file size/destination/warnings, keyboard-focusable actions, large touch targets, dynamic text, and a reduced-motion path. This phase does not modify the frozen navigation or design-system APIs.

## Future ecosystem plan

- `EcosystemProduct` and `EcosystemAdapter` provide a shared contract for Comprezza Photo, Video, PDF, Convert, and Resize modules.
- `BackupAdapter` is versionable for local backup, cloud backup, import/export, and migration compatibility; no cloud implementation exists and offline privacy remains unchanged.
- `ExportReport` is JSON-serializable and can later feed CSV/JSON/ZIP/PDF report adapters without changing the export coordinator. Comparison sharing reports the compressed asset once; the original is a second payload and is not double-counted.
- `ExportDestination.userSelectedFolder` is ready for SAF/DocumentFile integration after platform review.
- Future Android share targets remain Sharesheet targets, not hardcoded vendor integrations.

## Validation and tests

Focused tests cover trusted managed-root and symlink path security, comparison-sharing requirements and report aggregation, deterministic smart-share recommendations, premium defaults, and the no-op ad boundary. Flutter formatter/analyzer/test execution and Android Sharesheet/FileProvider/device validation must run in a Flutter/Android-enabled CI environment before release approval.

## Known limitations

- No UI route or DI registration was added because those architecture surfaces are frozen.
- No PDF generation, ZIP creation, CSV writer, document picker, cloud backup, billing, ads, or target-specific share API is implemented.
- The existing history screen's export callback remains a presentation seam; wiring it to this coordinator requires the approved post-freeze integration step.
- `share_plus` provides the platform share abstraction; Android OEM behavior and recipient-app consumption still require device testing.
- The native MediaStore bridge canonicalizes source paths, restricts them to the explicit managed cache/compression/export roots, sanitizes display names, and derives MIME from the validated extension.
- The transitional legacy compressor now writes generated outputs beneath the managed cache directory with the cleanup-recognized `comprezza_` prefix; deletion is restricted to that directory and prefix.
- The legacy export action now uses generated localization and adaptive Material 3 controls, but a dedicated Share Preview/Export Summary surface is still not wired.
- Folder export is represented but intentionally returns an unavailable result until SAF/DocumentFile is reviewed.

## Phase completion checklist

- [x] Immutable share/export domain models
- [x] Export report with required size, ratio, timing, format, resolution, preset, metadata, and destination fields
- [x] Secure filename/path/destination validation
- [x] Existing managed ExportService reused for collision-safe streaming copies
- [x] Offline `share_plus` Sharesheet adapter
- [x] Single/multiple/selected/original-plus-compressed request contracts
- [x] Deterministic offline smart-share recommendations
- [x] Premium manager and feature enum without payments
- [x] No-op ad abstraction that cannot interrupt workflows
- [x] Future backup/ecosystem contracts
- [x] Focused security/performance/report tests
- [x] Partial-staging rollback contract through the existing managed file boundary
- [x] Documentation, roadmap, changelog, technical-debt, and bug records updated
- [ ] Flutter formatter/analyzer/test execution in this environment
- [ ] Android Sharesheet, large-file, OEM, lifecycle, and accessibility validation
- [x] Successful-share outputs placed under the managed startup TTL cleanup policy
- [ ] Approved post-freeze UI/DI integration
- [ ] Owner approval before Phase 12

## Approval status

**Phase 11 foundation is not production-approved.** Repository code has received security and UX hardening, but approval is withheld pending trusted composition-root/UI integration, successful-share TTL cleanup scheduling, Flutter validation, Android Sharesheet/MediaStore/device testing, Play Data Safety/privacy review, and owner approval. Phase 12 has not started.
