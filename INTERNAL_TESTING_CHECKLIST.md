# Internal Testing Checklist — Comprezza RC1

## Artifact and Play Console

- [ ] Confirm the uploaded artifact is a signed Android App Bundle.
- [ ] Confirm application ID `com.dzynova.comprezza`.
- [ ] Confirm version name `1.0.0` and a unique, incremented version code.
- [ ] Confirm Play App Signing enrollment and upload-key identity.
- [ ] Confirm release notes and tester instructions are attached.
- [ ] Confirm the Data Safety form is accurate for the exact dependency graph.

## Install and upgrade

- [ ] Fresh install from the internal track.
- [ ] Upgrade from the prior test build.
- [ ] Uninstall/reinstall behavior.
- [ ] App launch after activity/process recreation.
- [ ] Dark mode and system theme behavior.

## Core workflow

- [ ] Select a JPEG, PNG, and WebP image through the user-mediated picker.
- [ ] Compress at low, medium, and high quality.
- [ ] Verify preview, dimensions, output size, and savings.
- [ ] Save to `Pictures/Comprezza`.
- [ ] Share through the Android Sharesheet.
- [ ] Dismiss the Sharesheet and verify recoverable behavior.
- [ ] Cancel compression and export operations.
- [ ] Retry a failed operation.

## Resilience and storage

- [ ] Test a 100 MiB image on a low-memory device.
- [ ] Test low free storage and failed MediaStore insertion.
- [ ] Test interrupted compression and process death.
- [ ] Verify temporary-file cleanup does not delete active share files.
- [ ] Verify expired generated files are reclaimed.
- [ ] Verify no original user file is deleted.

## Accessibility and localization

- [ ] TalkBack navigation and announcements.
- [ ] Large font and display scaling.
- [ ] Reduced motion.
- [ ] High contrast and color-blind-friendly settings.
- [ ] Touch targets and keyboard/focus traversal where applicable.
- [ ] English and Hindi content, truncation, and RTL smoke checks.

## Exit criteria

- [ ] No crash, ANR, data loss, unsafe path, or leaked temporary file.
- [ ] Attach device matrix, logs, screenshots, and artifact checksum to the test record.
- [ ] Obtain Principal Engineer and release-owner approval before closed testing.
