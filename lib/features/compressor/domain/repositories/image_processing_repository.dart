import '../../../../core/models/result.dart';
import '../entities/image_processing_request.dart';
import '../entities/image_processing_result.dart';

/// Domain contract for image processing without plugin or platform coupling.
abstract interface class ImageProcessingRepository {
  /// Processes one request using the configured engine.
  Future<Result<ImageProcessingResult>> process(ImageProcessingRequest request);
}
