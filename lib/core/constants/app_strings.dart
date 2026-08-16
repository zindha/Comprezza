/// Non-user-facing string identifiers used by infrastructure.
abstract final class AppStrings {
  /// Platform channel for device export.
  static const String deviceExportChannel = 'comprezza/device_export';

  /// Cache directory name.
  static const String cacheDirectory = 'cache';

  /// History directory name.
  static const String historyDirectory = 'history';

  /// Thumbnail directory name.
  static const String thumbnailDirectory = 'thumbnails';

  /// Export directory name.
  static const String exportDirectory = 'exports';

  /// Compression directory name.
  static const String compressionDirectory = 'compression';

  /// App-private backup directory name.
  static const String backupDirectory = 'backup';

  /// Semantic label for a compression progress indicator.
  static const String compressionProgressSemantics = 'Compression progress';

  /// MediaStore collection name for exported images.
  static const String exportCollectionName = 'Comprezza';
}
