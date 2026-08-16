import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

import '../../../core/utils/file_size_formatter.dart';
import '../data/services/file_management/interfaces/file_management_interfaces.dart';
import '../data/services/file_management/models/file_management_models.dart';

/// The visible stage of the batch workflow.
enum BatchWorkflowPhase {
  selection,
  analyzing,
  preview,
  settings,
  processing,
  completed,
}

/// The presentation status of one queue entry.
enum BatchQueueStatus {
  waiting,
  analyzing,
  compressing,
  paused,
  completed,
  failed,
  cancelled,
  skipped,
}

/// Output formats exposed by the batch presentation until the frozen engine
/// contracts are wired by a later integration phase.
enum BatchOutputFormat { jpeg, png, webp }

/// Resize choices exposed by the batch presentation.
enum BatchResizeChoice { original, percent75, percent50, percent25 }

/// A presentation-owned image descriptor. It deliberately contains metadata,
/// not decoded image buffers, so large selections remain memory-bounded.
class BatchImageItem {
  const BatchImageItem({
    required this.id,
    required this.path,
    required this.name,
    required this.bytes,
    required this.width,
    required this.height,
    required this.format,
    this.estimatedBytes,
    this.recommendedQuality = 72,
    this.qualityOverride,
    this.status = BatchQueueStatus.waiting,
    this.progress = 0,
    this.errorMessage,
    this.outputPath,
    this.outputBytes,
  });

  final String id;
  final String path;
  final String name;
  final int bytes;
  final int width;
  final int height;
  final String format;
  final int? estimatedBytes;
  final int recommendedQuality;
  final int? qualityOverride;
  final BatchQueueStatus status;
  final double progress;
  final String? errorMessage;
  final String? outputPath;
  final int? outputBytes;

  int get effectiveQuality => qualityOverride ?? recommendedQuality;

  BatchImageItem copyWith({
    String? id,
    int? estimatedBytes,
    int? recommendedQuality,
    int? qualityOverride,
    bool clearQualityOverride = false,
    BatchQueueStatus? status,
    double? progress,
    String? errorMessage,
    bool clearError = false,
    String? outputPath,
    bool clearOutputPath = false,
    int? outputBytes,
  }) => BatchImageItem(
    id: id ?? this.id,
    path: path,
    name: name,
    bytes: bytes,
    width: width,
    height: height,
    format: format,
    estimatedBytes: estimatedBytes ?? this.estimatedBytes,
    recommendedQuality: recommendedQuality ?? this.recommendedQuality,
    qualityOverride: clearQualityOverride
        ? null
        : qualityOverride ?? this.qualityOverride,
    status: status ?? this.status,
    progress: progress ?? this.progress,
    errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    outputPath: clearOutputPath ? null : outputPath ?? this.outputPath,
    outputBytes: outputBytes ?? this.outputBytes,
  );
}

/// Global settings applied to every batch entry unless an item override exists.
class BatchCompressionSettings {
  const BatchCompressionSettings({
    this.preset = 'Balanced',
    this.quality = 72,
    this.format = BatchOutputFormat.jpeg,
    this.resize = BatchResizeChoice.original,
    this.keepMetadata = false,
    this.targetBytes,
  });

  final String preset;
  final int quality;
  final BatchOutputFormat format;
  final BatchResizeChoice resize;
  final bool keepMetadata;
  final int? targetBytes;

  BatchCompressionSettings copyWith({
    String? preset,
    int? quality,
    BatchOutputFormat? format,
    BatchResizeChoice? resize,
    bool? keepMetadata,
    int? targetBytes,
    bool clearTargetBytes = false,
  }) => BatchCompressionSettings(
    preset: preset ?? this.preset,
    quality: quality ?? this.quality,
    format: format ?? this.format,
    resize: resize ?? this.resize,
    keepMetadata: keepMetadata ?? this.keepMetadata,
    targetBytes: clearTargetBytes ? null : targetBytes ?? this.targetBytes,
  );
}

/// Result returned by the presentation processor seam.
class BatchImageResult {
  const BatchImageResult({required this.outputPath, required this.outputBytes});

  final String outputPath;
  final int outputBytes;
}

/// A prepared batch ZIP archive ready for the user to save or share.
class BatchZipResult {
  const BatchZipResult({
    required this.path,
    required this.name,
    required this.bytes,
    required this.fileCount,
  });

  /// Absolute path of the generated archive.
  final String path;

  /// Safe display name of the archive (including the `.zip` extension).
  final String name;

  /// Total archive size in bytes.
  final int bytes;

  /// Number of compressed outputs packed into the archive.
  final int fileCount;
}

typedef BatchImagePicker = Future<List<BatchImageItem>> Function();
typedef BatchImageProcessor =
    Future<BatchImageResult> Function(
      BatchImageItem image,
      BatchCompressionSettings settings,
    );

/// Persists generated outputs to the device gallery (Pictures / Comprezza).
typedef BatchSaveAllHandler = Future<void> Function(List<String> outputPaths);

/// Dispatches generated files through the system share sheet.
typedef BatchShareHandler = Future<void> Function(List<String> filePaths);

/// Builds a STORE-method ZIP archive from generated outputs.
typedef BatchZipBuilder =
    Future<BatchZipResult> Function(List<String> outputPaths);

/// Persists a ZIP archive to the device Downloads folder.
typedef BatchZipSaver = Future<void> Function(String zipPath);

/// A small summary object used by the completion surface.
class BatchCompressionSummary {
  const BatchCompressionSummary({
    required this.total,
    required this.processed,
    required this.skipped,
    required this.failed,
    required this.cancelled,
    required this.originalBytes,
    required this.compressedBytes,
    required this.duration,
  });

  final int total;
  final int processed;
  final int skipped;
  final int failed;
  final int cancelled;
  final int originalBytes;
  final int compressedBytes;
  final Duration duration;

  /// Original bytes belonging to successfully completed entries. This is the
  /// denominator for savings because failed/skipped inputs produced no output.
  int get processedOriginalBytes => originalBytes;
  int get savedBytes => (processedOriginalBytes - compressedBytes)
      .clamp(0, processedOriginalBytes)
      .toInt();
  double get ratio =>
      compressedBytes == 0 ? 0 : processedOriginalBytes / compressedBytes;
}

/// Presentation-only queue coordinator. The picker and processor are injected
/// so the screen can be tested now and connected to the frozen application
/// contracts only after the architecture freeze is lifted.
class BatchCompressionController extends ChangeNotifier {
  BatchCompressionController({
    required BatchImagePicker picker,
    required BatchImageProcessor processor,
    HistoryStorage? history,
    this.saveAllHandler,
    this.shareHandler,
    this.zipBuilder,
    this.zipSaver,
  }) : _picker = picker,
       _processor = processor,
       _history = history;

  final BatchImagePicker _picker;
  final BatchImageProcessor _processor;

  /// Optional device-gallery persistence seam (wired by the DI adapter).
  final BatchSaveAllHandler? saveAllHandler;

  /// Optional share-sheet dispatch seam (used for images and ZIP archives).
  final BatchShareHandler? shareHandler;

  /// Optional ZIP archive builder seam.
  final BatchZipBuilder? zipBuilder;

  /// Optional ZIP-to-Downloads persistence seam.
  final BatchZipSaver? zipSaver;

  /// Optional persistent history sink. When present, completed batches record
  /// an aggregated session so the History and Insights destinations count them.
  final HistoryStorage? _history;

  /// Stable record id for the current queue so retrying failed items replaces
  /// the session record with updated totals instead of duplicating it.
  String? _sessionRecordId;
  final List<BatchImageItem> _items = <BatchImageItem>[];
  final Set<String> _selectedIds = <String>{};
  BatchCompressionSettings _settings = const BatchCompressionSettings();
  BatchWorkflowPhase _phase = BatchWorkflowPhase.selection;
  bool _selecting = false;
  bool _analysisCancelled = false;
  bool _pauseRequested = false;
  bool _cancelRequested = false;
  bool _disposed = false;
  int _analyzedCount = 0;
  Completer<void>? _resumeGate;
  DateTime? _processingStartedAt;
  Timer? _notificationTimer;
  bool _exporting = false;

  BatchWorkflowPhase get phase => _phase;
  List<BatchImageItem> get items => List<BatchImageItem>.unmodifiable(_items);
  BatchCompressionSettings get settings => _settings;
  bool get isSelecting => _selecting;
  bool get isPaused => _pauseRequested;
  bool get isProcessing => _phase == BatchWorkflowPhase.processing;
  bool get isBusy => isProcessing || _phase == BatchWorkflowPhase.analyzing;

  /// Whether a save-all / share / ZIP operation is in flight.
  bool get isExporting => _exporting;

  int get selectedCount =>
      _items.where((BatchImageItem item) => _isSelected(item)).length;
  int get analyzedCount => _analyzedCount.clamp(0, _items.length).toInt();
  double get analysisProgress =>
      _items.isEmpty ? 0 : analyzedCount / _items.length;

  int get totalBytes => _items.fold<int>(
    0,
    (int total, BatchImageItem item) => total + item.bytes,
  );

  int get estimatedBytes => _items.fold<int>(
    0,
    (int total, BatchImageItem item) =>
        total +
        (item.estimatedBytes ??
            _estimate(item.bytes, item.qualityOverride ?? _settings.quality)),
  );

  double get overallProgress {
    if (_items.isEmpty) return 0;
    final double total = _items.fold<double>(
      0,
      (double sum, BatchImageItem item) =>
          sum + (_isTerminal(item.status) ? 1 : item.progress),
    );
    return (total / _items.length).clamp(0, 1);
  }

  int get completedCount => _items
      .where((BatchImageItem item) => item.status == BatchQueueStatus.completed)
      .length;
  int get failedCount => _items
      .where((BatchImageItem item) => item.status == BatchQueueStatus.failed)
      .length;

  /// Output paths of every completed item, in queue order.
  List<String> get completedOutputPaths => _items
      .where(
        (BatchImageItem item) =>
            item.status == BatchQueueStatus.completed &&
            item.outputPath != null,
      )
      .map((BatchImageItem item) => item.outputPath!)
      .toList(growable: false);

  /// Output paths of the completed items the user still has selected.
  List<String> get selectedCompletedOutputPaths => _items
      .where(
        (BatchImageItem item) =>
            item.status == BatchQueueStatus.completed &&
            item.outputPath != null &&
            _selectedIds.contains(item.id),
      )
      .map((BatchImageItem item) => item.outputPath!)
      .toList(growable: false);

  int get remainingCount => _items.where((BatchImageItem item) {
    return item.status == BatchQueueStatus.waiting ||
        item.status == BatchQueueStatus.paused ||
        item.status == BatchQueueStatus.compressing;
  }).length;

  int get _completedOriginalBytes => _items.fold<int>(
    0,
    (int total, BatchImageItem item) =>
        total + (item.status == BatchQueueStatus.completed ? item.bytes : 0),
  );

  int get processingSpeedBytesPerSecond {
    final DateTime? started = _processingStartedAt;
    if (started == null) return 0;
    final int elapsedSeconds = DateTime.now().difference(started).inSeconds;
    if (elapsedSeconds <= 0 || _completedOriginalBytes <= 0) return 0;
    return _completedOriginalBytes ~/ elapsedSeconds;
  }

  Duration get estimatedRemaining {
    final int speed = processingSpeedBytesPerSecond;
    if (speed <= 0) return Duration.zero;
    final int remainingBytes = _items.fold<int>(
      0,
      (int total, BatchImageItem item) =>
          total +
          (item.status == BatchQueueStatus.waiting ||
                  item.status == BatchQueueStatus.compressing ||
                  item.status == BatchQueueStatus.paused
              ? item.bytes
              : 0),
    );
    return Duration(seconds: (remainingBytes / speed).ceil());
  }

  BatchCompressionSummary get summary => BatchCompressionSummary(
    total: _items.length,
    processed: completedCount,
    skipped: _items
        .where((BatchImageItem item) => item.status == BatchQueueStatus.skipped)
        .length,
    failed: failedCount,
    cancelled: _items
        .where(
          (BatchImageItem item) => item.status == BatchQueueStatus.cancelled,
        )
        .length,
    originalBytes: _items.fold<int>(
      0,
      (int total, BatchImageItem item) =>
          total + (item.status == BatchQueueStatus.completed ? item.bytes : 0),
    ),
    compressedBytes: _items.fold<int>(
      0,
      (int total, BatchImageItem item) => total + (item.outputBytes ?? 0),
    ),
    duration: _processingStartedAt == null
        ? Duration.zero
        : DateTime.now().difference(_processingStartedAt!),
  );

  Future<void> selectImages() async {
    if (_disposed || _selecting || isBusy) return;
    _selecting = true;
    _notify();
    try {
      final List<BatchImageItem> picked = await _picker();
      if (_disposed) return;
      addImages(picked);
    } finally {
      _selecting = false;
      _notify(immediate: true);
    }
  }

  void addImages(Iterable<BatchImageItem> images) {
    if (_disposed) return;
    // A batch completed earlier in this queue is a finished session; adding
    // new images starts a fresh one that must not replace its record.
    if (_phase == BatchWorkflowPhase.completed) _sessionRecordId = null;
    final Set<String> existingPaths = _items
        .map((BatchImageItem item) => item.path)
        .toSet();
    final Set<String> existingIds = _items
        .map((BatchImageItem item) => item.id)
        .toSet();
    for (final BatchImageItem image in images) {
      if (!existingPaths.add(image.path)) continue;
      String uniqueId = image.id;
      int suffix = 2;
      while (!existingIds.add(uniqueId)) {
        uniqueId = '${image.id}-$suffix';
        suffix++;
      }
      final BatchImageItem normalized = image.copyWith(id: uniqueId);
      _items.add(normalized);
      _selectedIds.add(uniqueId);
    }
    if (_items.isNotEmpty && _phase == BatchWorkflowPhase.selection) {
      _phase = BatchWorkflowPhase.preview;
    }
    _notify();
  }

  void removeImage(String id) {
    if (_disposed || isBusy) return;
    _items.removeWhere((BatchImageItem item) => item.id == id);
    _selectedIds.remove(id);
    if (_items.isEmpty) {
      _sessionRecordId = null;
      _phase = BatchWorkflowPhase.selection;
    }
    _notify();
  }

  void selectAll() {
    if (_disposed || isBusy) return;
    _selectedIds
      ..clear()
      ..addAll(_items.map((BatchImageItem item) => item.id));
    _notify();
  }

  void deselectAll() {
    if (_disposed || isBusy) return;
    _selectedIds.clear();
    _notify();
  }

  void toggleSelection(String id) {
    if (_disposed || isBusy) return;
    if (!_selectedIds.remove(id)) _selectedIds.add(id);
    _notify();
  }

  bool isSelected(String id) => _selectedIds.contains(id);

  void openSettings() {
    if (_disposed || _items.isEmpty || isBusy) return;
    _phase = BatchWorkflowPhase.settings;
    _notify();
  }

  void showPreview() {
    if (_disposed || _items.isEmpty || isBusy) return;
    _phase = BatchWorkflowPhase.preview;
    _notify();
  }

  void updateSettings(BatchCompressionSettings settings) {
    if (_disposed) return;
    _settings = settings;
    for (int index = 0; index < _items.length; index++) {
      final BatchImageItem item = _items[index];
      _items[index] = item.copyWith(
        estimatedBytes: _estimate(
          item.bytes,
          item.qualityOverride ?? settings.quality,
        ),
      );
    }
    _notify();
  }

  void setItemQualityOverride(String id, int? quality) {
    if (_disposed) return;
    final int? bounded = quality?.clamp(1, 100).toInt();
    final int index = _items.indexWhere((BatchImageItem item) => item.id == id);
    if (index < 0 || isProcessing) return;
    _items[index] = _items[index].copyWith(
      qualityOverride: bounded,
      clearQualityOverride: bounded == null,
      estimatedBytes: _estimate(
        _items[index].bytes,
        bounded ?? _settings.quality,
      ),
    );
    _notify();
  }

  /// Keeps queue reordering architecture-ready without retaining decoded data.
  void reorder(int oldIndex, int newIndex) {
    if (_disposed ||
        isProcessing ||
        oldIndex < 0 ||
        oldIndex >= _items.length) {
      return;
    }
    if (newIndex > oldIndex) newIndex -= 1;
    if (newIndex < 0 || newIndex >= _items.length) return;
    final BatchImageItem item = _items.removeAt(oldIndex);
    _items.insert(newIndex, item);
    _notify();
  }

  Future<bool> analyze() async {
    if (_disposed || _items.isEmpty || _phase == BatchWorkflowPhase.analyzing) {
      return false;
    }
    _analysisCancelled = false;
    _analyzedCount = 0;
    _phase = BatchWorkflowPhase.analyzing;
    _notify();
    for (int index = 0; index < _items.length; index++) {
      if (_analysisCancelled || _disposed) break;
      _items[index] = _items[index].copyWith(
        status: BatchQueueStatus.analyzing,
        progress: 0,
      );
      _notify();
      await Future<void>.delayed(Duration.zero);
      if (_analysisCancelled || _disposed) break;
      final BatchImageItem item = _items[index];
      _items[index] = item.copyWith(
        status: BatchQueueStatus.waiting,
        progress: 0,
        recommendedQuality: _recommendedQuality(item),
        // Recommendations remain advisory; processing uses the global
        // setting unless an explicit per-image override exists.
        estimatedBytes: _estimate(
          item.bytes,
          item.qualityOverride ?? _settings.quality,
        ),
        clearError: true,
      );
      _analyzedCount++;
      _notify();
    }
    if (_disposed) return false;
    if (_analysisCancelled) {
      for (int index = 0; index < _items.length; index++) {
        if (_items[index].status == BatchQueueStatus.analyzing) {
          _items[index] = _items[index].copyWith(
            status: BatchQueueStatus.waiting,
            progress: 0,
          );
        }
      }
      _phase = _items.isEmpty
          ? BatchWorkflowPhase.selection
          : BatchWorkflowPhase.preview;
      _notify(immediate: true);
      return false;
    }
    _phase = BatchWorkflowPhase.preview;
    _notify(immediate: true);
    return true;
  }

  void pause() {
    if (_disposed || !isProcessing || _pauseRequested) return;
    _pauseRequested = true;
    // The processor seam is currently not cancellable. Keep the active item
    // marked compressing until it returns; the pause applies between items.
    _resumeGate = Completer<void>();
    _notify(immediate: true);
  }

  void resume() {
    if (_disposed || !isProcessing || !_pauseRequested) return;
    _pauseRequested = false;
    _resumeGate?.complete();
    _resumeGate = null;
    _notify(immediate: true);
  }

  void cancel() {
    if (_disposed || !isProcessing) return;
    _cancelRequested = true;
    _pauseRequested = false;
    _resumeGate?.complete();
    _resumeGate = null;
    _notify(immediate: true);
  }

  Future<void> startProcessing({bool retryFailedOnly = false}) async {
    if (_disposed || _items.isEmpty || isBusy) return;
    if (!retryFailedOnly) {
      final bool analysisCompleted = await analyze();
      if (!analysisCompleted || _items.isEmpty) return;
    } else {
      for (int index = 0; index < _items.length; index++) {
        if (_items[index].status == BatchQueueStatus.failed &&
            _selectedIds.contains(_items[index].id)) {
          _items[index] = _items[index].copyWith(
            status: BatchQueueStatus.waiting,
            progress: 0,
            clearError: true,
          );
        }
      }
    }
    _cancelRequested = false;
    _pauseRequested = false;
    _phase = BatchWorkflowPhase.processing;
    _processingStartedAt = DateTime.now();
    _notify();

    for (int index = 0; index < _items.length; index++) {
      if (_cancelRequested || _disposed) {
        _markRemainingCancelled(index);
        break;
      }
      await _waitForResume();
      if (_disposed) return;
      if (_cancelRequested || _disposed) {
        _markRemainingCancelled(index);
        break;
      }
      final BatchImageItem item = _items[index];
      if (!_selectedIds.contains(item.id)) {
        _items[index] = item.copyWith(
          status: BatchQueueStatus.skipped,
          progress: 0,
        );
        _notify();
        continue;
      }
      if (item.status != BatchQueueStatus.waiting) continue;
      _items[index] = item.copyWith(
        status: BatchQueueStatus.compressing,
        progress: 0,
      );
      _notify();
      try {
        final BatchImageResult result = await _processor(
          _items[index],
          _settings.copyWith(
            quality: _items[index].qualityOverride ?? _settings.quality,
          ),
        );
        if (_disposed) return;
        if (result.outputBytes < 0) {
          throw const FormatException(
            'Processor returned a negative output size.',
          );
        }
        _items[index] = _items[index].copyWith(
          status: BatchQueueStatus.completed,
          progress: 1,
          outputPath: result.outputPath,
          outputBytes: result.outputBytes,
          clearError: true,
        );
      } catch (error) {
        if (_disposed) return;
        _items[index] = _items[index].copyWith(
          status: _cancelRequested
              ? BatchQueueStatus.cancelled
              : BatchQueueStatus.failed,
          progress: 0,
          errorMessage: _cancelRequested ? null : error.toString(),
          clearError: _cancelRequested,
        );
        _notify(immediate: true);
        continue;
      }
      _notify();
    }
    _phase = BatchWorkflowPhase.completed;
    if (completedCount > 0) unawaited(_recordHistory());
    _notify(immediate: true);
  }

  /// Persists one aggregated session record for the completed batch.
  ///
  /// Best-effort and non-blocking: a failed history write must never fail a
  /// completed batch. The record carries the aggregate bytes and file count,
  /// which the history/insights screens derive their metrics from. Retrying
  /// failed items reuses the same record id so `save` replaces the session
  /// with its final totals.
  Future<void> _recordHistory() async {
    final HistoryStorage? history = _history;
    if (history == null || _disposed) return;
    final BatchCompressionSummary summary = this.summary;
    final List<BatchImageItem> completed = _items
        .where(
          (BatchImageItem item) => item.status == BatchQueueStatus.completed,
        )
        .toList(growable: false);
    if (completed.isEmpty) return;
    final int fileCount = completed.length;
    final int originalBytes = summary.processedOriginalBytes;
    final int outputBytes = summary.compressedBytes;
    final int savedBytes = summary.savedBytes;
    final double ratio = summary.ratio;
    // A cheap deterministic identity for the aggregate (not a content hash).
    final String checksum = sha256
        .convert(utf8.encode('batch|$fileCount|$originalBytes|$outputBytes'))
        .toString();
    final String preset = _settings.targetBytes == null
        ? 'Batch · Quality ${_settings.quality}'
        : 'Batch · Target ${FileSizeFormatter.format(_settings.targetBytes!)}';
    final String id = _sessionRecordId ??=
        '${DateTime.now().microsecondsSinceEpoch}';
    final DateTime now = DateTime.now();
    try {
      await history.save(
        CompressionHistoryRecord(
          id: id,
          originalPath: completed.first.path,
          compressedPath: completed.first.outputPath ?? completed.first.path,
          createdAt: now,
          preset: preset,
          compressionRatio: ratio,
          savedBytes: savedBytes,
          checksum: checksum,
          processedFiles: fileCount,
        ),
      );
    } catch (_) {
      // Best-effort recording: storage failures are intentionally ignored so
      // a completed batch is never surfaced as an error.
    }
  }

  Future<void> retryFailed({String? itemId}) {
    if (_disposed) return Future<void>.value();
    for (final BatchImageItem item in _items) {
      if (item.status == BatchQueueStatus.failed &&
          (itemId == null || item.id == itemId)) {
        _selectedIds.add(item.id);
      }
    }
    return startProcessing(retryFailedOnly: true);
  }

  /// Returns the queue to an empty, reusable state without retaining paths or
  /// output metadata from the previous batch.
  void startOver() {
    if (_disposed || isProcessing || _selecting) return;
    _analysisCancelled = true;
    _cancelRequested = true;
    _pauseRequested = false;
    _resumeGate?.complete();
    _resumeGate = null;
    _items.clear();
    _selectedIds.clear();
    _analyzedCount = 0;
    _sessionRecordId = null;
    _phase = BatchWorkflowPhase.selection;
    _processingStartedAt = null;
    _notify(immediate: true);
  }

  void cancelAnalysis() {
    if (_disposed || _phase != BatchWorkflowPhase.analyzing) return;
    // Keep the phase busy until the cooperative analysis loop observes the
    // request, preventing list edits while an index is being analyzed.
    _analysisCancelled = true;
    _notify();
  }

  /// Saves every completed output to the device gallery.
  ///
  /// Returns the number of files saved, or 0 when there is nothing to save
  /// or the persistence seam is not wired. Errors from the seam propagate so
  /// the screen can surface them as human-readable messages.
  Future<int> saveAll() async {
    final BatchSaveAllHandler? handler = saveAllHandler;
    if (_disposed || _exporting || handler == null) return 0;
    final List<String> paths = completedOutputPaths;
    if (paths.isEmpty) return 0;
    return _guardedExport<int>(() async {
      await handler(paths);
      return paths.length;
    });
  }

  /// Shares the completed outputs the user still has selected.
  ///
  /// Falls back to every completed output when the selection is empty, so
  /// "Share selected" never silently drops work the user already finished.
  Future<int> shareSelected() async {
    final BatchShareHandler? handler = shareHandler;
    if (_disposed || _exporting || handler == null) return 0;
    final List<String> targets = selectedCompletedOutputPaths;
    final List<String> paths = targets.isEmpty ? completedOutputPaths : targets;
    if (paths.isEmpty) return 0;
    return _guardedExport<int>(() async {
      await handler(paths);
      return paths.length;
    });
  }

  /// Builds a ZIP archive containing every completed output.
  Future<BatchZipResult> prepareZip() async {
    final BatchZipBuilder? builder = zipBuilder;
    if (_disposed || _exporting || builder == null) {
      throw StateError('ZIP building is unavailable.');
    }
    final List<String> paths = completedOutputPaths;
    if (paths.isEmpty) {
      throw StateError('There are no completed outputs to archive.');
    }
    return _guardedExport<BatchZipResult>(() => builder(paths));
  }

  /// Saves a prepared ZIP archive to the device Downloads folder.
  Future<void> saveZip(String zipPath) async {
    final BatchZipSaver? saver = zipSaver;
    if (_disposed || _exporting || saver == null) return;
    await _guardedExport<void>(() => saver(zipPath));
  }

  /// Shares a prepared ZIP archive through the system share sheet.
  Future<void> shareZip(String zipPath) async {
    final BatchShareHandler? handler = shareHandler;
    if (_disposed || _exporting || handler == null) return;
    await _guardedExport<void>(() => handler(<String>[zipPath]));
  }

  /// Runs an export/share/zip seam while toggling the busy state.
  Future<T> _guardedExport<T>(Future<T> Function() operation) async {
    _exporting = true;
    _notify(immediate: true);
    try {
      return await operation();
    } finally {
      _exporting = false;
      if (!_disposed) _notify(immediate: true);
    }
  }

  /// Allows a future processor adapter to report bounded per-image progress.
  void setItemProgress(String id, double progress) {
    if (_disposed) return;
    final int index = _items.indexWhere((BatchImageItem item) => item.id == id);
    if (index < 0 || _items[index].status != BatchQueueStatus.compressing) {
      return;
    }
    _items[index] = _items[index].copyWith(
      progress: progress.clamp(0, 1).toDouble(),
    );
    _notify();
  }

  Future<void> _waitForResume() async {
    while (_pauseRequested && !_cancelRequested) {
      final Completer<void> gate = _resumeGate ??= Completer<void>();
      await gate.future;
    }
  }

  void _markRemainingCancelled(int startIndex) {
    for (int index = startIndex; index < _items.length; index++) {
      if (_items[index].status == BatchQueueStatus.waiting ||
          _items[index].status == BatchQueueStatus.paused) {
        _items[index] = _items[index].copyWith(
          status: BatchQueueStatus.cancelled,
          progress: 0,
        );
      }
    }
  }

  bool _isSelected(BatchImageItem item) => _selectedIds.contains(item.id);

  bool _isTerminal(BatchQueueStatus status) =>
      status == BatchQueueStatus.completed ||
      status == BatchQueueStatus.failed ||
      status == BatchQueueStatus.cancelled ||
      status == BatchQueueStatus.skipped;

  int _recommendedQuality(BatchImageItem item) {
    if (item.width >= 4000 || item.height >= 4000) return 68;
    if (item.bytes >= 8 * 1024 * 1024) return 70;
    return _settings.quality;
  }

  void _notify({bool immediate = false}) {
    if (_disposed) return;
    if (immediate) {
      _notificationTimer?.cancel();
      _notificationTimer = null;
      notifyListeners();
      return;
    }
    // Batch progress can update hundreds of times in a long session. Coalesce
    // rebuilds to roughly one notification per frame while preserving the
    // latest immutable queue state.
    if (_notificationTimer != null) return;
    _notificationTimer = Timer(const Duration(milliseconds: 16), () {
      _notificationTimer = null;
      if (!_disposed) notifyListeners();
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _notificationTimer?.cancel();
    _notificationTimer = null;
    _analysisCancelled = true;
    _cancelRequested = true;
    _resumeGate?.complete();
    _resumeGate = null;
    _items.clear();
    _selectedIds.clear();
    _sessionRecordId = null;
    super.dispose();
  }

  int _estimate(int bytes, int quality) {
    final double factor = .18 + quality / 100 * .62;
    return (bytes * factor).round().clamp(1, bytes).toInt();
  }
}
