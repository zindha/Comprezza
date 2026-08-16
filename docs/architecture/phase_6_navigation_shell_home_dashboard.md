# Phase 6 — Navigation Shell, Home Dashboard & Core User Experience

## Scope

Phase 6 creates only the application navigation shell and the Home Dashboard. It does not implement compression, history, statistics, settings, benchmark, or about workflows. Those locations are prepared as explicit, non-functional placeholders so later phases have stable navigation destinations.

The frozen state-management, repository, use-case, engine/platform, dependency-injection, design-system, and branding architecture is consumed without modification.

## Files created

- `lib/app/navigation/main_navigation_shell.dart`
- `lib/features/compressor/presentation/home_dashboard.dart`
- `docs/architecture/phase_6_navigation_shell_home_dashboard.md`
- `test/features/compressor/presentation/home_dashboard_test.dart`

## Files modified

- `lib/app/routing/app_routes.dart`
- `lib/app/routing/app_router.dart`
- `lib/app.dart`
- `ROADMAP.md`
- `PROJECT_CHANGELOG.md`

## Navigation diagram

```text
MaterialApp.router
        ↓
      GoRouter
        ↓
    ShellRoute
        ├── Home `/`
        │     └── HomeDashboard
        ├── Compression `/compression` (existing legacy workflow entry)
        ├── History `/history` (placeholder)
        ├── Statistics `/statistics` (placeholder)
        ├── Settings `/settings` (placeholder)
        ├── Benchmark `/benchmark` (placeholder)
        └── About `/about` (placeholder)
```

The shell uses a Material 3 `NavigationBar` on compact widths and a `NavigationRail` on tablet, landscape, foldable, and large layouts. Benchmark and About remain available from the overflow menu to avoid overcrowding primary navigation.

## Home widget tree

```text
MainNavigationShell (`lib/app/navigation/main_navigation_shell.dart`)
└── Scaffold
    ├── NavigationBar / NavigationRail
    └── HomeDashboard
        ├── AppBar + Comprezza wordmark
        ├── Hero section
        │   ├── Brand mark
        │   ├── Welcome message + tagline
        │   ├── Primary choose-photos CTA
        │   └── Animated visual placeholder
        ├── Quick actions responsive grid
        │   ├── Compress, batch, convert, resize
        │   ├── History, benchmark, settings
        │   ├── Reusable action cards
        │   └── Future search slot (not implemented)
        ├── Compression preset preview cards
        ├── Storage savings overview
        ├── Recent activity / empty state
        ├── Statistics preview cards
        ├── Rotating smart tip card
        └── Extended Select Images FAB
```

## Responsive layout decisions

- Phone widths use a two-column quick-action/statistics grid and a bottom `NavigationBar`.
- Tablet widths use three columns and a `NavigationRail`.
- Large widths use six quick-action columns, four statistics columns, a constrained content width, and a `NavigationRail`.
- Hero and storage sections switch between stacked and side-by-side arrangements based on their local constraints rather than device type.
- All primary content is inside a bounded, scrollable surface to support landscape, foldables, and large displays.

## Accessibility notes

- Material navigation controls retain keyboard focus behavior and semantic destinations.
- Icon-only actions have tooltips and accessible labels.
- Hero illustration, storage progress, cards, and empty states expose descriptive semantics.
- Interactive controls use Material minimum touch targets and support dynamic text scaling.
- Empty states provide a primary action and guidance rather than a blank surface.
- Motion respects `MediaQuery.disableAnimations`.
- No screen depends on color alone to communicate state.

## Animation decisions

- Hero content uses one subtle fade-in on entry.
- Statistics use a short count-up animation, ready for live values in a later data-backed phase.
- Tips use a restrained cross-fade when manually rotated.
- Material navigation and FAB retain platform-standard motion.
- Reduced-motion settings switch custom transitions to zero duration.

## Performance notes

- Dashboard widgets are stateless except for the small, bounded tip index.
- All constructors are const where possible.
- No image decoding, file scans, history reads, or compression work is introduced.
- The dashboard uses lightweight illustration placeholders and no network resources.
- The page is a single lazy scroll surface; future history collections should use a sliver-backed implementation before large datasets are displayed.
- The existing compression workflow remains behind its existing adapter and is only entered through the Compression destination.

## Future extension points

- Replace placeholder dashboard values with read-only application view-state once the frozen application flow is approved and wired.
- Connect recent-file cards to Phase 9 history data.
- Connect preset/action cards to approved compression, conversion, resize, and batch use cases.
- Add recent-file thumbnail/metadata/action rows when Phase 9 history data is available.
- Add a localized search affordance for recent files, history, and presets without changing the shell contract; the Phase 6 slot is intentionally not interactive.
- Replace the illustration placeholder with approved brand artwork while retaining the current semantic label.

## Phase completion checklist

- [x] Material 3 adaptive navigation shell.
- [x] Home route and requested future route locations.
- [x] Hero, branding, tagline, and privacy-first message.
- [x] Quick actions with reusable action-card composition, including settings/history/benchmark entries.
- [x] Compression preset preview section.
- [x] Storage savings overview.
- [x] Recent activity empty state with primary and secondary actions; populated thumbnail/size/action rows remain deferred until history exists.
- [x] Statistics preview with animated counters.
- [x] Rotating smart tips.
- [x] Adaptive FAB for Select Images.
- [x] Reduced-motion behavior and semantic labels.
- [x] Responsive phone/tablet/large layout decisions documented.
- [x] Compression, history, statistics, settings, benchmark, and about workflows remain unimplemented.
- [ ] Flutter-enabled analyzer, formatter, generated-localization, and test validation in this environment.
- [ ] Principal Flutter Architect review and owner approval.

## Review status

The review refactor corrected app-layer dependency direction, nested shell/chrome composition, localization coverage, semantic replacement labels, and dynamic-text typography risk. Final approval remains blocked until `flutter gen-l10n`, `dart format`, `flutter analyze`, focused widget tests, full tests, and large-text/dark-theme validation run in a Flutter-enabled environment.

Phase 7 must not begin until Phase 6 is reviewed and approved by the project owner.
