# Comprezza

**Compress. Convert. Optimize.**

Comprezza is a privacy-first Flutter Android photo compressor by Dzynova Technologies. It is designed to process selected images locally — one at a time, from the camera, or as a batch — show clear output information, save through Android's scoped MediaStore flow, and share through the Android system share sheet.

## Current release scope

- User-mediated image selection.
- In-app camera capture into the local compression workflow.
- Batch compression of multiple selected images with a bounded, cancelable queue and progress.
- Local image inspection and JPEG quality control.
- Original/optimized previews and file-size information.
- App-private temporary staging.
- Save to `Pictures/Comprezza` through MediaStore.
- User-initiated Android sharing.
- Material 3 light, dark, and system themes.
- English and Hindi localization resources.
- Local settings and accessibility preferences.

## Privacy

The current product is designed without login, cloud uploads, analytics, behavioral tracking, or advertising services. Camera capture opens the system camera app; the photo is processed and stored only as the user directs. Read the published privacy policy for the exact release behavior. Sharing sends an output to the Android recipient app selected by the user.

## Android requirements

- Package: `com.dzynova.comprezza`
- Minimum Android API: 29
- Java/Kotlin target: 17
- Flutter stable toolchain as pinned by the release workflow

## Development

```bash
flutter pub get
flutter gen-l10n
dart format --set-exit-if-changed lib test
flutter analyze
flutter test
flutter run
```

## Release documentation

The complete Phase 15 package is in [`docs/release/phase_15/`](./), including store copy, Data Safety preparation, legal templates, asset specifications, testing checklists, support/marketing drafts, business strategy, and the master launch checklist.

## Release status

The documentation package is prepared, but the release is not approved until the release owner closes the legal policy, product-scope, protected CI, signed AAB, Android/device, and Google Play Console gates. Do not treat this repository README as evidence of Play approval.

## License

See the repository [`LICENSE`](../../../LICENSE) and the generated open-source notice package for the exact release dependency inventory.
