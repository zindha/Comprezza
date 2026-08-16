# Comprezza — Google Play Store Package

**Status:** Draft for release-owner and legal review — **not approved for upload**  
**Package:** `com.dzynova.comprezza`  
**Developer:** Dzynova Technologies  
**Date prepared:** 2026-08-07

## Store listing identity

### Recommended title

**Comprezza Photo Compressor**

- 26 characters; within the 30-character Play title limit.
- Avoids keyword stuffing and accurately describes the currently available workflow.
- Do not use the longer internal product name as the Play title unless Play Console confirms it fits the current limit.

### Short description

**Compress photos locally, save storage, and share optimized images privately.**

### Long description

**Compress. Convert. Optimize. — privately on your device.**

Comprezza helps you reduce photo file sizes without sending your images to a cloud service. Capture with the camera or choose images with Android's user-mediated picker, adjust JPEG quality — one photo at a time or several at once — preview the results, save them to Pictures/Comprezza, or share them through Android's system share sheet.

### Why Comprezza

- **Private by design:** image processing is intended to stay on your device.
- **Clear results:** compare the original and optimized image, dimensions, file sizes, and estimated savings.
- **Simple quality control:** choose the quality level that fits your needs.
- **Batch workflow:** compress several selected photos in one pass with progress, retry, and cancel.
- **Camera capture:** take a photo from the workflow and compress it locally in the same step.
- **Modern Android storage:** save through scoped MediaStore storage without broad legacy storage permissions.
- **Easy sharing:** use the Android share sheet when you are ready.
- **Material 3 experience:** light, dark, and system themes with accessibility preferences.
- **No account required:** the current product is designed without login, cloud upload, analytics, behavioral tracking, or advertising services.

Comprezza is built for people who want smaller, easier-to-share photos while keeping control of their files.

### Privacy disclosure for listing

Comprezza processes selected images locally. The Android share sheet can transfer an output to an app selected by the user; the receiving app controls its own handling. Read the published privacy policy before release.

### What's new — version 1.0.0

- Local photo compression with adjustable JPEG quality.
- Batch compression of multiple selected photos with a bounded, cancelable queue.
- Camera capture that feeds directly into the local compression workflow.
- Optional preservation of original metadata during compression.
- Original and optimized previews with size and savings information.
- Save to `Pictures/Comprezza` using scoped Android storage.
- User-initiated Android share-sheet support.
- Material 3 light, dark, and system themes.
- English and Hindi localization resources.
- Privacy-focused local settings and accessibility preferences.

### Promotional text

**Make room for what matters — compress photos locally and share with confidence.**

Use only if the current Play Console surface supports promotional text. Do not claim features not present in the exact uploaded AAB.

## Classification recommendations

| Field | Recommendation | Final owner action |
|---|---|---|
| Category | Photography | Confirm against the final product scope; Tools is an acceptable alternative if the listing emphasizes utility. |
| Tags | photo compressor, image optimizer, reduce photo size, resize photos, offline photo tool | Select only relevant Play tags available in Console; avoid competitor names and keyword stuffing. |
| App classification | Utility/photo productivity app; not a social network, game, financial app, health app, or child-directed app | Complete Play Console declarations for the exact artifact. |
| Target audience | General audience; not specifically directed to children | Complete target-audience and Families declarations accurately. |
| Content rating | Expected low-risk utility rating, subject to IARC questionnaire | Submit the questionnaire; do not self-assign an official rating. |
| Ads | None in the current build | Verify the exact AAB and console declaration. |
| Account creation | None | Confirm no login/account flow exists in the uploaded artifact. |

## Listing compliance rules

- Keep title at or below the current Play limit; verify limits in Console before upload.
- Keep short description at or below 80 characters and long description at or below 4,000 characters.
- Batch compression, camera capture, and local statistics are implemented in the current build and covered by the unit suite; close the signed-AAB and device-validation gates before claiming them in live listing copy.
- Do not claim “lossless,” “AI,” “unlimited,” or multi-format conversion beyond what the exact release artifact enables and passes device validation.
- Do not use “official,” “best,” “#1,” guaranteed savings, or competitor trademarks.
- Use screenshots of the exact release artifact only.

## Official references

- Data Safety: https://support.google.com/googleplay/android-developer/answer/10787469
- Target API requirements: https://support.google.com/googleplay/android-developer/answer/11926878
- Main store listing: https://support.google.com/googleplay/android-developer/answer/9866151
- Developer Program Policies: https://play.google.com/about/developer-content-policy/
