import 'package:flutter/material.dart';

import '../../tokens/tokens.dart';

/// One preset offered by [AppPresetSelector].
class AppPresetOption {
  /// Creates a preset option.
  const AppPresetOption({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  /// Stable identity used for comparison.
  final String id;

  /// Preset name (e.g. "Balanced").
  final String title;

  /// Short supporting line (e.g. "The everyday default").
  final String subtitle;

  /// Leading glyph.
  final IconData icon;
}

/// A premium preset control: three quiet selectable surfaces instead of a row
/// of generic buttons. The selected preset receives a hairline brand border and
/// a subtle tonal fill; the others stay on the surface.
class AppPresetSelector extends StatelessWidget {
  /// Creates a preset selector.
  const AppPresetSelector({
    required this.options,
    required this.selectedId,
    required this.onSelected,
    super.key,
  });

  /// Available presets, in display order.
  final List<AppPresetOption> options;

  /// Currently selected preset id.
  final String selectedId;

  /// Called with the picked preset id.
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool wide = constraints.maxWidth >= 560;
        final List<Widget> tiles = <Widget>[
          for (final AppPresetOption option in options)
            _PresetTile(
              option: option,
              selected: option.id == selectedId,
              onTap: () => onSelected(option.id),
            ),
        ];
        if (wide) {
          return Row(
            children: <Widget>[
              for (int index = 0; index < tiles.length; index++) ...<Widget>[
                if (index > 0) const SizedBox(width: AppSpacing.sm),
                Expanded(child: tiles[index]),
              ],
            ],
          );
        }
        // The selector can live inside vertical scrollables, so the stacked
        // tiles must size themselves naturally instead of flexing on the
        // (unbounded) height axis.
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            for (int index = 0; index < tiles.length; index++) ...<Widget>[
              if (index > 0) const SizedBox(height: AppSpacing.sm),
              tiles[index],
            ],
          ],
        );
      },
    );
  }
}

class _PresetTile extends StatelessWidget {
  const _PresetTile({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final AppPresetOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final bool reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      selected: selected,
      button: true,
      label: '${option.title}. ${option.subtitle}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadii.medium,
          child: AnimatedContainer(
            duration: reduceMotion ? Duration.zero : AppAnimations.fast,
            curve: AppAnimations.standardCurve,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: selected ? colors.surfaceContainerLow : Colors.transparent,
              borderRadius: AppRadii.medium,
              border: Border.all(
                color: selected
                    ? colors.primary.withValues(alpha: .65)
                    : colors.outlineVariant.withValues(alpha: .45),
                width: selected ? 1.6 : 1,
              ),
            ),
            child: Row(
              children: <Widget>[
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: selected
                        ? colors.primary
                        : colors.surfaceContainerHighest.withValues(alpha: .5),
                    borderRadius: AppRadii.small,
                  ),
                  child: Icon(
                    option.icon,
                    size: AppIconSizes.sm + 2,
                    color: selected
                        ? colors.onPrimary
                        : colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        option.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: selected ? colors.primary : colors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        option.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: selected
                              ? colors.onSurfaceVariant
                              : colors.onSurfaceVariant.withValues(alpha: .8),
                        ),
                      ),
                    ],
                  ),
                ),
                if (selected) ...<Widget>[
                  const SizedBox(width: AppSpacing.xs),
                  Icon(
                    Icons.check_circle_rounded,
                    size: AppIconSizes.sm,
                    color: colors.primary,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
