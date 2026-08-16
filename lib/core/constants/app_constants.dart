/// Immutable application-wide constants and policy defaults.
abstract final class AppConstants {
  /// Product display name.
  static const String appName = 'Comprezza';

  /// Product version label used by diagnostics and support.
  static const String appVersion = '1.0.0';

  /// Build number shown in About and support surfaces.
  static const String appBuildNumber = '1';

  /// Default balanced compression quality.
  static const int defaultQuality = 72;

  /// Minimum valid compression quality.
  static const int minQuality = 1;

  /// Maximum valid compression quality.
  static const int maxQuality = 100;

  /// Maximum image preview decode edge in logical pixels.
  static const int previewDecodeEdge = 1600;

  /// Maximum concurrent processing operations.
  static const int maxConcurrentCompressionTasks = 1;

  /// Prefix used for generated temporary files.
  static const String temporaryOutputPrefix = 'comprezza_';

  /// Maximum age for abandoned temporary outputs before deletion.
  static const Duration temporaryFileMaxAge = Duration(hours: 24);

  /// Supported source and output extensions.
  static const Set<String> supportedImageExtensions = <String>{
    'jpg',
    'jpeg',
    'png',
    'webp',
  };

  /// Public website destination.
  ///
  /// TODO: replace with the approved public HTTPS website destination before
  /// release; the placeholder points at the developer domain until then.
  static const String websiteUrl = 'https://www.dzynova.com';

  /// Google Play listing for this application id.
  static const String playStoreUrl =
      'https://play.google.com/store/apps/details?id=com.dzynova.comprezza';
}
