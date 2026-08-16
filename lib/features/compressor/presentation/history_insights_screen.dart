import 'dart:async';

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;

import '../../../core/theme/app_dimensions.dart';
import '../../../core/utils/file_size_formatter.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/entities/application_entities.dart';
import 'design_system/design_system.dart';
import 'history_insights_controller.dart';

Future<void> _runHistoryAction(
  BuildContext context,
  Future<void> Function() action,
) async {
  try {
    await action();
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).genericError)),
      );
    }
  }
}

/// Presentation-only Phase 9 workspace. The controller is injected so the
/// screen can later consume the frozen HistoryProvider without changing this UI.
class HistoryInsightsScreen extends StatefulWidget {
  const HistoryInsightsScreen({
    required this.controller,
    this.onOpenCompression,
    this.initialTab = 0,
    super.key,
  });

  final HistoryInsightsController controller;
  final VoidCallback? onOpenCompression;

  /// Which tab is shown first: 0 for history, 1 for insights.
  final int initialTab;

  @override
  State<HistoryInsightsScreen> createState() => _HistoryInsightsScreenState();
}

class _HistoryInsightsScreenState extends State<HistoryInsightsScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final TextEditingController _searchController;
  late final TabController _tabController;

  HistoryInsightsController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _tabController = TabController(
      length: 2,
      initialIndex: widget.initialTab.clamp(0, 1),
      vsync: this,
    );
    controller.initialize();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) controller.refreshDateBuckets();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.initialTab == 1 ? l10n.insights : l10n.history),
        actions: <Widget>[
          PopupMenuButton<HistoryExportFormat>(
            tooltip: l10n.historyExport,
            icon: const Icon(Icons.file_download_outlined),
            onSelected: (HistoryExportFormat format) {
              unawaited(_export(context, format));
            },
            itemBuilder: (BuildContext context) =>
                <PopupMenuEntry<HistoryExportFormat>>[
                  PopupMenuItem(
                    value: HistoryExportFormat.csv,
                    child: Text(l10n.historyExportCsv),
                  ),
                  PopupMenuItem(
                    value: HistoryExportFormat.json,
                    child: Text(l10n.historyExportJson),
                  ),
                  PopupMenuItem(
                    value: HistoryExportFormat.pdf,
                    child: Text(l10n.historyExportPdf),
                  ),
                ],
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: <Widget>[
            Tab(text: l10n.history),
            Tab(text: l10n.insights),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: <Widget>[
          _HistoryTab(
            controller: controller,
            searchController: _searchController,
            onOpenCompression: widget.onOpenCompression,
            onDelete: (HistoryEntry entry) => _confirmDelete(context, entry),
          ),
          _InsightsTab(controller: controller),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, HistoryEntry entry) async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(l10n.historyDeleteTitle),
        content: Text(l10n.historyDeleteMessage),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await controller.deleteEntry(entry);
    } catch (_) {
      if (context.mounted) _showActionError(context);
      return;
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(l10n.historyDeleted),
          action: SnackBarAction(
            label: l10n.undo,
            onPressed: () {
              unawaited(_runHistoryAction(context, controller.undoLastDelete));
            },
          ),
        ),
      );
  }

  Future<void> _export(BuildContext context, HistoryExportFormat format) async {
    try {
      await controller.export(format);
    } catch (_) {
      if (context.mounted) _showActionError(context);
      return;
    }
    if (!context.mounted) return;
    final AppLocalizations l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          format == HistoryExportFormat.pdf
              ? l10n.historyPdfReserved
              : l10n.historyExportReady,
        ),
      ),
    );
  }

  void _showActionError(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).genericError)),
    );
  }
}

/// The workspace's quiet tonal surface. Thin wrapper over the shared
/// [AppSurface] keeping the original `md` default radius used by the
/// history/insights sections; everything else (fill, hairline border, no
/// elevation) comes from the design system.
class _Surface extends StatelessWidget {
  const _Surface({
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.radius = AppRadii.md,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  @override
  Widget build(BuildContext context) =>
      AppSurface(padding: padding, radius: radius, child: child);
}

class _HistoryTab extends StatelessWidget {
  const _HistoryTab({
    required this.controller,
    required this.searchController,
    required this.onDelete,
    this.onOpenCompression,
  });

  final HistoryInsightsController controller;
  final TextEditingController searchController;
  final Future<void> Function(HistoryEntry entry) onDelete;
  final VoidCallback? onOpenCompression;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final double horizontal = AppDimensions.pageHorizontal(
      MediaQuery.sizeOf(context).width,
    );
    return ListenableBuilder(
      listenable: controller.historyListenable,
      builder: (BuildContext context, Widget? child) {
        final List<HistoryEntry> entries = controller.entries;
        final List<HistoryEntry> favorites = controller.favorites;
        return CustomScrollView(
          key: const PageStorageKey<String>('history-scroll'),
          slivers: <Widget>[
            SliverPadding(
              padding: EdgeInsets.fromLTRB(horizontal, 20, horizontal, 0),
              sliver: SliverToBoxAdapter(
                child: _HistoryHeader(
                  controller: controller,
                  searchController: searchController,
                  onOpenCompression: onOpenCompression,
                ),
              ),
            ),
            if (favorites.isNotEmpty) ...<Widget>[
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  horizontal,
                  AppSpacing.lg,
                  horizontal,
                  0,
                ),
                sliver: SliverToBoxAdapter(
                  child: AppSectionHeader(title: l10n.historyFavorites),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  horizontal,
                  AppSpacing.sm,
                  horizontal,
                  0,
                ),
                sliver: SliverList.builder(
                  itemCount: favorites.length,
                  itemBuilder: (BuildContext context, int index) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: _HistoryCard(
                      entry: favorites[index],
                      controller: controller,
                      onDelete: onDelete,
                    ),
                  ),
                ),
              ),
            ],
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                horizontal,
                AppSpacing.lg,
                horizontal,
                0,
              ),
              sliver: SliverToBoxAdapter(
                child: AppSectionHeader(
                  title: controller.hasActiveFilters
                      ? l10n.historyResults
                      : l10n.historyAllSessions,
                  count: entries.length,
                ),
              ),
            ),
            if (entries.isEmpty)
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  horizontal,
                  AppSpacing.md,
                  horizontal,
                  40,
                ),
                sliver: SliverToBoxAdapter(
                  child: _HistoryEmptyState(
                    filtered: controller.hasActiveFilters,
                    onClear: controller.clearFilters,
                    onOpenCompression: onOpenCompression,
                  ),
                ),
              )
            else
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  horizontal,
                  AppSpacing.sm,
                  horizontal,
                  40,
                ),
                sliver: SliverList.builder(
                  itemCount: entries.length,
                  itemBuilder: (BuildContext context, int index) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: _HistoryCard(
                      entry: entries[index],
                      controller: controller,
                      onDelete: onDelete,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _HistoryHeader extends StatelessWidget {
  const _HistoryHeader({
    required this.controller,
    required this.searchController,
    this.onOpenCompression,
  });

  final HistoryInsightsController controller;
  final TextEditingController searchController;
  final VoidCallback? onOpenCompression;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          l10n.historyTitle,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -.3,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.historySubtitle,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: colors.onSurfaceVariant,
            height: 1.4,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        TextField(
          controller: searchController,
          onChanged: controller.setQuery,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            labelText: l10n.historySearch,
            hintText: l10n.historySearchHint,
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: controller.query.isEmpty
                ? null
                : IconButton(
                    tooltip: l10n.clear,
                    onPressed: () {
                      searchController.clear();
                      controller.setQuery('');
                    },
                    icon: const Icon(Icons.clear_rounded),
                  ),
            filled: true,
            fillColor: colors.surfaceContainerLow,
            border: OutlineInputBorder(
              borderRadius: AppRadii.medium,
              borderSide: BorderSide(
                color: colors.outlineVariant.withValues(alpha: .6),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: AppRadii.medium,
              borderSide: BorderSide(
                color: colors.outlineVariant.withValues(alpha: .6),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        // One compact horizontal filter row: each control is a quiet chip that
        // opens a bottom sheet, so filters never stack into vertical space.
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: <Widget>[
              _FilterChip<HistoryDateFilter>(
                label: l10n.historyDate,
                value: controller.dateFilter,
                options: HistoryDateFilter.values,
                optionLabel: (HistoryDateFilter value) =>
                    _dateLabel(l10n, value),
                onChanged: controller.setDateFilter,
              ),
              const SizedBox(width: AppSpacing.xs),
              _FilterChip<HistoryFormatFilter>(
                label: l10n.historyFormat,
                value: controller.formatFilter,
                options: HistoryFormatFilter.values,
                optionLabel: (HistoryFormatFilter value) =>
                    _formatFilterLabel(l10n, value),
                onChanged: controller.setFormatFilter,
              ),
              const SizedBox(width: AppSpacing.xs),
              _FilterChip<HistoryRatioFilter>(
                label: l10n.historyRatio,
                value: controller.ratioFilter,
                options: HistoryRatioFilter.values,
                optionLabel: (HistoryRatioFilter value) =>
                    _ratioLabel(l10n, value),
                onChanged: controller.setRatioFilter,
              ),
              const SizedBox(width: AppSpacing.xs),
              _FilterChip<HistorySortOrder>(
                label: l10n.historySort,
                value: controller.sortOrder,
                options: HistorySortOrder.values,
                optionLabel: (HistorySortOrder value) =>
                    _sortLabel(l10n, value),
                onChanged: controller.setSortOrder,
              ),
              if (controller.hasActiveFilters) ...<Widget>[
                const SizedBox(width: AppSpacing.xs),
                TextButton.icon(
                  onPressed: controller.clearFilters,
                  icon: const Icon(Icons.filter_alt_off_outlined, size: 18),
                  label: Text(l10n.historyClearFilters),
                ),
              ],
            ],
          ),
        ),
        if (controller.availablePresets.isNotEmpty) ...<Widget>[
          const SizedBox(height: AppSpacing.sm),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.xs),
                  child: Text(
                    l10n.historyPreset,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
                ChoiceChip(
                  label: Text(l10n.all),
                  selected: controller.presetFilter == null,
                  onSelected: (_) => controller.setPresetFilter(null),
                ),
                ...controller.availablePresets.map(
                  (String preset) => Padding(
                    padding: const EdgeInsets.only(left: AppSpacing.xs),
                    child: ChoiceChip(
                      label: Text(preset),
                      selected: controller.presetFilter == preset,
                      onSelected: (_) => controller.setPresetFilter(preset),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  String _dateLabel(AppLocalizations l10n, HistoryDateFilter value) =>
      switch (value) {
        HistoryDateFilter.all => l10n.all,
        HistoryDateFilter.today => l10n.today,
        HistoryDateFilter.week => l10n.thisWeek,
        HistoryDateFilter.month => l10n.thisMonth,
      };

  String _formatFilterLabel(AppLocalizations l10n, HistoryFormatFilter value) =>
      switch (value) {
        HistoryFormatFilter.all => l10n.all,
        HistoryFormatFilter.jpeg => l10n.jpegFormat,
        HistoryFormatFilter.png => l10n.pngFormat,
        HistoryFormatFilter.webp => l10n.webpFormat,
        HistoryFormatFilter.other => l10n.other,
      };

  String _ratioLabel(AppLocalizations l10n, HistoryRatioFilter value) =>
      switch (value) {
        HistoryRatioFilter.all => l10n.all,
        HistoryRatioFilter.underTwo => l10n.historyRatioUnderTwo,
        HistoryRatioFilter.twoToFour => l10n.historyRatioTwoToFour,
        HistoryRatioFilter.overFour => l10n.historyRatioOverFour,
      };

  String _sortLabel(AppLocalizations l10n, HistorySortOrder value) =>
      switch (value) {
        HistorySortOrder.newest => l10n.historyNewest,
        HistorySortOrder.oldest => l10n.historyOldest,
        HistorySortOrder.largestSaving => l10n.historyLargestSaving,
        HistorySortOrder.largestFile => l10n.historyLargestFile,
        HistorySortOrder.az => l10n.historyAz,
        HistorySortOrder.za => l10n.historyZa,
      };
}

/// A compact filter control: `Label: value` in a quiet pill that opens a
/// bottom sheet with the available options. Keeps the filter row to a single
/// horizontal line instead of stacked dropdowns.
class _FilterChip<T> extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.value,
    required this.options,
    required this.optionLabel,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<T> options;
  final String Function(T value) optionLabel;
  final ValueChanged<T> onChanged;

  Future<void> _openSheet(BuildContext context) async {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final T? selected = await showModalBottomSheet<T>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.xs,
              ),
              child: Text(
                label,
                style: Theme.of(
                  sheetContext,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: <Widget>[
                  for (final T option in options)
                    ListTile(
                      title: Text(optionLabel(option)),
                      trailing: option == value
                          ? Icon(Icons.check_rounded, color: colors.primary)
                          : null,
                      onTap: () => Navigator.of(sheetContext).pop(option),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
          ],
        ),
      ),
    );
    if (selected != null) onChanged(selected);
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final ThemeData theme = Theme.of(context);
    return Material(
      color: colors.surfaceContainerHighest.withValues(alpha: .45),
      shape: StadiumBorder(
        side: BorderSide(color: colors.outlineVariant.withValues(alpha: .6)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openSheet(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text.rich(
                TextSpan(
                  text: '$label: ',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                  children: <TextSpan>[
                    TextSpan(
                      text: optionLabel(value),
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: colors.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.expand_more_rounded,
                size: 16,
                color: colors.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({
    required this.entry,
    required this.controller,
    required this.onDelete,
  });

  final HistoryEntry entry;
  final HistoryInsightsController controller;
  final Future<void> Function(HistoryEntry entry) onDelete;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final CompressionStatistics stats = entry.statistics;
    final String format = _historyFormat(entry);
    return Semantics(
      container: true,
      label:
          '${entry.sourceName}, ${FileSizeFormatter.format(stats.savedBytes)} ${l10n.historySavedSemantic}',
      child: _Surface(
        radius: AppRadii.lg,
        padding: EdgeInsets.zero,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadii.lg),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) =>
                  HistoryDetailScreen(entry: entry, controller: controller),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final bool compact = constraints.maxWidth < 560;
                final Widget thumbnail = _HistoryThumbnail(
                  entry: entry,
                  format: format,
                );
                final Widget details = _HistoryDetails(
                  entry: entry,
                  format: format,
                );
                final Widget actions = Wrap(
                  spacing: 2,
                  children: <Widget>[
                    IconButton(
                      tooltip: controller.isFavorite(entry.id)
                          ? l10n.historyUnpin
                          : l10n.historyPin,
                      onPressed: () => controller.toggleFavorite(entry.id),
                      icon: Icon(
                        controller.isFavorite(entry.id)
                            ? Icons.push_pin_rounded
                            : Icons.push_pin_outlined,
                      ),
                    ),
                    IconButton(
                      tooltip: l10n.share,
                      onPressed: () {
                        unawaited(
                          _runHistoryAction(
                            context,
                            () => controller.share(entry),
                          ),
                        );
                      },
                      icon: const Icon(Icons.share_outlined),
                    ),
                    IconButton(
                      tooltip: l10n.delete,
                      onPressed: () => onDelete(entry),
                      icon: const Icon(Icons.delete_outline_rounded),
                    ),
                  ],
                );
                if (compact) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          thumbnail,
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(child: details),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Align(alignment: Alignment.centerRight, child: actions),
                    ],
                  );
                }
                return Row(
                  children: <Widget>[
                    thumbnail,
                    const SizedBox(width: AppSpacing.sm + 2),
                    Expanded(child: details),
                    actions,
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _HistoryThumbnail extends StatelessWidget {
  const _HistoryThumbnail({required this.entry, required this.format});
  final HistoryEntry entry;
  final String format;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Container(
      width: 76,
      height: 76,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: .6),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: .6)),
      ),
      child: Semantics(
        image: true,
        label: '${entry.sourceName}, $format',
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            Center(
              child: Icon(
                Icons.image_outlined,
                size: 30,
                color: colors.onSurfaceVariant.withValues(alpha: .8),
              ),
            ),
            Positioned(
              left: 6,
              bottom: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: .32),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  format,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .4,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryDetails extends StatelessWidget {
  const _HistoryDetails({required this.entry, required this.format});
  final HistoryEntry entry;
  final String format;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final CompressionStatistics stats = entry.statistics;
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                entry.sourceName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xs,
                vertical: 3,
              ),
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest.withValues(alpha: .7),
                borderRadius: AppRadii.pillRadius,
              ),
              child: Text(
                format,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colors.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                  letterSpacing: .3,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '${_date(entry.createdAt)} · ${entry.preset.name}',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.xs,
          children: <Widget>[
            AppMetric(
              label: l10n.originalSize,
              value: FileSizeFormatter.format(stats.inputBytes),
            ),
            AppMetric(
              label: l10n.outputSize,
              value: FileSizeFormatter.format(stats.outputBytes),
            ),
            AppMetric(
              label: l10n.historySaved,
              value: FileSizeFormatter.format(stats.savedBytes),
              accent: colors.primary,
            ),
            AppMetric(
              label: l10n.compressionRatio,
              value: '${_ratio(stats).toStringAsFixed(1)}×',
            ),
          ],
        ),
      ],
    );
  }

  String _date(DateTime date) =>
      intl.DateFormat.yMMMd().add_jm().format(date.toLocal());
}

class _HistoryEmptyState extends StatelessWidget {
  const _HistoryEmptyState({
    required this.filtered,
    required this.onClear,
    this.onOpenCompression,
  });
  final bool filtered;
  final VoidCallback onClear;
  final VoidCallback? onOpenCompression;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return AppStoryEmptyState(
      icon: filtered ? Icons.search_off_rounded : Icons.auto_graph_rounded,
      title: filtered ? l10n.historyNoResultsTitle : l10n.historyEmptyTitle,
      message: filtered
          ? l10n.historyNoResultsMessage
          : l10n.historyEmptyMessage,
      glyphSize: 72,
      compact: true,
      action: filtered
          ? OutlinedButton(
              onPressed: onClear,
              child: Text(l10n.historyClearFilters),
            )
          : FilledButton.icon(
              onPressed: onOpenCompression,
              icon: const Icon(Icons.add_photo_alternate_outlined),
              label: Text(l10n.choosePhotos),
            ),
    );
  }
}

class _InsightsTab extends StatelessWidget {
  const _InsightsTab({required this.controller});
  final HistoryInsightsController controller;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final double horizontal = AppDimensions.pageHorizontal(
      MediaQuery.sizeOf(context).width,
    );
    return ListenableBuilder(
      listenable: controller.insightsListenable,
      builder: (BuildContext context, Widget? child) {
        final HistoryInsights data = controller.insights;
        return CustomScrollView(
          key: const PageStorageKey<String>('insights-scroll'),
          slivers: <Widget>[
            SliverPadding(
              padding: EdgeInsets.fromLTRB(horizontal, 20, horizontal, 0),
              sliver: const SliverToBoxAdapter(child: _InsightsHeader()),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                horizontal,
                AppSpacing.md,
                horizontal,
                0,
              ),
              sliver: SliverToBoxAdapter(child: _SummaryGrid(data: data)),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                horizontal,
                AppSpacing.lg,
                horizontal,
                0,
              ),
              sliver: SliverToBoxAdapter(
                child: _ChartCard(
                  title: l10n.historySavedOverTime,
                  subtitle: l10n.historySavedOverTimeSubtitle,
                  values: data.savedByDay
                      .map((int value) => value.toDouble())
                      .toList(),
                  formatValue: (double value) =>
                      FileSizeFormatter.format(value.round()),
                ),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                horizontal,
                AppSpacing.sm,
                horizontal,
                40,
              ),
              sliver: SliverToBoxAdapter(
                child: _Achievements(achievements: controller.achievements),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Insights opens with a plain section header — the same voice as History —
/// so the tab reads as one product experience instead of a dashboard splash.
class _InsightsHeader extends StatelessWidget {
  const _InsightsHeader();

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          l10n.insightsTitle,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -.3,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.insightsSubtitle,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: colors.onSurfaceVariant,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({required this.data});
  final HistoryInsights data;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    // Average reduction is a percent of the original size, not a ratio — and
    // it stays a quiet dash until there is meaningful data to report.
    final double averageRatio = data.averageRatio;
    final int reductionPercent = averageRatio > 1
        ? (100 * (1 - 1 / averageRatio)).round()
        : 0;
    final String reductionValue = reductionPercent > 0
        ? '$reductionPercent%'
        : '—';
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final int columns = constraints.maxWidth >= 560 ? 3 : 1;
        final double itemWidth =
            ((constraints.maxWidth - AppSpacing.sm * (columns - 1)) / columns)
                .clamp(0, constraints.maxWidth)
                .toDouble();
        final List<Widget> tiles = <Widget>[
          _SummaryTile(
            label: l10n.spaceSaved,
            value: FileSizeFormatter.format(data.lifetimeSaved),
            icon: Icons.savings_outlined,
          ),
          _SummaryTile(
            label: l10n.imagesCompressed,
            value: '${data.imagesCompressed}',
            icon: Icons.photo_library_outlined,
          ),
          _SummaryTile(
            label: l10n.averageReduction,
            value: reductionValue,
            icon: Icons.compress_outlined,
          ),
        ];
        return Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: tiles
              .map((Widget tile) => SizedBox(width: itemWidth, child: tile))
              .toList(growable: false),
        );
      },
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.label,
    required this.value,
    required this.icon,
  });
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) => _Surface(
    padding: const EdgeInsets.all(AppSpacing.sm),
    child: AppMetric(icon: icon, label: label, value: value),
  );
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.title,
    required this.subtitle,
    required this.values,
    required this.formatValue,
  });
  final String title;
  final String subtitle;
  final List<double> values;
  final String Function(double value) formatValue;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final String summary = values.isEmpty
        ? l10n.notAvailable
        : values.map(formatValue).join(', ');
    return _Surface(
      radius: AppRadii.lg,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        14,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          if (values.isNotEmpty) ...<Widget>[
            const SizedBox(height: 8),
            Text(
              _chartLabels(context, values.length),
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Semantics(
            container: true,
            label: '$title. $summary',
            child: SizedBox(
              height: 150,
              width: double.infinity,
              child: values.isEmpty
                  ? Center(child: Text(l10n.notAvailable))
                  : RepaintBoundary(
                      child: ExcludeSemantics(
                        child: CustomPaint(
                          painter: _TrendPainter(
                            values: values,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  String _chartLabels(BuildContext context, int count) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return count == 7
        ? '${l10n.sixDaysAgo} · ${l10n.today}'
        : '${l10n.historyOldest} · ${l10n.historyNewest}';
  }
}

class _TrendPainter extends CustomPainter {
  const _TrendPainter({required this.values, required this.color});
  final List<double> values;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final double max = values.reduce((double a, double b) => a > b ? a : b);
    final double min = values.reduce((double a, double b) => a < b ? a : b);
    final bool isFlat = (max - min).abs() < .0001;
    final double range = isFlat ? 1 : max - min;
    final Paint line = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final Paint fill = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[
          color.withValues(alpha: .30),
          color.withValues(alpha: .02),
        ],
      ).createShader(Offset.zero & size)
      ..style = PaintingStyle.fill;
    final Paint grid = Paint()
      ..color = color.withValues(alpha: .07)
      ..strokeWidth = 1;
    for (int index = 1; index <= 3; index++) {
      final double y = size.height * index / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    double xFor(int index) => values.length == 1
        ? size.width / 2
        : index / (values.length - 1) * size.width;
    double yFor(int index) => isFlat
        ? size.height / 2
        : size.height -
              ((values[index] - min) / range * (size.height - 18)) -
              9;
    final Path path = Path();
    for (int index = 0; index < values.length; index++) {
      if (index == 0) {
        path.moveTo(xFor(index), yFor(index));
      } else {
        path.lineTo(xFor(index), yFor(index));
      }
    }
    final Path area = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(area, fill);
    canvas.drawPath(path, line);
    for (int index = 0; index < values.length; index++) {
      canvas.drawCircle(
        Offset(xFor(index), yFor(index)),
        index == 0 || index == values.length - 1 ? 5 : 4,
        Paint()..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(_TrendPainter oldDelegate) =>
      !listEquals(oldDelegate.values, values) || oldDelegate.color != color;
}

class _Achievements extends StatelessWidget {
  const _Achievements({required this.achievements});
  final List<HistoryAchievement> achievements;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ColorScheme colors = Theme.of(context).colorScheme;
    String titleFor(HistoryAchievement achievement) => switch (achievement.id) {
      'first-compression' => l10n.achievementFirstTitle,
      'hundred-images' => l10n.achievementHundredTitle,
      'one-gb-saved' => l10n.achievementGbTitle,
      _ => achievement.title,
    };
    String descriptionFor(HistoryAchievement achievement) =>
        switch (achievement.id) {
          'first-compression' => l10n.achievementFirstDescription,
          'hundred-images' => l10n.achievementHundredDescription,
          'one-gb-saved' => l10n.achievementGbDescription,
          _ => achievement.description,
        };
    return _Surface(
      radius: AppRadii.lg,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          AppSectionHeader(title: l10n.historyMilestones),
          const SizedBox(height: AppSpacing.sm),
          ...achievements.map(
            (HistoryAchievement achievement) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Semantics(
                label:
                    '${titleFor(achievement)}. ${descriptionFor(achievement)}',
                value: '${(achievement.progress * 100).round()}%',
                child: Row(
                  children: <Widget>[
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: achievement.unlocked
                            ? colors.surfaceContainerHighest
                            : colors.surfaceContainerHighest.withValues(
                                alpha: .5,
                              ),
                        borderRadius: BorderRadius.circular(AppRadii.sm),
                        border: Border.all(
                          color: achievement.unlocked
                              ? colors.primary.withValues(alpha: .35)
                              : colors.outlineVariant.withValues(alpha: .4),
                        ),
                      ),
                      child: Icon(
                        achievement.unlocked
                            ? Icons.emoji_events_rounded
                            : Icons.lock_outline_rounded,
                        size: 20,
                        color: achievement.unlocked
                            ? colors.primary
                            : colors.outline,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: Text(
                                  titleFor(achievement),
                                  style: Theme.of(context).textTheme.titleSmall
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Text(
                                '${(achievement.progress * 100).round()}%',
                                style:
                                    AppTypography.tabular(
                                      Theme.of(context).textTheme.labelSmall!,
                                    ).copyWith(
                                      color: achievement.unlocked
                                          ? colors.primary
                                          : colors.onSurfaceVariant,
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                            ],
                          ),
                          Text(
                            descriptionFor(achievement),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              value: achievement.progress,
                              minHeight: 5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Detail view for one history record: the savings story first, then the
/// before/after comparison, the record facts, and the actions. Source/thumbnail
/// paths are not part of the frozen HistoryEntry contract, so image surfaces
/// remain explicit placeholders until that contract is extended later.
class HistoryDetailScreen extends StatelessWidget {
  const HistoryDetailScreen({
    required this.entry,
    required this.controller,
    super.key,
  });
  final HistoryEntry entry;
  final HistoryInsightsController controller;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final CompressionStatistics stats = entry.statistics;
    final String format = _historyFormat(entry);
    final double savedFraction = stats.inputBytes <= 0
        ? 0
        : (stats.savedBytes / stats.inputBytes).clamp(0, 1).toDouble();
    return Scaffold(
      appBar: AppBar(title: Text(entry.sourceName)),
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          return ListView(
            padding: AppDimensions.pageInsets(constraints.maxWidth),
            children: <Widget>[
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AppDimensions.maxContentWidth,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      _DetailSavingsHero(
                        savedFraction: savedFraction,
                        original: FileSizeFormatter.format(stats.inputBytes),
                        compressed: FileSizeFormatter.format(stats.outputBytes),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _DetailComparePanel(
                        beforeLabel: l10n.historyBeforeImage,
                        afterLabel: l10n.historyAfterImage,
                        format: format,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _DetailFactsCard(entry: entry, format: format),
                      const SizedBox(height: AppSpacing.md),
                      _DetailActions(
                        onShare: () {
                          unawaited(
                            _runHistoryAction(
                              context,
                              () => controller.share(entry),
                            ),
                          );
                        },
                        onCompressAgain: () {
                          unawaited(
                            _runHistoryAction(
                              context,
                              () => controller.compressAgain(entry),
                            ),
                          );
                        },
                        onDelete: () {
                          unawaited(_confirmDetailDelete(context));
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmDetailDelete(BuildContext context) async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(l10n.historyDeleteTitle),
        content: Text(l10n.historyDeleteMessage),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await _runHistoryAction(context, () async {
        await controller.deleteEntry(entry);
        if (context.mounted) Navigator.pop(context);
      });
    }
  }
}

class _DetailSavingsHero extends StatelessWidget {
  const _DetailSavingsHero({
    required this.savedFraction,
    required this.original,
    required this.compressed,
  });
  final double savedFraction;
  final String original;
  final String compressed;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ColorScheme colors = Theme.of(context).colorScheme;
    final int percent = (savedFraction * 100).round();
    final bool reduceMotion = MediaQuery.disableAnimationsOf(context);
    return AppSurface(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  l10n.historySaved.toUpperCase(),
                  style: AppTypography.eyebrow(
                    context,
                  ).copyWith(color: colors.primary),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '$percent%',
                  style: AppTypography.metric(context).copyWith(
                    fontWeight: FontWeight.w800,
                    color: colors.primary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '$original → $compressed',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: savedFraction),
            duration: reduceMotion ? Duration.zero : AppDurations.expressive,
            curve: AppAnimations.emphasizedCurve,
            builder: (BuildContext context, double value, Widget? child) =>
                AppRingProgress(
                  size: 92,
                  strokeWidth: 7,
                  progress: value,
                  color: colors.primary,
                  child: Icon(
                    Icons.savings_rounded,
                    size: 30,
                    color: colors.primary,
                  ),
                ),
          ),
        ],
      ),
    );
  }
}

class _DetailComparePanel extends StatelessWidget {
  const _DetailComparePanel({
    required this.beforeLabel,
    required this.afterLabel,
    required this.format,
  });
  final String beforeLabel;
  final String afterLabel;
  final String format;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return AppSurface(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(child: _DetailImagePlaceholder(label: beforeLabel)),
              const SizedBox(width: AppSpacing.xl),
              Expanded(child: _DetailImagePlaceholder(label: afterLabel)),
            ],
          ),
          // A quiet center knob evokes the workflow's signature compare slider.
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: colors.surfaceContainerLow,
              shape: BoxShape.circle,
              border: Border.all(
                color: colors.outlineVariant.withValues(alpha: .8),
              ),
              boxShadow: AppShadows.subtle(colors.outlineVariant),
            ),
            child: Icon(
              Icons.compare_arrows_rounded,
              size: 20,
              color: colors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailImagePlaceholder extends StatelessWidget {
  const _DetailImagePlaceholder({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ColorScheme colors = Theme.of(context).colorScheme;
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest.withValues(alpha: .45),
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(
            color: colors.outlineVariant.withValues(alpha: .5),
          ),
        ),
        child: Semantics(
          label: '$label ${l10n.notAvailable}',
          image: true,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                Icons.image_outlined,
                size: 34,
                color: colors.onSurfaceVariant.withValues(alpha: .8),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              Text(
                l10n.notAvailable,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailFactsCard extends StatelessWidget {
  const _DetailFactsCard({required this.entry, required this.format});
  final HistoryEntry entry;
  final String format;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final CompressionStatistics stats = entry.statistics;
    final ColorScheme colors = Theme.of(context).colorScheme;
    return AppSurface(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  entry.sourceName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest.withValues(alpha: .7),
                  borderRadius: AppRadii.pillRadius,
                ),
                child: Text(
                  format,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                    letterSpacing: .3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _DetailRow(
            label: l10n.originalSize,
            value: FileSizeFormatter.format(stats.inputBytes),
          ),
          _DetailRow(
            label: l10n.outputSize,
            value: FileSizeFormatter.format(stats.outputBytes),
          ),
          _DetailRow(
            label: l10n.historySaved,
            value: FileSizeFormatter.format(stats.savedBytes),
            accent: colors.primary,
          ),
          const SizedBox(height: AppSpacing.xs),
          Divider(
            height: 1,
            color: colors.outlineVariant.withValues(alpha: .5),
          ),
          const SizedBox(height: AppSpacing.xs),
          _DetailRow(
            label: l10n.compressionRatio,
            value: '${_ratio(stats).toStringAsFixed(1)}×',
          ),
          _DetailRow(label: l10n.historyPreset, value: entry.preset.name),
          _DetailRow(
            label: l10n.processingTime,
            value: '${stats.duration.inMilliseconds} ms',
          ),
          _DetailRow(
            label: l10n.historyMetadataStatus,
            value: l10n.notAvailable,
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value, this.accent});
  final String label;
  final String value;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            value,
            style:
                AppTypography.tabular(
                  Theme.of(context).textTheme.titleSmall!,
                ).copyWith(
                  fontWeight: FontWeight.w700,
                  color: accent ?? colors.onSurface,
                ),
          ),
        ],
      ),
    );
  }
}

class _DetailActions extends StatelessWidget {
  const _DetailActions({
    required this.onShare,
    required this.onCompressAgain,
    required this.onDelete,
  });
  final VoidCallback onShare;
  final VoidCallback onCompressAgain;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        FilledButton.icon(
          onPressed: onShare,
          icon: const Icon(Icons.share_outlined),
          label: Text(l10n.share),
        ),
        OutlinedButton.icon(
          onPressed: onCompressAgain,
          icon: const Icon(Icons.replay_rounded),
          label: Text(l10n.compressAgain),
        ),
        TextButton.icon(
          onPressed: onDelete,
          style: TextButton.styleFrom(foregroundColor: colors.error),
          icon: const Icon(Icons.delete_outline),
          label: Text(l10n.delete),
        ),
      ],
    );
  }
}

String _historyFormat(HistoryEntry entry) {
  final String name = entry.outputName.toLowerCase();
  if (name.endsWith('.jpg') || name.endsWith('.jpeg')) return 'JPEG';
  if (name.endsWith('.png')) return 'PNG';
  if (name.endsWith('.webp')) return 'WebP';
  return entry.preset.format.name.toUpperCase();
}

double _ratio(CompressionStatistics statistics) => statistics.outputBytes <= 0
    ? 0
    : statistics.inputBytes / statistics.outputBytes;
