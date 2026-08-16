import 'package:flutter/material.dart';

import '../../../../../../core/constants/app_assets.dart';
import '../../../../../../core/theme/app_brand_colors.dart';
import '../../tokens/tokens.dart';

/// The Comprezza brand mark: the product glyph rendered from the bundled app
/// icon. Shared by the navigation shell, home dashboard, and about screens so
/// the identity never drifts between copies. Falls back to a composed
/// compression glyph on a brand gradient if the asset cannot be loaded.
class AppBrandMark extends StatelessWidget {
  /// Creates a brand mark.
  const AppBrandMark({
    this.size = AppIconSizes.lg,
    this.radius,
    this.wordmark,
    super.key,
  });

  /// Square size of the glyph.
  final double size;

  /// Corner radius override used by the fallback glyph; defaults to ~30% of
  /// [size].
  final double? radius;

  /// Optional wordmark text rendered next to the glyph.
  final String? wordmark;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final Widget glyph = Image.asset(
      AppAssets.logo,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (BuildContext context, Object error, StackTrace? stack) =>
          _fallbackGlyph(colors),
    );
    if (wordmark == null) return glyph;
    // Scale the whole mark down rather than overflow when large system text
    // pushes the wordmark past the app-bar title bounds.
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          glyph,
          const SizedBox(width: AppSpacing.sm),
          Text(
            wordmark!,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _fallbackGlyph(ColorScheme colors) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[
          AppBrandColors.ink,
          AppBrandColors.primary,
          AppBrandColors.cyan,
        ],
      ),
      borderRadius: BorderRadius.circular(radius ?? size * .3),
      boxShadow: <BoxShadow>[
        BoxShadow(
          color: const Color(0x1F0B1226),
          blurRadius: size * .5,
          offset: Offset(0, size * .18),
        ),
      ],
    ),
    child: Icon(Icons.compress_rounded, size: size * .56, color: Colors.white),
  );
}
