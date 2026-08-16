import '../../../../../core/errors/app_error.dart';
import '../../../../../core/errors/error_code.dart';
import '../../../../../core/models/result.dart';
import '../../../../../features/compressor/data/datasources/image_processing_data_source.dart';
import '../../../../../features/compressor/domain/entities/image_processing_request.dart';
import '../../../../../features/compressor/domain/entities/image_processing_result.dart';
import 'interfaces/engine_manager.dart';
import 'models/image_processing_models.dart';

/// Repository data source backed by the Phase 3 engine manager.
final class EngineManagerDataSource implements ImageProcessingDataSource {
  /// Creates an adapter around [manager].
  const EngineManagerDataSource(this.manager);

  /// Unified engine facade.
  final EngineManager manager;

  /// Processes the legacy request shape without changing its public contract.
  @override
  Future<Result<ImageProcessingResult>> process(
    ImageProcessingRequest request,
  ) async {
    if (request.quality < 1 ||
        request.quality > 100 ||
        request.sourcePath.isEmpty) {
      return const Result<ImageProcessingResult>.failure(
        AppError(
          code: ErrorCode.invalidArgument,
          message: 'The image processing request is invalid.',
          isRecoverable: false,
        ),
      );
    }
    final Result<ProcessingOutput> result = await manager.process(
      ProcessingRequest(
        sourcePath: request.sourcePath,
        operation: ProcessingOperation.compress,
        compression: CompressionOptions(
          quality: request.quality,
          preset: CompressionPreset.custom,
        ),
      ),
    );
    return result.fold(
      onSuccess: (ProcessingOutput output) =>
          Result<ImageProcessingResult>.success(
            ImageProcessingResult(
              outputPath: output.outputPath,
              byteLength: output.bytes,
            ),
          ),
      onFailure: (AppError error) =>
          Result<ImageProcessingResult>.failure(error),
    );
  }
}
