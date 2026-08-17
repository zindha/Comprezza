import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/compressor/presentation/about/about_screen.dart';
import '../../features/compressor/presentation/batch_compression_screen.dart';
import '../../features/compressor/presentation/benchmark/benchmark_screen.dart';
import '../../features/compressor/presentation/history/history_screen.dart';
import '../../features/compressor/presentation/home_dashboard.dart';
import '../../features/compressor/presentation/settings/settings_screen.dart';
import '../di/app_dependencies.dart';
import '../navigation/main_navigation_shell.dart';
import '../splash_screen.dart';
import 'app_routes.dart';

/// Creates the application router without importing feature implementations.
abstract final class AppRouter {
  /// Builds the Phase 6 navigation shell around real destination screens.
  static GoRouter create({
    required AppDependencies dependencies,
    required WidgetBuilder compressionBuilder,
  }) {
    return GoRouter(
      initialLocation: AppRoutes.splashLocation,
      routes: <RouteBase>[
        GoRoute(
          path: AppRoutes.splash,
          builder: (BuildContext context, GoRouterState _) =>
              const SplashScreen(),
        ),
        ShellRoute(
          builder: (BuildContext context, GoRouterState state, Widget child) =>
              MainNavigationShell(
                currentLocation: state.uri.path,
                child: child,
              ),
          routes: <RouteBase>[
            GoRoute(
              path: AppRoutes.home,
              builder: (BuildContext context, GoRouterState _) => HomeDashboard(
                history: dependencies.history,
                onSelectImages: () => context.go(AppRoutes.compression),
                onOpenCompression: () => context.go(AppRoutes.compression),
                onOpenHistory: () => context.go(AppRoutes.history),
                onOpenStatistics: () => context.go(AppRoutes.statistics),
                onOpenSettings: () => context.go(AppRoutes.settings),
                onOpenBatch: () => context.push(AppRoutes.batch),
              ),
            ),
            GoRoute(
              path: AppRoutes.compression,
              builder: (BuildContext context, GoRouterState _) =>
                  compressionBuilder(context),
            ),
            GoRoute(
              path: AppRoutes.history,
              builder: (BuildContext context, GoRouterState _) => HistoryScreen(
                history: dependencies.history,
                onOpenCompression: () => context.go(AppRoutes.compression),
              ),
            ),
            GoRoute(
              path: AppRoutes.statistics,
              builder: (BuildContext context, GoRouterState _) => HistoryScreen(
                history: dependencies.history,
                initialTab: 1,
                onOpenCompression: () => context.go(AppRoutes.compression),
              ),
            ),
            GoRoute(
              path: AppRoutes.settings,
              builder: (BuildContext context, GoRouterState _) =>
                  SettingsScreen(controller: dependencies.settingsController),
            ),
            GoRoute(
              path: AppRoutes.benchmark,
              builder: (BuildContext context, GoRouterState _) =>
                  BenchmarkScreen(
                    pickerGateway: dependencies.imagePickerGateway,
                    compressionGateway: dependencies.imageCompressionGateway,
                    timer: dependencies.benchmarkTimer,
                  ),
            ),
            GoRoute(
              path: AppRoutes.about,
              builder: (BuildContext context, GoRouterState _) =>
                  const AboutScreen(),
            ),
          ],
        ),
        GoRoute(
          path: AppRoutes.batch,
          builder: (BuildContext context, GoRouterState _) =>
              BatchCompressionScreen(controller: dependencies.batchCompression),
        ),
      ],
    );
  }
}
