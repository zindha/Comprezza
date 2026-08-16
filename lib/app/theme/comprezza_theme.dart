import 'package:flutter/material.dart';

/// Comprezza brand surfaces and typographic roles carried through the theme.
///
/// Registered by [AppThemeBuilder] so design-system components and screens can
/// read brand hairline, metric type, and the single quiet brand gradient from
/// one place instead of inventing colors per widget.
@immutable
class ComprezzaTheme extends ThemeExtension<ComprezzaTheme> {
  /// Creates a brand theme extension.
  const ComprezzaTheme({
    required this.hairline,
    required this.metricStyle,
    required this.metricSmallStyle,
    required this.brandGradientStart,
    required this.brandGradientEnd,
    required this.heroSurface,
  });

  /// Subtle border color for elevated surfaces (cards, sheets, pills).
  final Color hairline;

  /// Large metric text style (tabular figures) for headline numbers.
  final TextStyle metricStyle;

  /// Compact metric text style (tabular figures) for row-level numbers.
  final TextStyle metricSmallStyle;

  /// Quiet brand gradient start; used only for the brand mark and hero moments.
  final Color brandGradientStart;

  /// Quiet brand gradient end; used only for the brand mark and hero moments.
  final Color brandGradientEnd;

  /// Tint used behind hero content when a filled hero surface is needed.
  final Color heroSurface;

  /// Resolves the extension or falls back to sensible theme-derived values.
  static ComprezzaTheme of(BuildContext context) {
    final ComprezzaTheme? extension = Theme.of(
      context,
    ).extension<ComprezzaTheme>();
    if (extension != null) return extension;
    final TextTheme textTheme = Theme.of(context).textTheme;
    return ComprezzaTheme(
      hairline: Theme.of(context).colorScheme.outlineVariant,
      metricStyle: textTheme.headlineMedium!,
      metricSmallStyle: textTheme.titleMedium!,
      brandGradientStart: Theme.of(context).colorScheme.primary,
      brandGradientEnd: Theme.of(context).colorScheme.tertiary,
      heroSurface: Theme.of(context).colorScheme.primaryContainer,
    );
  }

  @override
  ComprezzaTheme copyWith({
    Color? hairline,
    TextStyle? metricStyle,
    TextStyle? metricSmallStyle,
    Color? brandGradientStart,
    Color? brandGradientEnd,
    Color? heroSurface,
  }) => ComprezzaTheme(
    hairline: hairline ?? this.hairline,
    metricStyle: metricStyle ?? this.metricStyle,
    metricSmallStyle: metricSmallStyle ?? this.metricSmallStyle,
    brandGradientStart: brandGradientStart ?? this.brandGradientStart,
    brandGradientEnd: brandGradientEnd ?? this.brandGradientEnd,
    heroSurface: heroSurface ?? this.heroSurface,
  );

  @override
  ComprezzaTheme lerp(ComprezzaTheme? other, double t) {
    if (other is! ComprezzaTheme) return this;
    return ComprezzaTheme(
      hairline: Color.lerp(hairline, other.hairline, t)!,
      metricStyle: TextStyle.lerp(metricStyle, other.metricStyle, t)!,
      metricSmallStyle: TextStyle.lerp(
        metricSmallStyle,
        other.metricSmallStyle,
        t,
      )!,
      brandGradientStart: Color.lerp(
        brandGradientStart,
        other.brandGradientStart,
        t,
      )!,
      brandGradientEnd: Color.lerp(
        brandGradientEnd,
        other.brandGradientEnd,
        t,
      )!,
      heroSurface: Color.lerp(heroSurface, other.heroSurface, t)!,
    );
  }
}
