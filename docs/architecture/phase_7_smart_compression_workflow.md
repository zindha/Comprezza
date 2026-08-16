# Phase 7 — Smart Compression Workflow

## Scope and approval gate

Phase 7 adds the presentation workflow at the existing `/compression` destination. The workflow is composed around the already-wired transitional `CompressorController` seam.

The project owner selected the **strict freeze** boundary. The following remain unchanged:

- Domain entities and contracts
- Repositories and use cases
- Provider registration and state wiring
- Engine/platform implementations
- Design system and theme/branding architecture
- Navigation and route identities
- Dependency injection and `LegacyCompressorAdapter`

Because those layers are frozen, the running workflow supports the existing single-image gallery → inspect → quality compression → preview → save/share path. The UI also presents the complete future workflow surface—analysis, recommendations, target-size choices, output format, resize, metadata, estimation, progress, success, and recovery—but advanced controls are explicitly marked as preview-only until their existing frozen contracts are wired into the app.

Production approval requires Flutter-enabled generation, formatting, analyzer, focused tests, full tests, and Android/device validation.

## Workflow diagram

```text
Select from gallery
        ↓
Native metadata inspection
        ↓
Recommendation / analysis summary
        ↓
Compression options
  quality · target size · format · resize · metadata
        ↓
Local estimate updates immediately
        ↓
Before / after preview
        ↓
Existing quality compression path
        ↓
Progress / start-over recovery
        ↓
Success metrics
        ↓
Save or share
```

## Widget tree

```text
HomeScreen (compatibility entry point)
└── CompressionWorkflowScreen
    └── Scaffold
        ├── AppBar
        └── ListView
            ├── WorkflowHeader
            ├── ProgressSteps
            ├── SelectionCard
            │   ├── Choose from gallery → CompressorController.pickImage
            │   ├── Use camera → explicit platform extension message
            │   └── Batch compress → explicit future-phase message
            ├── AnalysisCard
            ├── PreviewSection
            │   ├── Original preview
            │   └── Compressed preview / processing placeholder
            ├── OptionsCard
            │   ├── Quality Slider → existing controller
            │   ├── Target-size ChoiceChips → local estimate only
            │   ├── Format SegmentedButton → local estimate only
            │   ├── Resize Dropdown → local estimate only
            │   └── Metadata Switch → local estimate only
            ├── EstimateCard
            ├── ProcessingCard / ErrorCard / SuccessCard
            └── Privacy footer
```

## State flow

```text
empty
 ├─ gallery selection
 │    └─ processing (inspect + first compression)
 │          ├─ ready → preview / export
 │          └─ error → retry or start over
 └─ recovered picker result

ready
 └─ quality change (debounced by existing controller)
       └─ processing → ready | error

ready
 ├─ save → export feedback
 ├─ share → platform share sheet
 ├─ compress again → processing
 └─ start over → empty
```

## Animation flow

- Workflow step indicators use short Material-style implicit transitions.
- Native compression remains asynchronous through the existing controller.
- Preview loading uses Material progress indicators rather than custom frame-heavy animation.
- The workflow does not add an animation controller, timer, image decode loop, or polling task.
- Existing application reduced-motion behavior remains authoritative.

## Performance notes

- Heavy image work remains behind the existing asynchronous gateway.
- Preview images retain bounded `cacheWidth`/`cacheHeight` behavior.
- The workflow has one scroll surface and bounded option lists.
- Estimate calculations are small pure arithmetic and run only during widget rebuilds.
- Temporary outputs continue to be cleaned by the existing controller gateway.
- No network, analytics, cloud upload, broad storage permission, or unbounded batch operation was added.

## Accessibility notes

- Material buttons, sliders, chips, segmented controls, dropdowns, switches, and progress indicators retain native semantics.
- The workflow step strip exposes the current stage as a container label.
- Processing state uses one authoritative live-region message and a clear `Start over` recovery action.
- Touch targets are provided by Material controls.
- Content uses theme text styles, wraps metadata, and scrolls vertically for large text.
- Image previews provide visible Original/Compressed labels and size/dimension metadata.
- Dark theme and reduced-motion behavior continue to be covered by the app's existing test conventions; device TalkBack validation remains required.

## Strict-freeze limitations

These controls are intentionally visible but not falsely connected to the legacy JPEG controller:

- Camera selection
- Multiple-image selection
- Target-size quality search
- PNG/WebP output encoding
- Resize encoding
- Metadata policy encoding
- Interactive comparison zoom/pan
- Queue position, speed, and time remaining

Selecting an unsupported advanced option updates the local estimate and displays an explicit extension-point message. The actual compression action remains the existing JPEG quality path.

## Future extension points

1. Wire `HomeProvider` and `CompressionProvider` in the composition root after the freeze is lifted.
2. Replace the compatibility `HomeScreen` delegation with provider-backed immutable view state.
3. Bind `AnalyzeImagesUseCase`, `CompressToTargetSizeUseCase`, `ConvertImageFormatUseCase`, and `ResizeImageUseCase` to the corresponding controls.
4. Add the existing file-management camera/multi-select contracts through reviewed DI composition.
5. Add interactive preview gestures only after profiling large-image memory behavior.

## Files created

- `lib/features/compressor/presentation/compression_workflow_screen.dart`
- `test/features/compressor/presentation/compression_workflow_screen_test.dart`
- `docs/architecture/phase_7_smart_compression_workflow.md`

## Files modified

- `lib/features/compressor/presentation/home_screen.dart` — compatibility entry point delegates rendering to the workflow.
- `lib/l10n/app_en.arb`
- `lib/l10n/app_hi.arb`
- `lib/l10n/app_localizations.dart`
- `lib/l10n/app_localizations_en.dart`
- `lib/l10n/app_localizations_hi.dart`

No frozen architecture file was intentionally changed.

## Self-review and quality gate

- Material 3 controls and semantic color roles are used.
- Responsive preview changes from side-by-side at wide constraints to stacked on phones.
- Advanced controls are clearly non-functional extension points rather than silently pretending to alter the engine request.
- Existing controller lifecycle and stale-operation protection are reused.
- The workflow avoids direct platform/plugin access.
- Flutter analyzer, generated-localization, focused tests, full tests, and Android/device validation must pass before production approval.

## Phase completion checklist

- [x] Workflow screen and selection state composed.
- [x] Existing gallery/inspect/compress/save/share path retained.
- [x] Analysis, options, estimates, preview, processing, success, and recovery surfaces added.
- [x] Responsive phone/wide preview layouts added.
- [x] Localization resources and generated API updated consistently.
- [x] Focused widget tests added.
- [x] Frozen architecture and DI boundaries preserved.
- [x] Selection/inspection errors remain visible with retry recovery.
- [x] Workflow motion honors reduced-motion settings.
- [ ] Flutter `gen-l10n` validation.
- [ ] `dart format --set-exit-if-changed lib test`.
- [ ] `flutter analyze`.
- [ ] Focused and full Flutter tests.
- [ ] Android Photo Picker, codec, export, accessibility, and low-memory device validation.
- [ ] Principal Flutter UX/performance review.
- [ ] Owner approval.
