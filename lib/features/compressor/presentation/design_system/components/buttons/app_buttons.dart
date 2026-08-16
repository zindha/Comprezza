import 'package:flutter/material.dart';

import '../../tokens/tokens.dart';
import '../icons/app_icons.dart';

/// Semantic button intent.
enum AppButtonTone {
  primary,
  secondary,
  outlined,
  text,
  danger,
  success,
  support,
}

/// A reusable Material 3 button with consistent touch target and loading state.
class AppButton extends StatelessWidget {
  const AppButton({
    required this.label,
    required this.onPressed,
    this.tone = AppButtonTone.primary,
    this.icon,
    this.loading = false,
    this.loadingLabel,
    this.expand = false,
    this.semanticLabel,
    super.key,
  });
  final String label;
  final VoidCallback? onPressed;
  final AppButtonTone tone;
  final IconData? icon;
  final bool loading;
  final String? loadingLabel;
  final bool expand;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final ButtonStyle style = _style(context, scheme);
    final Widget child = loading
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const SizedBox(
                width: AppIconSizes.sm,
                height: AppIconSizes.sm,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(loadingLabel ?? label, overflow: TextOverflow.ellipsis),
            ],
          )
        : Text(label, overflow: TextOverflow.ellipsis);
    final Widget button = icon == null
        ? _plainButton(loading ? null : onPressed, child, style)
        : switch (tone) {
            AppButtonTone.primary => FilledButton.icon(
              onPressed: loading ? null : onPressed,
              icon: Icon(icon),
              label: child,
              style: style,
            ),
            AppButtonTone.secondary => ElevatedButton.icon(
              onPressed: loading ? null : onPressed,
              icon: Icon(icon),
              label: child,
              style: style,
            ),
            AppButtonTone.outlined => OutlinedButton.icon(
              onPressed: loading ? null : onPressed,
              icon: Icon(icon),
              label: child,
              style: style,
            ),
            AppButtonTone.text => TextButton.icon(
              onPressed: loading ? null : onPressed,
              icon: Icon(icon),
              label: child,
              style: style,
            ),
            _ => _plainButton(loading ? null : onPressed, child, style),
          };
    final Widget accessibleButton = semanticLabel == null
        ? button
        : Semantics(label: semanticLabel, child: button);
    return expand
        ? SizedBox(width: double.infinity, child: accessibleButton)
        : accessibleButton;
  }

  Widget _plainButton(
    VoidCallback? callback,
    Widget child,
    ButtonStyle style,
  ) => switch (tone) {
    AppButtonTone.primary || AppButtonTone.success => FilledButton(
      onPressed: callback,
      style: style,
      child: child,
    ),
    AppButtonTone.secondary => ElevatedButton(
      onPressed: callback,
      style: style,
      child: child,
    ),
    AppButtonTone.outlined => OutlinedButton(
      onPressed: callback,
      style: style,
      child: child,
    ),
    AppButtonTone.text || AppButtonTone.support || AppButtonTone.danger =>
      TextButton(onPressed: callback, style: style, child: child),
  };

  ButtonStyle _style(BuildContext context, ColorScheme scheme) {
    final Color? foreground = switch (tone) {
      AppButtonTone.danger => scheme.onErrorContainer,
      AppButtonTone.success => scheme.onTertiaryContainer,
      AppButtonTone.support => scheme.onSecondaryContainer,
      _ => null,
    };
    final Color? background = switch (tone) {
      AppButtonTone.success => scheme.tertiaryContainer,
      AppButtonTone.danger => scheme.errorContainer,
      AppButtonTone.support => scheme.secondaryContainer,
      _ => null,
    };
    final Color pressedOverlay = switch (tone) {
      AppButtonTone.danger => scheme.error.withValues(alpha: .16),
      AppButtonTone.success => scheme.tertiary.withValues(alpha: .20),
      AppButtonTone.support => scheme.secondary.withValues(alpha: .20),
      _ => scheme.onSurface.withValues(alpha: .10),
    };
    return ButtonStyle(
      minimumSize: const WidgetStatePropertyAll<Size>(
        Size(0, AppSpacing.minTouchTarget),
      ),
      padding: const WidgetStatePropertyAll<EdgeInsetsGeometry>(
        EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
      ),
      shape: WidgetStatePropertyAll<RoundedRectangleBorder>(
        RoundedRectangleBorder(borderRadius: AppRadii.medium),
      ),
      foregroundColor: foreground == null
          ? null
          : WidgetStatePropertyAll<Color>(foreground),
      backgroundColor: background == null
          ? null
          : WidgetStatePropertyAll<Color>(background),
      overlayColor: WidgetStateProperty.resolveWith<Color?>(
        (Set<WidgetState> states) =>
            states.contains(WidgetState.pressed) ||
                states.contains(WidgetState.hovered)
            ? pressedOverlay
            : null,
      ),
      animationDuration: AppAnimations.fast,
      mouseCursor: WidgetStateProperty.resolveWith<MouseCursor?>(
        (Set<WidgetState> states) => states.contains(WidgetState.disabled)
            ? SystemMouseCursors.basic
            : SystemMouseCursors.click,
      ),
    );
  }
}

/// An icon-only accessible Material button.
class AppIconButton extends StatelessWidget {
  const AppIconButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.tone = AppButtonTone.text,
    this.size = AppIconSizes.md,
    super.key,
  });
  final AppIcon icon;
  final String label;
  final VoidCallback? onPressed;
  final AppButtonTone tone;
  final double size;

  @override
  Widget build(BuildContext context) {
    final Color? iconColor = switch (tone) {
      AppButtonTone.danger => Theme.of(context).colorScheme.error,
      AppButtonTone.success => Theme.of(context).colorScheme.tertiary,
      AppButtonTone.support => Theme.of(context).colorScheme.primary,
      _ => null,
    };
    return IconButton(
      onPressed: onPressed,
      icon: AppIcons.icon(icon, size: size, color: iconColor),
      tooltip: label,
      constraints: const BoxConstraints(
        minWidth: AppSpacing.minTouchTarget,
        minHeight: AppSpacing.minTouchTarget,
      ),
    );
  }
}
