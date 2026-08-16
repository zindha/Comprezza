# Phase 13 — Release Engineering Report

**Product:** Comprezza — Photo Compressor & Converter  
**Package:** `com.dzynova.comprezza`  
**Developer:** Dzynova Technologies  
**Candidate:** RC1 / `1.0.0+1`

## Executive decision

**Release Candidate preparation is complete for repository scope. Production
approval is withheld.** The repository has release configuration, branded
launcher resources, protected CI signing conventions, and documentation
improvements, but the required Flutter, Android, signing, artifact, device, and
Play Console validations cannot be completed in this environment.

The following remain explicit release blockers rather than environment-only
notes: resolved target API evidence, signed AAB evidence, merged-manifest and
FileProvider inspection, legal HTTPS privacy-policy publication, real-device
accessibility/performance testing, and closed-testing exit approval.

## Files modified/created

- `android/app/build.gradle`
- `android/app/src/main/AndroidManifest.xml`
- `android/app/src/main/res/values/strings.xml`
- `android/app/src/main/res/drawable/ic_launcher_background.xml`
- `android/app/src/main/res/drawable/ic_launcher_foreground.xml`
- `android/app/src/main/res/mipmap-anydpi/ic_launcher.xml`
- `android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml`
- `.github/workflows/ci.yml`
- `android/app/proguard-rules.pro`
- `.gitignore`
- `RELEASE_NOTES_v1.0.0.md`
- `INTERNAL_TESTING_CHECKLIST.md`
- `CLOSED_TESTING_CHECKLIST.md`
- `PHASE_13_RELEASE_CANDIDATE_CHECKLIST.md`
- `RELEASE_ENGINEERING_REPORT_v1.0.0.md`
- `RELEASE_CHECKLIST.md`
- `PLAYSTORE_CHECKLIST.md`
- `README.md`
- `PROJECT_CHANGELOG.md`
- `ROADMAP.md`
- `TECH_DEBT.md`
- `BUG_TRACKER.md`

## Release configuration

- Package and namespace are consistently `com.dzynova.comprezza`.
- Java/Kotlin target is 17.
- Minimum SDK is API 29, matching the native MediaStore bridge policy.
- Version is `1.0.0+1`; Play uniqueness must be confirmed before upload.
- Release signing reads secrets from ignored `android/key.properties` when
  supplied by CI/local release infrastructure and never falls back to debug
  signing.
- R8 minification and resource shrinking are enabled for release builds.
- A dedicated `proguard-rules.pro` preserves manifest/plugin entry points.
- No release keys or secrets were generated.

The compile and target SDK currently delegate to the installed Flutter toolchain.
For the 2026-08-07 review window, CI enforces the active API 35 minimum.The threshold must be raised to API 36 before submissions on or after August 31,
2026. CI now contains an explicit transition-date gate, and the release owner
must still verify the current Play requirement at upload time.


## Permission and Android audit

Static manifest review found no broad storage permissions, `MANAGE_EXTERNAL_STORAGE`,
foreground service, notification, location, or network permission. The app uses
user-mediated picker selection, app-private staging, scoped MediaStore export,
and `share_plus` for Sharesheet dispatch.

The native bridge canonicalizes and restricts source paths, derives MIME from the
extension, writes with MediaStore `IS_PENDING`, and deletes failed pending rows.
The release artifact must still verify the merged `share_plus` FileProvider
configuration and provider paths.

## Security audit

- Signing secrets are excluded from source control.
- Release logging is disabled by build configuration in release mode.
- Developer options are release-gated.
- Managed source/export roots and symlink checks remain enforced.
- Temporary share files are retained for recipient access and reclaimed by TTL
  cleanup rather than immediately deleted after Sharesheet return.
- No cloud, analytics, tracking, login, ads, or Play Integrity dependency was
  introduced.
- Low-storage, process-death, OEM, and artifact-level R8 behavior remain tests.

## Google Play compliance

The app is aligned with the intended offline/privacy-first policy. Before upload,
complete and archive:

1. Current target API verification.
2. Data Safety form for the exact AAB and dependency graph.
3. Published, legally reviewed HTTPS privacy policy and support contact.
4. Content rating and target-audience declarations.
5. Play App Signing enrollment and upload-key verification.
6. Merged manifest and permission evidence.
7. Internal and closed testing exit records.

Play Integrity remains a documented future extension point only; it is not needed
for RC1's offline workflow and no dependency was added.

## Accessibility and localization

The existing implementation contains Material 3 semantics, dynamic text scaling,
reduced-motion propagation, high contrast, large touch targets, and English/Hindi
ARB infrastructure. Final TalkBack, keyboard/focus, contrast, large-text, Hindi,
and RTL smoke tests remain environment-dependent.

## CI/CD summary

A credential-scoped GitHub Actions workflow is now present for quality checks and
main-branch signed AAB generation. It pins Flutter/Java/Gradle tool versions,
creates the Android Gradle wrapper ephemerally on the release runner (the
repository does not contain a wrapper), uses environment secrets, removes
signing material in an always-run cleanup step, and uploads only the release
artifact. Play Console API automation is intentionally not enabled.

The release pipeline still requires one successful protected run before it is
considered evidence: wrapper generation, target-SDK resolution, signing,
shrinking, lint, and artifact upload have not executed in this environment.
The wrapper-bootstrap newline escaping was corrected during final review; it
still requires an actual GitHub Actions run to prove the generated
`local.properties` and wrapper behave correctly.

The workflow must be validated in GitHub Actions before it is treated as release
proof. It must execute, at minimum:

- dependency fetch and lockfile verification (now enforced in CI);
- localization generation;
- format, analyze, and full tests;
- Android lint and release AAB build;
- artifact checksum and R8 mapping retention (now enforced in CI);
- dependency/license/security audits and provenance review (still required; not implemented in this workflow);
- release-notes generation and protected artifact upload.

Automatic version bumping and future Play Developer API integration remain
pipeline extension points and are not implemented in RC1.

## Scorecard

| Category | Score | Reason |
|---|---:|---|
| Release engineering | 72/100 | Release signing/shrinking configuration and checklists exist; build/artifact execution is unavailable. |
| Architecture consistency | 86/100 | Frozen architecture preserved; transitional legacy adapter remains documented. |
| Security | 82/100 | Managed paths, scoped storage, secret exclusions, and release logging policy are present; signed/R8/device evidence is pending. |
| Privacy | 84/100 | Offline/no-analytics design is consistent; legal policy publication and final dependency audit remain open. |
| Accessibility | 78/100 | Strong Flutter foundations; TalkBack and device matrix are unverified. |
| Performance | 80/100 | Phase 12 optimizations remain intact; profile/release traces are unavailable. |
| Maintainability | 84/100 | Explicit Gradle/config documentation, lockfile enforcement, mapping retention, and checklists improve operations; CI execution remains unproven. |
| Play readiness | 68/100 | Permission posture is good; target API, signing, Data Safety, merged manifest, and Play Console gates remain open. |

**Production readiness score: 76/100 — not approved.**

## Environment-dependent validations

- Flutter/Dart generation, format, analyze, and tests (`flutter` and `dart` are unavailable in this shell).
- Flutter release AAB build.
- Android lint, R8/resource shrinking, and merged manifest.
- Java/Gradle/Android SDK availability.
- Upload-key signing and Play App Signing.
- Target API resolution and compatibility behavior.
- Real-device, low-memory, large-image, battery, thermal, OEM, TalkBack,
  large-text, reduced-motion, and Sharesheet recipient tests.
- Play Console Data Safety, content rating, internal testing, closed testing,
  and production rollout.
