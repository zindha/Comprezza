import 'package:flutter/material.dart';

/// Comprezza brand color tokens — the single source of truth for color.
///
/// The app icon is the visual authority: midnight navy, electric blue, and
/// cyan on a cool off-white. There is deliberately no purple, lavender, or
/// periwinkle anywhere in this palette.
abstract final class AppBrandColors {
  /// Midnight navy — the darkest brand ink. Dark canvas, light-mode text.
  static const Color ink = Color(0xFF0B1226);

  /// Elevated dark surface (one step above [ink]).
  static const Color navySurface = Color(0xFF111A33);

  /// Muted dark container used for secondary fills on dark surfaces.
  static const Color navyMuted = Color(0xFF1A2340);

  /// Electric blue — the primary interaction color.
  static const Color primary = Color(0xFF2563EB);

  /// Electric blue tuned for readability on dark navy surfaces.
  static const Color primaryDark = Color(0xFF6EA8FF);

  /// Cyan — the accent color for savings, success, and the compare handle.
  static const Color cyan = Color(0xFF45E4F7);

  /// Deep cyan used where the bright accent needs text-level contrast on light.
  static const Color cyanDark = Color(0xFF0E7490);

  /// Cool off-white — the light-mode canvas.
  static const Color paper = Color(0xFFF6F7FB);

  /// Light elevated surface.
  static const Color paperElevated = Color(0xFFFFFFFF);

  /// Dark slate — text and neutrals.
  static const Color slate = Color(0xFF2A3140);

  /// Light slate — cool grey containers and hairlines on light surfaces.
  static const Color lightSlate = Color(0xFFE8EBF2);

  /// Cool steel-blue support color for secondary actions and surfaces.
  static const Color secondary = Color(0xFF5B7DB1);

  /// Cyan accent alias, kept for existing call sites that read [accent].
  static const Color accent = cyan;

  /// Success state green.
  static const Color success = Color(0xFF39AA8E);

  /// Error state red.
  static const Color error = Color(0xFFEF4444);

  /// Informational state blue.
  static const Color info = primary;

  /// Warning state amber (used only where semantically necessary).
  static const Color warning = Color(0xFFF59E0B);
}
