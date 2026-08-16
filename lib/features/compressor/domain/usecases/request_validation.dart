import '../../../../core/errors/app_error.dart';
import '../../../../core/errors/error_code.dart';
import '../entities/entities.dart';

/// Maximum image size accepted by application workflows.
const int maxApplicationImageBytes = 100 * 1024 * 1024;

/// Returns whether a format has a currently registered application adapter.
bool isApplicationFormatSupported(ImageFormat format) => switch (format) {
  ImageFormat.jpeg || ImageFormat.png || ImageFormat.webp => true,
  ImageFormat.heic || ImageFormat.avif || ImageFormat.jpegXl => false,
};

/// Validates one selected image without touching platform APIs.
AppError? validateSelectedImage(SelectedImage image) {
  if (image.path.trim().isEmpty ||
      image.bytes <= 0 ||
      image.bytes > maxApplicationImageBytes ||
      image.width <= 0 ||
      image.height <= 0) {
    return const AppError(
      code: ErrorCode.invalidArgument,
      message: 'The selected image is invalid or exceeds the file limit.',
      isRecoverable: false,
    );
  }
  if (!isApplicationFormatSupported(image.format)) {
    return const AppError(
      code: ErrorCode.unsupportedPlatform,
      message: 'The selected image format is unavailable.',
      isRecoverable: false,
    );
  }
  return null;
}

/// Validates a compression request before repository work begins.
AppError? validateCompressionRequest(CompressionRequest request) {
  if (request.images.isEmpty) {
    return const AppError(
      code: ErrorCode.invalidArgument,
      message: 'Select at least one image.',
      isRecoverable: false,
    );
  }
  if (request.effectiveQuality < 1 || request.effectiveQuality > 100) {
    return const AppError(
      code: ErrorCode.invalidArgument,
      message: 'Compression quality must be between 1 and 100.',
      isRecoverable: false,
    );
  }
  final int? target = request.effectiveTargetBytes;
  if (target != null && target <= 0) {
    return const AppError(
      code: ErrorCode.invalidArgument,
      message: 'Target size must be greater than zero.',
      isRecoverable: false,
    );
  }
  final ResizeSpec? resize = request.resize;
  if (resize != null &&
      (resize.width != null && resize.width! <= 0 ||
          resize.height != null && resize.height! <= 0 ||
          resize.percentage != null &&
              (resize.percentage! < 1 || resize.percentage! > 1000) ||
          resize.percentage != null &&
              (resize.width != null || resize.height != null))) {
    return const AppError(
      code: ErrorCode.invalidArgument,
      message: 'Resize values are invalid.',
      isRecoverable: false,
    );
  }
  final Set<String> identities = <String>{};
  for (final SelectedImage image in request.images) {
    final AppError? imageError = validateSelectedImage(image);
    if (imageError != null) return imageError;
    final String identity = image.checksum?.isNotEmpty == true
        ? 'checksum:${image.checksum}'
        : 'path:${image.path}';
    if (!identities.add(identity)) {
      return const AppError(
        code: ErrorCode.invalidArgument,
        message: 'Duplicate images are not allowed in one request.',
        isRecoverable: false,
      );
    }
  }
  if (!isApplicationFormatSupported(request.effectiveFormat)) {
    return const AppError(
      code: ErrorCode.unsupportedPlatform,
      message: 'The requested image format is unavailable.',
      isRecoverable: false,
    );
  }
  return null;
}
