# Phase 19 — Design-System Cleanup & Pre-Runtime Hardening Report

Date: 2026-08-15
Mode: IMPLEMENTATION (no visual redesign)
Status: **STATICALLY READY — RUNTIME VALIDATION BLOCKED BY ENVIRONMENT**

---

## 1. Environment / tooling status

| Tool | Status |
|---|---|
| flutter / dart / java / gradle | MISSING |
| Android SDK / adb / emulator / device | MISSING |

All runtime validation (analyze, test, format, build, device) is **BLOCKED BY ENVIRONMENT**. No runtime result is claimed in this report.

---

## 2. Files inspected

- `lib/core/theme/*` (app_brand_colors, app_dimensions, app_elevations, app_radius, app_typography)
- `lib/app/theme/*` (app_theme_builder, app_theme_catalog, app_theme_mode, comprezza_theme, dynamic_color_source, theme_mode_controller)
- `lib/features/compressor/presentation/design_system/**` (all 25 component files + tokens + barrel)
- `lib/app.dart`, `lib/app/navigation/*`
- All screens (`home_dashboard`, `compression_workflow_screen`, `batch_compression_screen`, `history_screen`, `history_insights_screen`, `settings_screen`, `benchmark_screen`, `about_screen`)
- `test/**` (design_system_test, app_theme_builder_test, app_dimensions_test, navigation_shell_test, goldens)
- `android/app/src/main/res/**` (launcher, splash, values / values-night / values-v31)

---

## 3. Files modified

| File | Change |
|---|---|
| `lib/core/theme/app_typography.dart` | **Consolidated canonical typography**: merged the design-system context role helpers (`display/headline/title/subtitle/body/label/caption/metric/metricSmall/eyebrow`) into the single `AppTypography` class. |
| `lib/…/design_system/tokens/app_design_tokens.dart` | Removed the duplicate `AppTypography` class (now sourced from `core/theme`). |
| `lib/…/design_system/tokens/tokens.dart` | Re-export `core/theme/app_typography.dart` so components resolve one type source. |
| `lib/…/design_system/design_system.dart` | Removed 5 dead export lines (bottom_sheets, gradient_card, dialogs, images, snackbars). |
| `lib/app/theme/app_theme_catalog.dart` | Stripped dead `AppThemeDefinition` + `materialYou` + `build()`; kept only `toFlutterThemeMode`. |
| `lib/app/theme/app_theme_mode.dart` | Removed unused `AppThemeVariant` enum. |
| `lib/app.dart` | Removed `dynamicColors` from `_visualSettingsChanged`. |
| `lib/…/settings/settings_screen.dart` | Removed the no-op "Material You dynamic colors" toggle. |
| `lib/…/components/cards/app_cards.dart` | Removed 6 dead cards (`AppImageCard`, `AppStatisticsCard`, `AppFeatureCard`, `AppEmptyCard`, `AppSuccessCard`, `AppHistoryCard`). |
| `lib/…/components/indicators/app_indicators.dart` | Removed 6 dead indicators (`AppProgressCircular`, `AppBatchProgress`, `AppCardProgress`, `AppAnimatedProgress`, `AppStorageProgress`, `AppSavingIndicator`). |
| `lib/…/components/status/app_status.dart` | Removed 5 dead views (`AppLoadingView`, `AppEmptyView`, `AppOfflineView`, `AppSuccessView`, `AppPermissionView`). |
| `lib/…/components/animations/app_animations.dart` | Removed 4 dead animations (`AppFadeScale`, `AppSlide`, `AppHeroImage`, `AppSkeleton`). |
| `lib/…/components/layouts/app_layouts.dart` | Removed 2 dead helpers (`AppResponsiveContent`, `AppAdaptiveSpacing`). |
| `lib/…/components/icons/app_icons.dart` | Removed dead `AppSemanticIcon`. |
| `lib/…/components/inputs/app_inputs.dart` | Removed 10 dead controls (`AppSlider`, `AppQualitySlider`, `AppSegmented`, `AppDropdown`, `AppSwitch`, `AppCheckbox`, `AppRadio`, `AppStepper`, `AppNumberInput`, `AppTargetSizeInput`). |

## 4. Files deleted

| File | Why |
|---|---|
| `design_system/components/cards/app_gradient_card.dart` | `AppGradientCard` unreferenced (0 refs lib+test). |
| `design_system/components/dialogs/app_dialogs.dart` | 5 dialog classes, all 0 refs. |
| `design_system/components/bottom_sheets/app_bottom_sheets.dart` | 9 sheet classes, all 0 refs. |
| `design_system/components/snackbars/app_snackbars.dart` | `AppSnackbars` 0 refs. |
| `design_system/components/images/app_images.dart` | 7 image classes, all 0 refs (screens use `ImagePreviewCard`). |
| `app/theme/dynamic_color_source.dart` | `DynamicColorSource` + `NoOpDynamicColorSource` never imported/wired. |

Also removed 3 now-empty directories (`dialogs/`, `bottom_sheets/`, `snackbars/`).

**Net:** 155 → 149 Dart files; 25 → 19 design-system component files; ~45 dead classes removed.

---

## 5. Design-token consolidation

- **Colors — single source:** `AppBrandColors` (`core/theme`) is canonical; `AppColors` (`design_system/tokens`) **aliases** it. No second palette. ✔
- **Typography — single source (fixed this phase):** two classes were both named `AppTypography`. The component-layer copy was merged into `core/theme/app_typography.dart` and the design-system copy removed; `tokens.dart` re-exports the canonical class. Verified: exactly **one** `AppTypography` definition remains, all 12+ call sites resolve to it, and there is no import collision (no file imports both `core/theme/app_typography.dart` and the design-system barrel).
- **Motion — single source:** `AppAnimations` is canonical; `AppDurations` is a thin alias of it.
- **Remaining parallel (different-name) layer tokens — DOCUMENTED, not merged:** `AppDimensions`/`AppSpacing` (spacing + gutters), `AppRadius`/`AppRadii` (radii), `AppElevations`/`AppElevation` (elevation). These are two layers (foundation `core/theme` vs component `design_system/tokens`) with different member names and no name collision. Merging them would be a broad rename across ~40 call sites; deferred to a compiler-available pass to avoid no-compiler breakage risk.

## 6. Dynamic-color decision

**Decision: remove the no-op setting from Settings; retain the persisted field for backward compatibility.**

- `NoOpDynamicColorSource` was never wired, so the "Material You dynamic colors" toggle changed nothing visually — misleading.
- Removed the Settings toggle and the `_visualSettingsChanged` check in `app.dart`.
- Retained the `dynamicColors` field in `settings_models.dart` + `settings_controller` default so previously-persisted settings deserialize without error. It is now fully inert (never read by UI).
- `settingsDynamicColors` remains in the generated `l10n` files (unused, harmless — regenerating l10n requires Flutter tooling).
- Comprezza branding (navy/electric/cyan) remains authoritative; Android wallpaper colors cannot override it.

## 7. Dead-component cleanup

Classified every exported design-system symbol by actual reference (lib + test, excluding the defining file):

- **ACTIVE (kept):** `AppSurface`, `AppIcons`/`AppIcon`, `AppButton`, `AppSectionHeader`, `AppSettingsRow`/`AppIconBox`, `AppPresetSelector`/`AppPresetOption`, `AppMetric`, `AppValueSelector`/`AppValueOption`, `AppCard`, `AppInformationCard`, `AppErrorCard`, `AppRingProgress`, `AppPressable`/`AppPressableDurations`, `AppBrandMark`, `AppStoryEmptyState`, `AppCompareSlider`.
- **TEST-ONLY (kept):** `AppResponsiveLayout`, `AppFade`, `AppQueueProgress`/`AppProgressLinear`, `AppSearchField`/`AppTextField`, `AppErrorView`, `AppBreakpoints`/`AppBreakpoint`, `AppColors.stateForeground`, `AppInformationCard`.
- **DEAD (removed):** the ~45 classes listed in §3/§4.

No active or test-referenced component was removed.

## 8. Forbidden-color / visual-token audit

Repository-wide grep for purple/lavender/periwinkle/indigo hex, `Colors.purple/deepPurple/indigo`, `RadialGradient`, `SweepGradient`, `InkSparkle`, `auto_awesome`, `auto_fix_high`:

- **Result: 0 matches.** No forbidden residue.

Remaining `ColorScheme.fromSeed` (2 sites, both acceptable):
1. `app_design_tokens.dart` `_stateScheme` — derives semantic state containers from success/warning/error/info seeds (never brand).
2. `app_theme_builder.dart` `_colorBlindFriendlyColors` — accessibility variant with a blue seed, gated behind the user's color-blind setting.

Neither is the visual authority; the active theme is hand-tuned `AppThemeBuilder.light/dark`.

## 9. Accessibility preservation

- Kept 48dp touch targets, live regions, TalkBack semantics, slider semantics, reduced-motion gates, large-text scaling, tabular figures.
- No accessibility feature was removed. (Note: `AppSemanticIcon` removed was unused; `AppErrorView`'s retry semantics retained.)

## 10. Android presentation review

- Launcher icon / adaptive icon: **NO CHANGE REQUIRED** — background `#121934` (no white border), foreground full-bleed navy/cyan.
- Splash: light `#F6F7FB`, dark `#0B1226`, Android 12+ splash styles present.
- System-bar icon brightness: already handled by night/night-v31 styles.
- No artwork or mask changes made.

## 11. Static validation results

- Dangling-reference sweep over all removed symbols: **0 remaining references** (lib + test). PASS.
- Barrel export integrity: all `design_system.dart` and `tokens.dart` exports resolve to existing files. PASS.
- Single `AppTypography` definition verified. PASS.
- No import collisions (`core/theme/app_typography.dart` imported only by `app_theme_builder.dart`, which does not import the design-system barrel). PASS.
- Forbidden-color/visual-token audit: clean. PASS.

## 12. Runtime validation results

**BLOCKED BY ENVIRONMENT.** `flutter analyze`, `flutter test`, `dart format`, build, and device/screenshot review were NOT executed (tooling absent). Not reported as passed.

## 13. Remaining blockers

1. No Flutter/Dart/Android tooling → compile, tests, format, and device validation all pending a tooled environment.
2. Parallel layer tokens (`AppDimensions`/`AppSpacing`, `AppRadius`/`AppRadii`, `AppElevations`/`AppElevation`) remain as a deferred consolidation (different names, no collision; high-risk rename without a compiler).
3. Custom fonts (Space Grotesk/Manrope) still not bundled — tuned Roboto fallback retained (intentional).

## 14. Recommended next phase

Run, in a tooled environment: `flutter pub get`, `dart format --set-exit-if-changed .`, `flutter analyze`, `flutter test`, then a debug build + device pass (launcher masks, splash, dark/light, TalkBack, compare-slider drag, keyboard/resize). After that, optionally consolidate the three parallel layer token pairs with compiler safety.

## Success criteria checklist

- [x] One authoritative design-token system (colors + typography single-sourced; component tokens in one location).
- [x] No duplicate active brand palette.
- [x] No purple/lavender/periwinkle brand residue.
- [x] Dynamic color cannot silently override Comprezza branding.
- [x] Dead components removed only when conclusively unreachable.
- [x] Active components not accidentally deleted (test file intact).
- [x] Accessibility behavior intact.
- [x] Responsive behavior intact.
- [x] Android splash/launcher behavior intact.
- [x] No business/compression logic changed.
- [x] No new dependencies introduced.
- [x] No broad UI redesign.
- [x] Static validation performed where tooling allows.
- [x] Runtime validation honestly reported as BLOCKED.
- [x] Phase 19 report created.
