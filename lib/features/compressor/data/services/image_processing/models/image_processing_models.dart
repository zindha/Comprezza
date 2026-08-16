import '../../../../../../core/constants/app_constants.dart';

/// Supported image formats exposed by the replaceable codec platform.
enum ImageFormat {
  /// JPEG format.
  jpeg,

  /// PNG format.
  png,

  /// WebP format.
  webp,

  /// HEIC extension point.
  heic,

  /// AVIF extension point.
  avif,

  /// JPEG XL extension point.
  jpegXl,
}

/// Converts formats to file extensions and codec names.
extension ImageFormatX on ImageFormat {
  /// File extension without a leading dot.
  String get extension => switch (this) {
    ImageFormat.jpeg => 'jpg',
    ImageFormat.png => 'png',
    ImageFormat.webp => 'webp',
    ImageFormat.heic => 'heic',
    ImageFormat.avif => 'avif',
    ImageFormat.jpegXl => 'jxl',
  };

  /// Whether this format is implemented by the current native codec adapter.
  bool get isImplemented => switch (this) {
    ImageFormat.jpeg || ImageFormat.png || ImageFormat.webp => true,
    ImageFormat.heic || ImageFormat.avif || ImageFormat.jpegXl => false,
  };

  /// Resolves a format from a file path or returns null for unknown formats.
  static ImageFormat? fromPath(String path) {
    final String extension = path.split('.').last.toLowerCase();
    return switch (extension) {
      'jpg' || 'jpeg' => ImageFormat.jpeg,
      'png' => ImageFormat.png,
      'webp' => ImageFormat.webp,
      'heic' || 'heif' => ImageFormat.heic,
      'avif' => ImageFormat.avif,
      'jxl' => ImageFormat.jpegXl,
      _ => null,
    };
  }
}

/// Selects whether a codec may discard information.
enum CompressionMode {
  /// Quality-driven compression.
  lossy,

  /// Information-preserving compression where the codec supports it.
  lossless,
}

/// Named quality presets shared by future UI and batch workflows.
enum CompressionPreset {
  /// Preserve the most visual quality.
  maximumQuality,

  /// Balanced quality and size.
  balanced,

  /// Prefer a small output.
  smallestSize,

  /// Apply aggressive compression.
  extremeCompression,

  /// Use the explicit quality value.
  custom,
}

/// Resize strategy for a processing request.
class ResizeOptions {
  /// Creates resize options.
  const ResizeOptions.percentage(this.value, {this.preserveAspectRatio = true})
    : mode = ResizeMode.percentage,
      width = null,
      height = null;

  /// Creates a width-constrained resize.
  const ResizeOptions.width(this.value, {this.preserveAspectRatio = true})
    : mode = ResizeMode.width,
      width = value,
      height = null;

  /// Creates a height-constrained resize.
  const ResizeOptions.height(this.value, {this.preserveAspectRatio = true})
    : mode = ResizeMode.height,
      width = null,
      height = value;

  /// Creates an explicit dimension resize.
  const ResizeOptions.dimensions({
    required this.width,
    required this.height,
    this.preserveAspectRatio = true,
  }) : mode = ResizeMode.dimensions,
       value = null;

  /// Resize mode.
  final ResizeMode mode;

  /// Percentage or single-axis value.
  final int? value;

  /// Target width when supplied.
  final int? width;

  /// Target height when supplied.
  final int? height;

  /// Whether the codec should preserve the source aspect ratio.
  final bool preserveAspectRatio;
}

/// Supported resize modes.
enum ResizeMode { percentage, width, height, dimensions }

/// Metadata retention policy.
enum MetadataPolicy {
  /// Preserve metadata when the selected codec supports it.
  keepExif,

  /// Remove metadata during the output encode.
  removeExif,
}

/// The operation requested from the engine manager.
enum ProcessingOperation { compress, resize, convert, metadata }

/// A request understood by the engine platform.
class ProcessingRequest {
  /// Creates a processing request.
  const ProcessingRequest({
    required this.sourcePath,
    required this.operation,
    this.compression = const CompressionOptions(),
    this.resize,
    this.metadataPolicy = MetadataPolicy.removeExif,
    this.sourceWidth,
    this.sourceHeight,
    this.sourceBytes,
  });

  /// Local source path selected or created by the data layer.
  final String sourcePath;

  /// Requested operation.
  final ProcessingOperation operation;

  /// Compression and output format options.
  final CompressionOptions compression;

  /// Optional resize operation.
  final ResizeOptions? resize;

  /// Metadata policy for the output.
  final MetadataPolicy metadataPolicy;

  /// Optional source width used for percentage resize planning.
  final int? sourceWidth;

  /// Optional source height used for percentage resize planning.
  final int? sourceHeight;

  /// Optional source size supplied by a data boundary for benchmarking.
  final int? sourceBytes;
}

/// Compression and target-size options.
class CompressionOptions {
  /// Creates compression options.
  const CompressionOptions({
    this.quality = AppConstants.defaultQuality,
    this.preset = CompressionPreset.balanced,
    this.mode = CompressionMode.lossy,
    this.format = ImageFormat.jpeg,
    this.keepExif = false,
    this.targetBytes,
    this.maxWidth,
    this.maxHeight,
  });

  /// Requested quality from 1 to 100.
  final int quality;

  /// Named preset used to derive quality when not custom.
  final CompressionPreset preset;

  /// Lossy or lossless policy.
  final CompressionMode mode;

  /// Desired output format.
  final ImageFormat format;

  /// Whether EXIF data should be retained.
  final bool keepExif;

  /// Optional maximum output size in bytes.
  final int? targetBytes;

  /// Optional maximum output width.
  final int? maxWidth;

  /// Optional maximum output height.
  final int? maxHeight;

  /// Resolves the preset to a codec quality value.
  int get effectiveQuality => switch (preset) {
    CompressionPreset.maximumQuality => 95,
    CompressionPreset.balanced => 72,
    CompressionPreset.smallestSize => 45,
    CompressionPreset.extremeCompression => 20,
    CompressionPreset.custom => quality,
  };
}

/// Request to produce an image recommendation.
class AnalysisRequest {
  /// Creates an analysis request.
  const AnalysisRequest(
    this.sourcePath, {
    this.originalBytes,
    this.width,
    this.height,
  });

  /// Source path.
  final String sourcePath;

  /// Optional size supplied by the data boundary.
  final int? originalBytes;

  /// Optional source width.
  final int? width;

  /// Optional source height.
  final int? height;
}

/// Locally inferred image category.
enum ImageCategory {
  /// Camera photograph.
  photograph,

  /// Device or application screenshot.
  screenshot,

  /// Digital artwork.
  artwork,

  /// Illustration or line art.
  illustration,

  /// Wallpaper-like image.
  wallpaper,

  /// Scanned document.
  documentScan,
}

/// Heuristic recommendation returned by an analyzer.
class ImageAnalysis {
  /// Creates an analysis result.
  const ImageAnalysis({
    required this.category,
    required this.recommendedFormat,
    required this.recommendedQuality,
    required this.resizeRecommendation,
    required this.estimatedOutputBytes,
    required this.expectedSavingsRatio,
    required this.expectedQualityScore,
    required this.confidence,
  });

  /// Inferred image category.
  final ImageCategory category;

  /// Recommended output format.
  final ImageFormat recommendedFormat;

  /// Recommended quality.
  final int recommendedQuality;

  /// Optional resize guidance.
  final ResizeOptions? resizeRecommendation;

  /// Estimated output size.
  final int estimatedOutputBytes;

  /// Expected fractional storage savings.
  final double expectedSavingsRatio;

  /// Expected visual quality from zero to one.
  final double expectedQualityScore;

  /// Heuristic confidence from zero to one.
  final double confidence;
}

/// Input to the estimation engine.
class EstimationRequest {
  /// Creates an estimation request.
  const EstimationRequest({
    required this.originalBytes,
    required this.quality,
    required this.format,
    this.width,
    this.height,
    this.uploadBytesPerSecond,
    this.cloudStorageCostPerByte,
  });

  /// Original file size.
  final int originalBytes;

  /// Requested quality.
  final int quality;

  /// Requested output format.
  final ImageFormat format;

  /// Optional source width.
  final int? width;

  /// Optional source height.
  final int? height;

  /// Optional network estimate input, kept local and caller-supplied.
  final double? uploadBytesPerSecond;

  /// Optional caller-supplied storage cost model.
  final double? cloudStorageCostPerByte;
}

/// Output of storage and quality estimation.
class Estimation {
  /// Creates an estimation result.
  const Estimation({
    required this.estimatedOutputBytes,
    required this.compressionRatio,
    required this.storageSavingsRatio,
    required this.uploadTimeSavingsSeconds,
    required this.cloudStorageSavings,
    required this.qualityScore,
    required this.compressionScore,
  });

  /// Estimated output bytes.
  final int estimatedOutputBytes;

  /// Original-to-output size ratio.
  final double compressionRatio;

  /// Fractional storage savings.
  final double storageSavingsRatio;

  /// Estimated upload seconds saved.
  final double uploadTimeSavingsSeconds;

  /// Estimated cloud cost savings using the caller's model.
  final double cloudStorageSavings;

  /// Estimated visual quality score.
  final double qualityScore;

  /// Estimated compression score.
  final double compressionScore;
}

/// Request to apply a metadata policy through a codec.
class MetadataRequest {
  /// Creates a metadata request.
  const MetadataRequest({
    required this.sourcePath,
    required this.policy,
    this.format = ImageFormat.jpeg,
  });

  /// Source image path.
  final String sourcePath;

  /// Metadata policy.
  final MetadataPolicy policy;

  /// Output format used for the metadata pass.
  final ImageFormat format;
}

/// Metadata operation output.
class MetadataOutput {
  /// Creates a metadata output.
  const MetadataOutput({
    required this.outputPath,
    required this.bytes,
    required this.policy,
    required this.estimatedBytesSaved,
  });

  /// Generated output path.
  final String outputPath;

  /// Output byte length.
  final int bytes;

  /// Policy applied.
  final MetadataPolicy policy;

  /// Estimated bytes saved by metadata removal.
  final int estimatedBytesSaved;
}

/// Benchmark result for a completed local operation.
class ProcessingBenchmark {
  /// Creates a benchmark result.
  const ProcessingBenchmark({
    required this.name,
    required this.elapsed,
    required this.inputBytes,
    required this.outputBytes,
    required this.compressionRatio,
    this.memoryDeltaBytes,
    this.qualityScore,
  });

  /// Operation name.
  final String name;

  /// Wall-clock execution time.
  final Duration elapsed;

  /// Input bytes.
  final int inputBytes;

  /// Output bytes.
  final int outputBytes;

  /// Input-to-output ratio.
  final double compressionRatio;

  /// Optional process RSS delta.
  final int? memoryDeltaBytes;

  /// Optional quality score.
  final double? qualityScore;
}

/// Priority values for queued work.
enum QueuePriority { low, normal, high }

/// Cooperative cancellation token for queued operations.
class CancellationToken {
  bool _cancelled = false;

  /// Whether cancellation was requested.
  bool get isCancelled => _cancelled;

  /// Requests cooperative cancellation.
  void cancel() => _cancelled = true;
}

/// Output of a completed processing operation.
class ProcessingOutput {
  /// Creates an output descriptor.
  const ProcessingOutput({
    required this.outputPath,
    required this.bytes,
    required this.width,
    required this.height,
    required this.format,
    required this.quality,
  });

  /// Generated output path.
  final String outputPath;

  /// Output size in bytes.
  final int bytes;

  /// Output width.
  final int width;

  /// Output height.
  final int height;

  /// Output format.
  final ImageFormat format;

  /// Quality used for the encode.
  final int quality;
}
