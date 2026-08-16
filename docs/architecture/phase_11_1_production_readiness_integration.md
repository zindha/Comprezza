# Phase 11.1 — Production Readiness Integration

## Scope

Phase 11.1 connects the existing Phase 11 sharing/export/premium contracts to the
running compression workflow without redesigning the frozen architecture.

## Integration completed

- Registered `ShareDispatcher`, `ExportSecurityPolicy`, `ShareExportCleanup`,
  `ShareExportService`, `PremiumManager`, `PremiumCapabilities`, and
  `FeatureGate` in `AppDependencies`.
- Replaced the production `ImageExportGateway` implementation with
  `ShareExportGatewayAdapter`, which routes save/share operations through the
  secure managed export coordinator.
- Removed the legacy `DeviceExportService` implementation and all production
  references to it.
- Preserved the existing controller, route, and compatibility adapter seams.
- Added a cooperative cancellation port for local staging and exposed retry and
  cancellation controls through the existing compressor controller.
- Added a Material 3 confirmation preview, destination/status summary,
  progress indicator, warning/error recovery, retry, and cancellation actions to
  the existing workflow screen.
- Kept successful share files available for recipient apps; the existing
  startup TTL cleanup recognizes the generated prefix and removes expired
  artifacts rather than deleting them immediately when the Sharesheet returns.
- Cleaned staged export files when MediaStore publication fails, and converted
  cancellation/dismissed/unavailable outcomes into typed recoverable failures
  rather than false success.

## Android review

The existing Android bridge remains scoped-storage based:

- MediaStore uses `IS_PENDING` while writing and finalizes only after a complete
  copy.
- Source paths are canonicalized and restricted to app-owned cache,
  compression, and export roots.
- MIME type is derived from the validated extension.
- No broad storage permission or `MANAGE_EXTERNAL_STORAGE` permission is used.
- `share_plus` remains responsible for Sharesheet/FileProvider content URI
  handling.
- The manifest has no broad storage permission and keeps the Flutter embedding
  configuration explicit.

Android SDK, Java, Gradle, ADB, and a physical/emulated device are unavailable
in the current environment. Manifest merge, release/profile build, MediaStore,
FileProvider, recipient lifecycle, OEM, TalkBack, large-text, reduced-motion,
and low-storage checks therefore remain external validation gates.

## Security and privacy notes

- Only local app-managed source paths are accepted by the coordinator.
- Remote/content URIs, traversal, NUL bytes, symlink escapes, invalid metadata,
  and oversized selections fail closed.
- User-visible exports are collision-safe and never overwrite an existing file.
- Failed staging is rolled back through the existing managed deletion boundary;
  cancellation after a coordinator result also removes staged output before
  returning a recoverable failure.
- No network, analytics, accounts, billing, ads, or cloud backup were added.
- Premium capabilities fail closed until a future verified billing adapter exists.

## Known limitations and release gates

- The compatibility compressor controller remains a transitional surface; this
  pass does not migrate it to the future Provider/use-case workflow.
- The adapter currently derives a minimal export report from the generated output
  because the frozen controller gateway supplies only a file path. The combined
  validation also makes the app-managed destination and collision-safe naming
  policy explicit at this compatibility boundary.
- Android integration and device behavior cannot be proven without the Android
  toolchain.
- Flutter formatting, analyzer, generated localization, and tests must run in
  Flutter-enabled CI before production sign-off.
- A signed release build, merged manifest, Play Data Safety declaration,
  privacy-policy/legal URL review, and accessibility/device matrix remain
  mandatory.

## Completion status

**Repository integration implemented. Production approval is withheld until the
Flutter/Android and release gates above pass. Phase 12 must not begin.**
