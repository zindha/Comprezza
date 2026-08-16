# Phase 13 — RC1 Production Readiness Checklist

## Release engineering

- [ ] `pubspec.yaml` semantic version approved.
- [ ] Version code incremented and unique in Play Console.
- [ ] Application ID and namespace verified as `com.dzynova.comprezza`.
- [ ] Compile SDK and target SDK meet the current Play requirement (CI threshold is date-reviewed and must be raised before the next policy deadline).
- [ ] Minimum SDK/API 29 behavior verified.
- [ ] Debug, profile, and release configurations reviewed.
- [ ] Release logging and developer options are disabled.
- [ ] Feature flags are reviewed and release-safe.

## Build and optimization

- [ ] `flutter pub get`.
- [ ] `flutter gen-l10n`.
- [ ] `dart format --set-exit-if-changed lib test`.
- [ ] `flutter analyze` with zero warnings.
- [ ] `flutter test`.
- [ ] `flutter build appbundle --release`.
- [ ] Debug APK generated only for testing, never Play submission.
- [ ] Android lint passes.
- [ ] R8/minification and resource shrinking pass on the release artifact.
- [ ] Native libraries and bundle size reviewed.
- [ ] Dependency/license audit passes.

## Signing and supply chain

- [ ] Upload key is stored outside source control.
- [ ] Play App Signing enrollment is confirmed.
- [ ] App signing key and upload-key ownership are documented.
- [ ] Key rotation and disaster recovery procedures are documented.
- [ ] CI secrets are scoped and masked.
- [ ] No keystore, password, token, or local.properties file is committed.
- [ ] AAB checksum and provenance are recorded.

## Android and permissions

- [ ] Merged release manifest inspected.
- [ ] No `READ_EXTERNAL_STORAGE`, `WRITE_EXTERNAL_STORAGE`, or
      `MANAGE_EXTERNAL_STORAGE` permission.
- [ ] No unnecessary foreground service, notification, network, or location
      permission.
- [ ] Scoped storage and Android Photo Picker behavior verified.
- [ ] MediaStore `IS_PENDING`, MIME, path, and failure cleanup verified.
- [ ] share_plus FileProvider/content-URI merge verified.
- [ ] No exported component beyond the launcher activity without justification.

## Privacy and Play compliance

- [ ] Privacy policy reviewed, published, and linked in Play Console.
- [ ] Data Safety declaration completed for the exact artifact/dependencies.
- [ ] Content rating and target-audience declarations complete.
- [ ] No hidden tracking, analytics, cloud upload, login, or profiling.
- [ ] Permission justification is documented.
- [ ] Play Integrity extension point is documented; no unreviewed implementation
      or dependency is added in RC1.

## Functional QA

- [ ] Fresh install and upgrade.
- [ ] JPEG, PNG, and WebP flows.
- [ ] Save, share, dismiss, retry, cancel, and interrupted operations.
- [ ] Low storage and corrupted image behavior.
- [ ] Process death/activity recreation.
- [ ] Temporary-file TTL cleanup and original-file protection.
- [ ] Settings persistence/reset/import/export.

## Accessibility and localization

- [ ] TalkBack and screen-reader semantics.
- [ ] Large text and display scaling.
- [ ] Contrast and color-blind-friendly settings.
- [ ] Reduced motion.
- [ ] Touch targets and navigation order.
- [ ] English completeness and generated localization parity.
- [ ] Hindi smoke test and RTL/layout readiness.
- [ ] No user-visible hardcoded strings.

## Performance and stability

- [ ] Cold start and warm start targets measured.
- [ ] 60 FPS scrolling/frame timing reviewed.
- [ ] 100 MiB image and 100-image stress tested.
- [ ] 500-item simulation reviewed.
- [ ] Native/Dart heap and memory-pressure behavior measured.
- [ ] Battery/thermal session completed.
- [ ] Crash-free, ANR-free, and cancellation-safe sessions completed.
- [ ] OEM matrix completed.

## Distribution

- [ ] Signed AAB uploaded to Play Internal Testing.
- [ ] Internal testing checklist complete.
- [ ] Closed testing checklist complete.
- [ ] Release notes published.
- [ ] Staged rollout and rollback criteria approved.
- [ ] Production rollout only after all critical gates are green.
