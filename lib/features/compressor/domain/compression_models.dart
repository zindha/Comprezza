/// Describes a selected photo using an engine-neutral local file reference.
class PhotoAsset {
  /// Creates metadata for a selected photo.
  const PhotoAsset({
    required this.filePath,
    required this.bytes,
    required this.width,
    required this.height,
  });

  /// Local file reference owned by the data boundary.
  final String filePath;

  /// Source file size in bytes.
  final int bytes;

  /// Source image width in pixels.
  final int width;

  /// Source image height in pixels.
  final int height;
}

/// Describes a compressed output and the settings used to create it.
class CompressedAsset {
  /// Creates metadata for a compressed output.
  const CompressedAsset({
    required this.filePath,
    required this.bytes,
    required this.width,
    required this.height,
    required this.quality,
    required this.format,
  });

  /// Local output file reference owned by the data boundary.
  final String filePath;

  /// Compressed file size in bytes.
  final int bytes;

  /// Compressed image width in pixels.
  final int width;

  /// Compressed image height in pixels.
  final int height;

  /// Quality used for this output.
  final int quality;

  /// Output format produced by the encoder.
  final CompressorFormat format;
}

/// High-level states rendered by the compressor dashboard.
enum CompressorStatus { empty, processing, ready, error }

/// Output formats supported by the compression engine.
enum CompressorFormat { jpeg, png, webp }
