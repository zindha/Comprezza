import '../../../../../../core/errors/app_error.dart';
import '../../../../../../core/errors/error_code.dart';
import '../../../../../../core/models/result.dart';
import '../interfaces/processing_engine.dart';
import '../models/image_processing_models.dart';

/// Heuristic estimator that performs no file or network access.
final class LocalEstimationEngine implements EstimationEngine {
  /// Creates a local estimation engine.
  const LocalEstimationEngine();

  @override
  Result<Estimation> estimate(EstimationRequest request) {
    if (request.originalBytes <= 0 ||
        request.quality < 1 ||
        request.quality > 100) {
      return const Result<Estimation>.failure(
        AppError(
          code: ErrorCode.invalidArgument,
          message: 'Original bytes and quality must be valid positive values.',
          isRecoverable: false,
        ),
      );
    }
    final double formatFactor = switch (request.format) {
      ImageFormat.jpeg => 0.78,
      ImageFormat.webp => 0.68,
      ImageFormat.png => 0.92,
      ImageFormat.heic || ImageFormat.avif || ImageFormat.jpegXl => 0.68,
    };
    final double qualityFactor = 0.25 + (request.quality / 100) * 0.75;
    final double dimensionFactor = _dimensionFactor(
      request.width,
      request.height,
    );
    final int estimatedBytes =
        (request.originalBytes * formatFactor * qualityFactor * dimensionFactor)
            .round()
            .clamp(1, request.originalBytes);
    final double ratio = request.originalBytes / estimatedBytes;
    final double savings = 1 - (estimatedBytes / request.originalBytes);
    final double uploadSavings = request.uploadBytesPerSecond == null
        ? 0
        : (request.originalBytes - estimatedBytes) /
              request.uploadBytesPerSecond!;
    final double cloudSavings =
        (request.originalBytes - estimatedBytes) *
        (request.cloudStorageCostPerByte ?? 0);
    return Result<Estimation>.success(
      Estimation(
        estimatedOutputBytes: estimatedBytes,
        compressionRatio: ratio,
        storageSavingsRatio: savings.clamp(0, 1),
        uploadTimeSavingsSeconds: uploadSavings.clamp(0, double.infinity),
        cloudStorageSavings: cloudSavings.clamp(0, double.infinity),
        qualityScore: (request.quality / 100).clamp(0, 1),
        compressionScore: (savings * 100).clamp(0, 100),
      ),
    );
  }

  double _dimensionFactor(int? width, int? height) {
    if (width == null || height == null || width <= 0 || height <= 0) return 1;
    final int pixels = width * height;
    if (pixels > 20_000_000) return 0.82;
    if (pixels > 8_000_000) return 0.9;
    return 1;
  }
}
