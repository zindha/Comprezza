import '../../../../core/models/result.dart';
import '../entities/image_processing_request.dart';
import '../entities/image_processing_result.dart';
import '../repositories/image_processing_repository.dart';

/// Coordinates one image-processing request without knowing its engine.
final class ProcessImageUseCase {
  /// Creates a processing use case.
  const ProcessImageUseCase(this.repository);

  /// Repository port supplied by dependency injection.
  final ImageProcessingRepository repository;

  /// Processes [request].
  Future<Result<ImageProcessingResult>> call(ImageProcessingRequest request) {
    return repository.process(request);
  }
}
