import '../../../../../../core/models/result.dart';
import '../models/image_processing_models.dart';

/// Common contract implemented by every replaceable processing engine.
abstract interface class ProcessingEngine {
  /// Stable engine identifier used by diagnostics and registry lookup.
  String get id;

  /// Whether this engine can execute [request].
  bool supports(ProcessingRequest request);

  /// Executes one operation without exposing raw exceptions.
  Future<Result<ProcessingOutput>> process(ProcessingRequest request);
}

/// Performs local image classification and recommendations.
abstract interface class ImageAnalyzerEngine {
  /// Stable analyzer identifier.
  String get id;

  /// Analyzes [request] locally.
  Future<Result<ImageAnalysis>> analyze(AnalysisRequest request);
}

/// Estimates output and storage metrics without writing files.
abstract interface class EstimationEngine {
  /// Estimates metrics for [request].
  Result<Estimation> estimate(EstimationRequest request);
}

/// Measures a completed local operation.
abstract interface class BenchmarkEngine {
  /// Runs a benchmark around [operation] and returns both measurements and output.
  Future<Result<({ProcessingOutput output, ProcessingBenchmark benchmark})>>
  measure(
    String name,
    String sourcePath,
    int? inputBytes,
    Future<Result<ProcessingOutput>> Function() operation,
  );
}

/// Executes bounded, cancellable processing work.
abstract interface class QueueEngine {
  /// Adds work to the queue according to [priority].
  Future<Result<T>> enqueue<T>(
    QueuePriority priority,
    Future<Result<T>> Function(CancellationToken token) operation, {
    CancellationToken? token,
    int maxRetries = 0,
  });

  /// Prevents queued work from starting.
  void pause();

  /// Resumes queued work.
  void resume();
}

/// Compression-specific engine contract.
abstract interface class CompressionEngine implements ProcessingEngine {}

/// Resize-specific engine contract.
abstract interface class ResizeEngine implements ProcessingEngine {}

/// Format-conversion engine contract.
abstract interface class FormatConverterEngine implements ProcessingEngine {}

/// Metadata-policy engine contract.
abstract interface class MetadataEngine implements ProcessingEngine {}
