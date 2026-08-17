# Comprezza – Complete Play Store Listing

> Ready-to-paste reference for Google Play Console. Fields marked `[REPLACE_WITH_...]`
> must be filled with final, owner-approved values before submission. Keep the
> short description at or below 80 characters and the long description at or
> below 4,000 characters.

## 1. Identity

| Field | Value |
|---|---|
| App name | Comprezza |
| Play Store title | Comprezza – Photo Compressor & Converter |
| Android package | `com.dzynova.comprezza` |
| Developer | Dzynova Technologies |
| Version | `1.0.0` (version code `1`) |
| Brand primary | `#2563EB` |
| Brand secondary | `#06B6D4` |
| Brand accent | `#14B8A6` |

## 2. Short description (≤ 80 characters)

> Compress, convert & optimize photos on your device — 100% private, no uploads.

*(60 characters — fits the Play Store 80-character limit.)*

## 3. Long description (≤ 4,000 characters)

> **Comprezza – Photo Compressor & Converter**
>
> Compress. Convert. Optimize. All on your device.
>
> Comprezza shrinks your photo library without ever sending a single image to the cloud. Everything runs locally on your phone — no login, no account, no uploads, no analytics, no tracking.
>
> **Compress**
> - Squeeze JPEG photos from up to 90% smaller with quality control from 1% to 100%
> - See live before/after previews with dimensions, file sizes, and savings percentage
> - Target a specific file size instead of guessing at quality
> - Batch-compress dozens of photos at once with per-image quality overrides
>
> **Convert**
> - Switch between JPEG, PNG, and WebP
> - Adjust scale and strip metadata when you want the smallest possible file
>
> **Manage**
> - Export straight to your gallery with no broad storage permissions
> - Share compressed results through the Android share sheet
> - Bundle completed batches into a single ZIP for easy transfer
> - Review compression history with insights on how much space you've saved
> - Retry failed items with one tap and pick up where you left off, even after closing the app
>
> **Private by design**
> - No internet connection required — processing is 100% offline and on-device
> - No accounts, ads, or analytics
> - Your photos never leave your device
>
> Built with a clean, modern Material 3 interface in light and dark themes, with English and Hindi support.

## 4. Promotional text (optional surface)

> Make room for what matters — compress photos locally and share with confidence.

Use only if the current Play Console surface supports promotional text. Do not
claim features not present in the exact uploaded AAB.

## 5. Category and classification

| Field | Recommendation |
|---|---|
| Category | Photography (Tools is an acceptable alternative if the listing emphasizes utility) |
| Tags | photo compressor, image optimizer, reduce photo size, resize photos, offline photo tool |
| App classification | Utility/photo productivity app — not a social network, game, financial, health, or child-directed app |
| Target audience | General audience; not specifically directed to children |
| Content rating | Expected low-risk utility rating, subject to the IARC questionnaire in Console |
| Ads | None in the current build |
| Account creation | None — no login or account flow exists |

## 6. Contact details

| Field | Value |
|---|---|
| Support email | `zindhak@gmail.com` |
| Support URL | `[REPLACE_WITH_PUBLIC_SUPPORT_URL]` |
| Privacy email | `zindhak@gmail.com` |
| Privacy policy URL | `[REPLACE_WITH_PUBLIC_HTTPS_PRIVACY_POLICY_URL]` |
| Website | `[REPLACE_WITH_PUBLIC_WEBSITE_URL]` |

> The privacy-policy URL entered here must be identical to the one in the app's
> legal destination and to the one used for the Data Safety form.

## 7. Data Safety summary (for the form)

Position: the current build is designed for offline, local image processing with
no analytics, advertising, account, cloud-upload, tracking, or crash-reporting
SDK.

| Question | Proposed answer |
|---|---|
| Does the app collect or share user data? | No automatic developer-controlled collection. User-initiated Android Sharesheet sharing requires final Play policy/legal determination before selecting "no" or "yes" |
| Photos / videos | Not collected by Comprezza servers — selected images and camera captures are processed on-device |
| Files / documents | Not collected — generated files and batch history remain local |
| Personal info | Not collected — no account creation or profile |
| Contacts, location, financial, health, messages, audio | Not collected or accessed |
| App activity, device identifiers, crash logs | Not intentionally collected — no analytics or crash SDK included |
| Data shared with third parties | Pending final Play determination for the user-initiated share-sheet path |
| Encryption / deletion | No network transport; local data deletable via app controls; do not claim app-level encryption |
| Data sale / advertising | No data sale; no ads |

> Final answers must be checked against the exact signed AAB, merged manifest,
> transitive SDK behavior, and the published privacy policy. See
> `docs/release/phase_15/DATA_SAFETY_PACKAGE.md` for the full evidence list.

## 8. What's new — version 1.0.0

- Local photo compression with adjustable JPEG quality (1%–100%)
- Live before/after previews with dimensions, file sizes, and savings percentage
- Target a specific file size instead of guessing at quality
- Batch compression of multiple photos with a bounded, cancelable queue
- Batch retry for failed items and queue restoration after closing the app
- JPEG, PNG, and WebP conversion with scale and metadata options
- ZIP export of completed batches
- Compression history with storage-savings insights
- Camera capture that feeds directly into the local compression workflow
- Save to `Pictures/Comprezza` using scoped Android storage, no broad permissions
- User-initiated Android share-sheet support
- Material 3 light, dark, and system themes
- English and Hindi localization

## 9. Graphic assets

| Asset | Specification |
|---|---|
| App icon (Play listing) | 512×512 px, 32-bit PNG with alpha; compression mark on primary blue `#2563EB`, no text |
| Feature graphic | 1024×500 px; compression mark on the left, "Compress. Convert. Optimize." headline on the right; JPG or 24-bit PNG |
| Phone screenshots | Portrait 1080×2400 px (or device-native); 5–7 real screens, suggested order: hero/value → compression workflow → result/share → privacy → settings/accessibility |
| Tablet screenshots | 7-inch and 10-inch, responsive layouts only if present in the exact AAB |
| Promotional graphic | Only if Play Console requests it; match feature-graphic palette |

> All screenshots must come from the exact release artifact with no placeholder
> metrics, personal photos, or misleading badges. See
> `docs/release/phase_15/ASSET_SPECIFICATION.md` for full rules.

## 10. Compliance rules

- Title, short description (80), and long description (4,000) stay within Play limits.
- Do not claim "lossless," "AI," "unlimited," or formats beyond what the exact release artifact enables.
- Do not use "official," "best," "#1," guaranteed savings, or competitor trademarks.
- Screenshots and copy must reflect only features validated in the exact signed AAB.
- The published privacy policy must be legally reviewed and hosted at a stable HTTPS URL.
- Data Safety form answers must match the final artifact and this listing.

## 11. Pre-submission checklist

- [ ] Support email, support URL, website, and privacy-policy URL replaced and verified.
- [ ] Privacy policy published at stable HTTPS; same URL in Console, website, and app.
- [ ] Category, tags, target audience, and content-rating questionnaire completed in Console.
- [ ] Data Safety form submitted to match the exact signed AAB.
- [ ] Screenshots, feature graphic, and icon generated from the exact release artifact.
- [ ] Version name `1.0.0` and unique version code confirmed; signed AAB uploaded (never a debug APK).
- [ ] Full checklist in `PLAYSTORE_CHECKLIST.md` and `docs/release/phase_15/MASTER_LAUNCH_CHECKLIST.md` reviewed.
