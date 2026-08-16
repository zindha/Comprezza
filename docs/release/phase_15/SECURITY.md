# Comprezza Security

**Status:** Release security package; contact and incident process require owner completion.

## Security posture

Comprezza is designed to process images locally, use Android user-mediated selection, stage generated files in app-private storage, publish through scoped MediaStore APIs, and share only after explicit user action.

The current implementation includes managed-root and symlink validation, unsafe-path rejection, sanitized MediaStore names, failed-publish cleanup, release-gated diagnostics, and fail-closed release signing configuration.

## Data handling boundaries

- No intentional cloud upload, account, analytics, advertising, tracking, or crash-reporting service is included in the current build.
- Shared outputs are controlled by the Android recipient application after the user chooses a destination.
- Do not treat the local privacy design as a guarantee against a compromised device or recipient app.

## Reporting a vulnerability

Report security issues privately to:

`[REPLACE_WITH_MONITORED_SECURITY_EMAIL]`

Include affected version, Android version/device, reproduction steps, security impact, and safe evidence. Do not include real personal images or secrets. Allow `[REPLACE_WITH_RESPONSE_TIME_POLICY]` for an acknowledgement.

## Release controls

- [ ] Security contact monitored.
- [ ] Dependency and license audit completed for the exact AAB.
- [ ] Merged manifest reviewed.
- [ ] Release logs checked for paths, URIs, image data, and secrets.
- [ ] Signing material handled only by protected release infrastructure.
- [ ] R8 mapping archived securely.
- [ ] Vulnerability triage owner assigned.

## Known limitations

Native compression cancellation remains cooperative through the current frozen gateway. Android OEM, process-death, low-storage, and recipient lifecycle behavior require device validation before production approval.
