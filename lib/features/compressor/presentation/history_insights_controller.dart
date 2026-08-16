import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../../../core/utils/file_size_formatter.dart';
import '../domain/entities/application_entities.dart';

DateTime _localDay(DateTime value) {
  final DateTime local = value.toLocal();
  return DateTime(local.year, local.month, local.day);
}

List<HistoryEntry> _uniqueEntries(Iterable<HistoryEntry> entries) {
  final Set<String> seen = <String>{};
  final List<HistoryEntry> unique = <HistoryEntry>[];
  for (final HistoryEntry entry in entries) {
    if (seen.add(entry.id)) unique.add(entry);
  }
  return List<HistoryEntry>.unmodifiable(unique);
}

/// Sort orders supported by the history presentation.
enum HistorySortOrder { newest, oldest, largestSaving, largestFile, az, za }

/// Date buckets supported by the history presentation.
enum HistoryDateFilter { all, today, week, month }

/// Output-format filter supported by the history presentation.
enum HistoryFormatFilter { all, jpeg, png, webp, other }

/// Compression-ratio filter supported by the history presentation.
enum HistoryRatioFilter { all, underTwo, twoToFour, overFour }

/// Report formats reserved by the export presentation seam.
enum HistoryExportFormat { csv, json, pdf }

/// Presentation-only achievement descriptor. It intentionally contains no
/// gamification state or persistence contract.
class HistoryAchievement {
  const HistoryAchievement({
    required this.id,
    required this.title,
    required this.description,
    required this.unlocked,
    required this.progress,
    required this.icon,
  });

  final String id;
  final String title;
  final String description;
  final bool unlocked;
  final double progress;
  final String icon;
}

/// Aggregate metrics calculated from immutable local history records.
class HistoryInsights {
  const HistoryInsights({
    required this.imagesCompressed,
    required this.todaySavings,
    required this.weekSavings,
    required this.monthSavings,
    required this.lifetimeSaved,
    required this.averageRatio,
    required this.averageProcessingTime,
    required this.largestImageBytes,
    required this.largestSavingBytes,
    required this.mostUsedPreset,
    required this.mostUsedFormat,
    required this.mostCommonImageType,
    required this.batchSessionsCompleted,
    required List<int> savedByDay,
    required List<double> ratioBySession,
  }) : _savedByDay = savedByDay,
       _ratioBySession = ratioBySession;

  final int imagesCompressed;
  final int todaySavings;
  final int weekSavings;
  final int monthSavings;
  final int lifetimeSaved;
  final double averageRatio;
  final Duration averageProcessingTime;
  final int largestImageBytes;
  final int largestSavingBytes;
  final String? mostUsedPreset;
  final String? mostUsedFormat;
  final String? mostCommonImageType;
  final int batchSessionsCompleted;
  final List<int> _savedByDay;
  final List<double> _ratioBySession;

  List<int> get savedByDay => List<int>.unmodifiable(_savedByDay);
  List<double> get ratioBySession => List<double>.unmodifiable(_ratioBySession);
}

typedef HistoryDeleteCallback = Future<void> Function(HistoryEntry entry);
typedef HistoryRestoreCallback = Future<void> Function(HistoryEntry entry);
typedef HistoryActionCallback = Future<void> Function(HistoryEntry entry);
typedef HistoryExportCallback =
    Future<void> Function(HistoryExportFormat format);

/// Coordinates presentation state without owning persistence or application
/// providers. It can be replaced by the frozen HistoryProvider seam later.
class HistoryInsightsController extends ChangeNotifier {
  HistoryInsightsController({
    Iterable<HistoryEntry> entries = const <HistoryEntry>[],
    this.onDelete,
    this.onRestore,
    this.onShare,
    this.onCompressAgain,
    this.onExport,
  }) : _allEntries = _uniqueEntries(entries) {
    _cachedInsights = _calculateInsights(_allEntries);
  }

  final List<HistoryEntry> _allEntries;
  final ChangeNotifier _historyNotifier = ChangeNotifier();
  final ChangeNotifier _insightsNotifier = ChangeNotifier();
  final HistoryDeleteCallback? onDelete;
  final HistoryRestoreCallback? onRestore;
  final HistoryActionCallback? onShare;
  final HistoryActionCallback? onCompressAgain;
  final HistoryExportCallback? onExport;
  final Set<String> _favoriteIds = <String>{};
  final Set<String> _hiddenIds = <String>{};
  final List<HistoryEntry> _visibleEntries = <HistoryEntry>[];
  final List<HistoryEntry> _deletedEntries = <HistoryEntry>[];
  String _query = '';
  HistoryDateFilter _dateFilter = HistoryDateFilter.all;
  HistoryFormatFilter _formatFilter = HistoryFormatFilter.all;
  HistoryRatioFilter _ratioFilter = HistoryRatioFilter.all;
  String? _presetFilter;
  HistorySortOrder _sortOrder = HistorySortOrder.newest;
  bool _disposed = false;
  DateTime _today = _localDay(DateTime.now());
  late final Map<String, String> _searchTextById = <String, String>{
    for (final HistoryEntry entry in _allEntries)
      entry.id: '${entry.sourceName} ${entry.outputName} ${entry.preset.name}'
          .toLowerCase(),
  };
  late final Map<String, DateTime> _dayById = <String, DateTime>{
    for (final HistoryEntry entry in _allEntries)
      entry.id: _localDay(entry.createdAt),
  };
  late final Map<String, String> _formatById = <String, String>{
    for (final HistoryEntry entry in _allEntries)
      entry.id: _formatFor(entry).toLowerCase(),
  };
  late final Map<String, double> _ratioById = <String, double>{
    for (final HistoryEntry entry in _allEntries)
      entry.id: _safeRatio(entry.statistics),
  };
  late HistoryInsights _cachedInsights;

  String get query => _query;
  HistoryDateFilter get dateFilter => _dateFilter;
  HistoryFormatFilter get formatFilter => _formatFilter;
  HistoryRatioFilter get ratioFilter => _ratioFilter;
  String? get presetFilter => _presetFilter;
  HistorySortOrder get sortOrder => _sortOrder;
  List<HistoryEntry> get entries =>
      List<HistoryEntry>.unmodifiable(_visibleEntries);
  Listenable get historyListenable => _historyNotifier;

  /// Notified only when aggregate insights actually change, so the insights
  /// tab never rebuilds for a history search, sort, or filter.
  Listenable get insightsListenable => _insightsNotifier;
  List<HistoryEntry> get allEntries => _allEntries;
  List<HistoryEntry> get favorites => List<HistoryEntry>.unmodifiable(
    _allEntries.where(
      (HistoryEntry entry) =>
          !_hiddenIds.contains(entry.id) && isFavorite(entry.id),
    ),
  );
  bool get hasActiveFilters =>
      _query.trim().isNotEmpty ||
      _dateFilter != HistoryDateFilter.all ||
      _formatFilter != HistoryFormatFilter.all ||
      _ratioFilter != HistoryRatioFilter.all ||
      _presetFilter != null;
  HistoryInsights get insights => _cachedInsights;

  List<String> get availablePresets {
    final Set<String> presets = _allEntries
        .map((HistoryEntry entry) => entry.preset.name)
        .toSet();
    return presets.toList()..sort();
  }

  List<HistoryAchievement> get achievements {
    final int images = insights.imagesCompressed;
    final int saved = insights.lifetimeSaved;
    return <HistoryAchievement>[
      HistoryAchievement(
        id: 'first-compression',
        title: 'achievement_first_title',
        description: 'achievement_first_description',
        unlocked: images > 0,
        progress: images > 0 ? 1 : 0,
        icon: 'spark',
      ),
      HistoryAchievement(
        id: 'hundred-images',
        title: 'achievement_hundred_title',
        description: 'achievement_hundred_description',
        unlocked: images >= 100,
        progress: (images / 100).clamp(0, 1).toDouble(),
        icon: 'images',
      ),
      HistoryAchievement(
        id: 'one-gb-saved',
        title: 'achievement_gb_title',
        description: 'achievement_gb_description',
        unlocked: saved >= 1024 * 1024 * 1024,
        progress: (saved / (1024 * 1024 * 1024)).clamp(0, 1).toDouble(),
        icon: 'storage',
      ),
    ];
  }

  void initialize() {
    _recompute();
  }

  void refreshDateBuckets() {
    _recompute();
  }

  void setQuery(String query) {
    _query = query;
    _recompute(insightsChanged: false);
  }

  void setDateFilter(HistoryDateFilter filter) {
    _dateFilter = filter;
    _recompute(insightsChanged: false);
  }

  void setFormatFilter(HistoryFormatFilter filter) {
    _formatFilter = filter;
    _recompute(insightsChanged: false);
  }

  void setRatioFilter(HistoryRatioFilter filter) {
    _ratioFilter = filter;
    _recompute(insightsChanged: false);
  }

  void setPresetFilter(String? preset) {
    _presetFilter = preset;
    _recompute(insightsChanged: false);
  }

  void setSortOrder(HistorySortOrder order) {
    _sortOrder = order;
    _recompute(insightsChanged: false);
  }

  void clearFilters() {
    _query = '';
    _dateFilter = HistoryDateFilter.all;
    _formatFilter = HistoryFormatFilter.all;
    _ratioFilter = HistoryRatioFilter.all;
    _presetFilter = null;
    _recompute(insightsChanged: false);
  }

  bool isFavorite(String id) => _favoriteIds.contains(id);

  void toggleFavorite(String id) {
    if (!_favoriteIds.remove(id)) _favoriteIds.add(id);
    _notify(insightsChanged: false);
  }

  Future<void> deleteEntry(HistoryEntry entry) async {
    if (!_allEntries.any((HistoryEntry item) => item.id == entry.id) ||
        _hiddenIds.contains(entry.id)) {
      return;
    }
    _deletedEntries.add(entry);
    _hiddenIds.add(entry.id);
    _recompute();
    try {
      await onDelete?.call(entry);
    } catch (_) {
      _deletedEntries.removeLast();
      _hiddenIds.remove(entry.id);
      _recompute();
      rethrow;
    }
  }

  Future<void> deleteAllVisible() async {
    final List<HistoryEntry> deleted = List<HistoryEntry>.of(_visibleEntries);
    if (deleted.isEmpty) return;
    _deletedEntries.addAll(deleted);
    _hiddenIds.addAll(deleted.map((HistoryEntry entry) => entry.id));
    _recompute();
    try {
      for (final HistoryEntry entry in deleted) {
        await onDelete?.call(entry);
      }
    } catch (_) {
      for (final HistoryEntry entry in deleted) {
        _hiddenIds.remove(entry.id);
      }
      _deletedEntries.removeWhere(
        (HistoryEntry entry) =>
            deleted.any((HistoryEntry item) => item.id == entry.id),
      );
      _recompute();
      rethrow;
    }
  }

  Future<void> undoLastDelete() async {
    if (_deletedEntries.isEmpty) return;
    final HistoryEntry restored = _deletedEntries.last;
    await onRestore?.call(restored);
    _deletedEntries.removeLast();
    _hiddenIds.remove(restored.id);
    _recompute();
  }

  Future<void> share(HistoryEntry entry) async => onShare?.call(entry);

  Future<void> compressAgain(HistoryEntry entry) async =>
      onCompressAgain?.call(entry);

  Future<void> export(HistoryExportFormat format) async =>
      onExport?.call(format);

  void _recompute({bool insightsChanged = true}) {
    _today = _localDay(DateTime.now());
    _visibleEntries
      ..clear()
      ..addAll(
        _allEntries.where((HistoryEntry entry) {
          if (_hiddenIds.contains(entry.id)) return false;
          return _matches(entry);
        }),
      );
    _visibleEntries.sort(_compare);
    if (insightsChanged) {
      _cachedInsights = _calculateInsights(
        _allEntries.where(
          (HistoryEntry entry) => !_hiddenIds.contains(entry.id),
        ),
      );
    }
    _notify(insightsChanged: insightsChanged);
  }

  bool _matches(HistoryEntry entry) {
    final String query = _query.trim().toLowerCase();
    if (query.isNotEmpty && !_searchTextById[entry.id]!.contains(query)) {
      return false;
    }
    if (_presetFilter != null && entry.preset.name != _presetFilter) {
      return false;
    }
    if (!_matchesDate(entry)) return false;
    if (!_matchesFormat(entry)) return false;
    final double ratio = _ratioById[entry.id]!;
    return switch (_ratioFilter) {
      HistoryRatioFilter.all => true,
      HistoryRatioFilter.underTwo => ratio < 2,
      HistoryRatioFilter.twoToFour => ratio >= 2 && ratio <= 4,
      HistoryRatioFilter.overFour => ratio > 4,
    };
  }

  bool _matchesDate(HistoryEntry entry) {
    final DateTime today = _today;
    final DateTime candidate = _dayById[entry.id]!;
    return switch (_dateFilter) {
      HistoryDateFilter.all => true,
      HistoryDateFilter.today => candidate == today,
      HistoryDateFilter.week =>
        !candidate.isBefore(today.subtract(const Duration(days: 6))) &&
            !candidate.isAfter(today),
      HistoryDateFilter.month =>
        candidate.year == today.year &&
            candidate.month == today.month &&
            !candidate.isAfter(today),
    };
  }

  bool _matchesFormat(HistoryEntry entry) {
    final HistoryFormatFilter filter = _formatFilter;
    if (filter == HistoryFormatFilter.all) return true;
    final String format = _formatById[entry.id]!;
    return switch (filter) {
      HistoryFormatFilter.all => true,
      HistoryFormatFilter.jpeg => format == 'jpeg',
      HistoryFormatFilter.png => format == 'png',
      HistoryFormatFilter.webp => format == 'webp',
      HistoryFormatFilter.other => !<String>{
        'jpeg',
        'png',
        'webp',
      }.contains(format),
    };
  }

  int _compare(HistoryEntry a, HistoryEntry b) {
    return switch (_sortOrder) {
      HistorySortOrder.newest => b.createdAt.compareTo(a.createdAt),
      HistorySortOrder.oldest => a.createdAt.compareTo(b.createdAt),
      HistorySortOrder.largestSaving => _safeSaved(
        b.statistics,
      ).compareTo(_safeSaved(a.statistics)),
      HistorySortOrder.largestFile => _safeInput(
        b.statistics,
      ).compareTo(_safeInput(a.statistics)),
      HistorySortOrder.az => a.sourceName.toLowerCase().compareTo(
        b.sourceName.toLowerCase(),
      ),
      HistorySortOrder.za => b.sourceName.toLowerCase().compareTo(
        a.sourceName.toLowerCase(),
      ),
    };
  }

  HistoryInsights _calculateInsights(Iterable<HistoryEntry> source) {
    final List<HistoryEntry> entries = source.toList(growable: false);
    if (entries.isEmpty) {
      return const HistoryInsights(
        imagesCompressed: 0,
        todaySavings: 0,
        weekSavings: 0,
        monthSavings: 0,
        lifetimeSaved: 0,
        averageRatio: 0,
        averageProcessingTime: Duration.zero,
        largestImageBytes: 0,
        largestSavingBytes: 0,
        mostUsedPreset: null,
        mostUsedFormat: null,
        mostCommonImageType: null,
        batchSessionsCompleted: 0,
        savedByDay: <int>[0, 0, 0, 0, 0, 0, 0],
        ratioBySession: <double>[],
      );
    }
    final DateTime today = _localDay(DateTime.now());
    final DateTime weekStart = today.subtract(const Duration(days: 6));
    int imagesCompressed = 0;
    int todaySavings = 0;
    int weekSavings = 0;
    int monthSavings = 0;
    int lifetimeSaved = 0;
    int largestImageBytes = 0;
    int largestSavingBytes = 0;
    int batchSessionsCompleted = 0;
    double ratioTotal = 0;
    Duration totalDuration = Duration.zero;
    final Map<String, int> presets = <String, int>{};
    final Map<String, int> formats = <String, int>{};
    final Map<String, int> sourceTypes = <String, int>{};
    final List<int> savedByDay = List<int>.filled(7, 0);

    for (final HistoryEntry entry in entries) {
      final CompressionStatistics statistics = entry.statistics;
      final int fileCount = math.max(0, statistics.processedFiles);
      final int inputBytes = _safeInput(statistics);
      final int savedBytes = _safeSaved(statistics);
      final double ratio = _safeRatio(statistics);
      final DateTime day = _localDay(entry.createdAt);
      final int daysAgo = today.difference(day).inDays;
      final String format = _formatFor(entry);
      final String sourceType = _sourceTypeFor(entry);

      imagesCompressed += fileCount;
      lifetimeSaved += savedBytes;
      ratioTotal += ratio;
      totalDuration += statistics.duration;
      if (fileCount > 1) batchSessionsCompleted++;
      if (inputBytes > largestImageBytes) largestImageBytes = inputBytes;
      if (savedBytes > largestSavingBytes) largestSavingBytes = savedBytes;
      presets.update(
        entry.preset.name,
        (int value) => value + fileCount,
        ifAbsent: () => fileCount,
      );
      formats.update(
        format,
        (int value) => value + fileCount,
        ifAbsent: () => fileCount,
      );
      sourceTypes.update(
        sourceType,
        (int value) => value + fileCount,
        ifAbsent: () => fileCount,
      );

      if (_sameDay(day, today)) todaySavings += savedBytes;
      if (!day.isBefore(weekStart) && !day.isAfter(today)) {
        weekSavings += savedBytes;
      }
      if (day.year == today.year &&
          day.month == today.month &&
          !day.isAfter(today)) {
        monthSavings += savedBytes;
      }
      if (daysAgo >= 0 && daysAgo < 7) savedByDay[6 - daysAgo] += savedBytes;
    }

    final List<HistoryEntry> recentEntries = List<HistoryEntry>.of(entries)
      ..sort(
        (HistoryEntry a, HistoryEntry b) => b.createdAt.compareTo(a.createdAt),
      );
    return HistoryInsights(
      imagesCompressed: imagesCompressed,
      todaySavings: todaySavings,
      weekSavings: weekSavings,
      monthSavings: monthSavings,
      lifetimeSaved: lifetimeSaved,
      averageRatio: ratioTotal / entries.length,
      averageProcessingTime: Duration(
        microseconds: totalDuration.inMicroseconds ~/ entries.length,
      ),
      largestImageBytes: largestImageBytes,
      largestSavingBytes: largestSavingBytes,
      mostUsedPreset: _mostUsed(presets),
      mostUsedFormat: _mostUsed(formats),
      mostCommonImageType: _mostUsed(sourceTypes),
      batchSessionsCompleted: batchSessionsCompleted,
      savedByDay: savedByDay,
      ratioBySession: recentEntries
          .take(12)
          .map((HistoryEntry entry) => _safeRatio(entry.statistics))
          .toList(growable: false),
    );
  }

  String _formatFor(HistoryEntry entry) {
    final String name = entry.outputName.toLowerCase();
    if (name.endsWith('.jpeg') || name.endsWith('.jpg')) return 'JPEG';
    if (name.endsWith('.png')) return 'PNG';
    if (name.endsWith('.webp')) return 'WebP';
    return entry.preset.format.name.toUpperCase();
  }

  String _sourceTypeFor(HistoryEntry entry) {
    final String name = entry.sourceName.toLowerCase();
    if (name.endsWith('.jpg') || name.endsWith('.jpeg')) return 'JPEG';
    if (name.endsWith('.png')) return 'PNG';
    if (name.endsWith('.webp')) return 'WebP';
    return 'Other';
  }

  double _safeRatio(CompressionStatistics statistics) {
    if (statistics.savingsRatio.isFinite && statistics.savingsRatio >= 0) {
      return statistics.savingsRatio;
    }
    final int output = math.max(0, statistics.outputBytes);
    return output == 0 ? 0 : math.max(0, statistics.inputBytes) / output;
  }

  int _safeInput(CompressionStatistics statistics) =>
      math.max(0, statistics.inputBytes);

  int _safeSaved(CompressionStatistics statistics) =>
      math.max(0, statistics.savedBytes);

  String? _mostUsed(Map<String, int> counts) {
    if (counts.isEmpty) return null;
    return counts.entries
        .reduce(
          (MapEntry<String, int> a, MapEntry<String, int> b) =>
              a.value >= b.value ? a : b,
        )
        .key;
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
  void _notify({required bool insightsChanged}) {
    if (_disposed) return;
    if (insightsChanged) {
      _insightsNotifier.notifyListeners();
      notifyListeners();
    }
    _historyNotifier.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _historyNotifier.dispose();
    _insightsNotifier.dispose();
    super.dispose();
  }

  static String formatBytes(int bytes) => FileSizeFormatter.format(bytes);
}
