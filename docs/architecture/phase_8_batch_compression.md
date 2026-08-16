# Phase 8 — Batch Compression & Queue Management

## Scope and freeze boundary

Phase 8 adds a presentation-only batch compression experience. The architecture freeze remains active; no domain, repository, provider, engine, platform, navigation, dependency-injection, design-system, or branding file is changed.

The experience is intentionally isolated behind two injected presentation seams:

- `BatchImagePicker` — returns metadata descriptors for selected images.
- `BatchImageProcessor` — processes one descriptor with the current batch settings.

The screen is not routed or registered in DI during the freeze. This makes the workflow testable now without pretending that the frozen application contracts already support a production batch integration.

## Files created

- `lib/features/compressor/presentation/batch_compression_controller.dart`
- `lib/features/compressor/presentation/batch_compression_screen.dart`
- `test/features/compressor/presentation/batch_compression_controller_test.dart`
- `test/features/compressor/presentation/batch_compression_screen_test.dart`
- `docs/architecture/phase_8_batch_compression.md`

## Files modified

- `lib/l10n/app_en.arb`
- `lib/l10n/app_hi.arb`
- `lib/l10n/app_localizations.dart`
- `lib/l10n/app_localizations_en.dart`
- `lib/l10n/app_localizations_hi.dart`

No frozen architecture file was modified.

## Workflow diagram

```text
Select multiple images
        ↓
Metadata-only batch analysis
        ↓
Virtualized thumbnail preview grid
  remove · select/deselect · add more
        ↓
Apply global settings
  preset · quality · format · resize · metadata
  per-image quality override seam
        ↓
Create bounded presentation queue
        ↓
Process one item at a time through injected seam
  waiting → compressing → completed
                    ↘ failed → retry failed only
                    ↘ paused → resume
                    ↘ cancelled
        ↓
Completion summary
  processed · skipped · failed · original · output · saved · ratio
        ↓
Save all / share selected feedback seams
Prepare ZIP remains explicitly future work
```

## Queue architecture diagram

```text
BatchCompressionScreen
        │ listens to
        ▼
BatchCompressionController (ChangeNotifier)
        │ owns metadata only
        ├── List<BatchImageItem>
        │     id/path/name/bytes/dimensions/status/progress/output metadata
        ├── Set<String> selectedIds
        ├── BatchCompressionSettings
        ├── BatchWorkflowPhase
        ├── pause/resume Completer gate
        └── injected seams
              ├── BatchImagePicker
              └── BatchImageProcessor (one image at a time)
```

The controller deliberately does not store decoded image buffers. Queue entries contain paths and metadata, while the grid uses bounded `cacheWidth` decoding for thumbnails. Reordering is implemented as a presentation-ready list operation and does not alter processing contracts.

## State flow

```text
selection
  ├─ add/select → preview
  └─ empty picker result → selection

preview
  ├─ open settings → settings
  ├─ start → analyzing
  └─ remove all → selection

settings
  ├─ update global settings → settings
  ├─ start → analyzing
  └─ preview → preview

analyzing
  ├─ each item: waiting → analyzing → waiting
  ├─ complete → preview
  └─ cancel → preview (or selection when empty)

processing
  ├─ selected item: waiting → compressing → completed|failed
  ├─ deselected item: waiting → skipped
  ├─ pause → paused → resume → compressing
  ├─ cancel → remaining waiting/paused become cancelled
  └─ drain → completed

completed
  ├─ retry failed → failed items return to waiting
  ├─ save/share → explicit export integration feedback
  └─ start over → selection with all paths and outputs released
```

A single failed image never aborts the batch. Retry only requeues selected failed entries; successful entries are not processed again.

## UX and Material 3 decisions

- One scroll surface uses `CustomScrollView` and sliver virtualization for 100+ thumbnails.
- The step strip gives a stable workflow position without competing with the queue itself.
- Overview metrics expose selected count, total original size, estimated output, and savings before processing.
- Cards, `FilledButton`, `OutlinedButton`, `ChoiceChip`, `SegmentedButton`, `DropdownButtonFormField`, `SwitchListTile`, `Checkbox`, `Chip`, and progress indicators use Material 3 primitives and theme roles.
- Phone layouts use two columns; wider layouts use three or four columns.
- Controls wrap instead of relying on fixed widths.
- Pause, resume, cancel, retry, remove, select-all, deselect-all, and start-over actions have explicit labels/tooltips.
- Progress and status surfaces expose live-region semantics and a current image where available.
- Implicit motion honors `MediaQuery.disableAnimationsOf(context)`.
- ZIP creation, save-all, and share-selected are visible as explicit integration seams; no fake file operation is claimed.

## Performance notes

- Processing is sequential at this presentation seam: this is intentionally conservative until the frozen engine queue/concurrency contract is wired.
- Pause and cancel are cooperative between images only; the injected processor cannot interrupt an in-flight native operation. The production adapter must use the existing cancellable `OperationControl`/queue contract before claiming true interruption.
- `ListView`-style grid virtualization is provided by `SliverGrid`/`SliverChildBuilderDelegate`; the widget tree does not build all 100+ tiles at once.
- Metadata analysis uses small pure computations and yields between entries.
- Controller notifications are coarse at queue transitions. A future processor adapter can call `setItemProgress` for bounded per-image progress.
- No timer, polling loop, decoded-image list, or unbounded worker pool is created.
- The screen uses one `CustomScrollView`, avoiding nested scroll physics and duplicate layout work.
- Current speed is calculated from completed original bytes and elapsed processing time; remaining time is an estimate, not a promise.

## Memory optimizations

- Queue state retains strings, dimensions, byte counts, status, and output metadata only.
- Duplicate selections are rejected by source path before entering the queue.
- Thumbnail decode width is derived from tile width and device pixel ratio, bounded to 160–1200 pixels.
- `Image.file` is not used for processing; it is presentation-only.
- No compressed output bytes are held in Dart memory.
- `startOver` clears queue entries, selection IDs, output paths, and timing state.
- Production integration must still validate native decoder reuse, temporary-file cleanup, and low-memory behavior on real devices.

## Accessibility and responsiveness

- Status, current image, and overall progress are exposed through semantic labels/values.
- Native Material controls preserve keyboard/focus behavior and minimum touch targets.
- Image semantics include filename and dimensions while the underlying image semantics are excluded to avoid duplicate announcements.
- Dynamic text is supported by wrapping metric/action groups and vertical scrolling.
- Phone, tablet, landscape, and foldable-friendly widths are handled through constraint-based padding and grid columns.
- TalkBack, large-font, contrast, and keyboard validation remain device gates.

## Known limitations and future improvements

1. Wire the injected picker to the approved Photo Picker/multi-select platform seam after the freeze is lifted.
2. Wire the processor to the frozen EngineManager/application use case path.
3. Replace sequential processing with the approved bounded-concurrency queue contract after profiling memory and thermal behavior.
4. Add actual progress callbacks, codec-specific recommendations, and target-size search.
5. Add MediaStore save-all and share-selected integrations.
6. Add ZIP preparation/creation in a separately reviewed export phase; ZIP is not implemented here.
7. Add queue persistence/background interruption recovery only after lifecycle and product requirements are approved.
8. Add device tests for 100+ images, large images, low-memory devices, OEM codecs, rotation, process death, TalkBack, and large text.

## Phase completion checklist

### Experience

- [x] Multiple-selection presentation seam
- [x] Select all / deselect all
- [x] Add more images
- [x] Remove individual images
- [x] Count, original size, estimated output, estimated savings
- [x] Batch analysis progress surface
- [x] Metadata thumbnail grid with filename, dimensions, sizes, and status
- [x] Global settings surface
- [x] Per-image quality override API seam
- [x] Waiting/analyzing/compressing/paused/completed/failed/cancelled/skipped statuses
- [x] Pause, resume, cancel, retry failed only (cooperative presentation seam)
- [x] Continue processing after an individual failure
- [x] Completion summary
- [x] Save/share/ZIP export placeholders with truthful messaging

### Quality

- [x] Presentation-only frozen-boundary compliance
- [x] Sliver-based grid virtualization
- [x] Metadata-only queue state
- [x] Bounded thumbnail decode dimensions
- [x] Responsive phone/wide layouts
- [x] Material 3 controls and theme roles
- [x] Reduced-motion handling
- [x] Progress and status semantics
- [x] Focused controller and widget tests added
- [ ] Flutter generation/analyzer/format/test validation in a Flutter-enabled environment
- [ ] Android picker, codec, export, lifecycle, low-memory, and signed-release validation
- [ ] Wire the real multi-picker, cancellable engine queue, and multi-output export before production approval
- [ ] TalkBack, large text, contrast, and device performance validation
- [ ] Owner approval before Phase 9

## Approval status

**Phase 8 is presentation-complete but not production-approved.** Approval remains gated on Flutter-enabled validation, integration with the frozen application/engine seams after the architecture freeze is lifted, Android/device testing, accessibility testing, and owner approval. Phase 9 must not begin until those gates are explicitly accepted.
