import '../../domain/entities/entities.dart';

/// Home state for selection and recent workflow information.
final class HomeState {
  HomeState({
    this.status = OperationStatus.empty,
    Iterable<SelectedImage> images = const <SelectedImage>[],
    this.message,
    this.canRetry = false,
  }) : images = immutableList(images);

  final OperationStatus status;
  final List<SelectedImage> images;
  final String? message;
  final bool canRetry;

  HomeState copyWith({
    OperationStatus? status,
    Iterable<SelectedImage>? images,
    String? message,
    bool clearMessage = false,
    bool? canRetry,
  }) => HomeState(
    status: status ?? this.status,
    images: images ?? this.images,
    message: clearMessage ? null : message ?? this.message,
    canRetry: canRetry ?? this.canRetry,
  );

  @override
  bool operator ==(Object other) =>
      other is HomeState &&
      status == other.status &&
      deepEquals(images, other.images) &&
      message == other.message &&
      canRetry == other.canRetry;

  @override
  int get hashCode => Object.hash(status, deepHash(images), message, canRetry);
}

/// State for a single-image or multi-image compression action.
final class CompressionState {
  CompressionState({
    this.status = OperationStatus.empty,
    this.result,
    this.progress = ProcessingProgress.initial,
    this.message,
    this.canRetry = false,
  });

  final OperationStatus status;
  final CompressionResult? result;
  final ProcessingProgress progress;
  final String? message;
  final bool canRetry;

  CompressionState copyWith({
    OperationStatus? status,
    CompressionResult? result,
    bool clearResult = false,
    ProcessingProgress? progress,
    String? message,
    bool clearMessage = false,
    bool? canRetry,
  }) => CompressionState(
    status: status ?? this.status,
    result: clearResult ? null : result ?? this.result,
    progress: progress ?? this.progress,
    message: clearMessage ? null : message ?? this.message,
    canRetry: canRetry ?? this.canRetry,
  );

  @override
  bool operator ==(Object other) =>
      other is CompressionState &&
      status == other.status &&
      result == other.result &&
      progress == other.progress &&
      message == other.message &&
      canRetry == other.canRetry;

  @override
  int get hashCode => Object.hash(status, result, progress, message, canRetry);
}

/// State for a batch operation, including queue-visible progress.
final class BatchCompressionState {
  BatchCompressionState({
    this.status = OperationStatus.empty,
    Iterable<CompressedImage> results = const <CompressedImage>[],
    this.progress = ProcessingProgress.initial,
    this.message,
    this.canRetry = false,
  }) : results = immutableList(results);

  final OperationStatus status;
  final List<CompressedImage> results;
  final ProcessingProgress progress;
  final String? message;
  final bool canRetry;

  BatchCompressionState copyWith({
    OperationStatus? status,
    Iterable<CompressedImage>? results,
    ProcessingProgress? progress,
    String? message,
    bool clearMessage = false,
    bool? canRetry,
  }) => BatchCompressionState(
    status: status ?? this.status,
    results: results ?? this.results,
    progress: progress ?? this.progress,
    message: clearMessage ? null : message ?? this.message,
    canRetry: canRetry ?? this.canRetry,
  );

  @override
  bool operator ==(Object other) =>
      other is BatchCompressionState &&
      status == other.status &&
      deepEquals(results, other.results) &&
      progress == other.progress &&
      message == other.message &&
      canRetry == other.canRetry;

  @override
  int get hashCode =>
      Object.hash(status, deepHash(results), progress, message, canRetry);
}

/// State for persisted history.
final class HistoryState {
  HistoryState({
    this.status = OperationStatus.empty,
    Iterable<HistoryEntry> entries = const <HistoryEntry>[],
    this.message,
    this.canRetry = false,
  }) : entries = immutableList(entries);

  final OperationStatus status;
  final List<HistoryEntry> entries;
  final String? message;
  final bool canRetry;

  HistoryState copyWith({
    OperationStatus? status,
    Iterable<HistoryEntry>? entries,
    String? message,
    bool clearMessage = false,
    bool? canRetry,
  }) => HistoryState(
    status: status ?? this.status,
    entries: entries ?? this.entries,
    message: clearMessage ? null : message ?? this.message,
    canRetry: canRetry ?? this.canRetry,
  );

  @override
  bool operator ==(Object other) =>
      other is HistoryState &&
      status == other.status &&
      deepEquals(entries, other.entries) &&
      message == other.message &&
      canRetry == other.canRetry;

  @override
  int get hashCode => Object.hash(status, deepHash(entries), message, canRetry);
}

/// State for user settings.
final class SettingsState {
  const SettingsState({
    this.status = OperationStatus.empty,
    this.settings = const Settings(),
    this.message,
    this.canRetry = false,
  });

  final OperationStatus status;
  final Settings settings;
  final String? message;
  final bool canRetry;

  SettingsState copyWith({
    OperationStatus? status,
    Settings? settings,
    String? message,
    bool clearMessage = false,
    bool? canRetry,
  }) => SettingsState(
    status: status ?? this.status,
    settings: settings ?? this.settings,
    message: clearMessage ? null : message ?? this.message,
    canRetry: canRetry ?? this.canRetry,
  );

  @override
  bool operator ==(Object other) =>
      other is SettingsState &&
      status == other.status &&
      settings == other.settings &&
      message == other.message &&
      canRetry == other.canRetry;

  @override
  int get hashCode => Object.hash(status, settings, message, canRetry);
}

/// State for aggregate statistics.
final class StatisticsState {
  const StatisticsState({
    this.status = OperationStatus.empty,
    this.statistics,
    this.message,
    this.canRetry = false,
  });

  final OperationStatus status;
  final CompressionStatistics? statistics;
  final String? message;
  final bool canRetry;

  StatisticsState copyWith({
    OperationStatus? status,
    CompressionStatistics? statistics,
    bool clearStatistics = false,
    String? message,
    bool clearMessage = false,
    bool? canRetry,
  }) => StatisticsState(
    status: status ?? this.status,
    statistics: clearStatistics ? null : statistics ?? this.statistics,
    message: clearMessage ? null : message ?? this.message,
    canRetry: canRetry ?? this.canRetry,
  );

  @override
  bool operator ==(Object other) =>
      other is StatisticsState &&
      status == other.status &&
      statistics == other.statistics &&
      message == other.message &&
      canRetry == other.canRetry;

  @override
  int get hashCode => Object.hash(status, statistics, message, canRetry);
}

/// State for benchmark output.
final class BenchmarkState {
  const BenchmarkState({
    this.status = OperationStatus.empty,
    this.result,
    this.message,
    this.canRetry = false,
  });

  final OperationStatus status;
  final BenchmarkResult? result;
  final String? message;
  final bool canRetry;

  BenchmarkState copyWith({
    OperationStatus? status,
    BenchmarkResult? result,
    bool clearResult = false,
    String? message,
    bool clearMessage = false,
    bool? canRetry,
  }) => BenchmarkState(
    status: status ?? this.status,
    result: clearResult ? null : result ?? this.result,
    message: clearMessage ? null : message ?? this.message,
    canRetry: canRetry ?? this.canRetry,
  );

  @override
  bool operator ==(Object other) =>
      other is BenchmarkState &&
      status == other.status &&
      result == other.result &&
      message == other.message &&
      canRetry == other.canRetry;

  @override
  int get hashCode => Object.hash(status, result, message, canRetry);
}
