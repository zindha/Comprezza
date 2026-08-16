import 'package:flutter/material.dart';

/// Canonical typography tokens — the single source of truth for type roles.
///
/// A restrained hierarchy: display and headline carry the page voice at 700,
/// titles sit at 600, body reads at 400, and labels at 500. Nothing is set to
/// 800 by default — heavy weight is reserved for the metric roles so savings
/// and file sizes read as the strongest moment on a screen. Numeric roles use
/// tabular figures so counters and file sizes never jitter while animating.
abstract final class AppTypography {
  /// Applies [FontFeature.tabularFigures] so numeric values align column-wise.
  static TextStyle tabular(TextStyle? style) =>
      (style ?? const TextStyle()).copyWith(
        fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
      );

  /// Builds the refined Material 3 text theme.
  static TextTheme textTheme(Brightness brightness) {
    final TextTheme base = ThemeData(
      brightness: brightness,
      useMaterial3: true,
    ).textTheme;
    return base.copyWith(
      displayLarge: base.displayLarge?.copyWith(
        fontSize: 57,
        height: 1.1,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.2,
      ),
      displayMedium: base.displayMedium?.copyWith(
        fontSize: 45,
        height: 1.14,
        fontWeight: FontWeight.w700,
        letterSpacing: -.8,
      ),
      displaySmall: base.displaySmall?.copyWith(
        fontSize: 36,
        height: 1.18,
        fontWeight: FontWeight.w700,
        letterSpacing: -.6,
      ),
      headlineLarge: base.headlineLarge?.copyWith(
        fontSize: 32,
        height: 1.22,
        fontWeight: FontWeight.w700,
        letterSpacing: -.4,
      ),
      headlineMedium: base.headlineMedium?.copyWith(
        fontSize: 28,
        height: 1.26,
        fontWeight: FontWeight.w700,
        letterSpacing: -.35,
      ),
      headlineSmall: base.headlineSmall?.copyWith(
        fontSize: 24,
        height: 1.3,
        fontWeight: FontWeight.w600,
        letterSpacing: -.25,
      ),
      titleLarge: base.titleLarge?.copyWith(
        fontSize: 22,
        height: 1.3,
        fontWeight: FontWeight.w600,
        letterSpacing: -.1,
      ),
      titleMedium: base.titleMedium?.copyWith(
        fontSize: 16,
        height: 1.4,
        fontWeight: FontWeight.w600,
        letterSpacing: .15,
      ),
      titleSmall: base.titleSmall?.copyWith(
        fontSize: 14,
        height: 1.4,
        fontWeight: FontWeight.w600,
        letterSpacing: .1,
      ),
      bodyLarge: base.bodyLarge?.copyWith(
        fontSize: 16,
        height: 1.55,
        fontWeight: FontWeight.w400,
        letterSpacing: .3,
      ),
      bodyMedium: base.bodyMedium?.copyWith(
        fontSize: 14,
        height: 1.5,
        fontWeight: FontWeight.w400,
        letterSpacing: .2,
      ),
      bodySmall: base.bodySmall?.copyWith(
        fontSize: 12,
        height: 1.45,
        fontWeight: FontWeight.w400,
        letterSpacing: .3,
      ),
      labelLarge: base.labelLarge?.copyWith(
        fontSize: 14,
        height: 1.4,
        fontWeight: FontWeight.w500,
        letterSpacing: .2,
      ),
      labelMedium: base.labelMedium?.copyWith(
        fontSize: 12,
        height: 1.4,
        fontWeight: FontWeight.w500,
        letterSpacing: .5,
      ),
      labelSmall: base.labelSmall?.copyWith(
        fontSize: 11,
        height: 1.4,
        fontWeight: FontWeight.w500,
        letterSpacing: .5,
      ),
    );
  }

  // ---- Context-based role helpers -----------------------------------------
  // These read the active TextTheme so components and screens resolve type
  // through one canonical API instead of inventing sizes per widget.

  /// Page-level display role.
  static TextStyle display(BuildContext context) =>
      Theme.of(context).textTheme.displaySmall!;

  /// Section headline role.
  static TextStyle headline(BuildContext context) =>
      Theme.of(context).textTheme.headlineSmall!;

  /// Primary title role.
  static TextStyle title(BuildContext context) =>
      Theme.of(context).textTheme.titleLarge!;

  /// Subtitle role for card/row headings.
  static TextStyle subtitle(BuildContext context) =>
      Theme.of(context).textTheme.titleMedium!;

  /// Body role.
  static TextStyle body(BuildContext context) =>
      Theme.of(context).textTheme.bodyLarge!;

  /// Interactive label role.
  static TextStyle label(BuildContext context) =>
      Theme.of(context).textTheme.labelLarge!;

  /// Quiet supporting text.
  static TextStyle caption(BuildContext context) =>
      Theme.of(context).textTheme.bodySmall!;

  /// Large numeric value (savings, sizes) with tabular figures.
  static TextStyle metric(BuildContext context) =>
      tabular(Theme.of(context).textTheme.headlineMedium!);

  /// Compact numeric value for row-level metrics.
  static TextStyle metricSmall(BuildContext context) =>
      tabular(Theme.of(context).textTheme.titleMedium!);

  /// Eyebrow/kicker text — quiet, uppercase, letter-spaced.
  static TextStyle eyebrow(BuildContext context) => Theme.of(context)
      .textTheme
      .labelSmall!
      .copyWith(fontWeight: FontWeight.w700, letterSpacing: 1.4);
}
