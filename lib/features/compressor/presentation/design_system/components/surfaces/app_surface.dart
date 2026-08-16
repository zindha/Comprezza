import 'package:flutter/material.dart';

import '../../tokens/tokens.dart';

/// A quiet tonal surface: hairline border, no elevation.
///
/// Preferred over elevated cards for metrics, metadata rows, and secondary
/// groupings, where shadow-card soup reads as generic Material. Pairs with
/// [AppCard] for the few surfaces that genuinely need elevation.
class AppSurface extends StatelessWidget {
  /// Creates a tonal surface.
  const AppSurface({
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.radius = AppRadii.md,
    this.color,
    super.key,
  });

  /// Content rendered inside the padding.
  final Widget child;

  /// Inner padding; defaults to the compact card inset.
  final EdgeInsetsGeometry padding;

  /// Corner radius; defaults to the restrained medium radius.
  final double radius;

  /// Fill color; defaults to transparent so groups read as quiet, hairline-
  /// outlined sections rather than floating cards. Pass a semantic container
  /// (e.g. an error tint) to keep state color while staying flat.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: .4)),
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}
