/// Engine-neutral image-processing result.
class ImageProcessingResult {
  /// Creates a processing result.
  const ImageProcessingResult({
    required this.outputPath,
    required this.byteLength,
  });

  /// Local output path owned by the data layer.
  final String outputPath;

  /// Output size in bytes.
  final int byteLength;
}
