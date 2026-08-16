import 'dart:convert';

/// Identifies the local file format used by an export asset.
enum ExportImageFormat { jpeg, png, webp, heic, avif, unknown }

/// Describes whether metadata was preserved in an output.
enum ExportMetadataStatus { unknown, kept, removed, notPresent }

/// Determines the set of files included in a share request.
enum SharePayload { compressedOnly, originalAndCompressed }

/// Describes the caller's selection scope for analytics-free UX decisions.
enum ShareScope { single, multiple, selected }

/// Local destinations supported by the export contract.
enum ExportDestinationKind { appManaged, temporaryShare, userSelectedFolder }

/// The result returned by a platform share dispatcher.
enum ShareDispatchStatus { shared, dismissed, unavailable }

/// A local image and the metadata needed to produce a truthful export report.
final class ExportAsset {
  const ExportAsset({
    required this.id,
    required this.filePath,
    required this.displayName,
    required this.bytes,
    this.originalBytes,
    required this.width,
    required this.height,
    required this.format,
    required this.preset,
    required this.metadataStatus,
    this.hasAlpha = false,
    this.processingTime = Duration.zero,
  });

  final String id;
  final String filePath;
  final String displayName;
  final int bytes;
  final int? originalBytes;
  final int width;
  final int height;
  final ExportImageFormat format;
  final String? preset;
  final ExportMetadataStatus metadataStatus;
  final bool hasAlpha;
  final Duration processingTime;

  bool get hasValidDimensions => width > 0 && height > 0;
  bool get hasValidSize => bytes > 0;
}

/// A compressed image paired with its original for comparison sharing.
final class ShareAsset {
  const ShareAsset({required this.compressed, this.original});

  final ExportAsset compressed;
  final ExportAsset? original;
}

/// Safe, user-configurable naming options for generated files.
final class ExportNamingOptions {
  const ExportNamingOptions({
    this.filenameTemplate = '{name}',
    this.suffix = 'Comprezza',
    this.includeTimestamp = false,
    this.includePreset = false,
    this.createFolderAutomatically = true,
    this.overwrite = false,
    this.versionNumber,
  });

  /// Supported tokens are `{name}`, `{timestamp}`, `{preset}`, and `{format}`.
  final String filenameTemplate;
  final String suffix;
  final bool includeTimestamp;
  final bool includePreset;
  final bool createFolderAutomatically;
  final bool overwrite;
  final int? versionNumber;
}

/// A requested share operation. Assets are supplied by the approved caller,
/// so "selected" sharing never needs a second selection or hidden file scan.
final class ShareRequest {
  ShareRequest({
    required Iterable<ShareAsset> assets,
    this.scope = ShareScope.selected,
    this.payload = SharePayload.compressedOnly,
    this.naming = const ExportNamingOptions(),
    this.subject,
    this.message,
  }) : assets = List<ShareAsset>.unmodifiable(assets);

  final List<ShareAsset> assets;
  final ShareScope scope;
  final SharePayload payload;
  final ExportNamingOptions naming;
  final String? subject;
  final String? message;
}

/// A requested local export operation.
final class ExportRequest {
  ExportRequest({
    required Iterable<ExportAsset> assets,
    this.destination = const ExportDestination.appManaged(),
    this.naming = const ExportNamingOptions(),
  }) : assets = List<ExportAsset>.unmodifiable(assets);

  final List<ExportAsset> assets;
  final ExportDestination destination;
  final ExportNamingOptions naming;
}

/// Identifies an export destination without exposing platform URI types.
final class ExportDestination {
  const ExportDestination.appManaged()
    : kind = ExportDestinationKind.appManaged,
      identifier = null;

  const ExportDestination.userSelectedFolder(String this.identifier)
    : kind = ExportDestinationKind.userSelectedFolder;

  final ExportDestinationKind kind;
  final String? identifier;
}

/// A safe file passed to a platform share implementation.
final class SharePayloadFile {
  const SharePayloadFile({
    required this.path,
    required this.name,
    required this.mimeType,
    required this.bytes,
  });

  final String path;
  final String name;
  final String mimeType;
  final int bytes;
}

/// Platform-neutral payload for Android Sharesheet or a future platform.
final class SharePayloadBundle {
  SharePayloadBundle({
    required Iterable<SharePayloadFile> files,
    this.subject,
    this.message,
  }) : files = List<SharePayloadFile>.unmodifiable(files);

  final List<SharePayloadFile> files;
  final String? subject;
  final String? message;
}

/// One row in an export report.
final class ExportItemReport {
  const ExportItemReport({
    required this.assetId,
    required this.outputName,
    required this.originalBytes,
    required this.compressedBytes,
    required this.savedBytes,
    required this.compressionRatio,
    required this.processingTime,
    required this.format,
    required this.width,
    required this.height,
    required this.preset,
    required this.metadataStatus,
    required this.destination,
  });

  final String assetId;
  final String outputName;
  final int originalBytes;
  final int compressedBytes;
  final int savedBytes;
  final double compressionRatio;
  final Duration processingTime;
  final ExportImageFormat format;
  final int width;
  final int height;
  final String? preset;
  final ExportMetadataStatus metadataStatus;
  final ExportDestinationKind destination;

  Map<String, Object?> toJson() => <String, Object?>{
    'assetId': assetId,
    'outputName': outputName,
    'originalBytes': originalBytes,
    'compressedBytes': compressedBytes,
    'savedBytes': savedBytes,
    'compressionRatio': compressionRatio,
    'processingTimeMs': processingTime.inMilliseconds,
    'format': format.name,
    'width': width,
    'height': height,
    'preset': preset,
    'metadataStatus': metadataStatus.name,
    'destination': destination.name,
  };
}

/// Detailed, serializable summary of a local export or share operation.
final class ExportReport {
  ExportReport({
    required Iterable<ExportItemReport> items,
    required this.destination,
    required this.createdAt,
  }) : items = List<ExportItemReport>.unmodifiable(items);

  final List<ExportItemReport> items;
  final ExportDestinationKind destination;
  final DateTime createdAt;

  int get originalBytes => items.fold(
    0,
    (int total, ExportItemReport item) => total + item.originalBytes,
  );
  int get compressedBytes => items.fold(
    0,
    (int total, ExportItemReport item) => total + item.compressedBytes,
  );
  int get savedBytes => items.fold(
    0,
    (int total, ExportItemReport item) => total + item.savedBytes,
  );
  double get compressionRatio =>
      compressedBytes <= 0 ? 0 : originalBytes / compressedBytes;

  Map<String, Object?> toJson() => <String, Object?>{
    'schemaVersion': 1,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'destination': destination.name,
    'originalBytes': originalBytes,
    'compressedBytes': compressedBytes,
    'savedBytes': savedBytes,
    'compressionRatio': compressionRatio,
    'items': items.map((ExportItemReport item) => item.toJson()).toList(),
  };

  String encode() => const JsonEncoder.withIndent('  ').convert(toJson());
}

/// A completed export operation and its report.
final class ExportOutcome {
  ExportOutcome({required Iterable<String> paths, required this.report})
    : paths = List<String>.unmodifiable(paths);

  final List<String> paths;
  final ExportReport report;
}

/// A completed share operation and its report.
final class ShareOutcome {
  ShareOutcome({
    required Iterable<SharePayloadFile> files,
    required this.status,
    required this.report,
  }) : files = List<SharePayloadFile>.unmodifiable(files);

  final List<SharePayloadFile> files;
  final ShareDispatchStatus status;
  final ExportReport report;
}

/// A deterministic local suggestion for the next sharing destination.
enum ShareRecommendationKind {
  largeFile,
  smallFile,
  transparentPng,
  websiteImage,
}

final class ShareRecommendation {
  const ShareRecommendation({required this.kind, required this.confidence});

  final ShareRecommendationKind kind;
  final double confidence;
}
