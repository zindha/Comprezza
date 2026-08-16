# Comprezza — Store Asset Specification

**Status:** Production specification; artwork files are not generated in this repository.  
**Brand:** Comprezza / Dzynova Technologies  
**Palette:** Primary `#2563EB`, secondary `#06B6D4`, accent `#14B8A6`, neutral surfaces from the Material 3 theme.

## Global asset rules

- Use the exact release build and current brand mark.
- Do not show unreleased buttons, placeholder destinations, fake statistics, or features disabled in the submitted AAB.
- Use high-contrast type, generous safe areas, and legible copy at thumbnail size.
- Avoid system status/navigation bars in marketing compositions unless the screenshot intentionally demonstrates Android UI.
- Do not include personal photos, real user names, private paths, or test data.
- Do not use misleading badges such as “#1,” “best,” “unlimited,” or “AI-powered.”

## Launcher icon

- Play listing icon: 512×512 px, 32-bit PNG with alpha; verify current Play file-size and transparency rules in Console.
- Artwork: Comprezza compression mark centered with generous optical padding.
- Background: primary blue or approved adaptive background; maintain legibility in light and dark system surfaces.
- No text in the launcher icon.
- Test at small launcher sizes and against themed icon surfaces.

## Adaptive icon

- Foreground: vector compression mark inside the Android adaptive safe zone.
- Background: solid or approved gradient that survives masking.
- Validate circular, squircle, rounded-square, and legacy masks.
- Confirm the final merged resource and rendered icon on Pixel, Samsung, Xiaomi, and OnePlus launchers.

## Monochrome icon

- Single-color vector mark with no gradients or transparency-dependent detail.
- Test Material You themed-icon rendering on Android versions that support it.
- Maintain recognizable silhouette at 24–48 dp.

## Feature graphic

- Size: 1024×500 px.
- Composition: compression mark on the left; one clear benefit statement on the right.
- Suggested headline: **Compress. Convert. Optimize.**
- Suggested support line: **Private photo compression, right on your device.**
- Keep all important type inside a central safe area; do not place critical content at edges.
- Export as JPG or 24-bit PNG according to current Play requirements.

## Promotional graphic

- Create only if the current Play Console surface requests it.
- Match the feature graphic palette and typography.
- Use a single user benefit, not a feature inventory.
- Do not imply cloud security, encryption, or unsupported formats.

## Phone screenshots

- Produce at least the current Play-required minimum; recommended set is 5–7 only when every screen is real and functional.
- Portrait master: 1080×2400 px or device-native equivalent; maintain a 9:16–9:20 usable composition.
- Use consistent headline overlay: white or dark text with WCAG-conscious contrast.
- Capture on a clean Pixel-like device with no personal notifications or accounts.
- Suggested order: hero/value, compression workflow, result/share, privacy, settings/accessibility.

## Tablet screenshots

### 7-inch tablet

- Capture at a representative 7-inch Android tablet resolution and aspect ratio.
- Demonstrate responsive two-column or constrained-content behavior.
- Keep screenshot headline placement consistent with phone assets.

### 10-inch tablet

- Capture at a representative 10-inch Android tablet resolution and aspect ratio.
- Demonstrate navigation rail/large-screen composition only if present in the exact AAB.
- Verify no stretched phone UI or excessive unused space.

## Image order and marketing focus

1. Local value proposition and clear compression result.
2. Quality control and before/after information.
3. Save/share workflow.
4. Local privacy and no-account positioning.
5. Settings, accessibility, and Material 3 personalization.
6. Tablet/responsive experience, only if validated.

## Asset sign-off

- [ ] All UI is from the exact release artifact.
- [ ] Text is localized or marked as English listing copy intentionally.
- [ ] No placeholder/static metric appears as a real user result.
- [ ] Legal/privacy claims match the published policy.
- [ ] Final files are archived with source files, fonts/licenses, dimensions, and checksum.
