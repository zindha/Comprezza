import 'package:flutter/foundation.dart';

/// Flutter build modes supported by the application.
enum BuildType { debug, profile, release }

/// Runtime environment labels used for policy/configuration selection.
enum Environment { local, staging, production }

/// Backwards-compatible build environment enum retained for existing callers.
enum AppEnvironment { debug, profile, release }

/// Immutable feature switches for future controlled rollouts.
class FeatureFlags {
  /// Creates feature flags.
  const FeatureFlags({
    this.enableHistory = false,
    this.enableBatchCompression = false,
    this.enableFolderCompression = false,
    this.enableBenchmarkMode = false,
  });

  /// Enables local compression history.
  final bool enableHistory;

  /// Enables batch processing.
  final bool enableBatchCompression;

  /// Enables user-mediated folder processing.
  final bool enableFolderCompression;

  /// Enables benchmark comparisons.
  final bool enableBenchmarkMode;
}

/// Immutable configuration shared by infrastructure and future features.
class AppConfig {
  /// Creates application configuration.
  const AppConfig({
    required this.environment,
    required this.enableDiagnostics,
    required this.enablePerformanceMonitoring,
    this.buildType = BuildType.debug,
    this.runtimeEnvironment = Environment.local,
    this.featureFlags = const FeatureFlags(),
  });

  /// Creates configuration from Flutter's official build-mode constants.
  factory AppConfig.fromBuildMode({
    FeatureFlags featureFlags = const FeatureFlags(),
  }) {
    final BuildType buildType = kReleaseMode
        ? BuildType.release
        : kProfileMode
        ? BuildType.profile
        : BuildType.debug;
    final AppEnvironment compatibilityEnvironment = switch (buildType) {
      BuildType.debug => AppEnvironment.debug,
      BuildType.profile => AppEnvironment.profile,
      BuildType.release => AppEnvironment.release,
    };
    return AppConfig(
      environment: compatibilityEnvironment,
      buildType: buildType,
      runtimeEnvironment: _runtimeEnvironmentFromDefines(buildType),
      featureFlags: featureFlags,
      enableDiagnostics: buildType != BuildType.release,
      enablePerformanceMonitoring: buildType == BuildType.debug,
    );
  }

  /// Compatibility build environment value.
  final AppEnvironment environment;

  /// Normalized build type.
  final BuildType buildType;

  /// Runtime environment label.
  final Environment runtimeEnvironment;

  /// Feature switches.
  final FeatureFlags featureFlags;

  /// Whether diagnostic logging is enabled.
  final bool enableDiagnostics;

  /// Whether development performance hooks are enabled.
  final bool enablePerformanceMonitoring;

  static Environment _runtimeEnvironmentFromDefines(BuildType buildType) {
    const String requested = String.fromEnvironment('APP_ENV');
    if (requested == 'staging') return Environment.staging;
    if (requested == 'production' || buildType == BuildType.release) {
      return Environment.production;
    }
    return Environment.local;
  }

  /// Whether this is a release build.
  bool get isRelease => buildType == BuildType.release;

  /// Whether this is a profile build.
  bool get isProfile => buildType == BuildType.profile;

  /// Whether this is a debug build.
  bool get isDebug => buildType == BuildType.debug;
}
