# Comprezza — Release Notes and Product Roadmap

## v1.0.0 release notes

Comprezza brings a private, local photo-compression workflow to Android. Capture from the camera or select images with Android's user-mediated picker, adjust JPEG quality, inspect the results, save them to Pictures/Comprezza, or share them through Android's system share sheet. Batch compression processes multiple selected photos in one bounded, cancelable queue with progress and retry.

This release focuses on a clear local workflow, batch processing, camera capture, optional metadata preservation, Material 3 themes, privacy-safe storage boundaries, accessibility preferences, and user-controlled sharing.

## Known limitations

- Exact codec support varies by Android device and source image.
- Batch compression, camera capture, and local statistics are implemented and unit-tested in the current build; the release scope must not advertise folder workflows, comparison-slider interactions, or multi-format conversion beyond the batch format options until those are implemented and device-validated.
- Android OEM, low-memory, battery, thermal, TalkBack, and lifecycle validation must be completed on the signed release artifact.
- Native compression cancellation is cooperative through the current gateway.
- English and Hindi resources exist; additional locales are not translated.
- A final legal privacy policy and public support contact are required before Play publication.

## Version 1.0.1 plan

Only after launch telemetry is intentionally reviewed and privacy-compatible:

- Fix validated crash, ANR, picker, MediaStore, and sharing issues.
- Improve device-specific compatibility.
- Refine accessibility findings from TalkBack and large-text testing.
- Improve cleanup and cancellation behavior where profiling demonstrates need.
- Keep scope limited; do not add speculative features.

## Version 1.1 roadmap

Subject to a separate architecture and product approval:

- Close device validation for the integrated batch, camera, and statistics workflows on signed release artifacts.
- Integrate persisted compression preferences with the active workflow (including the metadata toggle).
- Add richer format/resize behavior after codec acceptance testing.

## Version 2.0 vision

Potential future product family: Comprezza Video, Comprezza PDF, Comprezza Convert, and Comprezza Resize. Cloud backup, AI, monetization, and background processing require separate privacy, security, battery, architecture, and Play reviews.
