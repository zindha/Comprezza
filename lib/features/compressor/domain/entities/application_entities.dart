import 'value_object.dart';

/// Formats supported by the application contract.
enum ImageFormat { jpeg, png, webp, heic, avif, jpegXl }

/// Lifecycle state shared by application workflows.
enum OperationStatus {
  idle,
  loading,
  success,
  error,
  empty,
  cancelled,
  paused,
  completed,
}

/// A user-selected image represented without a platform file handle.
final class SelectedImage {
  const SelectedImage({
    required this.id,
    required this.path,
    required this.name,
    required this.bytes,
    required this.width,
    required this.height,
    required this.format,
    this.checksum,
  });
  final String id;
  final String path;
  final String name;
  final int bytes;
  final int width;
  final int height;
  final ImageFormat format;
  final String? checksum;
  SelectedImage copyWith({
    String? id,
    String? path,
    String? name,
    int? bytes,
    int? width,
    int? height,
    ImageFormat? format,
    String? checksum,
  }) => SelectedImage(
    id: id ?? this.id,
    path: path ?? this.path,
    name: name ?? this.name,
    bytes: bytes ?? this.bytes,
    width: width ?? this.width,
    height: height ?? this.height,
    format: format ?? this.format,
    checksum: checksum ?? this.checksum,
  );
  @override
  bool operator ==(Object other) =>
      other is SelectedImage &&
      id == other.id &&
      path == other.path &&
      name == other.name &&
      bytes == other.bytes &&
      width == other.width &&
      height == other.height &&
      format == other.format &&
      checksum == other.checksum;
  @override
  int get hashCode =>
      Object.hash(id, path, name, bytes, width, height, format, checksum);
}

/// A generated image descriptor.
final class CompressedImage {
  const CompressedImage({
    required this.sourceId,
    required this.path,
    required this.name,
    required this.bytes,
    required this.width,
    required this.height,
    required this.format,
    required this.quality,
    required this.createdAt,
  });
  final String sourceId;
  final String path;
  final String name;
  final int bytes;
  final int width;
  final int height;
  final ImageFormat format;
  final int quality;
  final DateTime createdAt;
  @override
  bool operator ==(Object other) =>
      other is CompressedImage &&
      sourceId == other.sourceId &&
      path == other.path &&
      name == other.name &&
      bytes == other.bytes &&
      width == other.width &&
      height == other.height &&
      format == other.format &&
      quality == other.quality &&
      createdAt == other.createdAt;
  @override
  int get hashCode => Object.hash(
    sourceId,
    path,
    name,
    bytes,
    width,
    height,
    format,
    quality,
    createdAt,
  );
}

/// A named compression policy.
final class CompressionPreset {
  const CompressionPreset({
    required this.id,
    required this.name,
    required this.quality,
    this.targetBytes,
    this.format = ImageFormat.jpeg,
    this.keepMetadata = false,
  });
  final String id;
  final String name;
  final int quality;
  final int? targetBytes;
  final ImageFormat format;
  final bool keepMetadata;
  @override
  bool operator ==(Object other) =>
      other is CompressionPreset &&
      id == other.id &&
      name == other.name &&
      quality == other.quality &&
      targetBytes == other.targetBytes &&
      format == other.format &&
      keepMetadata == other.keepMetadata;
  @override
  int get hashCode =>
      Object.hash(id, name, quality, targetBytes, format, keepMetadata);
}

/// Resize constraints for one compression request.
final class ResizeSpec {
  const ResizeSpec({this.width, this.height, this.percentage});
  final int? width;
  final int? height;
  final int? percentage;
  bool get isEmpty => width == null && height == null && percentage == null;
  @override
  bool operator ==(Object other) =>
      other is ResizeSpec &&
      width == other.width &&
      height == other.height &&
      percentage == other.percentage;
  @override
  int get hashCode => Object.hash(width, height, percentage);
}

/// Input to compression, conversion, and resize workflows.
final class CompressionRequest {
  CompressionRequest({
    required Iterable<SelectedImage> images,
    required this.preset,
    this.quality,
    this.targetBytes,
    this.outputFormat,
    this.resize,
    this.keepMetadata,
  }) : images = immutableList(images);
  final List<SelectedImage> images;
  final CompressionPreset preset;
  final int? quality;
  final int? targetBytes;
  final ImageFormat? outputFormat;
  final ResizeSpec? resize;
  final bool? keepMetadata;
  int get effectiveQuality => quality ?? preset.quality;
  ImageFormat get effectiveFormat => outputFormat ?? preset.format;
  int? get effectiveTargetBytes => targetBytes ?? preset.targetBytes;
  bool get effectiveKeepMetadata => keepMetadata ?? preset.keepMetadata;
  @override
  bool operator ==(Object other) =>
      other is CompressionRequest &&
      deepEquals(images, other.images) &&
      preset == other.preset &&
      quality == other.quality &&
      targetBytes == other.targetBytes &&
      outputFormat == other.outputFormat &&
      resize == other.resize &&
      keepMetadata == other.keepMetadata;
  @override
  int get hashCode => Object.hash(
    deepHash(images),
    preset,
    quality,
    targetBytes,
    outputFormat,
    resize,
    keepMetadata,
  );
}

/// Result of processing one or more selected images.
final class CompressionResult {
  CompressionResult({
    required Iterable<CompressedImage> images,
    required this.statistics,
    this.benchmark,
  }) : images = immutableList(images);
  final List<CompressedImage> images;
  final CompressionStatistics statistics;
  final BenchmarkResult? benchmark;
  @override
  bool operator ==(Object other) =>
      other is CompressionResult &&
      deepEquals(images, other.images) &&
      statistics == other.statistics &&
      benchmark == other.benchmark;
  @override
  int get hashCode => Object.hash(deepHash(images), statistics, benchmark);
}

/// Analysis data used to guide recommendations without exposing engine types.
final class ImageAnalysis {
  const ImageAnalysis({
    required this.imageId,
    required this.format,
    required this.width,
    required this.height,
    required this.bytes,
    required this.hasAlpha,
    required this.recommendedPreset,
    this.averageLuminance,
    this.entropy,
  });
  final String imageId;
  final ImageFormat format;
  final int width;
  final int height;
  final int bytes;
  final bool hasAlpha;
  final CompressionPreset recommendedPreset;
  final double? averageLuminance;
  final double? entropy;
  @override
  bool operator ==(Object other) =>
      other is ImageAnalysis &&
      imageId == other.imageId &&
      format == other.format &&
      width == other.width &&
      height == other.height &&
      bytes == other.bytes &&
      hasAlpha == other.hasAlpha &&
      recommendedPreset == other.recommendedPreset &&
      averageLuminance == other.averageLuminance &&
      entropy == other.entropy;
  @override
  int get hashCode => Object.hash(
    imageId,
    format,
    width,
    height,
    bytes,
    hasAlpha,
    recommendedPreset,
    averageLuminance,
    entropy,
  );
}

/// Aggregate metrics for a completed compression operation.
final class CompressionStatistics {
  const CompressionStatistics({
    required this.inputBytes,
    required this.outputBytes,
    required this.savedBytes,
    required this.savingsRatio,
    required this.processedFiles,
    required this.duration,
  });
  final int inputBytes;
  final int outputBytes;
  final int savedBytes;
  final double savingsRatio;
  final int processedFiles;
  final Duration duration;
  @override
  bool operator ==(Object other) =>
      other is CompressionStatistics &&
      inputBytes == other.inputBytes &&
      outputBytes == other.outputBytes &&
      savedBytes == other.savedBytes &&
      savingsRatio == other.savingsRatio &&
      processedFiles == other.processedFiles &&
      duration == other.duration;
  @override
  int get hashCode => Object.hash(
    inputBytes,
    outputBytes,
    savedBytes,
    savingsRatio,
    processedFiles,
    duration,
  );
}

/// Local timing and throughput information for one workflow.
final class BenchmarkResult {
  const BenchmarkResult({
    required this.duration,
    required this.bytesPerSecond,
    required this.peakMemoryBytes,
  });
  final Duration duration;
  final double bytesPerSecond;
  final int? peakMemoryBytes;
  @override
  bool operator ==(Object other) =>
      other is BenchmarkResult &&
      duration == other.duration &&
      bytesPerSecond == other.bytesPerSecond &&
      peakMemoryBytes == other.peakMemoryBytes;
  @override
  int get hashCode => Object.hash(duration, bytesPerSecond, peakMemoryBytes);
}

/// One historical compression record.
final class HistoryEntry {
  const HistoryEntry({
    required this.id,
    required this.sourceName,
    required this.outputName,
    required this.createdAt,
    required this.statistics,
    required this.preset,
    this.outputPath,
  });
  final String id;
  final String sourceName;
  final String outputName;
  final DateTime createdAt;
  final CompressionStatistics statistics;
  final CompressionPreset preset;
  final String? outputPath;
  @override
  bool operator ==(Object other) =>
      other is HistoryEntry &&
      id == other.id &&
      sourceName == other.sourceName &&
      outputName == other.outputName &&
      createdAt == other.createdAt &&
      statistics == other.statistics &&
      preset == other.preset &&
      outputPath == other.outputPath;
  @override
  int get hashCode => Object.hash(
    id,
    sourceName,
    outputName,
    createdAt,
    statistics,
    preset,
    outputPath,
  );
}

/// An explicit export request.
final class ExportRequest {
  ExportRequest({
    required Iterable<CompressedImage> images,
    required this.destination,
    this.overwrite = false,
  }) : images = immutableList(images);
  final List<CompressedImage> images;
  final String destination;
  final bool overwrite;
  @override
  bool operator ==(Object other) =>
      other is ExportRequest &&
      deepEquals(images, other.images) &&
      destination == other.destination &&
      overwrite == other.overwrite;
  @override
  int get hashCode => Object.hash(deepHash(images), destination, overwrite);
}

/// User preferences kept platform-neutral for persistence and testing.
final class Settings {
  const Settings({
    this.theme = 'system',
    this.compressionQuality = 72,
    this.defaultFormat = ImageFormat.jpeg,
    this.keepMetadata = false,
    this.autoCleanup = true,
    this.defaultPreset,
    this.cloudBackupEnabled = false,
  });
  final String theme;
  final int compressionQuality;
  final ImageFormat defaultFormat;
  final bool keepMetadata;
  final bool autoCleanup;
  final CompressionPreset? defaultPreset;
  final bool cloudBackupEnabled;
  Settings copyWith({
    String? theme,
    int? compressionQuality,
    ImageFormat? defaultFormat,
    bool? keepMetadata,
    bool? autoCleanup,
    CompressionPreset? defaultPreset,
    bool clearDefaultPreset = false,
    bool? cloudBackupEnabled,
  }) => Settings(
    theme: theme ?? this.theme,
    compressionQuality: compressionQuality ?? this.compressionQuality,
    defaultFormat: defaultFormat ?? this.defaultFormat,
    keepMetadata: keepMetadata ?? this.keepMetadata,
    autoCleanup: autoCleanup ?? this.autoCleanup,
    defaultPreset: clearDefaultPreset
        ? null
        : defaultPreset ?? this.defaultPreset,
    cloudBackupEnabled: cloudBackupEnabled ?? this.cloudBackupEnabled,
  );
  @override
  bool operator ==(Object other) =>
      other is Settings &&
      theme == other.theme &&
      compressionQuality == other.compressionQuality &&
      defaultFormat == other.defaultFormat &&
      keepMetadata == other.keepMetadata &&
      autoCleanup == other.autoCleanup &&
      defaultPreset == other.defaultPreset &&
      cloudBackupEnabled == other.cloudBackupEnabled;
  @override
  int get hashCode => Object.hash(
    theme,
    compressionQuality,
    defaultFormat,
    keepMetadata,
    autoCleanup,
    defaultPreset,
    cloudBackupEnabled,
  );
}

/// Progress snapshot emitted by long-running use cases.
final class ProcessingProgress {
  const ProcessingProgress({
    this.currentFile,
    required this.completedFiles,
    required this.totalFiles,
    required this.currentFileProgress,
    required this.overallProgress,
    required this.speedBytesPerSecond,
    required this.estimatedTimeRemaining,
    required this.queuePosition,
  }) : assert(completedFiles >= 0),
       assert(totalFiles >= 0),
       assert(completedFiles <= totalFiles),
       assert(queuePosition >= 0),
       assert(currentFileProgress >= 0 && currentFileProgress <= 1),
       assert(overallProgress >= 0 && overallProgress <= 1),
       assert(speedBytesPerSecond >= 0),
       remainingFiles = totalFiles - completedFiles;
  final String? currentFile;
  final int completedFiles;
  final int totalFiles;
  final double currentFileProgress;
  final double overallProgress;
  final double speedBytesPerSecond;
  final Duration? estimatedTimeRemaining;
  final int queuePosition;
  final int remainingFiles;
  static const ProcessingProgress initial = ProcessingProgress(
    completedFiles: 0,
    totalFiles: 0,
    currentFileProgress: 0,
    overallProgress: 0,
    speedBytesPerSecond: 0,
    estimatedTimeRemaining: null,
    queuePosition: 0,
  );
  @override
  bool operator ==(Object other) =>
      other is ProcessingProgress &&
      currentFile == other.currentFile &&
      completedFiles == other.completedFiles &&
      totalFiles == other.totalFiles &&
      currentFileProgress == other.currentFileProgress &&
      overallProgress == other.overallProgress &&
      speedBytesPerSecond == other.speedBytesPerSecond &&
      estimatedTimeRemaining == other.estimatedTimeRemaining &&
      queuePosition == other.queuePosition &&
      remainingFiles == other.remainingFiles;
  @override
  int get hashCode => Object.hash(
    currentFile,
    completedFiles,
    totalFiles,
    currentFileProgress,
    overallProgress,
    speedBytesPerSecond,
    estimatedTimeRemaining,
    queuePosition,
    remainingFiles,
  );
}

/// Cooperative lifecycle control owned by an application workflow.
final class OperationControl {
  bool _cancelled = false;
  bool _paused = false;
  bool get isCancelled => _cancelled;
  bool get isPaused => _paused;
  void cancel() => _cancelled = true;
  void pause() {
    if (!_cancelled) _paused = true;
  }

  void resume() {
    if (!_cancelled) _paused = false;
  }
}
