# Comprezza

[![Comprezza CI](https://github.com/zindha/Comprezza/actions/workflows/ci.yml/badge.svg)](https://github.com/zindha/Comprezza/actions/workflows/ci.yml)

**Comprezza – Photo Compressor & Converter** is a privacy-first Flutter application by **Dzynova Technologies**.

> Compress. Convert. Optimize.

All current image processing is designed to happen locally on the device. The application does not require login, cloud uploads, analytics, or tracking.

## Product identity

- **App name:** Comprezza
- **Play Store title:** Comprezza – Photo Compressor & Converter
- **Android package:** `com.dzynova.comprezza`
- **Version:** `1.0.0`
- **Brand primary:** `#2563EB`
- **Brand secondary:** `#06B6D4`
- **Brand accent:** `#14B8A6`

## Current capabilities

- Android Photo Picker-compatible image selection through `image_picker`.
- No broad storage permissions.
- Native asynchronous image compression through `flutter_image_compress`.
- Adjustable JPEG quality from 1% to 100%.
- Original/compressed previews, dimensions, file sizes, and savings percentage.
- Temporary output processing through `path_provider`.
- Android share-sheet integration through `share_plus`.
- Scoped-storage-safe gallery export through Android MediaStore.
- Light, dark, and system Material 3 themes.
- English and Hindi ARB localization foundations.
- Lost picker-result recovery for low-memory Android activity recreation.

## Development setup

1. Install Flutter stable 3.44 or newer and Dart.
2. Configure an Android SDK and Java 17 for Android builds.
3. Delete any copied `android/local.properties` file if it contains another
   computer's SDK path; Flutter regenerates it for the current machine.
4. From the project root run:

   ```bash
   flutter pub get
   flutter gen-l10n
   dart format lib test
   flutter analyze
   flutter test
   flutter run
   ```

For a local signed Windows release, first create an upload keystore and the
ignored signing properties with:

```powershell
.\\scripts\\setup_release_signing.ps1
```

The script stores the keystore outside the project and refuses to overwrite an
existing key. After it completes, build with:

```powershell
flutter clean
flutter pub get
flutter build apk --release
```

For Google Play, use `flutter build appbundle --release`. Never copy
`android/key.properties`, a keystore, or passwords into source control.

The local Android SDK path is configured through `android/local.properties` and should not be committed if it contains machine-specific paths.

## Architecture

```text
lib/
├── app.dart
├── main.dart
├── app/                       # Composition, routing, theme, localization, DI
├── l10n/                      # ARB resources and generated localization
├── core/                      # Errors, services, tokens, utilities
└── features/compressor/
    ├── data/                  # Plugins, codecs, export adapters
    ├── domain/                # Platform-neutral models, gateways, use cases
    └── presentation/          # Controller, screen, widgets
```

Concrete services are assembled in `lib/app/di`. Presentation depends on domain gateway contracts, while platform plugins remain in the data layer.

## Android storage model

Comprezza reads only images selected by the user through the system picker. Intermediate files remain in app-private temporary storage. **Save to Device** inserts the finished image into `Pictures/Comprezza` through MediaStore without broad storage permissions.

The native bridge requires Android 10/API 29 or newer for permission-free MediaStore export. Sharing remains available through the operating-system share sheet.

## Product roadmap

Version 1 focuses on an excellent local photo workflow: compression, resizing, conversion, and batch processing.

HEIC/AVIF support, background processing, smart recommendations, folder monitoring, video/PDF/ZIP workflows, and optional cloud backup are future roadmap items only. They must not be added without separate privacy, security, performance, and Play Store reviews.

## Release engineering

The complete Phase 15 production release package is maintained in [`docs/release/phase_15/`](docs/release/phase_15/). It includes the Play listing, Data Safety preparation, legal/security templates, asset specification, testing package, support/marketing package, business strategy, and master launch checklist.

Phase 13 RC1 release documentation is maintained in:

- `RELEASE_ENGINEERING_REPORT_v1.0.0.md`
- `PHASE_13_RELEASE_CANDIDATE_CHECKLIST.md`
- `INTERNAL_TESTING_CHECKLIST.md`
- `CLOSED_TESTING_CHECKLIST.md`
- `RELEASE_NOTES_v1.0.0.md`

Release signing uses an external, ignored `android/key.properties` file supplied
by the release environment. No keys are generated or stored in this repository.
The release Gradle profile enables R8/resource shrinking and refuses to silently
fall back to debug signing. A Flutter/Android-enabled CI host must run the full
checklist and produce the signed AAB before Play upload.
