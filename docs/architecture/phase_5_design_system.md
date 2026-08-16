# Phase 5 — Design System & Reusable Material 3 Component Library

## Scope

Phase 5 adds reusable UI infrastructure only. It does not add or modify application screens, routing, state management, repositories, use cases, engine/platform code, dependency injection, theme architecture, or branding.

## Files Created

- `lib/features/compressor/presentation/design_system/design_system.dart`
- `tokens/app_design_tokens.dart` and `tokens/tokens.dart`
- Components for animations, bottom sheets, buttons, cards, dialogs, icons, images, indicators, inputs, layouts, snackbars, and status views.

## Component Library Diagram

```text
DesignSystem barrel
├── Tokens
│   ├── Colors / spacing / radii / typography
│   ├── elevation / motion / durations / icon sizes
│   ├── breakpoints / shadows
│   └── Material ColorScheme and TextTheme integration
└── Components
    ├── Buttons
    ├── Cards
    ├── Inputs
    ├── Images
    ├── Indicators
    ├── Status views
    ├── Dialogs / bottom sheets / snackbars
    ├── Animations
    ├── Icons
    └── Responsive layouts
```

## Design Token Diagram

```text
Global token values
        ↓
Material 3 semantic theme (ColorScheme / TextTheme)
        ↓
Reusable component defaults
        ↓
Feature screens compose components (future phase)
```

Components use the active Material theme for semantic colors and typography, while shared dimensions, motion, shapes, and icon sizes come from centralized tokens.

## Architecture Decisions

- Components are stateless, constructor-injected, and composable.
- The barrel export is the single import surface for feature UI composition.
- Material 3 primitives remain the implementation foundation.
- The existing frozen theme architecture is consumed, not changed.
- Responsive behavior is parent-constraint based through `LayoutBuilder`.
- Motion is centralized and respects accessible-navigation reduced-motion settings.
- Icon roles are semantic and resolved through allocation-free static mappings.

## Accessibility Notes

- Interactive controls retain Material's native semantics and minimum touch targets.
- Icon-only actions require a visible tooltip and semantic label.
- Images, loading states, errors, and progress expose descriptive labels.
- Text uses the active `TextTheme` and does not impose fixed text heights.
- Components use adaptive Material controls where available.
- Reduced motion is honored by animation wrappers.
- Radio grouping uses the current `RadioGroup` API while preserving the reusable `AppRadio` interface.

## Performance Notes

- Constructors are const where possible.
- Icon maps are static and are not rebuilt per build or lookup.
- Components avoid stateful business logic and unnecessary subscriptions.
- Responsive grids are intentionally shrink-wrapped for embedding in parent scroll views; large collections should use a future sliver variant.
- Image components use framework image caching and lightweight placeholders.

## Future Extension Points

- Theme extensions for additional semantic component roles.
- Localized component labels supplied by feature composition.
- Sliver-based responsive collections for large datasets.
- Dedicated preset, format, share, and settings sheet compositions built from the existing sheet primitives.
- Golden and widget coverage for every public component state.

## Known Limitations

- No screen has been migrated to the library in this phase by design.
- Platform permission, camera, gallery, sharing, and persistence behavior remain outside the design system.
- Visual golden testing requires a configured Flutter rendering environment and will be expanded before screen integration.

## Phase Completion Checklist

- [x] Centralized Material 3 design tokens.
- [x] Reusable button, card, input, image, progress, status, dialog, sheet, snackbar, icon, animation, and layout primitives.
- [x] Responsive phone/tablet/large-screen layout helpers.
- [x] Accessibility labels, touch-target defaults, and reduced-motion support.
- [x] No application screens or frozen architecture changes.
- [x] Static scope and syntax checks pass.
- [x] Full Flutter test suite passes.
- [x] Design-system and focused-test analyzer is clean; one pre-existing Phase 4 provider lint remains outside this phase's scope.

Phase 6 remains blocked pending approval.
