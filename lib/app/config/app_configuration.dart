import 'app_environment.dart';

/// Provides application configuration to infrastructure without globals.
abstract interface class AppConfiguration {
  /// Current build configuration.
  AppConfig get value;
}

/// Default immutable implementation of [AppConfiguration].
final class DefaultAppConfiguration implements AppConfiguration {
  /// Creates configuration from the current build mode.
  DefaultAppConfiguration() : value = AppConfig.fromBuildMode();

  @override
  final AppConfig value;
}
