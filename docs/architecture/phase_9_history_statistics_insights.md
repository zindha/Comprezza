# Phase 9 — History, Statistics & Insights Dashboard

## Scope and freeze boundary

Phase 9 adds a presentation-only history, statistics, and insights experience. The architecture freeze remains active: state management, repositories, use cases, engine, platform, navigation, design system, and branding contracts are not changed.

The screen accepts a presentation-owned `HistoryInsightsController`. That controller consumes immutable `HistoryEntry` records and exposes callbacks for deletion, sharing, repeat compression, and report export. These callbacks are integration seams; they do not pretend that persistence, file export, or navigation wiring is complete during the freeze.

## Files created

- `lib/features/compressor/presentation/history_insights_controller.dart`
- `lib/features/compressor/presentation/history_insights_screen.dart`
- `test/features/compressor/presentation/history_insights_controller_test.dart`
- `test/features/compressor/presentation/history_insights_screen_test.dart`
- `docs/architecture/phase_9_history_statistics_insights.md`

## Files modified

- `lib/l10n/app_en.arb`
- `lib/l10n/app_hi.arb`
- `lib/l10n/app_localizations.dart`
- `lib/l10n/app_localizations_en.dart`
- `lib/l10n/app_localizations_hi.dart`

No frozen architecture file was modified.

## Workflow diagram

```text
History entry source
        ↓
Presentation controller
  immutable records + local filters/favorites/delete undo
        ├───────────────┐
        ↓               ↓
History tab       Insights tab
 search/filter    aggregate cards
 sort/pin         trend charts
 detail view      facts + milestones
        ↓               ↓
 injected actions: delete · share · compress again · export seam
```

## History architecture diagram

```text
HistoryInsightsScreen
        │ ListenableBuilder
        ▼
HistoryInsightsController (presentation-owned)
        ├── immutable source entries
        ├── visible filtered/sorted snapshot
        ├── local favorite IDs
        ├── hidden/deleted IDs + undo stack
        ├── filter and sort state
        ├── aggregate HistoryInsights
        ├── presentation-only HistoryAchievement descriptors
        └── nullable action callbacks
              ├── onDelete
              ├── onShare
              ├── onCompressAgain
              └── onExport(CSV | JSON | PDF)
```

The controller keeps metadata and immutable records only. It does not decode images, own files, or persist favorites/deletions. The frozen `HistoryEntry` contract does not provide thumbnail bytes or a source preview path suitable for this screen, so thumbnails and detail image panels truthfully remain metadata placeholders rather than triggering hidden I/O.

## Statistics flow diagram

```text
HistoryEntry.statistics
        ↓
Input/output/saved bytes · ratio · duration · processed files
        ↓
Date buckets + preset/format frequency maps
        ↓
HistoryInsights
        ├── today/week/month/lifetime savings
        ├── image count and batch sessions
        ├── average ratio and processing time
        ├── largest input and saving
        ├── most-used preset/format
        ├── seven-day savings series
        └── recent ratio series
        ↓
Summary tiles · semantic trend charts · facts · milestone progress
```

Statistics intentionally use the complete source history, not the currently filtered list, so the dashboard remains a stable lifetime view while users explore search results.

## Widget tree

```text
Scaffold
 ├── AppBar
 │    ├── title
 │    ├── export PopupMenuButton (CSV / JSON / PDF seam)
 │    └── TabBar
 └── ListenableBuilder
      └── TabBarView
           ├── History tab
           │    └── CustomScrollView
           │         ├── search and filter header
           │         ├── pinned section
           │         ├── session count
           │         └── SliverList.builder history cards
           └── Insights tab
                └── CustomScrollView
                     ├── impact header
                     ├── responsive summary grid
                     ├── saved-over-time chart
                     ├── ratio trend chart
                     ├── facts card
                     └── milestone card
```

History detail is opened from a card with a normal Material route and uses a metadata-first `ListView` with before/after placeholders and action seams.

## UX and Material 3 decisions

- Search, date/format/ratio/preset filters, and six sort modes are visible without a separate modal flow.
- Pinned records appear in a dedicated section while remaining in the regular result list, preserving discoverability.
- Deletion is confirmed and followed by an undo snackbar. The controller hides records deterministically until undo or future provider refresh.
- Empty and no-result states provide distinct guidance and a primary compression CTA where one is supplied.
- Material 3 `Card`, `Chip`, `ChoiceChip`, `DropdownButton`, `TabBar`, `FilledButton`, `SnackBar`, and theme `ColorScheme` roles are used.
- Detail, action, and filter controls use native Material focus and touch-target behavior.
- The layout uses adaptive padding, wrapping action groups, responsive grid columns, and vertical scrolling for phones, tablets, landscape, and foldable widths.
- Export labels clearly distinguish CSV/JSON seams from PDF generation reserved for a later phase.
- Charts are lightweight `CustomPainter` trends with text-based semantic summaries; no chart library or frozen design-system dependency was introduced.

## Performance and memory notes

- History uses `CustomScrollView` and `SliverList.builder`; records are built lazily and are not copied into widget-owned buffers.
- Search text, local-day buckets, output formats, and safe ratios are precomputed once per unique history ID instead of reallocated for every keystroke.
- Insights calculate aggregate metrics in one pass over immutable metadata and retain only bounded seven-day and recent-session series.
- The controller exposes unmodifiable snapshots, preventing accidental widget mutation and preserving predictable rebuild behavior.
- No image decoding, file reads, network calls, timers, or unbounded asynchronous work occur in the presentation layer.
- History and insights use separate listenable rebuild scopes, so search/pin/delete changes do not repaint chart cards and insight changes do not rebuild the history list.
- `ListenableBuilder` scopes updates to the Phase 9 workspace. Individual cards are immutable stateless widgets.
- Custom chart painting is O(n) over bounded series sizes, centers flat series for truthful empty/constant states, and repaints only when the values or color identity changes.
- Real pagination/provider synchronization, thumbnail cache policy, and thousands-of-record profiling remain integration gates because the frozen provider is not wired here.

## Accessibility and responsiveness

- Cards, thumbnails, charts, progress indicators, actions, and export controls have semantic labels or tooltips.
- Charts include a text summary of all plotted values for screen readers instead of relying on pixels alone, and render a localized visible empty state when no data exists.
- Milestones expose title, description, and percentage progress through semantics.
- The interface uses Material controls, wrapped layouts, flexible text, and scrollable content to support large text and keyboard focus traversal.
- TalkBack, VoiceOver, contrast, keyboard, switch access, and foldable hinge testing remain device validation gates.

## Export and data-management seams

- `HistoryExportFormat` reserves CSV, JSON, and PDF.
- `onExport` is injectable and can later connect to the frozen export/file-management contracts.
- Individual delete and delete-all-visible controller operations are available; the screen currently exposes the safe individual-delete path and undo feedback.
- Favorites are presentation-local until the approved persistence contract is connected.
- Generated image files are explicitly not deleted by the history-record delete message.

## Known limitations and future improvements

1. Wire the controller to `HistoryProvider` and `StatisticsProvider` after the architecture freeze is lifted.
2. Connect persisted favorites, deletion, undo, pagination, and recent-activity records.
3. Supply approved source/output preview descriptors and bounded image loading for real detail thumbnails.
4. Connect share, repeat-compression, CSV/JSON export, and PDF generation through reviewed platform/file-management seams.
5. Add server-free aggregation tests for timezone boundaries, malformed records, zero-byte outputs, and large histories.
6. Profile 1,000+ records on low-memory devices and add provider-side pagination or indexed filtering if required.
7. Validate accessibility with TalkBack/VoiceOver, large text, contrast, keyboard, and switch access.
8. Add motion polish only after reduced-motion and frame-timing validation; no unrelated features are introduced here.

## Phase completion checklist

### Experience

- [x] History cards with filename, format, sizes, saving, ratio, date, preset, and quick actions
- [x] Search, date/format/ratio/preset filters, and sort modes
- [x] Favorites/pinned section
- [x] Detail view with metadata and action seams
- [x] Statistics summary cards and aggregate metrics
- [x] Storage-saved and compression-ratio trend charts
- [x] Recent-session ratio and seven-day saving series
- [x] Achievement-ready descriptors without persistent gamification
- [x] CSV/JSON/PDF export seams with PDF explicitly reserved
- [x] Delete confirmation and undo presentation path
- [x] Premium empty and no-result states
- [x] Responsive phone/tablet/wide layouts
- [x] Semantics, labels, and chart summaries

### Quality

- [x] Presentation-only frozen-boundary compliance
- [x] Lazy sliver history rendering
- [x] Immutable metadata-first controller state
- [x] Bounded chart series
- [x] Focused controller and widget tests added
- [x] Localization API and English/Hindi values updated
- [x] Local-time/future-date-safe and invalid-ratio-safe aggregate calculations
- [x] One-pass insight aggregation and precomputed filter metadata
- [x] Separate history/insights rebuild scopes
- [x] Global favorites and asynchronous restore seam
- [x] Immutable chart series and explicit async action handling
- [ ] Flutter generation/analyzer/format/test validation in a Flutter-enabled environment
- [ ] Runtime provider/repository synchronization and persistence validation
- [ ] Real thumbnail/detail image loading and export/share validation
- [ ] Large-history, timezone, low-memory, accessibility, and foldable device validation
- [ ] Owner approval before Phase 10

## Approval status

**Phase 9 is presentation-complete but not production-approved.** The UI and controller seams are ready for review after the final correctness hardening, but production approval remains gated on Flutter-enabled validation, runtime provider/persistence wiring, real preview and export integrations, device accessibility/performance testing, and owner approval. Phase 10 should wait for those gates.
