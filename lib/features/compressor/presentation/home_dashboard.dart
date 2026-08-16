import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/comprezza_theme.dart';
import '../../../core/errors/app_error.dart';
import '../../../core/models/result.dart';
import '../../../core/theme/app_brand_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/utils/file_size_formatter.dart';
import '../../../l10n/app_localizations.dart';
import '../data/services/file_management/interfaces/file_management_interfaces.dart';
import '../data/services/file_management/models/file_management_models.dart';
import '../domain/entities/application_entities.dart';
import 'design_system/design_system.dart';
import 'history/history_entry_mapper.dart';

/// Aggregated impact numbers shown on the dashboard, derived from the same
/// persisted history the Insights destination reads.
class _DashboardSummary {
  const _DashboardSummary({
    this.imagesCompressed = 0,
    this.savedBytes = 0,
    this.todaySavedBytes = 0,
    this.averagePercent = 0,
    this.recent = const <String>[],
  });

  final int imagesCompressed;
  final int savedBytes;
  final int todaySavedBytes;
  final int averagePercent;
  final List<String> recent;
}

/// Premium first-run and returning-user dashboard for Phase 6.
class HomeDashboard extends StatefulWidget {
  /// Creates the Home Dashboard.
  const HomeDashboard({
    required this.onSelectImages,
    this.history,
    this.onOpenCompression,
    this.onOpenHistory,
    this.onOpenStatistics,
    this.onOpenSettings,
    this.onOpenBatch,
    super.key,
  });

  /// Starts the existing image-selection entry point.
  final VoidCallback onSelectImages;

  /// Optional persisted history used to fill the impact cards with real data.
  /// When omitted the dashboard renders its first-run zero state.
  final HistoryStorage? history;

  /// Opens the future compression route.
  final VoidCallback? onOpenCompression;

  /// Opens the future history route.
  final VoidCallback? onOpenHistory;

  /// Opens the future statistics route.
  final VoidCallback? onOpenStatistics;

  /// Opens the future settings route.
  final VoidCallback? onOpenSettings;

  /// Opens the batch compression route.
  final VoidCallback? onOpenBatch;

  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard> {
  _DashboardSummary _summary = const _DashboardSummary();

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    final HistoryStorage? storage = widget.history;
    if (storage == null) return;
    final Result<List<CompressionHistoryRecord>> result = await storage
        .readAll();
    if (!mounted) return;
    result.fold(
      onSuccess: (List<CompressionHistoryRecord> records) {
        final List<HistoryEntry> entries = records
            .map(historyEntryFromRecord)
            .toList(growable: false);
        int imagesCompressed = 0;
        int savedBytes = 0;
        int todaySavedBytes = 0;
        double ratioSum = 0;
        final DateTime now = DateTime.now();
        final DateTime dayStart = DateTime(now.year, now.month, now.day);
        for (final HistoryEntry entry in entries) {
          final CompressionStatistics stats = entry.statistics;
          final int count = math.max(0, stats.processedFiles);
          final int saved = math.max(0, stats.savedBytes);
          imagesCompressed += count;
          savedBytes += saved;
          ratioSum += math.max(0, stats.savingsRatio);
          if (entry.createdAt.isAfter(dayStart)) todaySavedBytes += saved;
        }
        final double averageRatio = entries.isEmpty
            ? 0
            : ratioSum / entries.length;
        final int averagePercent = averageRatio <= 0
            ? 0
            : (100 * (1 - 1 / averageRatio)).clamp(0, 99).round();
        setState(() {
          _summary = _DashboardSummary(
            imagesCompressed: imagesCompressed,
            savedBytes: savedBytes,
            todaySavedBytes: todaySavedBytes,
            averagePercent: averagePercent,
            recent: entries
                .take(3)
                .map((HistoryEntry entry) => entry.sourceName)
                .toList(growable: false),
          );
        });
      },
      onFailure: (AppError _) {
        // Stay on the first-run zero state rather than blocking the dashboard.
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final _DashboardSummary summary = _summary;
    return Scaffold(
      appBar: AppBar(
        title: AppBrandMark(wordmark: AppLocalizations.of(context).appName),
        actions: <Widget>[
          IconButton(
            onPressed: widget.onOpenSettings,
            tooltip: AppLocalizations.of(context).openSettings,
            icon: const Icon(Icons.settings_outlined),
            style: IconButton.styleFrom(
              backgroundColor: Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest.withValues(alpha: .5),
            ),
          ),
          PopupMenuButton<String>(
            tooltip: AppLocalizations.of(context).moreDestinations,
            onSelected: (String value) {
              if (value == 'batch') widget.onOpenBatch?.call();
              if (value == 'about') context.go('/about');
            },
            itemBuilder: (BuildContext context) {
              final AppLocalizations l10n = AppLocalizations.of(context);
              return <PopupMenuEntry<String>>[
                PopupMenuItem<String>(
                  value: 'batch',
                  child: ListTile(
                    leading: const Icon(Icons.collections_outlined),
                    title: Text(l10n.batchCompress),
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'about',
                  child: ListTile(
                    leading: const Icon(Icons.info_outline_rounded),
                    title: Text(l10n.about),
                  ),
                ),
              ];
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: AppDimensions.pageInsets(
          MediaQuery.sizeOf(context).width,
          top: AppDimensions.spacingSm,
          bottom: AppDimensions.spacingXxl,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppSpacing.maxWideContentWidth,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _Hero(onSelectImages: widget.onSelectImages),
                const SizedBox(height: AppSpacing.lg),
                AppSectionHeader(
                  title: AppLocalizations.of(context).quickActions,
                  subtitle: AppLocalizations.of(context).quickActionsSubtitle,
                ),
                const SizedBox(height: AppSpacing.md),
                _QuickActions(
                  onSelectImages: widget.onSelectImages,
                  onOpenCompression: widget.onOpenCompression,
                  onOpenBatch: widget.onOpenBatch,
                ),
                const SizedBox(height: AppSpacing.lg),
                AppSectionHeader(
                  title: AppLocalizations.of(context).recentActivity,
                  subtitle: AppLocalizations.of(context).recentActivitySubtitle,
                  action: TextButton(
                    onPressed: widget.onOpenHistory,
                    child: Text(AppLocalizations.of(context).viewHistory),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                _RecentFiles(
                  onSelectImages: widget.onSelectImages,
                  recent: summary.recent,
                ),
                const SizedBox(height: AppSpacing.lg),
                AppSectionHeader(
                  title: AppLocalizations.of(context).compressionPresets,
                  subtitle: AppLocalizations.of(
                    context,
                  ).compressionPresetsSubtitle,
                ),
                const SizedBox(height: AppSpacing.md),
                _PresetChips(onOpenCompression: widget.onOpenCompression),
                const SizedBox(height: AppSpacing.lg),
                AppSectionHeader(
                  title: AppLocalizations.of(context).yourImpact,
                  subtitle: AppLocalizations.of(context).yourImpactSubtitle,
                  action: TextButton(
                    onPressed: widget.onOpenStatistics,
                    child: Text(AppLocalizations.of(context).seeAll),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                _StatisticsPreview(summary: summary),
                const SizedBox(height: AppSpacing.lg),
                _StorageOverview(summary: summary),
                const SizedBox(height: AppSpacing.lg),
                const _TipsCarousel(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The composed hero: a solid ink band that anchors the page in deliberate
/// contrast — deep navy in light, an elevated slate in dark — with strong
/// typography and one dominant action. No orbs, no gradient wash, no
/// decorative glyph: the hierarchy does the work.
class _Hero extends StatelessWidget {
  const _Hero({required this.onSelectImages});

  final VoidCallback onSelectImages;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final AppLocalizations l10n = AppLocalizations.of(context);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color band = isDark
        ? colors.surfaceContainerHigh
        : AppBrandColors.ink;
    final Color onBand = isDark ? colors.onSurface : Colors.white;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : AppAnimations.expressive,
      curve: AppAnimations.emphasizedCurve,
      builder: (BuildContext context, double value, Widget? child) =>
          Opacity(opacity: value, child: child),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: band,
          borderRadius: AppRadii.large,
          border: isDark
              ? Border.all(color: colors.outlineVariant.withValues(alpha: .6))
              : null,
        ),
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final bool wide = constraints.maxWidth >= 620;
            final Widget copy = Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: isDark ? colors.primary : Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        l10n.appName,
                        style: AppTypography.eyebrow(context).copyWith(
                          color: isDark ? colors.primary : Colors.white70,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    l10n.heroWelcome,
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: onBand,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -.6,
                      height: 1.14,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppPressable(
                    child: FilledButton.icon(
                      onPressed: onSelectImages,
                      icon: const Icon(Icons.add_photo_alternate_rounded),
                      label: Text(l10n.choosePhotos),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 52),
                        backgroundColor: isDark ? colors.primary : Colors.white,
                        foregroundColor: isDark
                            ? colors.onPrimary
                            : AppBrandColors.ink,
                      ),
                    ),
                  ),
                ],
              ),
            );
            if (!wide) return copy;
            return Row(
              children: <Widget>[
                Expanded(flex: 5, child: copy),
                Expanded(
                  flex: 4,
                  child: Center(
                    child: Icon(
                      Icons.compress_rounded,
                      size: 96,
                      color: onBand.withValues(alpha: .12),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Quick actions with an unmistakable priority order: one prominent primary
/// action, then quiet text-based workflow shortcuts instead of a grid of
/// equal-weight boxes.
class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.onSelectImages,
    this.onOpenCompression,
    this.onOpenBatch,
  });

  final VoidCallback onSelectImages;
  final VoidCallback? onOpenCompression;
  final VoidCallback? onOpenBatch;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ColorScheme colors = Theme.of(context).colorScheme;
    return AppSurface(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _QuickActionTile(
            icon: Icons.compress_rounded,
            title: l10n.compressPhotos,
            subtitle: l10n.compressPhotosSubtitle,
            onTap: onSelectImages,
            prominent: true,
          ),
          Divider(
            height: 1,
            indent: AppSpacing.md,
            endIndent: AppSpacing.md,
            color: colors.outlineVariant.withValues(alpha: .4),
          ),
          _QuickActionTile(
            icon: Icons.collections_outlined,
            title: l10n.batchCompress,
            subtitle: l10n.batchCompressSubtitle,
            onTap: onOpenBatch,
          ),
        ],
      ),
    );
  }
}

/// One row inside the quick-action surface. The leading row carries the
/// primary action; the batch row is deliberately quieter — same shape, less
/// weight, no tinted icon chip.
class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.prominent = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool prominent;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final Color accent = prominent ? colors.primary : colors.onSurfaceVariant;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: <Widget>[
              Icon(icon, size: AppIconSizes.sm + 2, color: accent),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: prominent
                            ? FontWeight.w700
                            : FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Icon(Icons.arrow_forward_rounded, size: 20, color: accent),
            ],
          ),
        ),
      ),
    );
  }
}

class _PresetChips extends StatelessWidget {
  const _PresetChips({this.onOpenCompression});

  final VoidCallback? onOpenCompression;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final List<Widget> chips = <Widget>[
      _PresetChip(
        icon: Icons.language_rounded,
        label: l10n.webReady,
        caption: l10n.webReadySubtitle,
        onTap: onOpenCompression,
      ),
      _PresetChip(
        icon: Icons.share_rounded,
        label: l10n.socialShare,
        caption: l10n.socialShareSubtitle,
        onTap: onOpenCompression,
      ),
      _PresetChip(
        icon: Icons.high_quality_rounded,
        label: l10n.lossless,
        caption: l10n.losslessSubtitle,
        onTap: onOpenCompression,
      ),
    ];
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double maxChipWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth * .9
            : double.infinity;
        return Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: <Widget>[
            for (final Widget chip in chips)
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxChipWidth),
                child: chip,
              ),
          ],
        );
      },
    );
  }
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({
    required this.icon,
    required this.label,
    required this.caption,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String caption;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.pill),
        side: BorderSide(color: ComprezzaTheme.of(context).hairline),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(icon, size: 18, color: colors.primary),
              const SizedBox(width: AppSpacing.xs),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Flexible(
                child: Text(
                  caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StorageOverview extends StatelessWidget {
  const _StorageOverview({required this.summary});

  final _DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final AppLocalizations l10n = AppLocalizations.of(context);
    final double progress = (summary.savedBytes / (1024 * 1024 * 1024)).clamp(
      0,
      1,
    );
    return AppSurface(
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool compact = constraints.maxWidth < AppBreakpoints.tablet;
          final Widget copy = Row(
            children: <Widget>[
              Icon(
                Icons.savings_outlined,
                size: AppIconSizes.sm + 2,
                color: colors.primary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      l10n.storageSavings,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.storageSavingsDescription,
                      style: AppTypography.caption(context),
                    ),
                  ],
                ),
              ),
            ],
          );
          final Widget value = FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: <Widget>[
                Text(
                  FileSizeFormatter.format(summary.savedBytes),
                  style: AppTypography.metricSmall(
                    context,
                  ).copyWith(color: colors.primary),
                ),
                const SizedBox(width: AppSpacing.xxs),
                Text(l10n.savedSoFar, style: AppTypography.caption(context)),
              ],
            ),
          );
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              compact
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        copy,
                        const SizedBox(height: AppSpacing.md),
                        value,
                      ],
                    )
                  : Row(
                      children: <Widget>[
                        Expanded(child: copy),
                        const SizedBox(width: AppSpacing.lg),
                        value,
                      ],
                    ),
              const SizedBox(height: AppSpacing.md),
              Semantics(
                label: l10n.storageSavingsProgress,
                excludeSemantics: true,
                child: ClipRRect(
                  borderRadius: AppRadii.pillRadius,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: progress),
                    duration: MediaQuery.disableAnimationsOf(context)
                        ? Duration.zero
                        : AppDurations.expressive,
                    curve: AppAnimations.emphasizedCurve,
                    builder:
                        (BuildContext context, double value, Widget? child) =>
                            LinearProgressIndicator(value: value, minHeight: 8),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _RecentFiles extends StatelessWidget {
  const _RecentFiles({required this.onSelectImages, required this.recent});

  final VoidCallback onSelectImages;
  final List<String> recent;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ColorScheme colors = Theme.of(context).colorScheme;
    if (recent.isEmpty) {
      // A quiet, compact inline state: the story illustration is reserved for
      // the History empty state, so Recent activity stays unobtrusive.
      return AppSurface(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: <Widget>[
            Icon(
              Icons.history_rounded,
              size: AppIconSizes.sm + 2,
              color: colors.onSurfaceVariant.withValues(alpha: .7),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    l10n.recentFilesEmptyTitle,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.recentFilesEmptyMessage,
                    style: AppTypography.caption(context),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            // Flexible + FittedBox keeps the action on one line at normal
            // sizes and gently scales it only when the button genuinely can't
            // fit (smallest phones at maximum text scale).
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: onSelectImages,
                  child: Text(l10n.choosePhotos),
                ),
              ),
            ),
          ],
        ),
      );
    }
    return AppSurface(
      padding: EdgeInsets.zero,
      child: Column(
        children: <Widget>[
          for (int index = 0; index < recent.length; index++)
            Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.md,
                index == 0 ? AppSpacing.sm : 0,
                AppSpacing.md,
                index == recent.length - 1 ? AppSpacing.sm : 0,
              ),
              child: Row(
                children: <Widget>[
                  Icon(
                    Icons.image_outlined,
                    size: AppIconSizes.sm,
                    color: colors.onSurfaceVariant.withValues(alpha: .8),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      recent[index],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: colors.onSurfaceVariant.withValues(alpha: .6),
                  ),
                ],
              ),
            ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: AppButton(
              label: l10n.choosePhotos,
              icon: Icons.add_photo_alternate_rounded,
              onPressed: onSelectImages,
              expand: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatisticsPreview extends StatelessWidget {
  const _StatisticsPreview({required this.summary});

  final _DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ColorScheme colors = Theme.of(context).colorScheme;
    return AppSurface(
      color: colors.surfaceContainerLow,
      padding: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: _AnimatedStat(
                    label: l10n.imagesCompressed,
                    value: summary.imagesCompressed,
                    icon: Icons.photo_library_outlined,
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: _StatValue(
                    label: l10n.storageSaved,
                    value: FileSizeFormatter.format(summary.savedBytes),
                    icon: Icons.savings_outlined,
                  ),
                ),
              ],
            ),
            Divider(
              height: AppSpacing.lg + 1,
              color: colors.outlineVariant.withValues(alpha: .4),
            ),
            Row(
              children: <Widget>[
                Expanded(
                  child: _StatValue(
                    label: l10n.todaysSavings,
                    value: FileSizeFormatter.format(summary.todaySavedBytes),
                    icon: Icons.today_outlined,
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: _StatValue(
                    label: l10n.averageCompression,
                    value: '${summary.averagePercent}%',
                    icon: Icons.compress_rounded,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatValue extends StatelessWidget {
  const _StatValue({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(icon, size: AppIconSizes.sm, color: colors.primary),
        const SizedBox(height: AppSpacing.xs),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.metricSmall(context),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.caption(context),
        ),
      ],
    );
  }
}

class _AnimatedStat extends StatelessWidget {
  const _AnimatedStat({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final int value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final bool reduceMotion = MediaQuery.disableAnimationsOf(context);
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: 0, end: value),
      duration: reduceMotion ? Duration.zero : AppAnimations.expressive,
      builder: (BuildContext context, int animated, Widget? child) =>
          _StatValue(label: label, value: '$animated', icon: icon),
    );
  }
}

class _TipsCarousel extends StatefulWidget {
  const _TipsCarousel();

  @override
  State<_TipsCarousel> createState() => _TipsCarouselState();
}

class _TipsCarouselState extends State<_TipsCarousel> {
  static const List<_Tip> _tips = <_Tip>[
    _Tip(
      titleKey: _TipKey.web,
      messageKey: _TipKey.web,
      icon: Icons.language_rounded,
    ),
    _Tip(
      titleKey: _TipKey.screenshot,
      messageKey: _TipKey.screenshot,
      icon: Icons.screenshot_monitor_rounded,
    ),
    _Tip(
      titleKey: _TipKey.batch,
      messageKey: _TipKey.batch,
      icon: Icons.bolt_rounded,
    ),
    _Tip(
      titleKey: _TipKey.metadata,
      messageKey: _TipKey.metadata,
      icon: Icons.info_outline_rounded,
    ),
  ];

  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final _Tip tip = _tips[_index];
    final ColorScheme colors = Theme.of(context).colorScheme;
    return AppSurface(
      color: colors.surfaceContainerLow,
      child: AnimatedSwitcher(
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : AppAnimations.standard,
        switchInCurve: AppAnimations.emphasizedCurve,
        switchOutCurve: AppAnimations.standardCurve,
        child: Row(
          key: ValueKey<int>(_index),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(tip.icon, size: 20, color: colors.primary),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    l10n.smartTip,
                    style: AppTypography.eyebrow(
                      context,
                    ).copyWith(color: colors.primary),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    tip.title(l10n),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    tip.message(l10n),
                    style: AppTypography.caption(context),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () =>
                  setState(() => _index = (_index + 1) % _tips.length),
              tooltip: l10n.nextTip,
              icon: Icon(
                Icons.arrow_forward_rounded,
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _TipKey { web, screenshot, batch, metadata }

class _Tip {
  const _Tip({
    required this.titleKey,
    required this.messageKey,
    required this.icon,
  });

  final _TipKey titleKey;
  final _TipKey messageKey;
  final IconData icon;

  String title(AppLocalizations l10n) => switch (titleKey) {
    _TipKey.web => l10n.tipWebTitle,
    _TipKey.screenshot => l10n.tipScreenshotTitle,
    _TipKey.batch => l10n.tipBatchTitle,
    _TipKey.metadata => l10n.tipMetadataTitle,
  };

  String message(AppLocalizations l10n) => switch (messageKey) {
    _TipKey.web => l10n.tipWebMessage,
    _TipKey.screenshot => l10n.tipScreenshotMessage,
    _TipKey.batch => l10n.tipBatchMessage,
    _TipKey.metadata => l10n.tipMetadataMessage,
  };
}
