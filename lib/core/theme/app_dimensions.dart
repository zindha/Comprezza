import 'package:flutter/material.dart';

/// Centralized spacing and common component dimensions.
abstract final class AppDimensions {
  /// Small spacing unit.
  static const double spacingXs = 4;

  /// Small spacing.
  static const double spacingSm = 8;

  /// Medium spacing.
  static const double spacingMd = 16;

  /// Named medium padding token for component APIs.
  static const double paddingMedium = spacingMd;

  /// Large spacing.
  static const double spacingLg = 24;

  /// Extra-large spacing.
  static const double spacingXl = 32;

  /// Double-extra-large spacing.
  static const double spacingXxl = 48;

  /// Standard page horizontal padding for fixed-width layouts.
  static const EdgeInsets pagePadding = EdgeInsets.symmetric(
    horizontal: spacingLg,
  );

  /// Returns the shared page gutter for the available content width.
  ///
  /// Phones stay calm at 16dp, tablets gain 24dp, and wide layouts use 32dp.
  /// Keeping this decision in one token prevents each screen from inventing
  /// its own outer padding and makes the Android shell feel aligned.
  static double pageHorizontal(double width) {
    if (width >= maxWideContentWidth) return spacingXl;
    if (width >= navigationRailBreakpoint) return spacingLg;
    return spacingMd;
  }

  /// Returns consistent outer page insets without adding system-bar padding.
  ///
  /// System insets are owned by the shell/AppBar/NavigationBar. Scrollable
  /// destinations should use this for content rhythm, not a second SafeArea.
  static EdgeInsets pageInsets(
    double width, {
    double top = spacingMd,
    double bottom = spacingXl,
  }) => EdgeInsets.fromLTRB(
    pageHorizontal(width),
    top,
    pageHorizontal(width),
    bottom,
  );

  /// Minimum recommended interactive control height.
  static const double minInteractiveHeight = 48;

  /// Maximum content width for tablet-friendly layouts.
  static const double maxContentWidth = 720;

  /// Width at which persistent navigation moves to a rail.
  static const double navigationRailBreakpoint = 840;

  /// Maximum width for dashboard and wide-screen content.
  static const double maxWideContentWidth = 1200;

  /// Minimum hero surface height.
  static const double heroMinHeight = 260;

  /// Hero illustration diameter.
  static const double heroVisualSize = 148;
}
