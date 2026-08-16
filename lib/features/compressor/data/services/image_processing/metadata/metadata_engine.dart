import '../../../../../../core/errors/app_error.dart';
import '../../../../../../core/errors/error_code.dart';
import '../../../../../../core/models/result.dart';
import '../interfaces/processing_engine.dart';
import '../models/image_processing_models.dart';

/// Validates metadata policy requests for codec-backed processing.
///
/// EXIF retention/removal is applied by the selected codec during compression
/// through [CompressionOptions.keepExif]. A standalone metadata rewrite is
/// intentionally rejected until a dedicated EXIF adapter is introduced.
final class CodecMetadataEngine implements MetadataEngine {
  /// Creates a metadata engine.
  const CodecMetadataEngine();

  @override
  String get id => 'codec_metadata_policy';

  @override
  bool supports(ProcessingRequest request) =>
      request.operation == ProcessingOperation.metadata;

  @override
  Future<Result<ProcessingOutput>> process(ProcessingRequest request) async {
    if (!supports(request) || request.sourcePath.isEmpty) {
      return const Result<ProcessingOutput>.failure(
        AppError(
          code: ErrorCode.invalidArgument,
          message: 'A source path is required for metadata processing.',
          isRecoverable: false,
        ),
      );
    }
    return const Result<ProcessingOutput>.failure(
      AppError(
        code: ErrorCode.unsupportedPlatform,
        message:
            'Standalone metadata rewriting requires a dedicated local EXIF adapter.',
      ),
    );
  }
}
