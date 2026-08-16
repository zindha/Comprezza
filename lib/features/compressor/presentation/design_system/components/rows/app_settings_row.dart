import 'package:flutter/material.dart';

/// Tinted rounded icon container used by settings-style rows and section
/// headers for a coherent icon language.
///
/// Defaults to a quiet neutral chip (surface + hairline border) so rows stay
/// calm; a [tone] is only passed for semantic rows (destructive, success).
class AppIconBox extends StatelessWidget {
  /// Creates an icon container.
  const AppIconBox({required this.icon, this.tone, super.key});

  /// Leading icon.
  final IconData icon;

  /// Optional icon box tint override.
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final Color background =
        tone ?? colors.surfaceContainerHighest.withValues(alpha: .35);
    final Color foreground = tone ?? colors.onSurfaceVariant;
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: .45)),
      ),
      child: Icon(icon, size: 20, color: foreground),
    );
  }
}

/// One settings-style row: icon, title/description column, optional trailing
/// control, and optional tap handling.
///
/// Shared by Settings, About, and any future control center so every screen
/// speaks the same row language: hierarchy through weight, never through
/// making every label bold.
class AppSettingsRow extends StatelessWidget {
  /// Creates a settings-style row.
  const AppSettingsRow({
    required this.icon,
    required this.title,
    this.description,
    this.trailing,
    this.tone,
    this.onTap,
    super.key,
  });

  /// Leading icon.
  final IconData icon;

  /// Row title.
  final String title;

  /// Optional supporting description.
  final String? description;

  /// Optional trailing control or value.
  final Widget? trailing;

  /// Optional content tint (for example destructive rows).
  final Color? tone;

  /// Optional tap handler.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final Color contentColor = tone ?? colors.onSurface;
    final Widget row = Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: <Widget>[
          AppIconBox(icon: icon, tone: tone),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: contentColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (description != null) ...<Widget>[
                  const SizedBox(height: 2),
                  Text(
                    description!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                      height: 1.35,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...<Widget>[
            const SizedBox(width: 12),
            // Flexible lets the trailing value pill shrink (and ellipsize)
            // instead of overflowing on narrow screens at large text scales.
            Flexible(child: trailing!),
          ],
        ],
      ),
    );
    if (onTap == null) return row;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: row,
      ),
    );
  }
}
