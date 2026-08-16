# Comprezza — Roadmap

This roadmap is living project context. Update phase status only after the phase review and owner approval.

## Phase 15 status

- [x] **Phase 15 — Production release package generated (documentation complete; release not approved)**
  - Generated Play Store, Data Safety, privacy/legal, security, asset, screenshot, testing, support, marketing, business, release-owner, and final-report packages under `docs/release/phase_15/`.
  - Replaced the old privacy-policy draft with a structured legal template containing explicit manual replacement fields; no legal or contact values were fabricated.
  - No application architecture, feature, or UI code was modified for Phase 15.
  - The project now transitions to real-device validation, protected CI, signed AAB generation, Play Console declarations, Internal Testing, Closed Testing, and production rollout gates.
  - Phase 15 documentation is complete; publication remains blocked by the Phase 14 audit decision and all unresolved legal/product/artifact/device gates.

## Final engineering audit status

- [x] **Final engineering audit — complete product review (Do Not Approve; score 76/100)**
  - Audited the complete commercial product without redesigning architecture, adding features, or changing the UI design language.
  - Added cooperative export/share cancellation during compressor-controller disposal.
  - Classified remaining findings as implementation/product defects or environment limitations in `docs/architecture/final_engineering_audit.md`.
  - Internal Testing, Closed Testing, and Production approval are withheld pending legal policy publication, commercial-scope completion/acceptance, protected CI, signed AAB/R8/lint/manifest evidence, and Android/device/Play validation.

## Phase 14 status

- [x] **Phase 14 — Complete Production Audit and RC1 Review (audit complete; production approval withheld)**
  - Audited code quality, UI/Material 3, UX, accessibility, localization, performance, memory, security, privacy, Android/Play readiness, testing, and release engineering without architectural changes or feature additions.
  - Corrected workflow accessibility announcements to use localized positional progress text while preserving screen-reader context.
  - Static ARB parity, generated localization presence, source balance, manifest permission, resource, and signing-artifact checks pass.
  - Flutter/Android/CI/device/Play Console evidence and legal HTTPS privacy-policy publication remain release gates.
  - Overall static-review readiness score: 78/100. RC1 is not production-approved; Phase 15 waits for release-owner approval and closure of mandatory gates.

## 2026-08-08 — Finished product items

- [x] **Batch compression wired into the app** — `/batch` route, home quick action/menu entry, workflow-button navigation, and a `BatchCompressionAdapter` connecting the queue to the real picker, engine, and history; adapter tests added.
- [x] **Camera capture** — `ImagePickerGateway.pickCameraImagePath()` and controller support; the workflow "Use camera" button now opens the system camera.
- [x] **Keep-metadata (EXIF)** — `keepExif` threaded through the gateway and engine; the workflow toggle now preserves metadata.
- [x] **Settings/About destinations** — Play-store listing and website/rate rows open external URLs via `url_launcher`; the website constant is a marked placeholder pending the approved domain.
- [x] **Benchmark tool hidden from user-facing navigation** — removed from the home tile, app-bar menu, and navigation-rail menu; the route remains for debug use.
- [x] **Stub copy removed** — seven "will be connected / coming soon" localization keys deleted from the English and Hindi ARB resources and regenerated.
- [x] **Privacy policy finalized** — complete publishable text; five personal fields (date, contacts, address, URL), legal review, and HTTPS publication remain.
- [x] **Flutter validation green** — `flutter analyze` clean, 144/144 tests pass, formatting and localization generation verified on Flutter 3.44.9 / Dart 3.12.2.

## Completed

- [x] **Phase 1 — Initial Architecture Foundation**
  - Feature-first Clean Architecture boundaries.
  - Core/data/domain/presentation folder structure.
  - Architecture documentation.

- [x] **Phase 1 Hardening — Production Infrastructure**
  - Manual dependency injection.
  - Repository and use-case ports.
  - `AppError` and `Result<T>`.
  - Startup and cache cleanup services.
  - Logging and development performance hooks.
  - Debug/profile/release configuration.
  - GoRouter structure.
  - ARB localization infrastructure.
  - Theme architecture.
  - Test and golden-test boundaries.

- [x] **Phase 2 — Foundation Services & Dependency Injection**
  - Scoped manual dependency injection.
  - Configuration, logging, error/result boundaries.
  - Filesystem and cache services.
  - Localization, theme, routing, utilities, device, and benchmark foundations.
  - Senior Engineer Review completed; Flutter toolchain validation remains pending.

## Next phases

- [x] **Phase 3 — Core Image Processing Platform**
  - Replaceable engine interfaces, registry, and manager.
  - JPEG, PNG, WebP native codec path.
  - Resize, conversion, codec metadata policy, estimation, benchmark, and queue foundations.
  - Target-size search and intermediate cleanup.
  - 29-test validation suite and architecture audit passed.
  - Heuristic analysis, standalone EXIF rewriting, legacy migration, and Android integration remain tracked limitations.

- [x] **Phase 4 — File Management Platform (architecture approved; production release gated by Android integration/device validation) — File Management Platform**
  - Central FileManager facade and manual DI registration.
  - Photo Picker/camera/gallery selection with lost-data recovery.
  - App-private import, storage, export, history, cleanup, naming, validation, checksum, and permission foundations.
  - Native decode validation with disposed image buffers.
  - 38-test validation matrix and architecture/compliance audits passed.
  - Android SAF and device integration remain later validation gates.

- [ ] **Phase 5 — Legacy Single-Image Migration**
  - Migrate the legacy compressor into the hardened data/domain/presentation architecture.
  - Add Provider-backed state.
  - Replace the transitional adapter.
  - Add domain, repository, provider, and widget tests.

- [ ] **Phase 5 — Production Image Engine Integration**
  - Replace the legacy compressor service with the Phase 3 EngineManager path.
  - Add Android codec integration and low-memory tests.
  - Add standalone local EXIF adapter if required.
  - Add quality, resize, conversion, and target-size acceptance tests.

- [ ] **Phase 6 — Navigation Shell, Home Dashboard & Core User Experience (implemented; awaiting review/approval)**
  - Adaptive Material 3 NavigationBar/NavigationRail shell.
  - Home Dashboard hero, quick actions, storage overview, recent activity empty state, statistics preview, smart tips, and Select Images FAB.
  - Future routes prepared for Compression, History, Statistics, Settings, Benchmark, and About.
  - Responsive phone, tablet, large-screen, landscape, and foldable-friendly composition.
  - Accessibility semantics, tooltips, touch targets, and reduced-motion behavior.
  - Compression, history, statistics, settings, and about workflows route to real screens; the benchmark tool is no longer exposed in user-facing navigation (route retained for debug use).
  - Awaiting Principal Flutter Architect review and project-owner approval; Flutter-enabled validation remains pending.

- [ ] **Phase 7 — Smart Compression Workflow (presentation implemented; validation and approval pending)**
  - Presentation-only workflow at `/compression` composed around the preserved legacy controller seam.
  - Gallery selection, analysis summary, quality control, local estimates, before/after preview, processing, success, save/share, and recovery surfaces.
  - Camera capture and metadata (EXIF keep) are now wired into the workflow; multi-image selection is provided by the Phase 8 batch route. Target-size search, format conversion, and resize are live workflow controls; interactive gestures and Settings-preference propagation remain extension points.
  - Flutter-enabled generation/analyzer/tests and Android/device validation remain required before production approval.

- [ ] **Phase 7b — Presets and Target File Size**
  - Built-in presets.
  - Custom preset CRUD.
  - Target-size search algorithm.
  - Estimated output size.

- [ ] **Phase 8 — Batch Compression (integrated into the app; device validation pending)**
  - Queue model with real picker/engine wiring through `BatchCompressionAdapter` (inspection, format/resize/quality/target-size/keepExif mapping, history recording).
  - `/batch` route, home-dashboard quick action and menu entry; the workflow "Batch compress" button navigates to the batch workspace.
  - Individual/overall progress, status badges, summary, retry recovery, pause/resume/cancel, selection controls, and start-over.
  - Sliver thumbnail virtualization and bounded metadata/decode behavior.
  - Adapter tests pass; Android/device testing and owner approval remain required.

- [ ] **Phase 8 — Folder Compression**
  - Android SAF folder selection.
  - Subfolder policy.
  - Unsupported-file skipping.
  - Permission and retention review.

- [ ] **Phase 9 — History and Recent Files**
  - Local persistence.
  - Thumbnails.
  - Recompress/share/delete actions.
  - Retention policy.

- [ ] **Phase 10 — Statistics Dashboard**
  - Local aggregate statistics.
  - Daily/monthly/lifetime savings.
  - Processing metrics.
  - Privacy review.

- [x] **Phase 10 — Settings, Personalization, Accessibility & App Intelligence (implementation closed; production gates remain)**
  - Localized Material 3 settings sections, immutable preferences, app-scoped persistence, offline recommendations, privacy-safe import/export, storage usage, responsive layouts, lazy sections, root personalization propagation, accessibility surfaces, storage-action boundaries, and debug-only developer options.
  - Repository-owned implementation and documentation are complete. Project-owner approval for progression was received on 2026-08-06. Flutter/Dart analyzer, formatter, generated localization, focused/full tests (144 passing), legal/HTTPS-policy publication, the real website domain, document-picker integration, Android/device validation, legacy workflow integration, and production approval remain tracked release gates. Phase 11 may proceed only as a separately authorized phase.

- [ ] **Phase 11 — Benchmark Mode**
  - Multi-setting comparison.
  - Processing-time measurement.
  - Visual comparison.
  - Deterministic test fixtures.

- [ ] **Phase 11 — Sharing, Export, Premium Foundation & App Ecosystem (Phase 11.1 repository integration implemented; production validation pending)**
  - Feature-owned offline share/export contracts around the existing managed file boundary.
  - Secure naming/path authorization, collision-safe staging, detailed export reports, and Sharesheet dispatch.
  - Premium feature/entitlement and non-interruptive ad extension points without payments or ads.
  - Future backup/ecosystem contracts for Comprezza product modules.
  - Phase 11.1 now wires the managed share/export coordinator, premium contracts, feature gate, production image-export gateway, confirmation preview, export summary, progress, retry, and cancellation into the existing workflow.
  - Flutter/Android validation, post-freeze device lifecycle testing, and owner approval remain required before Phase 12.

- [ ] **Phase 12 — Production Engineering Optimization (combined Phase 11.1/12 validation complete; production gates pending)**
  - Deferred Settings/cache startup I/O until after the first frame.
  - Bounded decoded-image cache and memory-pressure eviction.
  - Frame-coalesced batch notifications and single-pass resize planning.
  - Metadata-only 500-image simulation coverage.
  - Flutter/profile Android startup, low-memory, thermal, 60 FPS, accessibility, and release validation remain required.
  - Cross-phase validation preserved the optimization and integration boundaries and made the compatibility export destination/naming and pre-inspection path validation explicit.
  - Production approval and owner review remain pending until Flutter/Android/device gates pass.

- [ ] **Phase 13 — Release Engineering and RC1 Production Readiness (repository preparation and CI hardening complete; artifact/device validation pending)**
  - Release Gradle signing conventions, fail-fast protected signing, R8/resource shrinking, and ProGuard configuration.
  - Branded adaptive/backward-compatible launcher resources and credential-scoped CI quality/AAB workflow.
  - RC1 release notes, engineering report, internal-testing, closed-testing, and complete production checklists.
  - Permission, privacy/Data Safety, security, accessibility, localization, CI/CD, and Play readiness review.
  - Flutter/Android/AAB/lint/R8/manifest/signing/device/Play Console validations remain required.
  - Production release is not approved; wait for owner approval before Phase 14.

## Product vision

- **Version 1:** Photo compression, resize, conversion, and batch processing.
- **Version 2 candidates:** HEIC/AVIF support, background processing, offline smart optimization, and folder monitoring.
- **Version 3 candidates:** Video/PDF/ZIP workflows and optional cloud backup only after an explicit privacy-policy decision.

Future product directions remain subject to separate architecture, privacy, security, performance, and Play Store reviews.

## Future product directions

- [ ] Premium feature entitlements.
- [ ] Ads architecture integration points, without interrupting compression.
- [ ] **Conditional alternative — Cloud backup**, only after an explicit product-owner decision changes the offline-only policy and a separate privacy/security/Play Store review.
- [ ] **Conditional alternative — AI-assisted recommendations**, only if implemented fully offline or after an explicit product-owner decision changes the no-cloud policy and a separate privacy/security review.
- [ ] iOS support.
- [ ] Desktop support.
- [ ] Tablet optimization beyond the Android baseline.
- [ ] Wear OS companion.
- [ ] Web support.
