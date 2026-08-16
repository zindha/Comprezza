# Closed Testing Checklist — Comprezza RC1

## Governance

- [ ] Internal testing exit criteria are complete.
- [ ] Release owner, security reviewer, and accessibility reviewer approve the artifact.
- [ ] Privacy policy is published at a reviewed HTTPS URL.
- [ ] Support contact and data-retention disclosures are verified.
- [ ] Play Console declarations match the shipped artifact and dependencies.

## Device and OEM matrix

- [ ] Android 10/API 29 baseline device.
- [ ] Current Android release/API target device.
- [ ] Low-memory device.
- [ ] Samsung, Pixel, and one additional OEM.
- [ ] Small phone, large phone, tablet, and landscape layout.
- [ ] Dark mode, large text, reduced motion, and TalkBack.

## Functional acceptance

- [ ] Picker selection and lost-selection recovery.
- [ ] Large JPEG/PNG/WebP compression.
- [ ] Save/export through MediaStore with correct MIME and display name.
- [ ] Share through at least three recipient categories.
- [ ] Dismissed, unavailable, interrupted, and cancelled operations.
- [ ] Retry and cleanup after failure.
- [ ] Settings persistence, reset confirmations, and privacy-safe export/import.

## Performance and stability

- [ ] Cold start and warm start traces attached.
- [ ] Frame timing and scroll jank review attached.
- [ ] Native/Dart heap measurements attached.
- [ ] Battery and thermal session attached.
- [ ] 100-image stress and 500-item simulation evidence attached.
- [ ] No ANR, crash, OOM, or unreclaimed generated-file regression.

## Release gate

- [ ] All high/critical bugs are resolved or explicitly accepted by the release owner.
- [ ] Final AAB checksum and version code recorded.
- [ ] Rollback/version strategy documented.
- [ ] Production rollout staged with monitoring and pause criteria.
