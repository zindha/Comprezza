import 'package:flutter/foundation.dart';

import 'app_theme_mode.dart';

/// Holds the user-selected theme mode independently from feature state.
class ThemeModeController extends ChangeNotifier {
  /// Creates a theme mode controller.
  ThemeModeController({AppThemeMode initialMode = AppThemeMode.system})
    : _mode = initialMode;

  AppThemeMode _mode;

  /// Current user-selected mode.
  AppThemeMode get mode => _mode;

  /// Updates the selected mode.
  void setMode(AppThemeMode mode) {
    if (_mode == mode) return;
    _mode = mode;
    notifyListeners();
  }
}
