# Comprezza Phase 2 — Foundation Services & Dependency Injection

## Scope

This phase establishes reusable application infrastructure only. It does not implement image compression, UI screens, Provider feature state, batch processing, folder traversal, history, duplicate detection, smart analysis, or export workflows.

## Dependency graph

```text
main.dart
  → AppBootstrap
  → AppDependencies
  → scoped ServiceLocator
  → startup task access after first frame
  → PhotoCompressorApp

PhotoCompressorApp
  → AppProviderScope
  → ThemeModeController
  → GoRouter
  → temporary LegacyCompressorAdapter

Future feature Provider
  → constructor-injected UseCase
  → domain Repository interface
  ← data Repository implementation
  ← data Source / platform adapter

Infrastructure services
  → AppConfig / constants
  → Result<AppError>
  → platform-safe abstractions
```

The locator is scoped to `AppDependencies`; it is not a global singleton. Tests can create isolated dependency graphs.

## Implemented infrastructure

- `ServiceLocator`: lazy singleton, factory, and async lazy singleton registrations; duplicate-registration rejection; disposal ownership; retry after async factory failure.
- Domain-facing compressor gateways keep presentation independent from concrete picker, codec, export, and platform services; filesystem-backed legacy state is represented by path/value models in the domain.
- `AppConfig`: debug/profile/release build types, local/staging/production environment selection through `APP_ENV`, feature flags, release diagnostics policy.
- Constants: `AppConstants`, `AppDurations`, `AppStrings`, `AppAssets`, `AppIcons`.
- Design tokens: dimensions, radii, elevations, shadows, typography, theme durations.
- Error boundary: typed `ErrorCode`, thrown `AppException`, returned `AppError`, `Result<T>`, canonical `Failure<T>` result variant, `ErrorMapper`, and one exception-to-result adapter.
- Filesystem: app-private cache, support, history, export, and compression directories; injected path-provider boundary; directory creation; platform-neutral metadata; safe deletion with root/parent/traversal protection.
- Cache manager: explicit cache categories, age and byte limits, generated-file-only cleanup, injected filesystem and clock.
- Logger: release-disabled configuration, context redaction, no raw stack traces in console output.
- Benchmark timer: stopwatch timing, optional synchronous DevTools timeline events, RSS samples where available, average summaries.
- Device information: platform, orientation, theme brightness, optional RSS; no permission requests; nullable platform capability hooks.
- Localization: English runtime locale with ARB-based future language support.
- Theme: Material 3 static-seed fallback, light/dark/system modes, typography, spacing, radii, shadows, animation tokens, and a replaceable dynamic-color source interface.
- Routing: GoRouter factory and centralized route paths.

## Deliberate deferrals

### True Android wallpaper-derived Dynamic Color

Flutter core does not provide wallpaper-derived Material You colors by itself. The foundation exposes `DynamicColorSource` and uses a static Material 3 seed fallback. A future reviewed package or native Android adapter may implement the source without changing theme consumers.

### Android SDK and available-storage values

The device service exposes nullable values and no-permission fallbacks. Native adapters can fill these values later if a feature has a justified need. No broad permissions are requested.

### Typed routes

The current router centralizes route locations and uses a factory boundary. Typed route generation can be introduced once the route set is stable, avoiding generator churn during feature migration.

### Startup cleanup

Cache cleanup runs after the first frame to avoid delaying cold-start rendering. It is a best-effort noncritical task and returns structured errors for diagnostics.

## Security decisions

- No network, analytics, tracking, or login dependencies.
- No Android storage permissions.
- Filesystem operations are limited to app-owned directories.
- Root directories cannot be deleted through the safe-delete API.
- Child directory names reject path traversal separators.
- Release console logging is intrinsically disabled by build mode and configuration.
- Context keys containing path, URI, or file information are redacted.

## Performance decisions

- Services are lazy so unused infrastructure is not initialized.
- Startup cache cleanup is deferred until after the first frame.
- Cache traversal is asynchronous and constrained by explicit age/byte policies; chunking and cancellation remain tracked hardening work for very large caches.
- Image processing remains unimplemented and will define its own concurrency/memory budget in a later phase.
- Benchmarking is local only and does not report telemetry.

## Test boundaries

Infrastructure tests cover:

- Service locator lazy/factory behavior.
- Async singleton behavior.
- Configuration and feature flags.
- Error mapping.
- Result formatting utilities.
- Benchmark measurement/averages.
- Device-information shape.
- Cache cleanup through a fake filesystem.

Live Flutter analyzer, localization generation, formatting, unit tests, and Android builds require a Flutter-enabled environment.
