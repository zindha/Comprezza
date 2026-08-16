import 'dart:io';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as p;

import '../../../../../../core/errors/app_error.dart';
import '../../../../../../core/errors/error_code.dart';
import '../../../../../../core/errors/error_mapper.dart';
import '../../../../../../core/errors/result_error_adapter.dart';
import '../../../../../../core/models/result.dart';
import '../../../../../../core/services/file_system_service.dart';
import '../interfaces/processing_engine.dart';
import '../models/image_processing_models.dart';

/// Native codec adapter for JPEG, PNG, and WebP output.
final class FlutterImageCompressEngine
    implements
        CompressionEngine,
        ResizeEngine,
        FormatConverterEngine,
        MetadataEngine {
  /// Creates a codec engine using app-private filesystem directories.
  const FlutterImageCompressEngine({required this.fileSystem});

  /// Injected filesystem boundary.
  final FileSystemService fileSystem;

  @override
  String get id => 'flutter_image_compress';

  @override
  bool supports(ProcessingRequest request) {
    final ImageFormat format = request.compression.format;
    return switch (request.operation) {
      ProcessingOperation.compress ||
      ProcessingOperation.resize ||
      ProcessingOperation.convert ||
      ProcessingOperation.metadata => format.isImplemented,
    };
  }

  @override
  Future<Result<ProcessingOutput>> process(ProcessingRequest request) async {
    if (!supports(request)) {
      return const Result<ProcessingOutput>.failure(
        AppError(
          code: ErrorCode.unsupportedPlatform,
          message: 'The native codec cannot handle this request.',
          isRecoverable: false,
        ),
      );
    }
    if (request.sourcePath.isEmpty) {
      return const Result<ProcessingOutput>.failure(
        AppError(
          code: ErrorCode.invalidArgument,
          message: 'A source path is required.',
          isRecoverable: false,
        ),
      );
    }
    if (request.compression.effectiveQuality < 1 ||
        request.compression.effectiveQuality > 100 ||
        !_hasValidBounds(request)) {
      return const Result<ProcessingOutput>.failure(
        AppError(
          code: ErrorCode.invalidArgument,
          message: 'Compression quality must be between 1 and 100.',
          isRecoverable: false,
        ),
      );
    }
    if (request.compression.mode == CompressionMode.lossless &&
        request.compression.format != ImageFormat.png) {
      return const Result<ProcessingOutput>.failure(
        AppError(
          code: ErrorCode.invalidArgument,
          message: 'Lossless mode is supported only for PNG in this engine.',
          isRecoverable: false,
        ),
      );
    }
    final Result<Directory> directoryResult = await _compressionDirectory();
    if (directoryResult case Failure<Directory>(error: final AppError error)) {
      return Result<ProcessingOutput>.failure(error);
    }
    final Directory directory = (directoryResult as Success<Directory>).value;
    final ImageFormat format = request.compression.format;
    final ({int width, int height})? planned = request.resize == null
        ? null
        : _plannedDimensions(request);
    final String outputPath = p.join(
      directory.path,
      'comprezza_${DateTime.now().microsecondsSinceEpoch}.${format.extension}',
    );
    XFile? output;
    try {
      output = await FlutterImageCompress.compressAndGetFile(
        request.sourcePath,
        outputPath,
        format: _codecFormat(format),
        quality: request.compression.effectiveQuality,
        keepExif: request.operation == ProcessingOperation.metadata
            ? request.metadataPolicy == MetadataPolicy.keepExif
            : request.compression.keepExif,
        minWidth:
            planned?.width ??
            request.compression.maxWidth ??
            _positiveDimensionOrFallback(request.sourceWidth),
        minHeight:
            planned?.height ??
            request.compression.maxHeight ??
            _positiveDimensionOrFallback(request.sourceHeight),
      );
      if (output == null) {
        await _cleanupOutputs(<String>{outputPath});
        return const Result<ProcessingOutput>.failure(
          AppError(
            code: ErrorCode.ioFailure,
            message: 'The native codec returned no output.',
          ),
        );
      }
      final File file = File(output.path);
      final FileMetadata metadata = await fileSystem.stat(file);
      final int bytes = metadata.size;
      return Result<ProcessingOutput>.success(
        ProcessingOutput(
          outputPath: file.path,
          bytes: bytes,
          width: planned?.width ?? request.sourceWidth ?? 0,
          height: planned?.height ?? request.sourceHeight ?? 0,
          format: format,
          quality: request.compression.effectiveQuality,
        ),
      );
    } catch (error, stackTrace) {
      await _cleanupOutputs(<String>{
        outputPath,
        if (output != null) output.path,
      });
      final exception = ErrorMapper.map(error, stackTrace);
      return Result<ProcessingOutput>.failure(
        ResultErrorAdapter.fromException(exception),
      );
    }
  }

  bool _hasValidBounds(ProcessingRequest request) {
    final int? maxWidth = request.compression.maxWidth;
    final int? maxHeight = request.compression.maxHeight;
    if ((maxWidth != null && maxWidth <= 0) ||
        (maxHeight != null && maxHeight <= 0)) {
      return false;
    }
    final ResizeOptions? resize = request.resize;
    if (resize == null) return true;
    return switch (resize.mode) {
      ResizeMode.percentage => resize.value != null && resize.value! > 0,
      ResizeMode.width => resize.width != null && resize.width! > 0,
      ResizeMode.height => resize.height != null && resize.height! > 0,
      ResizeMode.dimensions =>
        resize.width != null &&
            resize.width! > 0 &&
            resize.height != null &&
            resize.height! > 0,
    };
  }

  int _positiveDimensionOrFallback(int? dimension) =>
      dimension != null && dimension > 0 ? dimension : 100000;

  Future<void> _cleanupOutputs(Iterable<String> paths) async {
    for (final String path in paths.toSet()) {
      try {
        await fileSystem.safeDelete(File(path));
      } on Object {
        // Cleanup is best effort; the original failure is returned.
      }
    }
  }

  ({int width, int height}) _plannedDimensions(ProcessingRequest request) {
    final int sourceWidth =
        request.sourceWidth != null && request.sourceWidth! > 0
        ? request.sourceWidth!
        : 1920;
    final int sourceHeight =
        request.sourceHeight != null && request.sourceHeight! > 0
        ? request.sourceHeight!
        : 1080;
    final ResizeOptions options = request.resize!;
    switch (options.mode) {
      case ResizeMode.percentage:
        final double factor = (options.value ?? 100) / 100;
        return (
          width: (sourceWidth * factor).round().clamp(1, 100000),
          height: (sourceHeight * factor).round().clamp(1, 100000),
        );
      case ResizeMode.width:
        final int width = options.width ?? sourceWidth;
        return (
          width: width,
          height: options.preserveAspectRatio
              ? (width * sourceHeight / sourceWidth).round()
              : sourceHeight,
        );
      case ResizeMode.height:
        final int height = options.height ?? sourceHeight;
        return (
          width: options.preserveAspectRatio
              ? (height * sourceWidth / sourceHeight).round()
              : sourceWidth,
          height: height,
        );
      case ResizeMode.dimensions:
        return (
          width: options.width ?? sourceWidth,
          height: options.height ?? sourceHeight,
        );
    }
  }

  CompressFormat _codecFormat(ImageFormat format) => switch (format) {
    ImageFormat.jpeg => CompressFormat.jpeg,
    ImageFormat.png => CompressFormat.png,
    ImageFormat.webp => CompressFormat.webp,
    ImageFormat.heic ||
    ImageFormat.avif ||
    ImageFormat.jpegXl => CompressFormat.jpeg,
  };

  Future<Result<Directory>> _compressionDirectory() async {
    final Result<AppDirectories> result = await fileSystem.directories();
    return result.fold(
      onSuccess: (AppDirectories directories) =>
          Result<Directory>.success(directories.compression),
      onFailure: (AppError error) => Result<Directory>.failure(error),
    );
  }
}
