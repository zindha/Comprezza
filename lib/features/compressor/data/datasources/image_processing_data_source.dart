import '../../../../core/errors/app_error.dart';
import '../../../../core/errors/error_code.dart';
import '../../../../core/models/result.dart';
import '../../domain/entities/image_processing_request.dart';
import '../../domain/entities/image_processing_result.dart';

/// Data-source abstraction for native or alternate image engines.
abstract interface class ImageProcessingDataSource {
  /// Executes engine-specific processing.
  Future<Result<ImageProcessingResult>> process(ImageProcessingRequest request);
}

/// Explicit placeholder until a reviewed engine adapter is introduced.
final class UnconfiguredImageProcessingDataSource
    implements ImageProcessingDataSource {
  /// Creates an unconfigured data source.
  const UnconfiguredImageProcessingDataSource();

  @override
  Future<Result<ImageProcessingResult>> process(
    ImageProcessingRequest request,
  ) async {
    return const Result<ImageProcessingResult>.failure(
      AppError(
        code: ErrorCode.imageEngineUnconfigured,
        message: 'No image-processing engine has been configured.',
        isRecoverable: false,
      ),
    );
  }
}
