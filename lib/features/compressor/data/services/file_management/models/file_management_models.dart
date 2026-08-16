import 'dart:io';

/// Selects the operating-system source used for image selection.
enum ImageSelectionSource {
  /// Select an image from the gallery/photo picker.
  gallery,

  /// Capture a new image with the camera.
  camera,
}

/// Identifies an app-managed storage area.
enum StorageLocation {
  /// Temporary imported or generated files.
  temporary,

  /// Compression working files.
  compression,

  /// User-visible export staging files.
  exports,

  /// Persistent history records.
  history,

  /// Generated thumbnails and cache entries.
  cache,

  /// Reserved location for a future backup adapter.
  backup,
}

/// Options for selecting one or more images.
class ImageSelectionRequest {
  /// Creates an image selection request.
  const ImageSelectionRequest({
    this.source = ImageSelectionSource.gallery,
    this.multiple = false,
    this.imageQuality,
    this.maxWidth,
    this.maxHeight,
  });

  /// Gallery or camera source.
  final ImageSelectionSource source;

  /// Whether multiple gallery images may be selected.
  final bool multiple;

  /// Optional picker-side quality hint.
  final int? imageQuality;

  /// Optional picker-side width bound.
  final double? maxWidth;

  /// Optional picker-side height bound.
  final double? maxHeight;
}

/// A local path returned by a picker or folder scanner.
class SelectedFile {
  /// Creates a selected-file descriptor.
  const SelectedFile({required this.path, required this.name});

  /// Local path supplied by the platform picker.
  final String path;

  /// Original display name.
  final String name;
}

/// Options controlling a future folder scan.
class FolderScanOptions {
  /// Creates folder scan options.
  const FolderScanOptions({
    this.recursive = true,
    this.includeHidden = false,
    this.skipDuplicates = true,
  });

  /// Whether nested directories are traversed.
  final bool recursive;

  /// Whether hidden files and directories are included.
  final bool includeHidden;

  /// Whether duplicate checks should be applied by the caller.
  final bool skipDuplicates;
}

/// A validated local file and its measured identity.
class ManagedFile {
  /// Creates a managed-file descriptor.
  const ManagedFile({
    required this.path,
    required this.name,
    required this.extension,
    required this.mimeType,
    required this.bytes,
    required this.checksum,
    required this.modified,
  });

  /// Local file path.
  final String path;

  /// File name including extension.
  final String name;

  /// Lowercase extension without a leading dot.
  final String extension;

  /// Best-effort MIME type.
  final String mimeType;

  /// File length in bytes.
  final int bytes;

  /// Stable SHA-256 checksum.
  final String checksum;

  /// Last modified timestamp.
  final DateTime modified;

  /// Returns a dart:io handle only at the data-layer boundary.
  File get file => File(path);
}

/// Validation policy for image files.
class FileValidationPolicy {
  /// Creates a validation policy.
  const FileValidationPolicy({
    this.maxBytes = 100 * 1024 * 1024,
    this.supportedExtensions = const <String>{'jpg', 'jpeg', 'png', 'webp'},
  });

  /// Maximum accepted file size.
  final int maxBytes;

  /// Accepted lowercase extensions.
  final Set<String> supportedExtensions;
}

/// Duplicate identity composed from cheap metadata and a checksum.
class DuplicateSignature {
  /// Creates a duplicate signature.
  const DuplicateSignature({
    required this.bytes,
    required this.checksum,
    required this.normalizedName,
  });

  /// File length.
  final int bytes;

  /// Content checksum.
  final String checksum;

  /// Normalized file name used as a secondary signal.
  final String normalizedName;
}

/// Result of exporting a managed file.
class ExportedFile {
  /// Creates an exported-file descriptor.
  const ExportedFile({
    required this.path,
    required this.name,
    required this.bytes,
    required this.location,
  });

  /// Exported local path.
  final String path;

  /// Collision-safe output name.
  final String name;

  /// Output size.
  final int bytes;

  /// Storage location used for the export.
  final StorageLocation location;
}

/// Naming input for generated files.
class FileNameRequest {
  /// Creates a generated-name request.
  const FileNameRequest({
    required this.originalName,
    required this.suffix,
    required this.extension,
    this.version,
  });

  /// Original source name.
  final String originalName;

  /// Semantic suffix such as Compressed or Optimized.
  final String suffix;

  /// Target extension without a leading dot.
  final String extension;

  /// Optional explicit version number.
  final int? version;
}

/// Persistent local history entry.
class CompressionHistoryRecord {
  /// Creates a history record.
  const CompressionHistoryRecord({
    required this.id,
    required this.originalPath,
    required this.compressedPath,
    required this.createdAt,
    required this.preset,
    required this.compressionRatio,
    required this.savedBytes,
    required this.checksum,
    this.processedFiles = 1,
  });

  /// Stable local record identifier.
  final String id;

  /// Original source path.
  final String originalPath;

  /// Generated compressed path.
  final String compressedPath;

  /// Creation timestamp.
  final DateTime createdAt;

  /// Preset label used by the caller.
  final String preset;

  /// Original-to-output ratio.
  final double compressionRatio;

  /// Bytes saved.
  final int savedBytes;

  /// Original checksum.
  final String checksum;

  /// Number of source files this session covered (1 for single-image runs,
  /// >1 for batch sessions). Drives batch-session insights.
  final int processedFiles;

  /// Converts the record to local JSON storage.
  Map<String, Object> toJson() => <String, Object>{
    'id': id,
    'originalPath': originalPath,
    'compressedPath': compressedPath,
    'createdAt': createdAt.toIso8601String(),
    'preset': preset,
    'compressionRatio': compressionRatio,
    'savedBytes': savedBytes,
    'checksum': checksum,
    'processedFiles': processedFiles,
  };

  /// Restores a record from local JSON storage.
  static CompressionHistoryRecord? fromJson(Map<String, Object?> json) {
    final Object? id = json['id'];
    final Object? originalPath = json['originalPath'];
    final Object? compressedPath = json['compressedPath'];
    final Object? createdAt = json['createdAt'];
    final Object? preset = json['preset'];
    final Object? ratio = json['compressionRatio'];
    final Object? savedBytes = json['savedBytes'];
    final Object? checksum = json['checksum'];
    final Object? processedFiles = json['processedFiles'];
    if (id is! String ||
        originalPath is! String ||
        compressedPath is! String ||
        createdAt is! String ||
        preset is! String ||
        ratio is! num ||
        savedBytes is! num ||
        checksum is! String ||
        (processedFiles != null && processedFiles is! num)) {
      return null;
    }
    final DateTime? date = DateTime.tryParse(createdAt);
    if (date == null) return null;
    // Records written before the file-count field was introduced default to a
    // single-file session so existing history stays valid.
    final int fileCount = processedFiles is num
        ? (processedFiles.toInt() < 0 ? 0 : processedFiles.toInt())
        : 1;
    return CompressionHistoryRecord(
      id: id,
      originalPath: originalPath,
      compressedPath: compressedPath,
      createdAt: date,
      preset: preset,
      compressionRatio: ratio.toDouble(),
      savedBytes: savedBytes.toInt(),
      checksum: checksum,
      processedFiles: fileCount,
    );
  }
}

/// Configurable file cleanup policy.
class FileCleanupPolicy {
  /// Creates a cleanup policy.
  const FileCleanupPolicy({
    this.maxAge = const Duration(hours: 24),
    this.maxBytes = 256 * 1024 * 1024,
    this.includeExports = true,
    this.includeThumbnails = true,
    this.protectedPaths = const <String>{},
  });

  /// Maximum age of generated files.
  final Duration maxAge;

  /// Maximum aggregate generated-file size.
  final int maxBytes;

  /// Whether export staging files are eligible.
  final bool includeExports;

  /// Whether thumbnail files are eligible.
  final bool includeThumbnails;

  /// Paths referenced by history or an active workflow.
  final Set<String> protectedPaths;
}

/// Summary returned by cleanup.
class FileCleanupReport {
  /// Creates a cleanup report.
  const FileCleanupReport({
    required this.removedFiles,
    required this.removedBytes,
    required this.failedFiles,
  });

  /// Number of removed files.
  final int removedFiles;

  /// Number of removed bytes.
  final int removedBytes;

  /// Number of files that could not be removed.
  final int failedFiles;
}

/// File-management-level operation status.
class FileOperationSummary {
  /// Creates an operation summary.
  const FileOperationSummary({required this.accepted, required this.rejected});

  /// Files accepted by validation.
  final List<ManagedFile> accepted;

  /// Paths rejected with their structured errors.
  final Map<String, String> rejected;
}
