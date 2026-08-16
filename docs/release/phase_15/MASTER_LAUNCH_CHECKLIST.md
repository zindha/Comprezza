# Comprezza — Master Launch Checklist

**Release owner:** `[REPLACE_WITH_RELEASE_OWNER]`  
**Release:** `1.0.0` / version code `[REPLACE_WITH_UNIQUE_VERSION_CODE]`  
**Decision:** `[APPROVE / HOLD / ROLLBACK]`

> Every checkbox is required before pressing **Publish**. A checkbox marked N/A requires written release-owner justification.

## Product and scope

- [ ] Final AAB contains only approved, functional, documented features (batch compression, camera capture, and statistics are now integrated features; verify they work in the exact artifact).
- [ ] Listing claims match the exact AAB: batch, camera, and statistics are implemented and unit-tested, but device validation is still pending; no placeholder screen, fake statistic, unreleased comparison slider, or unsupported marketing claim remains.
- [ ] Known limitations are accepted and visible where necessary.
- [ ] Version name and unique version code confirmed.

## Engineering quality

- [ ] `flutter pub get` succeeds from a clean checkout.
- [ ] `flutter gen-l10n` succeeds.
- [ ] `dart format --set-exit-if-changed lib test` succeeds.
- [ ] `flutter analyze` succeeds with zero warnings.
- [ ] `flutter test` succeeds.
- [ ] Integration/widget/regression evidence archived.
- [ ] Manual QA matrix (`COMPREZZA_MANUAL_QA_1000.csv`, 1,040 cases) executed for implemented features, including the Batch compression (TC-0801..TC-0840) and Camera capture (TC-1001..TC-1040) blocks.
- [ ] Dependency, license, and security audit complete.

## Android artifact

- [ ] `flutter build appbundle --release` succeeds.
- [ ] Signed AAB generated with protected upload key.
- [ ] Play App Signing enrollment and upload certificate verified.
- [ ] Compile/target SDK meets the current Play requirement at upload time.
- [ ] Minimum SDK and supported device range approved.
- [ ] Android lint passes.
- [ ] R8/resource shrinking passes.
- [ ] `mapping.txt`, checksum, provenance, and AAB archived.
- [ ] Merged manifest inspected.
- [ ] No unnecessary permissions, services, providers, or exported components.
- [ ] No debug logging, developer options, test endpoints, secrets, or signing material.

## Security and privacy

- [ ] Privacy policy legally reviewed and published at a public HTTPS URL.
- [ ] Terms, disclaimer, security contact, copyright, and license notices reviewed.
- [ ] Data Safety form matches exact AAB and dependency graph.
- [ ] Account, ads, analytics, crash reporting, location, contacts, photo/file, and storage declarations are truthful.
- [ ] Share recipient handling and retention are disclosed.
- [ ] Camera flow verified: no CAMERA permission requested; system camera intent returns the photo to app-private staging.
- [ ] Export paths, filenames, symlinks, temporary files, and process death tested (including batch multi-output and camera-sourced files).
- [ ] Security contact monitored.

## Store listing

- [ ] Title, short description, long description, category, tags, target audience, and content rating approved.
- [ ] Icon, adaptive icon, monochrome icon, feature graphic, promo graphic, and screenshots meet current Play requirements.
- [ ] Screenshots show the exact AAB and no placeholder/fabricated state.
- [ ] Batch (Screenshot 3) and camera (Screenshot 8) storyboard gates closed per the updated `SCREENSHOT_STORYBOARD.md` before capture.
- [ ] English listing and any translated listings reviewed by native speakers.
- [ ] Store privacy URL and support URL work without login.

## Real-device validation

- [ ] Android 13.
- [ ] Android 14.
- [ ] Android 15.
- [ ] Android 16, where available and required by upload date.
- [ ] Samsung.
- [ ] Pixel.
- [ ] Xiaomi.
- [ ] OnePlus.
- [ ] TalkBack.
- [ ] RTL.
- [ ] Large text.
- [ ] Reduced motion.
- [ ] Battery and thermal.
- [ ] Memory/low-RAM.
- [ ] Large images.
- [ ] Batch flow: multi-image selection, queue progress, retry/cancel, batch save and share.
- [ ] Camera flow: capture from the in-app camera action, compression of the captured photo, and graceful handling of a missing/denied camera.
- [ ] Crash/ANR/process-death/interrupted-operation.

## Testing tracks

- [ ] Internal Testing AAB uploaded.
- [ ] Internal testers complete core workflow and exit criteria.
- [ ] Internal issues triaged and fixed/accepted.
- [ ] Closed Testing AAB uploaded.
- [ ] Closed tester duration/participant requirement completed if applicable to account.
- [ ] Closed issues triaged and fixed/accepted.
- [ ] Pre-launch report reviewed.

## Production rollout

- [ ] Production release notes approved.
- [ ] Rollout percentage approved.
- [ ] Crash/ANR thresholds and pause criteria defined.
- [ ] Support workflow staffed.
- [ ] Review-response templates approved.
- [ ] Rollback version identified.
- [ ] Publish button authorization recorded.
- [ ] Post-launch monitoring begins immediately.

## Post-launch monitoring

- [ ] Crash-free users/sessions.
- [ ] ANR rate.
- [ ] Export/share failure rate.
- [ ] Picker and MediaStore failure rate.
- [ ] Batch and camera flow failure rate.
- [ ] Temporary-file cleanup failures.
- [ ] Battery/thermal complaints.
- [ ] Accessibility complaints.
- [ ] Privacy/security reports.
- [ ] Rating and review trend.
- [ ] 24-hour, 72-hour, and 7-day reviews completed.
