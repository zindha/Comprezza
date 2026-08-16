import 'package:comprezza/app/theme/app_theme_builder.dart';
import 'package:comprezza/core/theme/app_brand_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('runtime themes preserve the Comprezza supporting hue family', () {
    final ThemeData light = AppThemeBuilder.light();
    final ThemeData dark = AppThemeBuilder.dark();

    expect(light.colorScheme.primary, isNot(equals(Colors.blue)));
    expect(
      light.colorScheme.secondary,
      isNot(equals(light.colorScheme.primary)),
    );
    expect(
      light.colorScheme.tertiary,
      isNot(equals(light.colorScheme.primary)),
    );
    expect(
      light.colorScheme.secondaryContainer,
      isNot(light.colorScheme.surface),
    );
    expect(
      dark.colorScheme.secondaryContainer,
      isNot(dark.colorScheme.surface),
    );
    expect(AppBrandColors.primary, isNot(AppBrandColors.secondary));
  });

  test('semantic color pairs retain readable contrast', () {
    for (final ThemeData theme in <ThemeData>[
      AppThemeBuilder.light(),
      AppThemeBuilder.dark(),
      AppThemeBuilder.light(highContrast: true),
      AppThemeBuilder.dark(highContrast: true),
      AppThemeBuilder.light(colorBlindFriendly: true),
      AppThemeBuilder.dark(colorBlindFriendly: true),
    ]) {
      final ColorScheme colors = theme.colorScheme;
      expect(
        _contrast(colors.onPrimaryContainer, colors.primaryContainer),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        _contrast(colors.onSecondaryContainer, colors.secondaryContainer),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        _contrast(colors.onTertiaryContainer, colors.tertiaryContainer),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        _contrast(colors.onErrorContainer, colors.errorContainer),
        greaterThanOrEqualTo(4.5),
      );
    }
  });

  test('dark theme keeps canvas and card surfaces tonally distinct', () {
    final ThemeData theme = AppThemeBuilder.dark();
    expect(theme.scaffoldBackgroundColor, isNot(theme.cardTheme.color));
    expect(
      theme.navigationBarTheme.backgroundColor,
      isNot(theme.scaffoldBackgroundColor),
    );
    expect(theme.cardTheme.shape, isNotNull);
  });
}

double _contrast(Color foreground, Color background) {
  final double foregroundLuminance = foreground.computeLuminance();
  final double backgroundLuminance = background.computeLuminance();
  final double lighter = foregroundLuminance > backgroundLuminance
      ? foregroundLuminance
      : backgroundLuminance;
  final double darker = foregroundLuminance > backgroundLuminance
      ? backgroundLuminance
      : foregroundLuminance;
  return (lighter + .05) / (darker + .05);
}
