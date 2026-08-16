# Comprezza — Phase 15 Testing Package

**Status:** Execution checklist; no item is pre-approved. Attach evidence to the exact version code.

## Universal evidence record

- Version name/code: `[REPLACE_WITH_VERSION_AND_VERSION_CODE]`
- AAB checksum: `[REPLACE_WITH_AAB_CHECKSUM]`
- Tester/build date: `[REPLACE_WITH_DATE]`
- Device/OS/build: `[REPLACE_WITH_DEVICE_MATRIX]`
- Result: `[PASS/FAIL/BLOCKED]`
- Evidence links: `[REPLACE_WITH_EVIDENCE_LOCATION]`

## Internal testing checklist

- [ ] Signed AAB uploaded to Internal Testing.
- [ ] Application ID/package, version, signing, and Play App Signing verified.
- [ ] Fresh install, upgrade, uninstall/reinstall, process recreation.
- [ ] JPEG, PNG, WebP, HEIC behavior tested where supported.
- [ ] Quality, preview, dimensions, size, save, share, cancel, retry, failure recovery.
- [ ] Low storage, denied picker result, corrupted image, interrupted operation.
- [ ] Settings persistence, reset confirmation, privacy-safe import/export.
- [ ] TalkBack, large text, reduced motion, contrast, touch targets.
- [ ] No crash, ANR, data loss, unsafe path, or stale temporary-file leak.

## Closed testing checklist

- [ ] Internal exit criteria approved.
- [ ] Privacy policy and support contact published.
- [ ] Data Safety, content rating, target audience, and store declarations complete.
- [ ] Testers cover Android 13/14/15/16 as available and representative OEMs.
- [ ] Samsung, Pixel, Xiaomi, and OnePlus tested.
- [ ] Phone/tablet/landscape/foldable-sized layouts tested where devices exist.
- [ ] 100 MiB images and 100-image sessions tested on low-memory hardware.
- [ ] Battery/thermal, startup, memory, jank, lifecycle, and recipient behavior recorded.
- [ ] All high/critical issues resolved or explicitly accepted by release owner.
- [ ] If applicable to the developer account, Google’s closed-testing production-access requirement is fulfilled and documented.

## Production rollout checklist

- [ ] Closed-testing exit report approved.
- [ ] Exact AAB, version code, checksum, mapping, and provenance archived.
- [ ] Play App Signing and rollback path confirmed.
- [ ] Store listing, privacy URL, Data Safety, content rating, audience, and support reviewed.
- [ ] Staged rollout percentage and pause criteria approved.
- [ ] Crash/ANR, review, support, and policy monitoring owners assigned.
- [ ] Rollback artifact and communication plan ready.

## Manual functional testing

- [ ] User selects an image and cancels selection.
- [ ] User selects supported and unsupported/corrupted inputs.
- [ ] User adjusts quality repeatedly and leaves/re-enters the screen.
- [ ] User saves output; verify MIME, name, Pictures/Comprezza destination, and gallery visibility.
- [ ] User shares output; verify recipient receives the correct file and dismissal is recoverable.
- [ ] User backgrounds/kills/reopens during picker, compression, save, and share.
- [ ] User clears cache/history/storage; verify originals and exports follow documented boundaries.
- [ ] User imports/exports configuration; verify sensitive paths/debug data are excluded.

## Accessibility checklist

- [ ] TalkBack reading order and action labels.
- [ ] Progress/error announcements are localized and meaningful.
- [ ] Focus traversal and keyboard navigation where applicable.
- [ ] 48 dp minimum touch target behavior, including large-touch setting.
- [ ] 200% text/display scaling without clipped actions.
- [ ] Contrast in light, dark, high-contrast, and error states.
- [ ] Reduced motion preserves comprehension and does not re-enable animations.
- [ ] English, Hindi, and RTL smoke checks.
- [ ] No essential information conveyed by color alone.

## Performance checklist

- [ ] Cold start and warm start traces.
- [ ] First frame and Settings loading timing.
- [ ] 60 FPS scroll and animation trace on representative phones.
- [ ] Single 100 MiB image memory/CPU trace.
- [ ] 100-image batch/queue trace if the feature is enabled for release.
- [ ] Temporary-file count/size before and after success, failure, cancellation, and process death.
- [ ] R8 release behavior and startup comparison.

## Battery checklist

- [ ] No unexpected background work after leaving the workflow.
- [ ] Long compression session thermal and battery profile.
- [ ] Screen-off/background interruption behavior.
- [ ] No polling loop or repeated wakeup after cancellation.
- [ ] Cleanup work does not create unacceptable post-frame spikes.

## Large-image checklist

- [ ] 25 MiB, 50 MiB, 100 MiB, and device-limit samples.
- [ ] JPEG, PNG, WebP, and supported HEIC samples.
- [ ] Very wide, very tall, high-resolution, malformed, and metadata-heavy samples.
- [ ] Verify no OOM, ANR, UI freeze, descriptor leak, or unsafe output.
- [ ] Verify temporary cleanup after every failure path.

## Low-end-device checklist

- [ ] 2 GB RAM device.
- [ ] 3 GB RAM device.
- [ ] Slow storage and low free-space conditions.
- [ ] Background/foreground and configuration changes.
- [ ] Large text, TalkBack, dark mode, and reduced motion.
- [ ] Compression remains cancellable at the UI/staging boundary.

## OEM compatibility checklist

- [ ] Pixel — picker, MediaStore, Sharesheet, theme, lifecycle.
- [ ] Samsung — picker, gallery visibility, MIME, Sharesheet, battery behavior.
- [ ] Xiaomi — picker/storage restrictions, background behavior, cleanup.
- [ ] OnePlus — picker, lifecycle, battery optimization, Sharesheet.
- [ ] Record OS version, vendor skin, build, result, evidence, and workaround.
