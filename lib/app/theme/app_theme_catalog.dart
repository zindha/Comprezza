import 'package:flutter/material.dart';

import 'app_theme_mode.dart';

/// Maps the user's theme-mode preference to a [ThemeMode].
///
/// The active themes are hand-tuned by `AppThemeBuilder` (midnight navy /
/// electric blue / cyan). This catalog deliberately constructs no palette of
/// its own: the Comprezza brand is the single visual authority, and there is
/// no seed-based or Material You theme family.
abstract final class AppThemeCatalog {
  /// Returns the appropriate theme mode for [mode].
  static ThemeMode toFlutterThemeMode(AppThemeMode mode) {
    return switch (mode) {
      AppThemeMode.system => ThemeMode.system,
      AppThemeMode.light => ThemeMode.light,
      AppThemeMode.dark => ThemeMode.dark,
    };
  }
}
