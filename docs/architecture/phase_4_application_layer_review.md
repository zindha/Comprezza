# Phase 4 Application Layer — Principal Architecture Review

## Review decision

**Rejected for production approval.** The application-layer design is directionally sound, but the current repository is not production-ready and Phase 5 must remain blocked.

## Reviewed areas

- Domain entities and value equality.
- Repository contracts and dependency inversion.
- Use-case responsibility and validation.
- Provider state transitions and lifecycle safety.
- Immutable view models and rebuild behavior.
- Scalability, memory, performance, and testability.
- Circular/dependency boundary risks.
- Google Play and Android readiness.

## Strengths

- Domain contracts do not import Flutter, `dart:io`, plugins, data implementations, or `EngineManager`.
- Repository ports are constructor-injectable and return `Result<T>`.
- Providers depend on use cases rather than platform services.
- Entity/state collections are defensively copied and state equality is structural.
- Request validation is centralized in `request_validation.dart` for quality, limits, resize policy, supported formats, and duplicate identity.
- Progress now derives `remainingFiles` from `totalFiles - completedFiles` and validates basic bounds in debug mode.
- Providers suppress unchanged state notifications and guard overlapping work.
- Cancellation guards ignore late progress and late terminal success after cancellation; disposing compression providers requests cooperative cancellation.

## Production blockers

1. **The required runtime flow is not integrated.** The running app still uses `LegacyCompressorAdapter` and the old gateway/controller path. The new Provider → Use Case → Repository application flow is not registered in `AppDependencies` or connected to the UI. This is an operational architecture gap, not a cosmetic omission.
2. **Cancellation is cooperative but not guaranteed.** The repository contracts do not guarantee prompt cancellation, completion, or resource release after provider disposal. A production contract needs an explicit lifecycle guarantee before a provider can be safely torn down.
3. **Provider orchestration is duplicated.** `CompressionProvider` and `BatchCompressionProvider` duplicate most request lifecycle, progress, cancellation, error, retry, and disposal code. This creates long-term divergence risk and should be consolidated before production.
4. **Provider race coverage is insufficient.** Tests do not cover cancellation followed by late progress/result, pause/resume races, disposal during an in-flight operation, or batch lifecycle transitions.
5. **Validation is not fully policy-driven.** The application validation limit is centralized as a constant, but not injected/configured as a policy. Target-size feasibility is not checked against source metadata. These are release-quality concerns for large and target-size workflows.
6. **Toolchain validation is unavailable.** `dart` and `flutter` are not installed in the current shell. Formatter, analyzer, focused tests, full tests, and release checks have not been executed for this review.
7. **Android/Play readiness is unverified.** No new application-layer code introduces Play permissions, but Photo Picker lifecycle, native codec behavior, low-memory behavior, Android integration, and release APK validation remain unverified.

## Required before approval

- Wire the new application contracts and Providers through the existing composition root and replace the legacy runtime path, in a separately approved integration step.
- Define and test the repository cancellation/disposal contract.
- Consolidate duplicated compression/batch orchestration without changing behavior.
- Add race/lifecycle/provider-state tests.
- Run `dart format --set-exit-if-changed lib test`, `flutter analyze`, focused tests, full `flutter test`, and Android-enabled integration/release validation.

## Validation performed in this environment

- Static brace and relative-import sanity scan: passed.
- Domain forbidden-dependency scan: passed for production domain files. A naive scan also matched test package imports, which are not production dependencies.
- No Flutter/Dart executables available.
- No browser or Android validation performed.

## Approval gate

Phase 4 remains **architecturally promising but not production-approved**. No Phase 5 work should begin until the blockers above are resolved and the owner reviews the integration plan.
