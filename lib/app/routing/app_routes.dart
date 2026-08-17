/// Typed application route identities.
enum AppRoute {
  home,
  compression,
  batch,
  history,
  statistics,
  settings,
  benchmark,
  about,
}

/// Centralized application route definitions.
abstract final class AppRoutes {
  /// Root application route identity.
  static const AppRoute homeRoute = AppRoute.home;

  /// Branded splash route shown on cold start.
  static const String splash = '/splash';

  /// Branded splash route location.
  static String get splashLocation => splash;

  /// Root application route location.
  static const String home = '/';

  /// Compression workspace location.
  static const String compression = '/compression';

  /// Batch compression workspace location.
  static const String batch = '/batch';

  /// History location reserved for a later phase.
  static const String history = '/history';

  /// Statistics location reserved for a later phase.
  static const String statistics = '/statistics';

  /// Settings location reserved for a later phase.
  static const String settings = '/settings';

  /// Benchmark location reserved for a later phase.
  static const String benchmark = '/benchmark';

  /// About location for the app information surface.
  static const String about = '/about';

  /// The default route location.
  static String get homeLocation => home;

  /// Returns the location associated with [route].
  static String locationFor(AppRoute route) => switch (route) {
    AppRoute.home => home,
    AppRoute.compression => compression,
    AppRoute.batch => batch,
    AppRoute.history => history,
    AppRoute.statistics => statistics,
    AppRoute.settings => settings,
    AppRoute.benchmark => benchmark,
    AppRoute.about => about,
  };

  /// Returns the shell destination index associated with [location].
  static int indexForLocation(String location) {
    if (location == compression) return 1;
    if (location == history || location == statistics) return 2;
    if (location == settings) return 3;
    return 0;
  }
}
