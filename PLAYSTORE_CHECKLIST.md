# Comprezza Google Play RC1 Checklist

This checklist must be completed for the exact signed AAB. Internal-only testing
may have different console declaration requirements, but production submission
requires every applicable item below.

## Identity and artifact

- [ ] App name, title, developer, package, icon, and store listing are approved.
- [ ] Version name `1.0.0` and a unique incremented version code are confirmed.
- [ ] Signed AAB uploaded; debug APK is never submitted to Play.
- [ ] Play App Signing is enabled and upload-key fingerprints are recorded.
- [ ] Artifact checksum and build provenance are archived.

## Target API and Android

- [ ] Current Play target API requirement is verified in Play Console.
- [ ] RC1 target SDK is at least the required API (API 36 for submissions on/after
      August 31, 2026 under the current reviewed guidance).
- [ ] Compile SDK, minimum SDK/API 29, and Java 17 are verified.
- [ ] Release manifest merge is inspected.
- [ ] No `READ_EXTERNAL_STORAGE`, `WRITE_EXTERNAL_STORAGE`, or
      `MANAGE_EXTERNAL_STORAGE` permission is present.
- [ ] No unnecessary foreground service, notification, network, location, or
      account permission is present.
- [ ] Android Photo Picker, scoped storage, MediaStore, `IS_PENDING`, MIME,
      FileProvider, and `share_plus` behavior are device-tested.

## Privacy and Data Safety

- [ ] Legally reviewed privacy policy is published at a stable HTTPS URL.
- [ ] Data Safety form matches the exact artifact and all transitive SDK behavior.
- [ ] Offline/no-upload/no-account/no-analytics/no-tracking claims are verified.
- [ ] Retention, deletion, temporary sharing, and recipient handling are disclosed.
- [ ] Support contact, age rating, target audience, and content declarations are
      complete.

## Security and quality

- [ ] R8/resource shrinking passes and mapping is archived securely.
- [ ] No release logs expose paths, image data, secrets, or stack traces.
- [ ] Developer options and debug flags are disabled in release.
- [ ] Large image, low storage, process death, cancellation, and cleanup tests pass.
- [ ] TalkBack, large text, contrast, reduced motion, and touch-target tests pass.
- [ ] English/Hindi localization and RTL smoke checks pass.
- [ ] Crash-free, ANR-free, battery, thermal, and startup evidence is attached.

## Testing tracks

- [ ] Internal testing build uploaded and accepted.
- [ ] Internal tester exit criteria complete.
- [ ] Closed testing build uploaded and accepted.
- [ ] Closed tester exit criteria complete.
- [ ] Staged production rollout, pause, rollback, and support procedures approved.

## Future extension points

- [ ] Play Integrity remains documented as a future verification integration.
- [ ] Future Play Developer API automation remains documented, not enabled by
      unreviewed credentials or dependencies in RC1.
