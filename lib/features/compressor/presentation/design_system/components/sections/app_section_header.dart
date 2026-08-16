import 'package:flutter/material.dart';

import '../../tokens/tokens.dart';

/// A consistent, typographic section heading.
///
/// Titles carry the section voice at medium weight with tight tracking;
/// subtitles stay one step quieter so a page reads with clear hierarchy
/// instead of a row of equally bold labels. Optional [count] renders as a
/// quiet numeral pill; [action] sits right-aligned.
class AppSectionHeader extends StatelessWidget {
  /// Creates a section header.
  const AppSectionHeader({
    required this.title,
    this.subtitle,
    this.action,
    this.count,
    this.padding = EdgeInsets.zero,
    super.key,
  });

  /// Section title.
  final String title;

  /// Optional supporting caption.
  final String? subtitle;

  /// Optional trailing action (for example a text button).
  final Widget? action;

  /// Optional numeric count rendered as a quiet pill (e.g. history results).
  final int? count;

  /// Outer padding; defaults to none so callers own page rhythm.
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final Widget heading = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Flexible(
              child: Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -.2,
                  color: colors.onSurface,
                  height: 1.25,
                ),
              ),
            ),
            if (count != null) ...<Widget>[
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest.withValues(alpha: .7),
                  borderRadius: AppRadii.pillRadius,
                ),
                child: Text(
                  '$count',
                  style: AppTypography.tabular(
                    theme.textTheme.labelMedium!,
                  ).copyWith(color: colors.onSurfaceVariant),
                ),
              ),
            ],
          ],
        ),
        if (subtitle != null) ...<Widget>[
          const SizedBox(height: 3),
          Text(
            subtitle!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
              height: 1.4,
            ),
          ),
        ],
      ],
    );
    final Widget row = action == null
        ? heading
        : Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.xs,
            // spaceBetween keeps the action at the far edge on roomy lines
            // while still allowing it to drop below the heading when tight.
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[heading, action!],
          );
    return Padding(padding: padding, child: row);
  }
}
