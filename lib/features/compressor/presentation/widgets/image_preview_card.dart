import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../core/utils/file_size_formatter.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/compression_models.dart';
import '../design_system/design_system.dart';

/// Displays a photo preview and its size/resolution metadata.
class ImagePreviewCard extends StatelessWidget {
  /// Creates a preview card.
  const ImagePreviewCard({
    required this.label,
    required this.asset,
    this.isCompressed = false,
    this.savingsPercent,
    super.key,
  });

  /// The preview label.
  final String label;

  /// The metadata to display.
  final PhotoAsset asset;

  /// Whether this is the compressed result style.
  final bool isCompressed;

  /// When set (compressed previews), shows a savings ring and a delta pill.
  final int? savingsPercent;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return RepaintBoundary(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: .2,
                  ),
                ),
              ),
              if (savingsPercent != null) ...<Widget>[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: colors.tertiaryContainer.withValues(alpha: .7),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: colors.tertiary.withValues(alpha: .25),
                    ),
                  ),
                  child: Text(
                    '−$savingsPercent%',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: colors.onTertiaryContainer,
                      fontWeight: FontWeight.w900,
                      letterSpacing: .3,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 9),
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final int cachePixels =
                    (constraints.maxWidth *
                            MediaQuery.devicePixelRatioOf(context))
                        .round()
                        .clamp(1, 1600)
                        .toInt();
                return AspectRatio(
                  aspectRatio: 1,
                  child: ColoredBox(
                    color: colors.surfaceContainerHighest,
                    child: Semantics(
                      excludeSemantics: true,
                      label:
                          '$label, ${FileSizeFormatter.format(asset.bytes)}, '
                          '${asset.width} × ${asset.height}',
                      image: true,
                      child: Stack(
                        fit: StackFit.expand,
                        children: <Widget>[
                          Image.file(
                            File(asset.filePath),
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.low,
                            cacheWidth: cachePixels,
                            errorBuilder:
                                (
                                  BuildContext context,
                                  Object error,
                                  StackTrace? stackTrace,
                                ) => Center(
                                  child: Icon(
                                    Icons.broken_image_outlined,
                                    color: colors.onSurfaceVariant,
                                    size: 34,
                                  ),
                                ),
                          ),
                          if (isCompressed)
                            ExcludeSemantics(
                              child: Align(
                                alignment: Alignment.topRight,
                                child: Padding(
                                  padding: const EdgeInsets.all(9),
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(
                                        alpha: .45,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 9,
                                        vertical: 5,
                                      ),
                                      child: Text(
                                        AppLocalizations.of(context).compressed,
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall
                                            ?.copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: .8,
                                            ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          if (savingsPercent != null)
                            Positioned(
                              right: 10,
                              bottom: 10,
                              child: ExcludeSemantics(
                                child: AppRingProgress(
                                  size: 54,
                                  strokeWidth: 5,
                                  progress: savingsPercent! / 100,
                                  color: Colors.white,
                                  backgroundColor: Colors.white.withValues(
                                    alpha: .28,
                                  ),
                                  child: Text(
                                    '−$savingsPercent%',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w900,
                                        ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          Text(
            FileSizeFormatter.format(asset.bytes),
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(
            '${asset.width} × ${asset.height}',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
