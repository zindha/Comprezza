import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routing/app_routes.dart';
import '../../../core/theme/app_brand_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/utils/file_size_formatter.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/compression_models.dart';
import 'compressor_controller.dart';
import 'design_system/design_system.dart';
import 'widgets/image_preview_card.dart';

/// Presents the Smart Compression journey around the existing controller.
///
/// Target-size, format, and resize controls are wired into the compression
/// engine: picking a target size makes the engine search for the best quality
/// and the slider follows the achieved value.
class CompressionWorkflowScreen extends StatefulWidget {
  /// Creates the compression workflow.
  const CompressionWorkflowScreen({
    required this.controller,
    required this.isDarkMode,
    required this.onThemeToggle,
    super.key,
  });

  /// Existing presentation controller assembled by the composition root.
  final CompressorController controller;

  /// Whether the app currently uses the dark theme.
  final bool isDarkMode;

  /// Toggles the app theme.
  final VoidCallback onThemeToggle;

  @override
  State<CompressionWorkflowScreen> createState() =>
      _CompressionWorkflowScreenState();
}

class _CompressionWorkflowScreenState extends State<CompressionWorkflowScreen> {
  late _TargetSize _targetSize;
  late _WorkflowFormat _format;
  late _ResizeChoice _resize;
  String _presetId = 'balanced';

  CompressorController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    _resetOptions();
  }

  void _resetOptions() {
    _targetSize = _TargetSize.original;
    _format = _WorkflowFormat.jpeg;
    _resize = _ResizeChoice.original;
    _presetId = 'balanced';
  }

  void _showMessage(String message, {bool error = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: error ? 4 : 3),
        ),
      );
  }

  void _startOver() {
    if (controller.isExporting) return;
    controller.reset();
    setState(_resetOptions);
  }

  void _retry() {
    if (controller.original == null) {
      controller.pickImage();
    } else if (_targetSize == _TargetSize.original) {
      controller.setQuality(controller.quality.toDouble());
    } else {
      controller.setTargetSize(_targetBytesFor(_targetSize));
    }
  }

  void _applyPreset(String presetId) {
    setState(() {
      _presetId = presetId;
      _targetSize = _TargetSize.original;
    });
    final int quality = switch (presetId) {
      'maximum' => 92,
      'smallest' => 38,
      _ => 72,
    };
    controller.setQuality(quality.toDouble());
  }

  Future<bool> _confirmExport({required bool share}) async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(l10n.preview),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              share ? l10n.openingShareSheet : l10n.saveToDevice,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Text(
              '${l10n.outputSize}: ${FileSizeFormatter.format(controller.compressed?.bytes ?? 0)}',
            ),
            const SizedBox(height: 8),
            Text(l10n.privateProcessing),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(share ? l10n.share : l10n.saveToDevice),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  Future<void> _showExportSummary({required bool share}) async {
    if (!mounted) return;
    final AppLocalizations l10n = AppLocalizations.of(context);
    await showDialog<void>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(l10n.success),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              '${l10n.originalSize}: ${FileSizeFormatter.format(controller.original?.bytes ?? 0)}',
            ),
            Text(
              '${l10n.outputSize}: ${FileSizeFormatter.format(controller.compressed?.bytes ?? 0)}',
            ),
            Text(
              '${l10n.qualityUsed}: ${controller.compressed?.quality ?? 0}%',
            ),
            const SizedBox(height: 10),
            Text(share ? l10n.openingShareSheet : l10n.savedToPictures),
            const SizedBox(height: 8),
            Text(l10n.privateProcessing),
          ],
        ),
        actions: <Widget>[
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.close),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (!await _confirmExport(share: false) || !mounted) return;
    final bool saved = await controller.saveToDevice();
    if (!mounted) return;
    if (saved) {
      await _showExportSummary(share: false);
      return;
    }
    _showMessage(
      controller.errorMessage ?? AppLocalizations.of(context).genericError,
      error: true,
    );
  }

  Future<void> _share() async {
    if (!await _confirmExport(share: true) || !mounted) return;
    final bool shared = await controller.shareImage();
    if (!mounted) return;
    if (shared) {
      await _showExportSummary(share: true);
      return;
    }
    _showMessage(
      controller.errorMessage ?? AppLocalizations.of(context).genericError,
      error: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.compress),
        actions: <Widget>[
          IconButton(
            tooltip: widget.isDarkMode
                ? l10n.switchToLightMode
                : l10n.switchToDarkMode,
            onPressed: widget.onThemeToggle,
            icon: Icon(
              widget.isDarkMode
                  ? Icons.light_mode_rounded
                  : Icons.dark_mode_rounded,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListenableBuilder(
        listenable: controller,
        builder: (BuildContext context, Widget? child) {
          final bool hasImage = controller.original != null;
          final bool isProcessing =
              controller.status == CompressorStatus.processing;
          final bool isReady =
              controller.status == CompressorStatus.ready &&
              controller.original != null &&
              controller.compressed != null;
          final bool hasError = controller.errorMessage != null;

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1120),
              child: ListView(
                padding: AppDimensions.pageInsets(
                  MediaQuery.sizeOf(context).width,
                ),
                children: <Widget>[
                  _WorkflowHeader(
                    title: l10n.workflowTitle,
                    subtitle: l10n.workflowSubtitle,
                  ),
                  const SizedBox(height: 20),
                  _ProgressSteps(
                    activeStep: !hasImage
                        ? 0
                        : isReady
                        ? 3
                        : 2,
                    labels: <String>[
                      l10n.selectImages,
                      l10n.imageAnalysis,
                      l10n.compressionOptions,
                      l10n.success,
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (!hasImage && !isProcessing && !hasError)
                    _SelectionCard(
                      onGallery: controller.pickImage,
                      onCamera: () => unawaited(controller.pickCameraImage()),
                      onBatch: () => context.push(AppRoutes.batch),
                    )
                  else if (!hasImage && hasError)
                    _ErrorCard(
                      message: controller.errorMessage ?? l10n.genericError,
                      onRetry: _retry,
                    )
                  else ...<Widget>[
                    ValueListenableBuilder<int>(
                      valueListenable: controller.qualityListenable,
                      builder:
                          (BuildContext context, int quality, Widget? child) =>
                              _AnalysisCard(
                                asset: controller.original!,
                                quality: quality,
                                targetSize: _targetSize,
                                l10n: l10n,
                              ),
                    ),
                    const SizedBox(height: 16),
                    if (isProcessing && controller.compressed == null)
                      _ProcessingCard(
                        controller: controller,
                        message: l10n.compressing,
                        onCancel: _startOver,
                      )
                    else ...<Widget>[
                      _PreviewSection(
                        original: controller.original!,
                        compressed: controller.compressed,
                        l10n: l10n,
                      ),
                      const SizedBox(height: 16),
                      ValueListenableBuilder<int>(
                        valueListenable: controller.qualityListenable,
                        builder:
                            (
                              BuildContext context,
                              int quality,
                              Widget? child,
                            ) => _OptionsCard(
                              quality: quality,
                              presetId: _presetId,
                              targetSize: _targetSize,
                              format: _format,
                              resize: _resize,
                              keepMetadata: controller.keepMetadata,
                              onPresetChanged: _applyPreset,
                              onQualityChanged: (double value) {
                                setState(() {
                                  _targetSize = _TargetSize.original;
                                  _presetId = 'custom';
                                });
                                controller.setQuality(value);
                              },
                              onTargetChanged: (_TargetSize value) {
                                setState(() {
                                  _targetSize = value;
                                  _presetId = 'custom';
                                });
                                controller.setTargetSize(
                                  _targetBytesFor(value),
                                );
                              },
                              onFormatChanged: (_WorkflowFormat value) {
                                setState(() => _format = value);
                                controller.setFormat(_domainFormat(value));
                              },
                              onResizeChanged: (_ResizeChoice value) {
                                setState(() => _resize = value);
                                controller.setScale(_scaleFor(value));
                              },
                              onMetadataChanged: controller.setMetadata,
                              l10n: l10n,
                            ),
                      ),
                      const SizedBox(height: 16),
                      ValueListenableBuilder<int>(
                        valueListenable: controller.qualityListenable,
                        builder:
                            (
                              BuildContext context,
                              int quality,
                              Widget? child,
                            ) => _EstimateCard(
                              original: controller.original!,
                              quality: quality,
                              targetSize: _targetSize,
                              format: _format,
                              resize: _resize,
                              l10n: l10n,
                            ),
                      ),
                      const SizedBox(height: 16),
                      if (isProcessing)
                        _ProcessingCard(
                          controller: controller,
                          message: l10n.compressing,
                          onCancel: _startOver,
                        )
                      else if (hasError)
                        _ErrorCard(
                          message: controller.errorMessage ?? l10n.genericError,
                          onRetry: controller.exportFailed
                              ? controller.retryLastExport
                              : _retry,
                        )
                      else if (isReady)
                        _SuccessCard(
                          original: controller.original!,
                          compressed: controller.compressed!,
                          l10n: l10n,
                          isExporting: controller.isExporting,
                          onSave: _save,
                          onShare: _share,
                          onCompressAgain: _retry,
                          onStartOver: _startOver,
                          onCancel: controller.cancelExport,
                        )
                      else
                        _ActionCard(
                          label: l10n.compressNow,
                          icon: Icons.compress_rounded,
                          onPressed: _retry,
                        ),
                    ],
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _WorkflowHeader extends StatelessWidget {
  const _WorkflowHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final AppLocalizations l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.lock_rounded, size: 14, color: colors.primary),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                l10n.privateProcessing,
                style: AppTypography.eyebrow(
                  context,
                ).copyWith(color: colors.primary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          title,
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -.5,
            height: 1.14,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: colors.onSurfaceVariant,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

class _ProgressSteps extends StatelessWidget {
  const _ProgressSteps({required this.activeStep, required this.labels});

  final int activeStep;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final int safeStep = activeStep.clamp(0, labels.length - 1).toInt();
    return Semantics(
      container: true,
      liveRegion: true,
      label: labels[safeStep],
      value: AppLocalizations.of(
        context,
      ).workflowStepPosition(safeStep + 1, labels.length, labels[safeStep]),
      child: Row(
        children: List<Widget>.generate(labels.length * 2 - 1, (int index) {
          if (index.isOdd) {
            return Expanded(
              child: Divider(
                color: index ~/ 2 < safeStep
                    ? colors.primary
                    : colors.outlineVariant,
                thickness: 2,
              ),
            );
          }
          final int step = index ~/ 2;
          final bool complete = step < safeStep;
          final bool current = step == safeStep;
          return Tooltip(
            message: labels[step],
            child: AnimatedContainer(
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 220),
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: complete || current
                    ? colors.primary
                    : colors.surfaceContainerHighest,
                border: Border.all(
                  color: complete || current
                      ? colors.primary
                      : colors.outlineVariant,
                ),
              ),
              child: Center(
                child: complete
                    ? Icon(
                        Icons.check_rounded,
                        size: 17,
                        color: colors.onPrimary,
                      )
                    : Text(
                        '${step + 1}',
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: current
                                  ? colors.onPrimary
                                  : colors.onSurfaceVariant,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// The import moment: a composed surface with a strong visual affordance,
/// supported formats, and clear primary/secondary actions — not a generic card
/// with a "Pick Image" button.
class _SelectionCard extends StatelessWidget {
  const _SelectionCard({
    required this.onGallery,
    required this.onCamera,
    required this.onBatch,
  });

  final VoidCallback onGallery;
  final VoidCallback onCamera;
  final VoidCallback onBatch;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ColorScheme colors = Theme.of(context).colorScheme;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color band = isDark
        ? colors.surfaceContainerHigh
        : AppBrandColors.ink;
    final Color onBand = isDark ? colors.onSurface : Colors.white;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: band,
        borderRadius: AppRadii.large,
        border: isDark
            ? Border.all(color: colors.outlineVariant.withValues(alpha: .6))
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Icon(
              Icons.add_photo_alternate_rounded,
              size: 44,
              color: onBand.withValues(alpha: .6),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.selectImages,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: onBand,
                fontWeight: FontWeight.w800,
                letterSpacing: -.3,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.workflowSubtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: onBand.withValues(alpha: .72),
                height: 1.5,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppPressable(
              child: FilledButton.icon(
                onPressed: onGallery,
                icon: const Icon(Icons.photo_library_outlined),
                label: Text(l10n.selectFromGallery),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 54),
                  backgroundColor: isDark ? colors.primary : Colors.white,
                  foregroundColor: isDark
                      ? colors.onPrimary
                      : AppBrandColors.ink,
                ),
              ),
            ),
            const SizedBox(height: 10),
            AppPressable(
              child: OutlinedButton.icon(
                onPressed: onCamera,
                icon: const Icon(Icons.camera_alt_outlined),
                label: Text(l10n.useCamera),
                style: OutlinedButton.styleFrom(
                  foregroundColor: onBand,
                  side: BorderSide(color: onBand.withValues(alpha: .35)),
                ),
              ),
            ),
            const SizedBox(height: 4),
            // Batch is a quiet shortcut, not a third primary action: one clear
            // primary (gallery), one secondary (camera), then this text link.
            Center(
              child: AppPressable(
                child: TextButton(
                  onPressed: onBatch,
                  style: TextButton.styleFrom(
                    foregroundColor: onBand.withValues(alpha: .82),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const Icon(Icons.collections_outlined, size: 18),
                      const SizedBox(width: AppSpacing.xs),
                      Flexible(
                        child: Text(
                          l10n.batchCompressMany,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(Icons.arrow_forward_rounded, size: 16),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.supportedFormats,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: onBand.withValues(alpha: .6),
                letterSpacing: .2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnalysisCard extends StatelessWidget {
  const _AnalysisCard({
    required this.asset,
    required this.quality,
    required this.targetSize,
    required this.l10n,
  });

  final PhotoAsset asset;
  final int quality;
  final _TargetSize targetSize;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final int estimate = _estimateBytes(
      asset.bytes,
      quality,
      targetSize,
      _WorkflowFormat.jpeg,
      _ResizeChoice.original,
    );
    return AppSurface(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(Icons.insights_rounded, size: 20, color: colors.primary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    l10n.imageAnalysis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerHighest.withValues(
                        alpha: .5,
                      ),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Icon(
                          Icons.check_rounded,
                          size: 15,
                          color: colors.primary,
                        ),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            l10n.analysisReady,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: colors.primary,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final Widget thumbnail = _AnalysisThumbnail(asset: asset);
                final Widget meta = Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: <Widget>[
                    _MetaPill(
                      label: l10n.originalSize,
                      value: FileSizeFormatter.format(asset.bytes),
                    ),
                    _MetaPill(
                      label: l10n.originalDimensions,
                      value: '${asset.width} × ${asset.height}',
                    ),
                    _MetaPill(
                      label: l10n.recommended,
                      value: '${l10n.jpegFormat} · $quality%',
                    ),
                    _MetaPill(
                      label: l10n.estimatedSize,
                      value: FileSizeFormatter.format(estimate),
                    ),
                    _MetaPill(
                      label: l10n.confidence,
                      value: l10n.confidenceValue,
                    ),
                  ],
                );
                if (constraints.maxWidth >= 520) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      SizedBox(width: 148, child: thumbnail),
                      const SizedBox(width: 16),
                      Expanded(child: meta),
                    ],
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    thumbnail,
                    const SizedBox(height: 14),
                    meta,
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _AnalysisThumbnail extends StatelessWidget {
  const _AnalysisThumbnail({required this.asset});

  final PhotoAsset asset;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: AppRadii.medium,
        child: AspectRatio(
          aspectRatio: 4 / 3,
          child: ColoredBox(
            color: colors.surfaceContainerHighest,
            child: Image.file(
              File(asset.filePath),
              fit: BoxFit.cover,
              cacheWidth: 420,
              filterQuality: FilterQuality.low,
              errorBuilder:
                  (BuildContext context, Object error, StackTrace? stack) =>
                      Center(
                        child: Icon(
                          Icons.broken_image_outlined,
                          size: 30,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The product hero moment: the image dominates. On phones the before/after
/// pair lives inside the signature [AppCompareSlider]; on wide surfaces a
/// side-by-side comparison reads better.
class _PreviewSection extends StatelessWidget {
  const _PreviewSection({
    required this.original,
    required this.compressed,
    required this.l10n,
  });

  final PhotoAsset original;
  final CompressedAsset? compressed;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final bool wide = MediaQuery.sizeOf(context).width >= 680;
    final PhotoAsset? outputAsset = compressed == null
        ? null
        : PhotoAsset(
            filePath: compressed!.filePath,
            bytes: compressed!.bytes,
            width: compressed!.width,
            height: compressed!.height,
          );
    final int? savedPercent = compressed == null
        ? null
        : FileSizeFormatter.savingsPercent(
            originalBytes: original.bytes,
            compressedBytes: compressed!.bytes,
          );

    if (wide && outputAsset != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _PreviewHeading(savedPercent: savedPercent, l10n: l10n),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: ImagePreviewCard(label: l10n.original, asset: original),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 78),
                child: Icon(Icons.arrow_forward_rounded),
              ),
              Expanded(
                child: ImagePreviewCard(
                  label: l10n.compressed,
                  asset: outputAsset,
                  isCompressed: true,
                  savingsPercent: savedPercent,
                ),
              ),
            ],
          ),
        ],
      );
    }

    // Phone: one dominant comparison surface with the signature slider.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _PreviewHeading(savedPercent: savedPercent, l10n: l10n),
        const SizedBox(height: 14),
        if (outputAsset != null)
          AppCompareSlider(
            before: _PreviewImage(asset: original),
            after: _PreviewImage(asset: outputAsset),
            beforeLabel: l10n.original,
            afterLabel: l10n.compressed,
            beforeCaption: FileSizeFormatter.format(original.bytes),
            afterCaption: FileSizeFormatter.format(outputAsset.bytes),
          )
        else
          const _PreviewLoading(),
      ],
    );
  }
}

class _PreviewHeading extends StatelessWidget {
  const _PreviewHeading({required this.savedPercent, required this.l10n});

  final int? savedPercent;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            l10n.preview,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        if (savedPercent != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: colors.primary.withValues(alpha: .22)),
            ),
            child: Text(
              '−$savedPercent%',
              style: AppTypography.tabular(
                Theme.of(context).textTheme.labelMedium!,
              ).copyWith(color: colors.primary, fontWeight: FontWeight.w800),
            ),
          ),
      ],
    );
  }
}

class _PreviewImage extends StatelessWidget {
  const _PreviewImage({required this.asset});

  final PhotoAsset asset;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return ColoredBox(
      color: colors.surfaceContainerHighest,
      child: Image.file(
        File(asset.filePath),
        fit: BoxFit.contain,
        filterQuality: FilterQuality.low,
        cacheWidth: 900,
        errorBuilder:
            (BuildContext context, Object error, StackTrace? stackTrace) =>
                Center(
                  child: Icon(
                    Icons.broken_image_outlined,
                    color: colors.onSurfaceVariant,
                    size: 34,
                  ),
                ),
      ),
    );
  }
}

class _PreviewLoading extends StatelessWidget {
  const _PreviewLoading();

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return AspectRatio(
      aspectRatio: 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest,
          borderRadius: AppRadii.medium,
        ),
        child: const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

/// A cohesive editing experience: premium presets lead, then the quality
/// slider, format, resize, and metadata live together without shouting.
class _OptionsCard extends StatelessWidget {
  const _OptionsCard({
    required this.quality,
    required this.presetId,
    required this.targetSize,
    required this.format,
    required this.resize,
    required this.keepMetadata,
    required this.onPresetChanged,
    required this.onQualityChanged,
    required this.onTargetChanged,
    required this.onFormatChanged,
    required this.onResizeChanged,
    required this.onMetadataChanged,
    required this.l10n,
  });

  final int quality;
  final String presetId;
  final _TargetSize targetSize;
  final _WorkflowFormat format;
  final _ResizeChoice resize;
  final bool keepMetadata;
  final ValueChanged<String> onPresetChanged;
  final ValueChanged<double> onQualityChanged;
  final ValueChanged<_TargetSize> onTargetChanged;
  final ValueChanged<_WorkflowFormat> onFormatChanged;
  final ValueChanged<_ResizeChoice> onResizeChanged;
  final ValueChanged<bool> onMetadataChanged;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return AppSurface(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(Icons.tune_rounded, size: 20, color: colors.primary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    l10n.compressionOptions,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.workflowPresetBadge,
              style: AppTypography.eyebrow(
                context,
              ).copyWith(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.sm),
            AppPresetSelector(
              selectedId: presetId,
              onSelected: onPresetChanged,
              options: <AppPresetOption>[
                AppPresetOption(
                  id: 'balanced',
                  title: l10n.workflowPresetBalanced,
                  subtitle: l10n.workflowPresetBalancedSubtitle,
                  icon: Icons.balance_rounded,
                ),
                AppPresetOption(
                  id: 'maximum',
                  title: l10n.workflowPresetMaximumQuality,
                  subtitle: l10n.workflowPresetMaximumQualitySubtitle,
                  icon: Icons.high_quality_rounded,
                ),
                AppPresetOption(
                  id: 'smallest',
                  title: l10n.workflowPresetSmallestSize,
                  subtitle: l10n.workflowPresetSmallestSizeSubtitle,
                  icon: Icons.compress_rounded,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    l10n.quality,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                AnimatedContainer(
                  duration: MediaQuery.disableAnimationsOf(context)
                      ? Duration.zero
                      : const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$quality%',
                    style:
                        AppTypography.tabular(
                          Theme.of(context).textTheme.titleSmall!,
                        ).copyWith(
                          color: colors.primary,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              l10n.qualityDescription,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
            ),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 5,
                thumbShape: const RoundSliderThumbShape(
                  enabledThumbRadius: 11,
                  elevation: 3,
                ),
                overlayShape: const RoundSliderOverlayShape(),
                valueIndicatorShape: const PaddleSliderValueIndicatorShape(),
              ),
              child: Slider(
                value: quality.toDouble(),
                min: 1,
                max: 100,
                divisions: 99,
                label: '$quality%',
                semanticFormatterCallback: (double value) =>
                    '${value.round()}%',
                onChanged: onQualityChanged,
              ),
            ),
            const SizedBox(height: 6),
            const Divider(),
            _ChoiceLabel(label: l10n.targetFileSize),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _TargetSize.values
                  .map(
                    (_TargetSize value) => _OptionPill(
                      label: value.label(l10n),
                      selected: targetSize == value,
                      onTap: () => onTargetChanged(value),
                    ),
                  )
                  .toList(growable: false),
            ),
            const SizedBox(height: AppSpacing.xs),
            _AdvancedOptions(
              format: format,
              resize: resize,
              keepMetadata: keepMetadata,
              onFormatChanged: onFormatChanged,
              onResizeChanged: onResizeChanged,
              onMetadataChanged: onMetadataChanged,
              l10n: l10n,
            ),
          ],
        ),
      ),
    );
  }
}

/// Fine-tuning controls (format, dimensions, metadata) hidden behind a
/// disclosure so the default workflow stays simple: presets, quality, and
/// target size are the only visible decisions until the user asks for more.
class _AdvancedOptions extends StatelessWidget {
  const _AdvancedOptions({
    required this.format,
    required this.resize,
    required this.keepMetadata,
    required this.onFormatChanged,
    required this.onResizeChanged,
    required this.onMetadataChanged,
    required this.l10n,
  });

  final _WorkflowFormat format;
  final _ResizeChoice resize;
  final bool keepMetadata;
  final ValueChanged<_WorkflowFormat> onFormatChanged;
  final ValueChanged<_ResizeChoice> onResizeChanged;
  final ValueChanged<bool> onMetadataChanged;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: EdgeInsets.zero,
          childrenPadding: EdgeInsets.zero,
          shape: const Border(),
          collapsedShape: const Border(),
          title: Text(
            l10n.advancedOptions,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          subtitle: Text(
            l10n.advancedOptionsDescription,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
          ),
          children: <Widget>[
            const SizedBox(height: AppSpacing.xs),
            _ChoiceLabel(label: l10n.outputFormat),
            _FormatSegmented(value: format, onChanged: onFormatChanged),
            const SizedBox(height: 8),
            Text(
              l10n.formatDescription,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            _ChoiceLabel(label: l10n.resize),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _ResizeChoice.values
                  .map(
                    (_ResizeChoice value) => _OptionPill(
                      label: value.label(l10n),
                      selected: resize == value,
                      onTap: () => onResizeChanged(value),
                    ),
                  )
                  .toList(growable: false),
            ),
            const SizedBox(height: 8),
            Material(
              color: Colors.transparent,
              child: SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: keepMetadata,
                onChanged: onMetadataChanged,
                title: Text(l10n.keepMetadata),
                subtitle: Text(l10n.metadataDescription),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionPill extends StatelessWidget {
  const _OptionPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final bool reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: AnimatedContainer(
            duration: reduceMotion
                ? Duration.zero
                : const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
            decoration: BoxDecoration(
              color: selected ? colors.primary : colors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: selected
                    ? Colors.transparent
                    : colors.outlineVariant.withValues(alpha: .7),
              ),
            ),
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: selected ? colors.onPrimary : colors.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FormatSegmented extends StatelessWidget {
  const _FormatSegmented({required this.value, required this.onChanged});

  final _WorkflowFormat value;
  final ValueChanged<_WorkflowFormat> onChanged;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Row(
        children: <Widget>[
          for (int index = 0; index < _WorkflowFormat.values.length; index++)
            Expanded(
              child: _SegmentPill(
                label: _WorkflowFormat.values[index].label(l10n),
                selected: value == _WorkflowFormat.values[index],
                isFirst: index == 0,
                isLast: index == _WorkflowFormat.values.length - 1,
                onTap: () => onChanged(_WorkflowFormat.values[index]),
              ),
            ),
        ],
      ),
    );
  }
}

class _SegmentPill extends StatelessWidget {
  const _SegmentPill({
    required this.label,
    required this.selected,
    required this.isFirst,
    required this.isLast,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool isFirst;
  final bool isLast;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Material(
      color: selected ? colors.primaryContainer : Colors.transparent,
      borderRadius: BorderRadius.horizontal(
        left: Radius.circular(isFirst ? 14 : 0),
        right: Radius.circular(isLast ? 14 : 0),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.horizontal(
          left: Radius.circular(isFirst ? 14 : 0),
          right: Radius.circular(isLast ? 14 : 0),
        ),
        child: AnimatedContainer(
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: colors.outlineVariant),
              bottom: BorderSide(color: colors.outlineVariant),
              left: isFirst
                  ? BorderSide(color: colors.outlineVariant)
                  : BorderSide.none,
              right: isLast
                  ? BorderSide(color: colors.outlineVariant)
                  : BorderSide.none,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: selected
                  ? colors.onPrimaryContainer
                  : colors.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _EstimateCard extends StatelessWidget {
  const _EstimateCard({
    required this.original,
    required this.quality,
    required this.targetSize,
    required this.format,
    required this.resize,
    required this.l10n,
  });

  final PhotoAsset original;
  final int quality;
  final _TargetSize targetSize;
  final _WorkflowFormat format;
  final _ResizeChoice resize;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final int estimated = _estimateBytes(
      original.bytes,
      quality,
      targetSize,
      format,
      resize,
    );
    final int saved = FileSizeFormatter.savingsPercent(
      originalBytes: original.bytes,
      compressedBytes: estimated,
    );
    return AppSurface(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(Icons.calculate_outlined, size: 20, color: colors.primary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    l10n.liveEstimate,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 24,
              runSpacing: 14,
              children: <Widget>[
                _EstimateMetric(
                  label: l10n.estimatedSize,
                  value: FileSizeFormatter.format(estimated),
                  color: colors.onSurface,
                ),
                _EstimateMetric(
                  label: l10n.estimatedSavings,
                  value: '$saved%',
                  color: colors.primary,
                ),
                _EstimateMetric(
                  label: l10n.compressionRatio,
                  value: '${(original.bytes / estimated).toStringAsFixed(1)}×',
                  color: colors.onSurface,
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: (saved / 100).clamp(0, 1)),
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : const Duration(milliseconds: 400),
                curve: Curves.easeOutCubic,
                builder: (BuildContext context, double value, Widget? child) =>
                    LinearProgressIndicator(
                      value: value,
                      minHeight: 8,
                      color: colors.primary,
                      backgroundColor: colors.primary.withValues(alpha: .12),
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProcessingCard extends StatefulWidget {
  const _ProcessingCard({
    required this.controller,
    required this.message,
    required this.onCancel,
  });

  final CompressorController controller;
  final String message;
  final VoidCallback onCancel;

  @override
  State<_ProcessingCard> createState() => _ProcessingCardState();
}

/// Live compression progress: an indeterminate bar while the engine works
/// (single-image encoding reports no fractional progress), the elapsed time,
/// and an estimated time remaining derived from the previous pass. A
/// determinate percentage is shown as soon as an engine reports progress.
class _ProcessingCardState extends State<_ProcessingCard> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ColorScheme colors = Theme.of(context).colorScheme;
    final Duration elapsed = widget.controller.compressionElapsed;
    final Duration? eta = widget.controller.estimatedCompressionRemaining;
    return AppSurface(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: <Widget>[
            Semantics(
              liveRegion: true,
              label: widget.message,
              child: const ExcludeSemantics(child: LinearProgressIndicator()),
            ),
            const SizedBox(height: 14),
            Text(widget.message, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              l10n.processingImage,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 18,
              runSpacing: 6,
              children: <Widget>[
                Text(
                  '${l10n.processingTime}: ${_format(elapsed)}',
                  style: AppTypography.tabular(
                    Theme.of(context).textTheme.labelLarge!,
                  ).copyWith(color: colors.onSurfaceVariant),
                ),
                if (eta != null)
                  Text(
                    '${l10n.estimatedTimeRemaining}: ${_format(eta)}',
                    style: AppTypography.tabular(
                      Theme.of(context).textTheme.labelLarge!,
                    ).copyWith(color: colors.onSurfaceVariant),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: widget.onCancel,
              icon: const Icon(Icons.close_rounded),
              label: Text(l10n.cancel),
            ),
          ],
        ),
      ),
    );
  }

  String _format(Duration duration) {
    if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m ${duration.inSeconds.remainder(60)}s';
    }
    return '${duration.inSeconds}s';
  }
}

class _SuccessCard extends StatelessWidget {
  const _SuccessCard({
    required this.original,
    required this.compressed,
    required this.l10n,
    required this.isExporting,
    required this.onSave,
    required this.onShare,
    required this.onCompressAgain,
    required this.onStartOver,
    required this.onCancel,
  });

  final PhotoAsset original;
  final CompressedAsset compressed;
  final AppLocalizations l10n;
  final bool isExporting;
  final VoidCallback onSave;
  final VoidCallback onShare;
  final VoidCallback onCompressAgain;
  final VoidCallback onStartOver;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final int saved = FileSizeFormatter.savingsPercent(
      originalBytes: original.bytes,
      compressedBytes: compressed.bytes,
    );
    return AppSurface(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      l10n.success,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.successMessage,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: saved / 100),
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : AppAnimations.expressive +
                          const Duration(milliseconds: 80),
                curve: AppAnimations.emphasizedCurve,
                builder: (BuildContext context, double value, Widget? child) {
                  final int percent = (value * 100).round();
                  return Transform.scale(
                    scale: .92 + (value * .08),
                    child: AppRingProgress(
                      size: 62,
                      strokeWidth: 6,
                      progress: value,
                      color: colors.primary,
                      backgroundColor: colors.primary.withValues(alpha: .14),
                      child: Text(
                        '$percent%',
                        style:
                            AppTypography.tabular(
                              Theme.of(context).textTheme.labelSmall!,
                            ).copyWith(
                              color: colors.primary,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 22,
            runSpacing: 10,
            children: <Widget>[
              _EstimateMetric(
                label: l10n.originalSize,
                value: FileSizeFormatter.format(original.bytes),
                color: colors.onSurface,
              ),
              _EstimateMetric(
                label: l10n.outputSize,
                value: FileSizeFormatter.format(compressed.bytes),
                color: colors.onSurface,
              ),
              _EstimateMetric(
                label: l10n.estimatedSavings,
                value: '$saved%',
                color: colors.primary,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.successQualityFormat(
              compressed.quality,
              compressed.format.label(l10n),
            ),
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: 18),
          if (isExporting) ...<Widget>[
            const LinearProgressIndicator(),
            const SizedBox(height: 8),
            Semantics(
              liveRegion: true,
              label: l10n.processingImage,
              child: Text(l10n.processingImage),
            ),
            TextButton.icon(
              onPressed: onCancel,
              icon: const Icon(Icons.close_rounded),
              label: Text(l10n.cancel),
            ),
            const SizedBox(height: 8),
          ],
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final Widget save = FilledButton.icon(
                onPressed: isExporting ? null : onSave,
                icon: const Icon(Icons.download_rounded),
                label: Text(l10n.saveToDevice),
              );
              final Widget share = OutlinedButton.icon(
                onPressed: isExporting ? null : onShare,
                icon: const Icon(Icons.ios_share_rounded),
                label: Text(l10n.share),
              );
              if (constraints.maxWidth < 420) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    save,
                    const SizedBox(height: AppSpacing.sm),
                    share,
                  ],
                );
              }
              return Row(
                children: <Widget>[
                  Expanded(flex: 3, child: save),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(flex: 2, child: share),
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: AppSpacing.xs,
            children: <Widget>[
              TextButton.icon(
                onPressed: isExporting ? null : onCompressAgain,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(l10n.compressAgain),
              ),
              TextButton.icon(
                onPressed: isExporting ? null : onStartOver,
                icon: const Icon(Icons.restart_alt_rounded),
                label: Text(l10n.startOver),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return AppSurface(
      color: colors.errorContainer.withValues(alpha: .5),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(Icons.error_outline_rounded, color: colors.error),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    message,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colors.onErrorContainer,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(AppLocalizations.of(context).tryAgain),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => FilledButton.icon(
    onPressed: onPressed,
    icon: Icon(icon),
    label: Text(label),
  );
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: AppRadii.pillRadius,
        border: Border.all(color: colors.outlineVariant.withValues(alpha: .5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            Icons.check_circle_outline_rounded,
            size: 15,
            color: colors.primary,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              '$label · $value',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colors.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EstimateMetric extends StatelessWidget {
  const _EstimateMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      Text(
        value,
        style: AppTypography.tabular(
          Theme.of(context).textTheme.titleMedium!,
        ).copyWith(color: color, fontWeight: FontWeight.w900),
      ),
      const SizedBox(height: 2),
      Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(color: color),
      ),
    ],
  );
}

class _ChoiceLabel extends StatelessWidget {
  const _ChoiceLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      label,
      style: Theme.of(
        context,
      ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
    ),
  );
}

enum _TargetSize {
  original,
  kb100,
  kb250,
  kb500,
  mb1,
  mb2,
  mb5;

  String label(AppLocalizations l10n) => switch (this) {
    _TargetSize.original => l10n.originalOption,
    _TargetSize.kb100 => l10n.target100Kb,
    _TargetSize.kb250 => l10n.target250Kb,
    _TargetSize.kb500 => l10n.target500Kb,
    _TargetSize.mb1 => l10n.target1Mb,
    _TargetSize.mb2 => l10n.target2Mb,
    _TargetSize.mb5 => l10n.target5Mb,
  };
}

enum _WorkflowFormat { jpeg, png, webp }

enum _ResizeChoice {
  original,
  percent75,
  percent50,
  percent25;

  String label(AppLocalizations l10n) => switch (this) {
    _ResizeChoice.original => l10n.originalOption,
    _ResizeChoice.percent75 => l10n.resize75,
    _ResizeChoice.percent50 => l10n.resize50,
    _ResizeChoice.percent25 => l10n.resize25,
  };
}

extension on _WorkflowFormat {
  String label(AppLocalizations l10n) => _domainFormat(this).label(l10n);
}

extension on CompressorFormat {
  String label(AppLocalizations l10n) => switch (this) {
    CompressorFormat.jpeg => l10n.jpegFormat,
    CompressorFormat.png => l10n.pngFormat,
    CompressorFormat.webp => l10n.webpFormat,
  };
}

int _estimateBytes(
  int original,
  int quality,
  _TargetSize target,
  _WorkflowFormat format,
  _ResizeChoice resize,
) {
  final double qualityFactor = .18 + quality / 100 * .62;
  final double formatFactor = switch (format) {
    _WorkflowFormat.jpeg => 1,
    _WorkflowFormat.png => 1.35,
    _WorkflowFormat.webp => .82,
  };
  final double resizeFactor = switch (resize) {
    _ResizeChoice.original => 1,
    _ResizeChoice.percent75 => .72,
    _ResizeChoice.percent50 => .48,
    _ResizeChoice.percent25 => .28,
  };
  final int qualityEstimate =
      (original * qualityFactor * formatFactor * resizeFactor).round();
  final int? targetBytes = switch (target) {
    _TargetSize.original => null,
    _TargetSize.kb100 => 100 * 1024,
    _TargetSize.kb250 => 250 * 1024,
    _TargetSize.kb500 => 500 * 1024,
    _TargetSize.mb1 => 1024 * 1024,
    _TargetSize.mb2 => 2 * 1024 * 1024,
    _TargetSize.mb5 => 5 * 1024 * 1024,
  };
  if (targetBytes == null) return qualityEstimate.clamp(1, original).toInt();
  return targetBytes < qualityEstimate
      ? targetBytes
      : qualityEstimate.clamp(1, original).toInt();
}

int? _targetBytesFor(_TargetSize value) => switch (value) {
  _TargetSize.original => null,
  _TargetSize.kb100 => 100 * 1024,
  _TargetSize.kb250 => 250 * 1024,
  _TargetSize.kb500 => 500 * 1024,
  _TargetSize.mb1 => 1024 * 1024,
  _TargetSize.mb2 => 2 * 1024 * 1024,
  _TargetSize.mb5 => 5 * 1024 * 1024,
};

CompressorFormat _domainFormat(_WorkflowFormat value) => switch (value) {
  _WorkflowFormat.jpeg => CompressorFormat.jpeg,
  _WorkflowFormat.png => CompressorFormat.png,
  _WorkflowFormat.webp => CompressorFormat.webp,
};

double _scaleFor(_ResizeChoice value) => switch (value) {
  _ResizeChoice.original => 1,
  _ResizeChoice.percent75 => .75,
  _ResizeChoice.percent50 => .5,
  _ResizeChoice.percent25 => .25,
};
