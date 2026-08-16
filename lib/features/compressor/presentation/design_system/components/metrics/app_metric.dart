import 'package:flutter/material.dart';

import '../../tokens/tokens.dart';

/// A label + value pair with tabular figures, used for file sizes, savings,
/// and counts. Optional [accent] draws the value in a semantic color; [large]
/// switches to the display metric size.
class AppMetric extends StatelessWidget {
  /// Creates a metric.
  const AppMetric({
    required this.label,
    required this.value,
    this.accent,
    this.large = false,
    this.icon,
    this.align = CrossAxisAlignment.start,
    super.key,
  });

  /// Metric label (e.g. "Estimated output").
  final String label;

  /// Metric value (e.g. "2.4 MB" or "64%").
  final String value;

  /// Optional accent color for the value (success, primary, etc.).
  final Color? accent;

  /// Renders the value at display size for headline metrics.
  final bool large;

  /// Optional leading icon shown above the value.
  final IconData? icon;

  /// Horizontal alignment of the metric column.
  final CrossAxisAlignment align;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final Color valueColor = accent ?? colors.onSurface;
    final TextStyle style = large
        ? AppTypography.metric(context).copyWith(color: valueColor)
        : AppTypography.metricSmall(context).copyWith(color: valueColor);
    return Column(
      crossAxisAlignment: align,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (icon != null) ...<Widget>[
          Icon(icon!, size: AppIconSizes.sm + 2, color: colors.primary),
          const SizedBox(height: AppSpacing.xs),
        ],
        Text(value, style: style, maxLines: 1, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 2),
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: colors.onSurfaceVariant,
            height: 1.3,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
