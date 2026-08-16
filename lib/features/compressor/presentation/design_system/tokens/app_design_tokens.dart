import 'package:flutter/material.dart';

import '../../../../../core/theme/app_brand_colors.dart';

/// Brand and semantic colors used by reusable components.
abstract final class AppColors {
  static const Color primary = AppBrandColors.primary;
  static const Color secondary = AppBrandColors.secondary;
  static const Color accent = AppBrandColors.accent;
  static const Color success = AppBrandColors.success;
  static const Color warning = AppBrandColors.warning;
  static const Color danger = AppBrandColors.error;
  static const Color info = AppBrandColors.info;

  /// Returns a contrast-safe semantic surface derived from the state hue.
  ///
  /// Success and warning intentionally do not reuse the brand's secondary and
  /// tertiary roles: those roles are steel-blue/cyan in Comprezza. A
  /// state-specific tonal palette keeps feedback recognisable while preserving
  /// readable foreground/container pairs in both light and dark themes.
  static Color stateContainer(ColorScheme scheme, AppStateTone tone) =>
      _stateScheme(scheme, tone).primaryContainer;

  /// Returns the foreground paired with [stateContainer].
  static Color stateForeground(ColorScheme scheme, AppStateTone tone) =>
      _stateScheme(scheme, tone).onPrimaryContainer;

  static ColorScheme _stateScheme(ColorScheme scheme, AppStateTone tone) {
    final Color seed = switch (tone) {
      AppStateTone.success => success,
      AppStateTone.warning => warning,
      AppStateTone.error => danger,
      AppStateTone.info => info,
    };
    return ColorScheme.fromSeed(seedColor: seed, brightness: scheme.brightness);
  }
}

enum AppStateTone { success, warning, error, info }

/// Consistent spacing and component dimensions.
abstract final class AppSpacing {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
  static const double xxxl = 64;
  static const double minTouchTarget = 48;
  static const double controlHeight = 52;
  static const double sectionGap = 20;
  static const double compactControlHeight = 44;
  static const double maxContentWidth = 720;
  static const double maxWideContentWidth = 1200;

  static const EdgeInsets page = EdgeInsets.symmetric(
    horizontal: lg,
    vertical: md,
  );
  static const EdgeInsets card = EdgeInsets.all(lg);
  static const EdgeInsets compactCard = EdgeInsets.all(md);
}

/// Shape tokens for controls and surfaces.
abstract final class AppRadii {
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double pill = 999;

  static final BorderRadius small = BorderRadius.circular(sm);
  static final BorderRadius medium = BorderRadius.circular(md);
  static final BorderRadius large = BorderRadius.circular(lg);
  static final BorderRadius extraLarge = BorderRadius.circular(xl);
  static final BorderRadius pillRadius = BorderRadius.circular(pill);
}

/// Typography is canonical in `core/theme/app_typography.dart` (re-exported via
/// `tokens.dart`); this file keeps only component-layer tokens.

/// Material surface elevation roles.
abstract final class AppElevation {
  static const double none = 0;
  static const double low = 1;
  static const double medium = 3;
  static const double high = 6;
}

/// Motion tokens used by design-system animations.
abstract final class AppAnimations {
  /// Standard enter/exit easing — snappy but not mechanical.
  static const Curve standardCurve = Curves.easeOutCubic;

  /// Emphasized M3 easing for large surfaces and hero entrances.
  static const Curve emphasizedCurve = Curves.easeInOutCubicEmphasized;

  static const Duration fast = Duration(milliseconds: 140);
  static const Duration standard = Duration(milliseconds: 260);
  static const Duration expressive = Duration(milliseconds: 420);
}

/// Backwards-compatible duration role names for component APIs.
abstract final class AppDurations {
  static const Duration fast = AppAnimations.fast;
  static const Duration standard = AppAnimations.standard;
  static const Duration expressive = AppAnimations.expressive;
}

/// Standard icon sizes.
abstract final class AppIconSizes {
  static const double xs = 16;
  static const double sm = 20;
  static const double md = 24;
  static const double lg = 32;
  static const double xl = 48;
  static const double hero = 72;
}

/// Responsive width thresholds.
abstract final class AppBreakpoints {
  static const double phone = 600;
  static const double tablet = 840;
  static const double large = 1200;
  static const double largeTextScale = 1.15;

  static AppBreakpoint fromWidth(double width) {
    if (width >= large) return AppBreakpoint.large;
    if (width >= tablet) return AppBreakpoint.tablet;
    return AppBreakpoint.phone;
  }
}

enum AppBreakpoint { phone, tablet, large }

/// Reusable shadows. Color is intentionally blended at render time by surfaces.
abstract final class AppShadows {
  static List<BoxShadow> subtle(Color color) => <BoxShadow>[
    BoxShadow(
      color: color.withValues(alpha: .10),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: color.withValues(alpha: .06),
      blurRadius: 4,
      offset: const Offset(0, 1),
    ),
  ];

  static List<BoxShadow> prominent(Color color) => <BoxShadow>[
    BoxShadow(
      color: color.withValues(alpha: .16),
      blurRadius: 32,
      offset: const Offset(0, 12),
    ),
    BoxShadow(
      color: color.withValues(alpha: .08),
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
  ];
}
