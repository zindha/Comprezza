import 'dart:ui';

/// Central localization policy for the application.
abstract final class AppLocalizationConfig {
  /// Locales currently shipped with the application.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hi'),
  ];

  /// Resolves a supported locale, falling back to English.
  static Locale resolve(Locale? requested) {
    if (requested == null) return supportedLocales.first;
    return supportedLocales.firstWhere(
      (Locale supported) => supported.languageCode == requested.languageCode,
      orElse: () => supportedLocales.first,
    );
  }
}
