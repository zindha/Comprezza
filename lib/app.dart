import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' as intl;
import 'package:provider/provider.dart';

import 'app/di/app_dependencies.dart';
import 'app/di/app_provider_scope.dart';
import 'app/di/legacy_compressor_adapter.dart';
import 'app/localization/app_localization_config.dart';
import 'app/routing/app_router.dart';
import 'app/theme/app_theme_builder.dart';
import 'app/theme/app_theme_catalog.dart';
import 'app/theme/app_theme_mode.dart';
import 'app/theme/theme_mode_controller.dart';
import 'core/constants/app_constants.dart';
import 'features/compressor/domain/settings/settings_models.dart';
import 'l10n/app_localizations.dart';

/// Root widget that owns app-wide infrastructure composition.
class PhotoCompressorApp extends StatefulWidget {
  /// Creates the root application widget.
  const PhotoCompressorApp({required this.dependencies, super.key});

  /// Fully initialized application dependencies.
  final AppDependencies dependencies;

  @override
  State<PhotoCompressorApp> createState() => _PhotoCompressorAppState();
}

class _ScaledTextScaler implements TextScaler {
  const _ScaledTextScaler(this.base, this.multiplier);

  final TextScaler base;
  final double multiplier;

  @override
  double scale(double fontSize) => base.scale(fontSize) * multiplier;

  @override
  double get textScaleFactor => scale(14) / 14;

  @override
  TextScaler clamp({
    double minScaleFactor = 0,
    double maxScaleFactor = double.infinity,
  }) => _ScaledTextScaler(
    base.clamp(minScaleFactor: minScaleFactor, maxScaleFactor: maxScaleFactor),
    multiplier,
  );

  @override
  bool operator ==(Object other) =>
      other is _ScaledTextScaler &&
      other.base == base &&
      other.multiplier == multiplier;

  @override
  int get hashCode => Object.hash(base, multiplier);
}

class _PhotoCompressorAppState extends State<PhotoCompressorApp>
    with WidgetsBindingObserver {
  late final ThemeModeController _themeModeController;
  LegacyCompressorAdapter? _legacyCompressor;
  SettingsPreferences? _lastVisualPreferences;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Keep the global decoded-image cache bounded for low-memory devices. View
    // surfaces also provide cacheWidth/cacheHeight for display-sized decodes.
    final ImageCache imageCache = PaintingBinding.instance.imageCache;
    imageCache.maximumSize = 100;
    imageCache.maximumSizeBytes = 64 * 1024 * 1024;
    _themeModeController = ThemeModeController();
    _themeModeController.addListener(_onThemeChanged);
    _router = AppRouter.create(
      dependencies: widget.dependencies,
      compressionBuilder: _buildLegacyHome,
    );
    widget.dependencies.settingsController.addListener(_onSettingsChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Settings and cache cleanup are disk work. Start them only after the
      // first frame so cold-start rendering is not coupled to persistence I/O.
      unawaited(widget.dependencies.settingsController.load());
      unawaited(_runDeferredStartup());
    });
  }

  @override
  void didHaveMemoryPressure() {
    // Decoded image memory is native memory and may not promptly trigger Dart
    // GC pressure. Evict cached/live images so Android can reclaim it.
    final ImageCache imageCache = PaintingBinding.instance.imageCache;
    imageCache.clear();
    imageCache.clearLiveImages();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.dependencies.settingsController.removeListener(_onSettingsChanged);
    _themeModeController
      ..removeListener(_onThemeChanged)
      ..dispose();
    widget.dependencies.dispose();
    _router.dispose();
    super.dispose();
  }

  void _onThemeChanged() {
    if (mounted) setState(() {});
  }

  void _onSettingsChanged() {
    if (!mounted) return;
    final SettingsPreferences preferences =
        widget.dependencies.settingsController.state.preferences;
    final AppThemeMode mode = switch (preferences.theme) {
      SettingsTheme.system => AppThemeMode.system,
      SettingsTheme.light => AppThemeMode.light,
      SettingsTheme.dark => AppThemeMode.dark,
    };
    final bool modeChanged = _themeModeController.mode != mode;
    final SettingsPreferences? previous = _lastVisualPreferences;
    _lastVisualPreferences = preferences;
    if (modeChanged) {
      _themeModeController.setMode(mode);
      return;
    }
    if (mounted &&
        (previous == null || _visualSettingsChanged(previous, preferences))) {
      setState(() {});
    }
  }

  bool _visualSettingsChanged(
    SettingsPreferences previous,
    SettingsPreferences next,
  ) =>
      previous.highContrast != next.highContrast ||
      previous.compactUiMode != next.compactUiMode ||
      previous.largeUiMode != next.largeUiMode ||
      previous.colorBlindFriendlyPalette != next.colorBlindFriendlyPalette ||
      previous.largeTouchTargets != next.largeTouchTargets ||
      previous.reduceMotion != next.reduceMotion ||
      previous.reduceAnimations != next.reduceAnimations ||
      previous.fontScale != next.fontScale ||
      previous.displayDensity != next.displayDensity ||
      previous.dynamicTextScaling != next.dynamicTextScaling;

  Future<void> _runDeferredStartup() async {
    if (!mounted) return;
    final startupResult = await widget.dependencies.startup.initialize();
    if (!mounted) return;
    startupResult.fold(
      onSuccess: (_) {},
      onFailure: (error) => widget.dependencies.logger.error(
        'Deferred startup task failed.',
        cause: error,
        stackTrace: error.stackTrace,
        context: <String, Object?>{'code': error.code},
      ),
    );
    unawaited(_warmHistoryDestination());
  }

  /// Warms one-time, per-process costs that would otherwise land on the first
  /// history/insights tab switch: the history file read and intl date-symbol
  /// initialization (used by history cards). Both are cached after first use.
  Future<void> _warmHistoryDestination() async {
    await widget.dependencies.history.readAll();
    for (final Locale locale in AppLocalizationConfig.supportedLocales) {
      try {
        intl.DateFormat.yMMMd(locale.languageCode).format(DateTime.now());
      } catch (_) {
        // Best-effort: locale data initialization must never fail startup.
      }
    }
  }

  Widget _buildLegacyHome(BuildContext context) {
    final LegacyCompressorAdapter legacy = _legacyCompressor ??=
        widget.dependencies.legacyCompressor;
    return legacy.build(
      context,
      themeMode: _themeModeController.mode,
      onToggleTheme: () {
        _themeModeController.setMode(
          _themeModeController.mode == AppThemeMode.dark
              ? AppThemeMode.light
              : AppThemeMode.dark,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppProviderScope(
      dependencies: widget.dependencies,
      child: ChangeNotifierProvider<ThemeModeController>.value(
        value: _themeModeController,
        child: MaterialApp.router(
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,
          theme: AppThemeBuilder.light(
            highContrast: widget
                .dependencies
                .settingsController
                .state
                .preferences
                .highContrast,
            compact:
                widget
                    .dependencies
                    .settingsController
                    .state
                    .preferences
                    .compactUiMode ||
                widget
                        .dependencies
                        .settingsController
                        .state
                        .preferences
                        .displayDensity ==
                    SettingsDisplayDensity.compact,
            large: widget
                .dependencies
                .settingsController
                .state
                .preferences
                .largeUiMode,
            colorBlindFriendly: widget
                .dependencies
                .settingsController
                .state
                .preferences
                .colorBlindFriendlyPalette,
            largeTouchTargets: widget
                .dependencies
                .settingsController
                .state
                .preferences
                .largeTouchTargets,
          ),
          darkTheme: AppThemeBuilder.dark(
            highContrast: widget
                .dependencies
                .settingsController
                .state
                .preferences
                .highContrast,
            compact:
                widget
                    .dependencies
                    .settingsController
                    .state
                    .preferences
                    .compactUiMode ||
                widget
                        .dependencies
                        .settingsController
                        .state
                        .preferences
                        .displayDensity ==
                    SettingsDisplayDensity.compact,
            large: widget
                .dependencies
                .settingsController
                .state
                .preferences
                .largeUiMode,
            colorBlindFriendly: widget
                .dependencies
                .settingsController
                .state
                .preferences
                .colorBlindFriendlyPalette,
            largeTouchTargets: widget
                .dependencies
                .settingsController
                .state
                .preferences
                .largeTouchTargets,
          ),
          themeMode: AppThemeCatalog.toFlutterThemeMode(
            _themeModeController.mode,
          ),
          builder: (BuildContext context, Widget? child) {
            final SettingsPreferences preferences =
                widget.dependencies.settingsController.state.preferences;
            final MediaQueryData media = MediaQuery.of(context);
            return MediaQuery(
              data: media.copyWith(
                // Preserve the platform's nonlinear accessibility scaler. The
                // local preference is applied as a multiplier rather than
                // flattening the OS curve into a linear scaler.
                textScaler: _ScaledTextScaler(
                  media.textScaler,
                  preferences.dynamicTextScaling ? preferences.fontScale : 1,
                ),
                // Preserve the platform accessibility preference. App settings
                // can additionally disable animations, but must never turn an
                // OS-level reduced-motion request back off.
                disableAnimations:
                    media.disableAnimations ||
                    preferences.reduceMotion ||
                    preferences.reduceAnimations,
              ),
              child: child ?? const SizedBox.shrink(),
            );
          },
          routerConfig: _router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizationConfig.supportedLocales,
        ),
      ),
    );
  }
}
