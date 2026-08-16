import 'package:flutter/material.dart';

import '../../tokens/tokens.dart';

/// A designed empty state that tells a small story instead of stacking
/// icon → text → button mechanically.
///
/// The composition is a layered photo stack that shrinks toward the bottom
/// right — "photos becoming lighter" — plus an optional supporting panel that
/// frames the copy and primary action.
class AppStoryEmptyState extends StatelessWidget {
  /// Creates a storytelling empty state.
  const AppStoryEmptyState({
    required this.title,
    required this.message,
    this.action,
    this.secondaryAction,
    this.kicker,
    this.icon = Icons.compress_rounded,
    this.glyphSize = 104,
    this.compact = false,
    super.key,
  });

  /// Small uppercase kicker above the title.
  final String? kicker;

  /// Headline copy.
  final String title;

  /// Supporting message.
  final String message;

  /// Primary call-to-action.
  final Widget? action;

  /// Quiet secondary action (for example a text button).
  final Widget? secondaryAction;

  /// Glyph icon; defaults to the compression mark.
  final IconData icon;

  /// Diameter of the layered glyph stack.
  final double glyphSize;

  /// Tighter rhythm for secondary empty states so they read as a quiet note
  /// rather than a full-page moment.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final ThemeData theme = Theme.of(context);
    final double glyphGap = compact ? AppSpacing.sm : AppSpacing.lg;
    final double actionGap = compact ? AppSpacing.md : AppSpacing.lg;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Center(
          child: _LayeredGlyph(icon: icon, size: glyphSize),
        ),
        SizedBox(height: glyphGap),
        if (kicker != null) ...<Widget>[
          Center(
            child: Text(
              kicker!,
              style: AppTypography.eyebrow(
                context,
              ).copyWith(color: colors.primary),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
        ],
        Text(
          title,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -.3,
            height: 1.25,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ),
        if (action != null) ...<Widget>[
          SizedBox(height: actionGap),
          Center(child: action),
        ],
        if (secondaryAction != null) ...<Widget>[
          const SizedBox(height: AppSpacing.xs),
          Center(child: secondaryAction),
        ],
      ],
    );
  }
}

class _LayeredGlyph extends StatelessWidget {
  const _LayeredGlyph({required this.icon, required this.size});

  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    // The layered photo-stack glyph is decorative: the headline and message
    // above already describe the state in the active locale. Marking it
    // non-semantic avoids announcing a hardcoded English phrase to TalkBack.
    return ExcludeSemantics(
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          children: <Widget>[
            Positioned(
              left: 0,
              top: 0,
              child: _tile(
                size * .62,
                colors.primary.withValues(alpha: .14),
                radius: size * .2,
              ),
            ),
            Positioned(
              left: size * .19,
              top: size * .17,
              child: _tile(
                size * .56,
                colors.tertiary.withValues(alpha: .18),
                radius: size * .18,
              ),
            ),
            Positioned(
              left: size * .38,
              top: size * .34,
              child: _tile(
                size * .5,
                colors.primary,
                radius: size * .16,
                icon: icon,
                iconColor: colors.onPrimary,
              ),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: size * .28,
                height: size * .28,
                decoration: BoxDecoration(
                  color: colors.tertiary,
                  shape: BoxShape.circle,
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: colors.tertiary.withValues(alpha: .3),
                      blurRadius: size * .12,
                      offset: Offset(0, size * .05),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.arrow_downward_rounded,
                  size: size * .14,
                  color: colors.onTertiary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tile(
    double dimension,
    Color color, {
    required double radius,
    IconData? icon,
    Color? iconColor,
  }) => Container(
    width: dimension,
    height: dimension,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: Colors.white.withValues(alpha: .18)),
    ),
    child: icon == null
        ? null
        : Icon(icon, size: dimension * .42, color: iconColor),
  );
}
