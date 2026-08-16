import '../../../../../../core/errors/app_error.dart';
import '../../../../../../core/errors/error_code.dart';
import '../../../../../../core/models/result.dart';
import '../interfaces/processing_engine.dart';
import '../models/image_processing_models.dart';

/// Validates and plans resize operations for a codec-backed pipeline.
///
/// The native codec remains responsible for decoding/encoding; this engine
/// computes safe dimensions without allocating decoded pixel buffers.
final class PlannedResizeEngine implements ResizeEngine {
  /// Creates a resize planner.
  const PlannedResizeEngine();

  @override
  String get id => 'planned_resize';

  @override
  bool supports(ProcessingRequest request) =>
      request.operation == ProcessingOperation.resize && request.resize != null;

  @override
  Future<Result<ProcessingOutput>> process(ProcessingRequest request) async {
    if (!supports(request)) {
      return const Result<ProcessingOutput>.failure(
        AppError(
          code: ErrorCode.invalidArgument,
          message: 'A resize option is required for resize operations.',
          isRecoverable: false,
        ),
      );
    }
    final ResizeOptions options = request.resize!;
    if (!_hasValidDimensions(options)) {
      return const Result<ProcessingOutput>.failure(
        AppError(
          code: ErrorCode.invalidArgument,
          message: 'Resize dimensions must be positive.',
          isRecoverable: false,
        ),
      );
    }
    final int width = request.sourceWidth ?? 0;
    final int height = request.sourceHeight ?? 0;
    if (width <= 0 || height <= 0) {
      return const Result<ProcessingOutput>.failure(
        AppError(
          code: ErrorCode.invalidArgument,
          message: 'Source dimensions are required for resize planning.',
          isRecoverable: false,
        ),
      );
    }
    final ({int width, int height}) dimensions = _dimensions(
      width,
      height,
      options,
    );
    return Result<ProcessingOutput>.success(
      ProcessingOutput(
        outputPath: request.sourcePath,
        bytes: 0,
        width: dimensions.width,
        height: dimensions.height,
        format: request.compression.format,
        quality: request.compression.effectiveQuality,
      ),
    );
  }

  ({int width, int height}) _dimensions(
    int width,
    int height,
    ResizeOptions options,
  ) {
    switch (options.mode) {
      case ResizeMode.percentage:
        final double factor = (options.value ?? 100) / 100;
        return (width: _safe(width * factor), height: _safe(height * factor));
      case ResizeMode.width:
        final int targetWidth = options.width ?? width;
        if (!options.preserveAspectRatio) {
          return (width: targetWidth, height: height);
        }
        return (
          width: targetWidth,
          height: _safe(targetWidth * height / width),
        );
      case ResizeMode.height:
        final int targetHeight = options.height ?? height;
        if (!options.preserveAspectRatio) {
          return (width: width, height: targetHeight);
        }
        return (
          width: _safe(targetHeight * width / height),
          height: targetHeight,
        );
      case ResizeMode.dimensions:
        return (
          width: _safe(options.width ?? width),
          height: _safe(options.height ?? height),
        );
    }
  }

  bool _hasValidDimensions(ResizeOptions options) => switch (options.mode) {
    ResizeMode.percentage => options.value != null && options.value! > 0,
    ResizeMode.width => options.width != null && options.width! > 0,
    ResizeMode.height => options.height != null && options.height! > 0,
    ResizeMode.dimensions =>
      options.width != null &&
          options.width! > 0 &&
          options.height != null &&
          options.height! > 0,
  };

  int _safe(num value) => value.round().clamp(1, 100000);
}
