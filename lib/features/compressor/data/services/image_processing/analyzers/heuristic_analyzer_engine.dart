import '../../../../../../core/errors/error_mapper.dart';
import '../../../../../../core/errors/result_error_adapter.dart';
import '../../../../../../core/models/result.dart';
import '../interfaces/processing_engine.dart';
import '../models/image_processing_models.dart';

/// Conservative filename/dimension heuristic analyzer.
///
/// This class is intentionally replaceable by a future on-device ML adapter.
final class HeuristicImageAnalyzerEngine implements ImageAnalyzerEngine {
  /// Creates a heuristic analyzer.
  const HeuristicImageAnalyzerEngine();

  @override
  String get id => 'local_heuristic_analyzer';

  @override
  Future<Result<ImageAnalysis>> analyze(AnalysisRequest request) async {
    try {
      final int bytes = request.originalBytes ?? 0;
      final ImageFormat format =
          ImageFormatX.fromPath(request.sourcePath) ?? ImageFormat.jpeg;
      final String name = request.sourcePath.toLowerCase();
      final ImageCategory category = _category(name, bytes);
      final int quality = switch (category) {
        ImageCategory.photograph => 80,
        ImageCategory.screenshot || ImageCategory.documentScan => 88,
        ImageCategory.artwork || ImageCategory.illustration => 86,
        ImageCategory.wallpaper => 78,
      };
      final ImageFormat recommendedFormat = switch (category) {
        ImageCategory.screenshot ||
        ImageCategory.documentScan => ImageFormat.png,
        _ => format == ImageFormat.png ? ImageFormat.webp : ImageFormat.jpeg,
      };
      final double confidence =
          name.contains('screenshot') || name.contains('scan') ? 0.82 : 0.42;
      final int estimated = bytes <= 0
          ? 0
          : (bytes * (quality / 100) * 0.72).round().clamp(1, bytes);
      final double savings = bytes <= 0 ? 0 : 1 - (estimated / bytes);
      return Result<ImageAnalysis>.success(
        ImageAnalysis(
          category: category,
          recommendedFormat: recommendedFormat,
          recommendedQuality: quality,
          resizeRecommendation: null,
          estimatedOutputBytes: estimated,
          expectedSavingsRatio: savings.clamp(0, 1),
          expectedQualityScore: quality / 100,
          confidence: confidence,
        ),
      );
    } catch (error, stackTrace) {
      final exception = ErrorMapper.map(error, stackTrace);
      return Result<ImageAnalysis>.failure(
        ResultErrorAdapter.fromException(exception),
      );
    }
  }

  ImageCategory _category(String name, int bytes) {
    if (name.contains('screenshot') || name.contains('screen_')) {
      return ImageCategory.screenshot;
    }
    if (name.contains('scan') || name.contains('document')) {
      return ImageCategory.documentScan;
    }
    if (name.contains('wallpaper') || name.contains('background')) {
      return ImageCategory.wallpaper;
    }
    if (name.contains('art') || name.contains('illustration')) {
      return ImageCategory.artwork;
    }
    if (bytes > 0 && bytes < 250 * 1024) return ImageCategory.illustration;
    return ImageCategory.photograph;
  }
}
