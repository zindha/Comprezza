import '../../../../../../core/models/result.dart';
import '../models/image_processing_models.dart';

/// Unified facade over all processing engines and lifecycle coordination.
abstract interface class EngineManager {
  /// Processes one request through the queue and registry.
  Future<Result<ProcessingOutput>> process(
    ProcessingRequest request, {
    QueuePriority priority = QueuePriority.normal,
    CancellationToken? token,
  });

  /// Runs local image analysis.
  Future<Result<ImageAnalysis>> analyze(AnalysisRequest request);

  /// Calculates deterministic estimates without writing files.
  Result<Estimation> estimate(EstimationRequest request);
}
