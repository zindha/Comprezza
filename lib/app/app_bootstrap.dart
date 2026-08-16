import 'di/app_dependencies.dart';

/// Builds the dependency graph before the root widget is rendered.
abstract final class AppBootstrap {
  /// Creates the scoped dependency graph.
  static AppDependencies initialize() => AppDependencies.create();
}
