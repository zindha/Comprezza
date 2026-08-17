import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../../core/theme/app_dimensions.dart';
import '../../../core/utils/file_size_formatter.dart';
import '../../../l10n/app_localizations.dart';
import 'batch_compression_controller.dart';
import 'design_system/design_system.dart';

/// Presentation-only Phase 8 batch compression workspace.
///
/// The screen is intentionally isolated from routing and DI while the
/// architecture freeze remains active. Picker and processor seams are injected
/// through [BatchCompressionController].
class BatchCompressionScreen extends StatefulWidget {
  /// Creates a batch workspace.
  const BatchCompressionScreen({required this.controller, super.key});

  /// Presentation-owned queue controller.
  final BatchCompressionController controller;

  @override
  State<BatchCompressionScreen> createState() => _BatchCompressionScreenState();
}

class _BatchCompressionScreenState extends State<BatchCompressionScreen> {
  BatchCompressionController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    // Restore a previously persisted session (in-flight or completed) so
    // re-entering the screen never loses the queue.
    unawaited(controller.restoreProgress());
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.batchCompress),
        actions: <Widget>[
          IconButton(
            tooltip: l10n.batchAddImages,
            onPressed: controller.isBusy ? null : controller.selectImages,
            icon: const Icon(Icons.add_photo_alternate_outlined),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListenableBuilder(
        listenable: controller,
        builder: (BuildContext context, Widget? child) =>
            _BatchBody(controller: controller),
      ),
    );
  }
}

class _BatchBody extends StatelessWidget {
  const _BatchBody({required this.controller});

  final BatchCompressionController controller;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final bool hasItems = controller.items.isNotEmpty;
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double horizontal = AppDimensions.pageHorizontal(
          constraints.maxWidth,
        );
        return CustomScrollView(
          key: const PageStorageKey<String>('batch-scroll'),
          slivers: <Widget>[
            SliverPadding(
              padding: EdgeInsets.fromLTRB(horizontal, 20, horizontal, 0),
              sliver: const SliverToBoxAdapter(child: _BatchHeader()),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(horizontal, 18, horizontal, 0),
              sliver: SliverToBoxAdapter(
                child: _BatchStepStrip(phase: controller.phase),
              ),
            ),
            if (!hasItems)
              SliverPadding(
                padding: EdgeInsets.fromLTRB(horizontal, 24, horizontal, 40),
                sliver: SliverToBoxAdapter(
                  child: _BatchEmptyState(
                    isSelecting: controller.isSelecting,
                    onSelect: controller.selectImages,
                  ),
                ),
              )
            else ...<Widget>[
              SliverPadding(
                padding: EdgeInsets.fromLTRB(horizontal, 24, horizontal, 0),
                sliver: SliverToBoxAdapter(
                  child: _BatchOverview(controller: controller),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(horizontal, 12, horizontal, 0),
                sliver: SliverToBoxAdapter(
                  child: _SelectionActions(controller: controller),
                ),
              ),
              if (controller.phase == BatchWorkflowPhase.analyzing)
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(horizontal, 16, horizontal, 0),
                  sliver: SliverToBoxAdapter(
                    child: _AnalysisProgress(
                      controller: controller,
                      onCancel: controller.cancelAnalysis,
                    ),
                  ),
                ),
              if (controller.phase == BatchWorkflowPhase.settings)
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(horizontal, 16, horizontal, 0),
                  sliver: SliverToBoxAdapter(
                    child: _GlobalSettingsCard(controller: controller),
                  ),
                ),
              if (controller.phase == BatchWorkflowPhase.processing)
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(horizontal, 16, horizontal, 0),
                  sliver: SliverToBoxAdapter(
                    child: _QueueProgressCard(controller: controller),
                  ),
                ),
              if (controller.phase == BatchWorkflowPhase.completed)
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(horizontal, 16, horizontal, 0),
                  sliver: SliverToBoxAdapter(
                    child: _SummaryCard(controller: controller),
                  ),
                ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(horizontal, 18, horizontal, 0),
                sliver: SliverToBoxAdapter(
                  child: _BatchSectionHeading(
                    title: controller.phase == BatchWorkflowPhase.processing
                        ? l10n.batchQueue
                        : l10n.batchPreview,
                    subtitle: controller.phase == BatchWorkflowPhase.processing
                        ? l10n.batchQueueSubtitle
                        : l10n.batchPreviewSubtitle,
                  ),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(horizontal, 12, horizontal, 0),
                sliver: _BatchGrid(controller: controller),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(horizontal, 20, horizontal, 40),
                sliver: SliverToBoxAdapter(
                  child: _BatchActions(controller: controller),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _BatchHeader extends StatelessWidget {
  const _BatchHeader();

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          l10n.batchTitle,
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.batchSubtitle,
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: colors.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _BatchStepStrip extends StatelessWidget {
  const _BatchStepStrip({required this.phase});

  final BatchWorkflowPhase phase;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final List<String> labels = <String>[
      l10n.batchSelectStep,
      l10n.batchAnalyzeStep,
      l10n.batchPreviewStep,
      l10n.batchProcessStep,
      l10n.batchCompleteStep,
    ];
    final int active = switch (phase) {
      BatchWorkflowPhase.selection => 0,
      BatchWorkflowPhase.analyzing => 1,
      BatchWorkflowPhase.preview => 2,
      BatchWorkflowPhase.settings => 2,
      BatchWorkflowPhase.processing => 3,
      BatchWorkflowPhase.completed => 4,
    };
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Semantics(
      container: true,
      liveRegion: true,
      label: labels[active],
      value: l10n.workflowStepPosition(
        active + 1,
        labels.length,
        labels[active],
      ),
      child: Row(
        children: List<Widget>.generate(labels.length * 2 - 1, (int index) {
          if (index.isOdd) {
            return Expanded(
              child: Divider(
                thickness: 2,
                color: index ~/ 2 < active
                    ? colors.primary
                    : colors.outlineVariant,
              ),
            );
          }
          final int step = index ~/ 2;
          final bool current = step == active;
          final bool complete = step < active;
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
                color: current || complete
                    ? colors.primary
                    : colors.surfaceContainerHighest,
                border: Border.all(
                  color: current || complete
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

class _BatchEmptyState extends StatelessWidget {
  const _BatchEmptyState({required this.isSelecting, required this.onSelect});

  final bool isSelecting;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return AppSurface(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: AppStoryEmptyState(
        icon: Icons.collections_rounded,
        title: l10n.batchEmptyTitle,
        message: l10n.batchEmptySubtitle,
        action: FilledButton.icon(
          onPressed: isSelecting ? null : onSelect,
          icon: isSelecting
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.photo_library_outlined),
          label: Text(l10n.batchSelectImages),
        ),
        secondaryAction: Padding(
          padding: const EdgeInsets.only(top: AppSpacing.sm),
          child: Text(
            l10n.batchPrivateNote,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: colorsOf(context)),
          ),
        ),
      ),
    );
  }

  Color colorsOf(BuildContext context) =>
      Theme.of(context).colorScheme.onSurfaceVariant;
}

class _BatchOverview extends StatelessWidget {
  const _BatchOverview({required this.controller});

  final BatchCompressionController controller;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final List<Widget> metrics = <Widget>[
              _OverviewMetric(
                icon: Icons.photo_library_outlined,
                label: l10n.batchImages,
                value: '${controller.selectedCount}',
              ),
              _OverviewMetric(
                icon: Icons.storage_outlined,
                label: l10n.batchOriginalSize,
                value: FileSizeFormatter.format(controller.totalBytes),
              ),
              _OverviewMetric(
                icon: Icons.compress_rounded,
                label: l10n.batchEstimatedOutput,
                value: FileSizeFormatter.format(controller.estimatedBytes),
              ),
              _OverviewMetric(
                icon: Icons.savings_outlined,
                label: l10n.batchEstimatedSavings,
                value:
                    '${_savings(controller.totalBytes, controller.estimatedBytes)}%',
              ),
            ];
            final bool wide = constraints.maxWidth >= 620;
            if (wide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  for (
                    int index = 0;
                    index < metrics.length;
                    index++
                  ) ...<Widget>[
                    if (index > 0) const SizedBox(width: AppSpacing.md),
                    Expanded(child: metrics[index]),
                  ],
                ],
              );
            }
            return Wrap(
              spacing: AppSpacing.lg,
              runSpacing: AppSpacing.md,
              children: metrics,
            );
          },
        ),
      ),
    );
  }

  int _savings(int original, int output) {
    if (original <= 0) return 0;
    return (((original - output) / original) * 100).round().clamp(0, 100);
  }
}

class _SelectionActions extends StatelessWidget {
  const _SelectionActions({required this.controller});

  final BatchCompressionController controller;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        OutlinedButton.icon(
          onPressed: controller.isBusy ? null : controller.selectAll,
          icon: const Icon(Icons.select_all_rounded),
          label: Text(l10n.batchSelectAll),
        ),
        OutlinedButton.icon(
          onPressed: controller.isBusy ? null : controller.deselectAll,
          icon: const Icon(Icons.deselect_rounded),
          label: Text(l10n.batchDeselectAll),
        ),
      ],
    );
  }
}

class _OverviewMetric extends StatelessWidget {
  const _OverviewMetric({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) =>
      AppMetric(icon: icon, label: label, value: value);
}

class _AnalysisProgress extends StatelessWidget {
  const _AnalysisProgress({required this.controller, required this.onCancel});

  final BatchCompressionController controller;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final BatchImageItem? current = controller.items
        .cast<BatchImageItem?>()
        .firstWhere(
          (BatchImageItem? item) => item?.status == BatchQueueStatus.analyzing,
          orElse: () => null,
        );
    final int analyzed = controller.analyzedCount;
    final double progress = controller.analysisProgress;
    final ColorScheme colors = Theme.of(context).colorScheme;
    return AppSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.insights_rounded, size: 20, color: colors.primary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  l10n.batchAnalyzing,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              TextButton(onPressed: onCancel, child: Text(l10n.cancel)),
            ],
          ),
          const SizedBox(height: 10),
          Semantics(
            liveRegion: true,
            label: current == null
                ? l10n.batchAnalyzing
                : '${l10n.batchAnalyzing} ${current.name}',
            value: '$analyzed of ${controller.items.length}',
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(end: progress),
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 220),
              builder: (BuildContext context, double value, Widget? child) =>
                  LinearProgressIndicator(value: value),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            current == null
                ? '$analyzed of ${controller.items.length} analyzed'
                : '${current.name} · $analyzed of ${controller.items.length}',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _GlobalSettingsCard extends StatelessWidget {
  const _GlobalSettingsCard({required this.controller});

  final BatchCompressionController controller;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final BatchCompressionSettings settings = controller.settings;
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
                    l10n.batchSettings,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.batchPreset,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            AppPresetSelector(
              selectedId: settings.preset,
              onSelected: (String preset) =>
                  controller.updateSettings(settings.copyWith(preset: preset)),
              options: <AppPresetOption>[
                AppPresetOption(
                  id: 'Balanced',
                  title: l10n.batchPresetBalanced,
                  subtitle: l10n.batchPresetBalancedSubtitle,
                  icon: Icons.balance_rounded,
                ),
                AppPresetOption(
                  id: 'Web ready',
                  title: l10n.batchPresetWebReady,
                  subtitle: l10n.batchPresetWebReadySubtitle,
                  icon: Icons.language_rounded,
                ),
                AppPresetOption(
                  id: 'Smallest',
                  title: l10n.batchPresetSmallest,
                  subtitle: l10n.batchPresetSmallestSubtitle,
                  icon: Icons.compress_rounded,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
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
                Text(
                  '${settings.quality}%',
                  style: AppTypography.tabular(
                    Theme.of(context).textTheme.titleSmall!,
                  ).copyWith(fontWeight: FontWeight.w800),
                ),
              ],
            ),
            Slider(
              value: settings.quality.toDouble(),
              min: 1,
              max: 100,
              divisions: 99,
              label: '${settings.quality}%',
              onChanged: (double value) => controller.updateSettings(
                settings.copyWith(quality: value.round()),
              ),
            ),
            const Divider(),
            Text(
              l10n.outputFormat,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SegmentedButton<BatchOutputFormat>(
                segments: BatchOutputFormat.values
                    .map((BatchOutputFormat format) {
                      return ButtonSegment<BatchOutputFormat>(
                        value: format,
                        label: Text(_formatLabel(format, l10n)),
                      );
                    })
                    .toList(growable: false),
                selected: <BatchOutputFormat>{settings.format},
                showSelectedIcon: false,
                onSelectionChanged: (Set<BatchOutputFormat> value) => controller
                    .updateSettings(settings.copyWith(format: value.first)),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<BatchResizeChoice>(
              initialValue: settings.resize,
              decoration: InputDecoration(labelText: l10n.resize),
              items: BatchResizeChoice.values
                  .map((BatchResizeChoice value) {
                    return DropdownMenuItem<BatchResizeChoice>(
                      value: value,
                      child: Text(_resizeLabel(value, l10n)),
                    );
                  })
                  .toList(growable: false),
              onChanged: (BatchResizeChoice? value) {
                if (value != null) {
                  controller.updateSettings(settings.copyWith(resize: value));
                }
              },
            ),
            Material(
              color: Colors.transparent,
              child: SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: settings.keepMetadata,
                title: Text(l10n.keepMetadata),
                subtitle: Text(l10n.metadataDescription),
                onChanged: (bool value) => controller.updateSettings(
                  settings.copyWith(keepMetadata: value),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatLabel(BatchOutputFormat format, AppLocalizations l10n) {
    return switch (format) {
      BatchOutputFormat.jpeg => l10n.jpegFormat,
      BatchOutputFormat.png => l10n.pngFormat,
      BatchOutputFormat.webp => l10n.webpFormat,
    };
  }

  String _resizeLabel(BatchResizeChoice resize, AppLocalizations l10n) {
    return switch (resize) {
      BatchResizeChoice.original => l10n.originalOption,
      BatchResizeChoice.percent75 => l10n.resize75,
      BatchResizeChoice.percent50 => l10n.resize50,
      BatchResizeChoice.percent25 => l10n.resize25,
    };
  }
}

class _QueueProgressCard extends StatelessWidget {
  const _QueueProgressCard({required this.controller});

  final BatchCompressionController controller;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final BatchImageItem? current = controller.items
        .cast<BatchImageItem?>()
        .firstWhere(
          (BatchImageItem? item) =>
              item?.status == BatchQueueStatus.compressing ||
              item?.status == BatchQueueStatus.paused,
          orElse: () => null,
        );
    final ColorScheme colors = Theme.of(context).colorScheme;
    return AppSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.compress_rounded, size: 20, color: colors.primary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  controller.isPaused
                      ? l10n.batchPaused
                      : l10n.batchCompressing,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                tooltip: controller.isPaused
                    ? l10n.batchResume
                    : l10n.batchPause,
                onPressed: controller.isPaused
                    ? controller.resume
                    : controller.pause,
                icon: Icon(
                  controller.isPaused
                      ? Icons.play_arrow_rounded
                      : Icons.pause_rounded,
                ),
              ),
              IconButton(
                tooltip: l10n.batchCancel,
                onPressed: controller.cancel,
                icon: const Icon(Icons.stop_circle_outlined),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              Expanded(
                child: Semantics(
                  liveRegion: true,
                  label: current == null
                      ? l10n.batchProgress
                      : '${l10n.batchCompressing} ${current.name}',
                  value: '${(controller.overallProgress * 100).round()}%',
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(end: controller.overallProgress),
                    duration: MediaQuery.disableAnimationsOf(context)
                        ? Duration.zero
                        : const Duration(milliseconds: 260),
                    builder:
                        (BuildContext context, double value, Widget? child) =>
                            LinearProgressIndicator(value: value),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Text(
                '${(controller.overallProgress * 100).round()}%',
                style: AppTypography.tabular(
                  Theme.of(context).textTheme.titleMedium!,
                ).copyWith(color: colors.primary, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 18,
            runSpacing: 8,
            children: <Widget>[
              Text(
                '${controller.completedCount}/${controller.items.length} ${l10n.batchCompleted}',
              ),
              Text('${controller.remainingCount} ${l10n.batchRemaining}'),
              if (controller.processingSpeedBytesPerSecond > 0)
                Text(
                  '${FileSizeFormatter.format(controller.processingSpeedBytesPerSecond.round())}/s',
                ),
              if (controller.estimatedRemaining != Duration.zero)
                Text(_formatDuration(controller.estimatedRemaining)),
              if (current != null) Text(current.name),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m ${duration.inSeconds.remainder(60)}s';
    }
    return '${duration.inSeconds}s';
  }
}

class _BatchGrid extends StatelessWidget {
  const _BatchGrid({required this.controller});

  final BatchCompressionController controller;

  @override
  Widget build(BuildContext context) {
    return SliverLayoutBuilder(
      builder: (BuildContext context, SliverConstraints constraints) {
        final int columns = constraints.crossAxisExtent >= 1000
            ? 4
            : constraints.crossAxisExtent >= 620
            ? 3
            : 2;
        final double itemWidth =
            ((constraints.crossAxisExtent - 12 * (columns - 1)) / columns)
                .clamp(0, constraints.crossAxisExtent)
                .toDouble();
        return SliverList.builder(
          itemCount: (controller.items.length / columns).ceil(),
          itemBuilder: (BuildContext context, int rowIndex) {
            final int start = rowIndex * columns;
            return Padding(
              padding: EdgeInsets.only(
                bottom:
                    rowIndex == (controller.items.length / columns).ceil() - 1
                    ? 0
                    : 12,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  for (int column = 0; column < columns; column++) ...<Widget>[
                    if (column > 0) const SizedBox(width: 12),
                    SizedBox(
                      width: itemWidth,
                      child: start + column < controller.items.length
                          ? _BatchImageTile(
                              controller: controller,
                              item: controller.items[start + column],
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _BatchImageTile extends StatelessWidget {
  const _BatchImageTile({required this.controller, required this.item});

  final BatchCompressionController controller;
  final BatchImageItem item;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ColorScheme colors = Theme.of(context).colorScheme;
    final bool canEdit = !controller.isBusy;
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          AspectRatio(
            aspectRatio: 1.12,
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final double dpr = MediaQuery.devicePixelRatioOf(context);
                final int cacheWidth = (constraints.maxWidth * dpr)
                    .round()
                    .clamp(160, 1200)
                    .toInt();
                final int cacheHeight = (constraints.maxHeight * dpr)
                    .round()
                    .clamp(160, 1200)
                    .toInt();
                return Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    ColoredBox(
                      color: colors.surfaceContainerHighest,
                      child: Semantics(
                        excludeSemantics: true,
                        label: '${item.name}, ${item.width} × ${item.height}',
                        image: true,
                        child: Image.file(
                          File(item.path),
                          fit: BoxFit.cover,
                          cacheWidth: cacheWidth,
                          cacheHeight: cacheHeight,
                          filterQuality: FilterQuality.low,
                          errorBuilder:
                              (
                                BuildContext context,
                                Object error,
                                StackTrace? stackTrace,
                              ) => Icon(
                                Icons.broken_image_outlined,
                                color: colors.onSurfaceVariant,
                              ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 8,
                      top: 8,
                      child: _StatusBadge(status: item.status),
                    ),
                    if (canEdit) ...<Widget>[
                      Positioned(
                        right: 2,
                        top: 2,
                        child: IconButton(
                          tooltip: l10n.batchRemoveImage,
                          onPressed: () => controller.removeImage(item.id),
                          icon: const Icon(Icons.close_rounded),
                          style: IconButton.styleFrom(
                            backgroundColor: colors.surface.withValues(
                              alpha: .86,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 4,
                        bottom: 4,
                        child: Checkbox(
                          value: controller.isSelected(item.id),
                          onChanged: (_) => controller.toggleSelection(item.id),
                          semanticLabel: '${l10n.batchSelect} ${item.name}',
                          fillColor: WidgetStatePropertyAll(colors.surface),
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 9, 10, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 3),
                Text(
                  '${item.width} × ${item.height}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${FileSizeFormatter.format(controller.bytesOf(item.id))} → ${FileSizeFormatter.format(item.estimatedBytes ?? 0)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (item.status == BatchQueueStatus.failed) ...<Widget>[
                  const SizedBox(height: 5),
                  Text(
                    item.errorMessage ?? l10n.batchFailed,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: colors.error, fontSize: 11),
                  ),
                  TextButton(
                    onPressed: () => controller.retryFailed(itemId: item.id),
                    child: Text(l10n.retry),
                  ),
                ],
                if (item.status == BatchQueueStatus.compressing ||
                    item.status == BatchQueueStatus.paused)
                  Padding(
                    padding: const EdgeInsets.only(top: 7),
                    child: LinearProgressIndicator(
                      value: item.progress == 0 ? null : item.progress,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final BatchQueueStatus status;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ColorScheme colors = Theme.of(context).colorScheme;
    final (String, Color, IconData) data = switch (status) {
      BatchQueueStatus.waiting => (
        l10n.batchWaiting,
        colors.surface,
        Icons.schedule_rounded,
      ),
      BatchQueueStatus.analyzing => (
        l10n.batchAnalyzing,
        colors.primaryContainer,
        Icons.insights_outlined,
      ),
      BatchQueueStatus.compressing => (
        l10n.batchCompressing,
        colors.primaryContainer,
        Icons.compress_rounded,
      ),
      BatchQueueStatus.paused => (
        l10n.batchPaused,
        colors.secondaryContainer,
        Icons.pause_rounded,
      ),
      BatchQueueStatus.completed => (
        l10n.batchCompleted,
        colors.tertiaryContainer,
        Icons.check_rounded,
      ),
      BatchQueueStatus.failed => (
        l10n.batchFailed,
        colors.errorContainer,
        Icons.error_outline_rounded,
      ),
      BatchQueueStatus.cancelled => (
        l10n.batchCancelled,
        colors.surfaceContainerHighest,
        Icons.cancel_outlined,
      ),
      BatchQueueStatus.skipped => (
        l10n.batchSkipped,
        colors.surfaceContainerHighest,
        Icons.remove_circle_outline,
      ),
    };
    return Semantics(
      label: data.$1,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: data.$2.withValues(alpha: .92),
          borderRadius: BorderRadius.circular(AppRadii.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(data.$3, size: 13, color: _badgeForeground(context, status)),
            const SizedBox(width: 4),
            Text(
              data.$1,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: _badgeForeground(context, status),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _badgeForeground(BuildContext context, BatchQueueStatus status) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return switch (status) {
      BatchQueueStatus.waiting => colors.onSurfaceVariant,
      BatchQueueStatus.analyzing => colors.onPrimaryContainer,
      BatchQueueStatus.compressing => colors.onPrimaryContainer,
      BatchQueueStatus.paused => colors.onSecondaryContainer,
      BatchQueueStatus.completed => colors.onTertiaryContainer,
      BatchQueueStatus.failed => colors.onErrorContainer,
      BatchQueueStatus.cancelled => colors.onSurfaceVariant,
      BatchQueueStatus.skipped => colors.onSurfaceVariant,
    };
  }
}

class _BatchSectionHeading extends StatelessWidget {
  const _BatchSectionHeading({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -.2,
        ),
      ),
      const SizedBox(height: 3),
      Text(
        subtitle,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          height: 1.45,
        ),
      ),
    ],
  );
}

class _BatchActions extends StatelessWidget {
  const _BatchActions({required this.controller});

  final BatchCompressionController controller;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final bool processing = controller.isProcessing;
    final bool readyToProcess =
        controller.phase == BatchWorkflowPhase.preview ||
        controller.phase == BatchWorkflowPhase.settings;
    final bool hasFailed = controller.failedCount > 0;
    final bool hasCompleted = controller.completedCount > 0;
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: <Widget>[
        if (readyToProcess)
          FilledButton.icon(
            onPressed: controller.startProcessing,
            icon: const Icon(Icons.play_arrow_rounded),
            label: Text(l10n.batchStartCompression),
          ),
        if (readyToProcess)
          OutlinedButton.icon(
            onPressed: controller.openSettings,
            icon: const Icon(Icons.tune_rounded),
            label: Text(l10n.batchSettings),
          ),
        if (processing)
          FilledButton.tonalIcon(
            onPressed: controller.isPaused
                ? controller.resume
                : controller.pause,
            icon: Icon(
              controller.isPaused
                  ? Icons.play_arrow_rounded
                  : Icons.pause_rounded,
            ),
            label: Text(
              controller.isPaused ? l10n.batchResume : l10n.batchPause,
            ),
          ),
        if (processing)
          OutlinedButton.icon(
            onPressed: controller.cancel,
            icon: const Icon(Icons.stop_circle_outlined),
            label: Text(l10n.batchCancel),
          ),
        if (hasFailed && controller.phase == BatchWorkflowPhase.completed)
          FilledButton.tonalIcon(
            onPressed: controller.retryAllFailed,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(l10n.batchRetryFailed),
          ),
        if (hasCompleted &&
            controller.phase == BatchWorkflowPhase.completed) ...<Widget>[
          FilledButton.icon(
            onPressed: controller.isBusy || controller.isExporting
                ? null
                : () => _saveAll(context),
            icon: const Icon(Icons.download_rounded),
            label: Text(l10n.batchSaveAll),
          ),
          OutlinedButton.icon(
            onPressed: controller.isBusy || controller.isExporting
                ? null
                : () => _shareSelected(context),
            icon: const Icon(Icons.share_rounded),
            label: Text(l10n.batchShareSelected),
          ),
          TextButton.icon(
            onPressed: controller.isBusy || controller.isExporting
                ? null
                : () => _prepareZip(context),
            icon: const Icon(Icons.archive_outlined),
            label: Text(l10n.batchPrepareZip),
          ),
        ],
        if (!processing)
          TextButton.icon(
            onPressed: controller.startOver,
            icon: const Icon(Icons.restart_alt_rounded),
            label: Text(l10n.batchStartOver),
          ),
      ],
    );
  }

  /// Saves every completed output to the device gallery.
  Future<void> _saveAll(BuildContext context) async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    try {
      final int count = await controller.saveAll();
      if (!context.mounted) return;
      if (count > 0) {
        _message(context, l10n.batchSavedToDevice(count));
      } else {
        _message(context, l10n.batchSaveFailed, error: true);
      }
    } on Object {
      if (!context.mounted) return;
      _message(context, l10n.batchSaveFailed, error: true);
    }
  }

  /// Shares the selected completed outputs through the system share sheet.
  Future<void> _shareSelected(BuildContext context) async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    try {
      final int count = await controller.shareSelected();
      if (!context.mounted) return;
      if (count > 0) {
        _message(context, l10n.openingShareSheet);
      } else {
        _message(context, l10n.batchShareFailed, error: true);
      }
    } on Object {
      if (!context.mounted) return;
      _message(context, l10n.batchShareFailed, error: true);
    }
  }

  /// Builds the batch ZIP and presents save/share actions for it.
  Future<void> _prepareZip(BuildContext context) async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    try {
      final BatchZipResult zip = await controller.prepareZip();
      if (!context.mounted) return;
      await _showZipSheet(context, zip);
    } on Object {
      if (!context.mounted) return;
      _message(context, l10n.batchZipFailed, error: true);
    }
  }

  /// Shows the prepared ZIP with its save/share actions.
  Future<void> _showZipSheet(BuildContext context, BatchZipResult zip) async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ColorScheme colors = Theme.of(context).colorScheme;
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Icon(
                    Icons.folder_zip_outlined,
                    size: 22,
                    color: colors.primary,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      l10n.batchZipTitle,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -.2,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                zip.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Text(
                l10n.batchZipFiles(
                  zip.fileCount,
                  FileSizeFormatter.format(zip.bytes),
                ),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: <Widget>[
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.of(sheetContext).pop();
                        _saveZip(context, zip.path);
                      },
                      icon: const Icon(Icons.save_alt_rounded),
                      label: Text(l10n.batchZipSave),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(sheetContext).pop();
                        _shareZip(context, zip.path);
                      },
                      icon: const Icon(Icons.share_rounded),
                      label: Text(l10n.batchZipShare),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Saves the prepared ZIP to the device Downloads folder.
  Future<void> _saveZip(BuildContext context, String zipPath) async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    try {
      await controller.saveZip(zipPath);
      if (context.mounted) _message(context, l10n.batchZipSaved);
    } on Object {
      if (!context.mounted) return;
      _message(context, l10n.batchZipFailed, error: true);
    }
  }

  /// Shares the prepared ZIP through the system share sheet.
  Future<void> _shareZip(BuildContext context, String zipPath) async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    try {
      await controller.shareZip(zipPath);
      if (context.mounted) _message(context, l10n.openingShareSheet);
    } on Object {
      if (!context.mounted) return;
      _message(context, l10n.batchZipFailed, error: true);
    }
  }

  /// Shows a floating snackbar: 3 seconds for confirmations, 4 for errors.
  void _message(BuildContext context, String message, {bool error = false}) {
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
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.controller});

  final BatchCompressionController controller;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final BatchCompressionSummary summary = controller.summary;
    final ColorScheme colors = Theme.of(context).colorScheme;
    final int savedPercent = summary.originalBytes <= 0
        ? 0
        : ((summary.savedBytes / summary.originalBytes) * 100).round().clamp(
            0,
            100,
          );
    return AppSurface(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.check_circle_rounded, color: colors.primary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  l10n.batchSummary,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              AppRingProgress(
                size: 56,
                strokeWidth: 5,
                progress: savedPercent / 100,
                color: colors.primary,
                backgroundColor: colors.primary.withValues(alpha: .14),
                child: Text(
                  '$savedPercent%',
                  style:
                      AppTypography.tabular(
                        Theme.of(context).textTheme.labelSmall!,
                      ).copyWith(
                        color: colors.primary,
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 22,
            runSpacing: 14,
            children: <Widget>[
              _SummaryMetric(
                label: l10n.batchProcessed,
                value: '${summary.processed}/${summary.total}',
                color: colors.onSurface,
              ),
              _SummaryMetric(
                label: l10n.batchOriginalSize,
                value: FileSizeFormatter.format(summary.originalBytes),
                color: colors.onSurface,
              ),
              _SummaryMetric(
                label: l10n.batchCompressedSize,
                value: FileSizeFormatter.format(summary.compressedBytes),
                color: colors.onSurface,
              ),
              _SummaryMetric(
                label: l10n.batchStorageSaved,
                value: FileSizeFormatter.format(
                  summary.savedBytes.clamp(0, summary.originalBytes),
                ),
                color: colors.primary,
              ),
              _SummaryMetric(
                label: l10n.batchCompressionRatio,
                value: '${summary.ratio.toStringAsFixed(1)}×',
                color: colors.onSurface,
              ),
              if (summary.skipped > 0)
                _SummaryMetric(
                  label: l10n.batchSkipped,
                  value: '${summary.skipped}',
                  color: colors.onSurface,
                ),
              if (summary.failed > 0)
                _SummaryMetric(
                  label: l10n.batchFailed,
                  value: '${summary.failed}',
                  color: colors.error,
                ),
              if (summary.cancelled > 0)
                _SummaryMetric(
                  label: l10n.batchCancelled,
                  value: '${summary.cancelled}',
                  color: colors.onSurface,
                ),
            ],
          ),
          if (summary.failed > 1) ...<Widget>[
            const SizedBox(height: AppSpacing.lg),
            // One tap retries every failed item; the queue card then shows
            // the retry progress live.
            FilledButton.tonalIcon(
              onPressed: controller.isBusy ? null : controller.retryAllFailed,
              icon: const Icon(Icons.refresh_rounded),
              label: Text('${l10n.batchRetryAll} (${summary.failed})'),
            ),
          ],
        ],
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({
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
