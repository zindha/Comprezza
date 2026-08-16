# Phase 10 — Settings, Personalization, Accessibility & App Intelligence

## Scope and integration boundary

Phase 10 adds a production-wired Settings experience. The previously frozen boundary was narrowly lifted only for the minimum required integration: the active Settings route, app-scoped Settings dependency registration, and root theme/accessibility propagation. Repositories, use cases, compression engines, navigation structure, branding, and the design-system API remain unchanged.

## Architecture diagram

```text
SettingsScreen
      │ listener
      ▼
SettingsController (presentation orchestration)
      │ immutable snapshots + typed errors
      ▼
SettingsStore (domain port)
      ├── MemorySettingsStore (tests/previews)
      └── LocalSettingsStore (app-private JSON/filesystem boundary)

SettingsPreferences / SettingsExportBundle / SettingsJsonCodec
      └── domain-owned, immutable, validated, platform-neutral contracts
```

The data adapter depends on the domain settings port and model; the domain layer does not depend on presentation. The controller coalesces asynchronous preference saves, invalidates stale loads/imports when a newer operation starts, and sanitizes developer-only state in release builds.

## Runtime integration

`AppDependencies` owns one lazy `SettingsStore` and one app-scoped `SettingsController`. `AppRouter` receives that controller and renders `SettingsScreen` for `/settings`. `PhotoCompressorApp` listens to the controller, maps the persisted theme into `ThemeModeController`, and applies density, high contrast, compact/large UI, and reduced-animation preferences through the root theme and `MediaQuery` builder. The platform-provided nonlinear `TextScaler` is preserved and composed with the local font multiplier; the local Dynamic Text Scaling control never disables the operating-system accessibility baseline.

## Settings flow

```text
Open Settings
    ↓
Load preferences + storage usage
    ↓
Validate/sanitize snapshot
    ↓
Render localized Material 3 sections
    ↓
User mutation → immutable state → coalesced app-private save
    ├── recommendation snapshot recalculated locally
    ├── storage action requires confirmation
    ├── version tapped seven times in debug/profile → developer section
    └── export/import uses privacy-filtered, validated JSON
```

## Sections and controls

General, Compression, Storage, Appearance, Accessibility, Notifications (future-ready), Privacy, Advanced, About, and debug-only Developer Options are represented. Storage usage displays cache, temporary files, history, and exports separately. Developer controls are omitted entirely in release builds and release import/load/update paths disable developer flags.

## Localization architecture

Visible Settings copy is accessed through `AppLocalizations`. English and Hindi ARB files, abstract localization API, and locale implementations are kept in sync. Numeric values use parameterized localization methods rather than hardcoded visible strings. The structure is ready for additional locales without changing Settings widgets.

## Accessibility and Material 3 checklist

- Native Material 3 controls (`SwitchListTile`, `DropdownButton`, `Slider`, `ExpansionTile`, `AlertDialog`, `FilledButton`, `Card`) are used.
- Interactive rows retain native keyboard/focus and minimum touch-target behavior.
- The Settings hero has a localized semantic label.
- Switches rely on the native switch semantics rather than creating duplicate semantic nodes.
- Confirmation is required for destructive storage, factory-reset, and preference-reset actions.
- Content is scrollable, constrained on wide layouts, and uses flexible/wrapping structures for large text and tablets.
- Large text, TalkBack/VoiceOver, contrast, keyboard navigation, switch access, and foldable devices remain device-validation gates.

## Privacy and security notes

- Processing and recommendations are offline and use aggregate local signals only.
- Local settings are stored in app-private storage through `FileSystemService`.
- Export removes developer flags and recursively filters path, URI, secret, token, and log keys from metadata.
- Imported JSON is size-limited, type-checked, whitelist-validates presets/formats/target sizes, clamps numeric ranges, bounds future flags, recursively sanitizes export collections, and is persisted only after release/privacy sanitization.
- Privacy guarantees (offline processing, no cloud upload, no analytics/tracking/accounts) are enforced by the controller and are not user-configurable.
- Original user photos are not touched by settings storage actions.
- Clear Cache removes only cache and thumbnail artifacts; exports and compression working files retain separate deletion semantics.
- Release builds never show developer tools and do not retain developer flags after load, update, or import.

## Performance notes

- Settings state is immutable and the feature uses one controller listener.
- Saves are coalesced so rapid switch/slider updates do not drop the latest value.
- Storage usage scans are performed by the injected store and are loaded with the initial snapshot.
- The Settings UI performs no image decoding, network access, timers, or unbounded work.
- Slider persistence is currently coalesced but should be profiled and debounced if device testing shows excessive writes.

## Future extension points and known limitations

1. Replace clipboard-based configuration import with the approved document-picker contract when a reviewed picker dependency is added.
2. Connect Privacy Policy, Terms, rating, and website actions to approved public destinations after legal/store URLs are supplied.
3. Add reviewed dynamic-color, color-blind palette, and platform screen-reader adapters if product requirements require them.
4. Replace future-ready notification copy with a reviewed local notification contract.
5. Add Flutter-enabled formatter, generated localization, analyzer, focused widget tests, full tests, and Android/device accessibility/performance validation before release sign-off.

## Accessibility checklist

- [x] Native Material 3 switches, sliders, dropdowns, cards, dialogs, and expansion controls
- [x] Keyboard/focus traversal remains available through native controls
- [x] Localized semantics label for the Settings overview hero
- [x] Slider value announcements use localized semantic formatter values
- [x] Privacy guarantees expose explicit read-only semantics rather than ambiguous status controls
- [x] Large-text layouts move dropdown controls below their labels
- [x] Large touch-target preference propagates to the root Material theme
- [x] System reduced-motion is preserved and combines with the local motion preference
- [ ] TalkBack, VoiceOver, switch access, high-contrast, and foldable device validation

## Performance notes (measured scope)

- Settings builds use one controller listener and section contents are discarded while collapsed.
- Rapid writes are coalesced by the controller; storage scans remain bounded by app-owned directories.
- Recommendation generation is deterministic, offline, and operates on aggregate counters only.
- No decoded image buffers, network calls, timers, or unbounded collections are introduced by Settings.
- Flutter performance and memory profiling remain a device/CI gate because the local shell lacks Flutter.

## Security notes

- Privacy guarantees are enforced by sanitization and cannot be disabled through imported configuration.
- Release builds remove developer flags and omit Developer Options from the widget tree.
- Export excludes developer state and recursively filters paths, URIs, secrets, tokens, and logs.
- Clipboard import is size-limited and confirmation-gated; no clipboard content is persisted until confirmation.
- Website, policy, terms, rating, and changelog actions remain informational until approved HTTPS/product destinations exist.
- Reset Storage removes cache, thumbnails, and local history metadata; exports and compression working files are intentionally preserved.

## Future extension points

- Replace the transitional legacy compressor adapter after the frozen migration phase.
- Apply the persisted compression preset/format/metadata/resize preferences when the approved workflow contract is available.
- Add reviewed dynamic-color, adaptive-icon, notification, document-picker, and screen-reader platform adapters.
- Add Tamil, Spanish, German, French, Arabic, Japanese, Korean, and Chinese ARB locales without changing Settings widgets.
- Add structured preset/history metadata providers to the existing privacy-safe export bundle.

## Known limitations

- The active legacy workflow currently consumes its own quality value; the remaining compression Settings are persisted and surfaced but are not yet execution inputs under the frozen architecture.
- Cache/history size limits and automatic cleanup preferences are persisted contracts; enforcement remains owned by the existing cleanup integration and is not yet connected to every Settings mutation.
- Dynamic colors and adaptive icons are exposed as stable preference contracts but still use the existing theme/launcher fallback.
- Notifications are intentionally future-ready and do not request notification permission.
- Legal and store destinations are informational until owner-supplied HTTPS URLs are approved.
- Full Flutter analyzer/test/build/device validation cannot be claimed in the current environment.

## Phase completion checklist

- [x] Domain-owned immutable Settings contracts
- [x] App-private persistence port and adapter
- [x] Release-safe developer option gating
- [x] Typed import/export validation and privacy filtering
- [x] General, compression, storage, appearance, accessibility, privacy, advanced, about, notifications, and debug sections
- [x] Offline deterministic recommendations
- [x] English/Hindi localization API and ARB coverage
- [x] Responsive Material 3 presentation and destructive confirmations
- [x] Focused controller/widget tests added
- [x] Static ARB and localization consistency checks pass in the current shell
- [x] Cache cleanup scope is covered by a LocalSettingsStore regression test
- [ ] Flutter formatter/analyzer/test execution in this environment
- [x] Active route, DI, root theme/accessibility propagation, lazy Settings sections, system share export, clipboard import confirmation, native license page, and reset confirmations
- [ ] Android build, Play, and device accessibility validation
- [x] Owner approval before Phase 11 (approved by project owner on 2026-08-06)

## Approval status

**Phase 10 implementation is closed and approved by the project owner for progression; production approval remains separate.** The active route, dependency graph, root personalization propagation, lazy sections, share export, clipboard import confirmation, native license page, reset confirmations, and storage-action boundaries are wired. Flutter/Dart executables remain unavailable in this environment, and legal/store destinations, a document picker, dynamic colors, legacy workflow integration, and device validation remain release gates.
