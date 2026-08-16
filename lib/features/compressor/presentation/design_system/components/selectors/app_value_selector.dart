import 'package:flutter/material.dart';

import '../../tokens/tokens.dart';

/// One selectable value inside an [AppValueSelector].
class AppValueOption<T> {
  /// Creates an option.
  const AppValueOption({
    required this.value,
    required this.label,
    this.description,
  });

  /// Backing value.
  final T value;

  /// Display label.
  final String label;

  /// Optional supporting description.
  final String? description;
}

/// A premium value control: a tappable pill that shows the current selection
/// and opens a modal bottom sheet listing every option.
///
/// Replaces default-looking dropdowns so settings read like a curated control
/// center rather than a form.
class AppValueSelector<T> extends StatelessWidget {
  /// Creates a value selector.
  const AppValueSelector({
    required this.value,
    required this.options,
    required this.title,
    required this.onSelected,
    this.subtitle,
    this.icon,
    this.maxWidth = 220,
    super.key,
  });

  /// Currently selected value.
  final T value;

  /// All selectable options.
  final List<AppValueOption<T>> options;

  /// Sheet title shown above the option list.
  final String title;

  /// Sheet subtitle shown under the title.
  final String? subtitle;

  /// Optional leading icon in the sheet header.
  final IconData? icon;

  /// Called with the picked value.
  final ValueChanged<T> onSelected;

  /// Maximum pill width before text truncates.
  final double maxWidth;

  Future<void> _open(BuildContext context) async {
    final T? selected = await showModalBottomSheet<T>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
      builder: (BuildContext context) => _AppValueSheet<T>(
        title: title,
        subtitle: subtitle,
        icon: icon,
        options: options,
        selected: value,
      ),
    );
    if (selected != null) onSelected(selected);
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final AppValueOption<T> current = options.firstWhere(
      (AppValueOption<T> option) => option.value == value,
      orElse: () => options.first,
    );
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _open(context),
          borderRadius: BorderRadius.circular(AppRadii.sm),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest.withValues(alpha: .55),
              borderRadius: BorderRadius.circular(AppRadii.sm),
              border: Border.all(
                color: colors.outlineVariant.withValues(alpha: .7),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Flexible(
                  child: Text(
                    current.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: colors.primary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AppValueSheet<T> extends StatelessWidget {
  const _AppValueSheet({
    required this.title,
    required this.options,
    required this.selected,
    this.subtitle,
    this.icon,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final List<AppValueOption<T>> options;
  final T selected;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final ThemeData theme = Theme.of(context);
    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (icon != null) ...<Widget>[
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerHighest.withValues(
                        alpha: .4,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colors.outlineVariant.withValues(alpha: .45),
                      ),
                    ),
                    child: Icon(icon, size: 20, color: colors.onSurfaceVariant),
                  ),
                  const SizedBox(height: 12),
                ],
                Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (subtitle != null) ...<Widget>[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.only(bottom: 16),
              children: options
                  .map((AppValueOption<T> option) {
                    final bool isSelected = option.value == selected;
                    return ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadii.sm),
                      ),
                      selected: isSelected,
                      selectedTileColor: colors.surfaceContainerHighest
                          .withValues(alpha: .4),
                      leading: Icon(
                        isSelected
                            ? Icons.radio_button_checked_rounded
                            : Icons.radio_button_off_rounded,
                        color: isSelected
                            ? colors.primary
                            : colors.outlineVariant,
                      ),
                      title: Text(
                        option.label,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                      subtitle: option.description == null
                          ? null
                          : Text(
                              option.description!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                      onTap: () => Navigator.of(context).pop(option.value),
                    );
                  })
                  .toList(growable: false),
            ),
          ),
        ],
      ),
    );
  }
}
