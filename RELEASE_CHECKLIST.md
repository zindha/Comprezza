# Comprezza RC1 Release Checklist

This checklist is a release gate, not a declaration that the artifact is approved.
The complete matrix is in `PHASE_13_RELEASE_CANDIDATE_CHECKLIST.md`.

## Required local/CI commands

```bash
flutter pub get
flutter gen-l10n
dart format --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build appbundle --release
```

For Windows local signing, run `.\\scripts\\setup_release_signing.ps1` once,
then use `flutter build apk --release` or `flutter build appbundle --release`.
The keystore remains outside the project and `android/key.properties` remains
ignored.

## Release configuration

- [ ] Semantic version and unique Play version code confirmed.
- [ ] Current Play target API requirement confirmed.
- [ ] Java 17, Android SDK, Flutter, and Gradle toolchain verified.
- [ ] Release `key.properties` supplied securely by CI or local release host.
- [ ] No key, password, token, or local.properties file is committed.
- [ ] R8/resource shrinking succeeds; mapping artifact is retained securely.
- [ ] Release logs and developer options are disabled.

## Android and security

- [ ] Merged manifest inspected.
- [ ] No broad storage, legacy storage, notification, network, location, or
      foreground-service permissions without explicit approval.
- [ ] Photo Picker, scoped MediaStore, `IS_PENDING`, MIME, FileProvider, and
      Sharesheet behavior verified on Android 10+.
- [ ] Path traversal, symlink, unsafe filename, temporary-file, low-storage,
      cancellation, and process-death tests pass.

## Quality and accessibility

- [ ] Analyzer has zero warnings.
- [ ] Full tests pass.
- [ ] Large image, memory pressure, battery, thermal, and startup tests pass.
- [ ] TalkBack, large text, contrast, reduced motion, touch targets, and
      navigation order pass on representative devices.
- [ ] English/Hindi localization and RTL smoke checks pass.

## Distribution

- [ ] Signed AAB built and checksum recorded.
- [ ] Play App Signing and upload key verified.
- [ ] Privacy policy published at reviewed HTTPS URL.
- [ ] Data Safety, content rating, target audience, and support declarations
      completed.
- [ ] Internal testing checklist complete.
- [ ] Closed testing checklist complete.
- [ ] Production rollout and rollback criteria approved.
