import 'package:flutter/material.dart';

import '../../tokens/tokens.dart';
import '../icons/app_icons.dart';
import '../surfaces/app_surface.dart';

/// Base surface card with consistent shape, padding, and elevation.
class AppCard extends StatelessWidget {
  const AppCard({
    required this.child,
    this.onTap,
    this.padding = AppSpacing.card,
    this.elevation = AppElevation.none,
    this.color,
    this.semanticLabel,
    super.key,
  });
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final double elevation;
  final Color? color;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final Widget content = Padding(padding: padding, child: child);
    final Widget card = Card(
      elevation: elevation,
      color: color,
      clipBehavior: Clip.antiAlias,
      child: onTap == null
          ? content
          : InkWell(
              onTap: onTap,
              excludeFromSemantics: semanticLabel != null,
              hoverColor: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: .05),
              focusColor: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: .08),
              splashColor: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: .12),
              highlightColor: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: .06),
              child: content,
            ),
    );
    return semanticLabel == null
        ? card
        : Semantics(
            container: true,
            label: semanticLabel,
            button: onTap != null,
            child: card,
          );
  }
}

/// Information card with semantic state tone.
class AppInformationCard extends StatelessWidget {
  const AppInformationCard({
    required this.title,
    required this.message,
    this.tone = AppStateTone.info,
    this.icon,
    this.action,
    super.key,
  });
  final String title;
  final String message;
  final AppStateTone tone;
  final AppIcon? icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Color color = AppColors.stateForeground(scheme, tone);
    // Semantic state cards stay flat: a tonal fill keeps the state color while
    // avoiding the elevated-card look the rest of the app moved away from.
    return AppSurface(
      color: AppColors.stateContainer(scheme, tone),
      padding: AppSpacing.card,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          AppIcons.icon(
            icon ??
                switch (tone) {
                  AppStateTone.success => AppIcon.success,
                  AppStateTone.warning => AppIcon.warning,
                  AppStateTone.error => AppIcon.error,
                  AppStateTone.info => AppIcon.info,
                },
            color: color,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: AppTypography.subtitle(context).copyWith(color: color),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  message,
                  style: AppTypography.body(context).copyWith(color: color),
                ),
                if (action != null)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.md),
                    child: action,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AppErrorCard extends StatelessWidget {
  const AppErrorCard({
    required this.title,
    required this.message,
    this.action,
    super.key,
  });
  final String title;
  final String message;
  final Widget? action;
  @override
  Widget build(BuildContext context) => AppInformationCard(
    title: title,
    message: message,
    tone: AppStateTone.error,
    action: action,
  );
}
