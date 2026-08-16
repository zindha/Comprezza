/// Engine-neutral image-processing request.
class ImageProcessingRequest {
  /// Creates a processing request.
  const ImageProcessingRequest({
    required this.sourcePath,
    required this.quality,
  });

  /// Local source path or content reference owned by the data layer.
  final String sourcePath;

  /// Requested quality from 1 through 100.
  final int quality;
}
