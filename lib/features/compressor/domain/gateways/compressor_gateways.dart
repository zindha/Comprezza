import '../compression_models.dart';

/// Selects user-owned images and returns local file references.
abstract interface class ImagePickerGateway {
  /// Selects one image, returning its local path when selected.
  Future<String?> pickImagePath();

  /// Captures one image with the system camera, returning its local path when
  /// captured, or null when the user dismisses the camera.
  Future<String?> pickCameraImagePath();

  /// Recovers a lost selection after activity recreation.
  Future<String?> recoverLostImagePath();
}

/// Inspects and compresses images through a replaceable engine.
abstract interface class ImageCompressionGateway {
  /// Reads source metadata without retaining decoded image memory.
  Future<PhotoAsset> inspect(String sourcePath);

  /// Compresses one image using the requested parameters.
  ///
  /// [quality] is the starting quality for lossy encoders. When [targetBytes]
  /// is set, the engine searches for the highest quality whose output stays at
  /// or under the target size and reports the achieved quality on the result.
  /// [scale] resizes the output (1.0 keeps dimensions, 0.5 halves them).
  Future<CompressedAsset> compress(
    PhotoAsset source, {
    int quality = 72,
    CompressorFormat format = CompressorFormat.jpeg,
    double scale = 1,
    int? targetBytes,
    bool keepExif = false,
  });

  /// Deletes an app-owned temporary output as a best-effort operation.
  Future<void> deleteTemporaryOutput(String filePath);
}

/// Exports a generated local output through platform capabilities.
abstract interface class ImageExportGateway {
  /// Saves an output to shared device storage.
  Future<void> saveToDevice(String filePath);

  /// Opens the operating-system share sheet for an output.
  Future<void> share(String filePath);
}

/// Optional control surface for gateways that can cancel staging work.
abstract interface class CancellableImageExportGateway
    implements ImageExportGateway {
  /// Requests cancellation of the active staging operation.
  void cancelExport();
}
