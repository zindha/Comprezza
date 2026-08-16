# Comprezza — Google Play Data Safety Package

**Status:** Preparation document; final answers require exact-AAB dependency review and Play Console owner submission.  
**Product:** Comprezza — Photo Compressor & Converter  
**Package:** `com.dzynova.comprezza`

## Executive position

The current source is designed for offline, local image processing and contains no intentional analytics, advertising, account, cloud-upload, tracking, or crash-reporting SDK. On-device processing is generally not treated as developer collection when data never leaves the device; however, the user-initiated Android Sharesheet path must be reviewed against the current Play Data Safety definitions before selecting final answers.

The Compress workflow also offers camera capture and batch processing. **Camera capture** uses Android's system camera app through the `ACTION_IMAGE_CAPTURE` intent; Comprezza does not declare or request the CAMERA permission. The captured photo is returned to the app, staged in app-private temporary storage, and processed locally exactly like a user-selected image — it is saved or shared only on explicit user action. The system camera app is a separate application whose own privacy behavior is outside Comprezza's control. **Batch processing** selects multiple user-owned images through the multi-image picker and compresses them in a bounded on-device queue; selection, inspection, compression, and any locally recorded history never leave the device.

The Android system share sheet can transfer a user-selected generated output to a recipient application after an explicit user action. That recipient's handling is outside Comprezza's control and must be disclosed in the privacy policy. Final Play answers must be checked against the exact signed AAB, merged manifest, transitive SDK behavior, and any later release configuration.

## Proposed Play Console responses

| Data Safety question | Proposed response | Evidence / owner check |
|---|---|---|
| Does the app collect or share user data? | **Proposed: no automatic developer-controlled collection. User-initiated sharing requires an explicit Play policy/legal determination for the exact share flow.** | Confirm final AAB has no telemetry, crash reporter, account, cloud, or advertising SDK; review Android Sharesheet behavior against current Data Safety definitions. |
| Photos or videos | Not collected by Comprezza servers. Selected images and camera captures (including batch selections) are processed on-device; no upload or cloud processing. | Photo Picker and system camera intent (no CAMERA permission requested); verify no network path and app-private staging for captures. |
| Files and documents | Not collected by Comprezza servers. Generated files — single or batch — remain local unless the user saves or shares them; batch history is recorded only on-device. | App-private staging, MediaStore bridge, and local batch history; verify exact behavior. |
| Personal info | Not collected. No account creation or profile. | Source review and release smoke test. |
| Contacts | Not collected or accessed. | Manifest/source audit. |
| Location | Not collected or accessed. | Manifest/source audit. |
| Financial/payment data | Not collected; no billing is implemented in this release. | Dependency and feature audit. |
| Health/fitness | Not collected. | Product scope. |
| Messages/email | Not collected. | Manifest/source audit. |
| Audio | Not collected. | Product scope. |
| App activity | No analytics or behavioral tracking is intentionally included. | Dependency lockfile and network audit. |
| Device identifiers | Not intentionally collected. | Dependency/SDK review. |
| Crash logs | No crash-reporting SDK is included. Local diagnostic logging is disabled in release. | Build config and dependency audit. |
| Data shared with third parties | **Pending exact Play determination:** user-initiated Android Sharesheet transfer may send the selected output to the app the user chooses. Do not pre-submit “no sharing” without review. | Verify share UX, recipient behavior, current Data Safety definitions, and final privacy text. |
| Data encrypted in transit | Comprezza has no network transport in the current offline build. | Confirm no network dependency/permission is introduced. |
| Data encrypted at rest | Do not claim app-level encryption unless separately implemented and tested. Android/app-private storage protections still apply according to platform behavior. | Release owner/legal review. |
| Data deletion | User can remove generated cache and history (including batch and camera-sourced entries) using app controls; exported files remain under user/device storage controls. | Test clear/reset boundaries and document accurately. |
| Account creation | No account creation. | Play declaration. |
| Data sale | No data sale. | Policy declaration. |
| Advertising | No ads in the current build. | Exact-AAB dependency and UI review. |

## Data categories to avoid claiming

Do not mark photos, files, analytics, crash logs, contacts, location, identifiers, or personal information as collected unless a future SDK, platform integration, or release configuration changes the data flow.

Do not claim end-to-end encryption, server deletion, cloud backup, account portability, or automated data deletion that the current implementation does not provide.

## SDK inventory for final submission

Current declared production packages include:

- Flutter framework and `flutter_localizations`.
- `image_picker`, Android picker support, and platform interface (single-image, system-camera, and multi-image batch selection).
- `flutter_image_compress`.
- `path_provider`.
- `share_plus`.
- `url_launcher` (opens the external Play listing and website; no user data involved).
- `provider`, `go_router`, `intl`, `path`, `crypto`, and `cupertino_icons`.

Before Play submission, export the resolved dependency tree from the exact build and inspect each package's Android transitive dependencies and privacy behavior.

## Required final evidence

- [ ] Exact signed AAB dependency tree archived.
- [ ] Merged manifest inspected (no CAMERA permission; system-camera intent and `url_launcher` queries confirmed).
- [ ] Network/proxy or static network audit confirms no automatic upload/telemetry for single, camera, and batch flows.
- [ ] Share-sheet recipient behavior documented.
- [ ] Camera-capture flow and batch picker/history behavior verified on-device and documented.
- [ ] Privacy policy published at a stable HTTPS URL.
- [ ] Data Safety answers reviewed by release owner and legal/privacy reviewer.
- [ ] Play Console form submitted for the exact artifact.

## References

- Google Play Data Safety: https://support.google.com/googleplay/android-developer/answer/10787469
- User Data policy: https://play.google.com/about/developer-content-policy/#user-data
- Android privacy best practices: https://developer.android.com/privacy
