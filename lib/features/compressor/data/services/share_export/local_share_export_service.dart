import 'package:path/path.dart' as p;

import '../../../../../core/errors/app_error.dart';
import '../../../../../core/errors/error_code.dart';
import '../../../../../core/models/result.dart';
import '../../../domain/share_export/share_export_interfaces.dart';
import '../../../domain/share_export/share_export_models.dart';
import '../file_management/interfaces/file_management_interfaces.dart';
import '../file_management/models/file_management_models.dart';

/// Coordinates secure local export staging and Sharesheet dispatch.
final class LocalShareExportService implements ShareExportService {
  const LocalShareExportService({
    required this.exporter,
    required this.dispatcher,
    required this.security,
    required this.cleanup,
    this.now = DateTime.now,
  });

  final ExportService exporter;
  final ShareDispatcher dispatcher;
  final ExportSecurityPolicy security;
  final ShareExportCleanup cleanup;
  final DateTime Function() now;

  @override
  Future<Result<ExportOutcome>> export(
    ExportRequest request, {
    ShareExportOperation? operation,
  }) async {
    final Result<void> validation = await security.validateRequest(request);
    if (validation.isFailure) {
      return Result<ExportOutcome>.failure((validation as Failure<void>).error);
    }
    if (request.destination.kind != ExportDestinationKind.appManaged ||
        !request.naming.createFolderAutomatically) {
      return const Result<ExportOutcome>.failure(
        AppError(
          code: ErrorCode.unavailable,
          message: 'The selected folder export adapter is not enabled yet.',
          isRecoverable: false,
        ),
      );
    }
    final List<String> paths = <String>[];
    final List<ExportItemReport> reports = <ExportItemReport>[];
    for (final ExportAsset asset in request.assets) {
      if (operation?.isCancelled ?? false) {
        await _cleanup(paths);
        return _cancelledExport();
      }
      final Result<ExportedFile> result = await exporter.export(
        asset.filePath,
        naming: _naming(asset, request.naming, temporary: false),
      );
      if (result case Failure<ExportedFile>(error: final AppError error)) {
        await _cleanup(paths);
        return Result<ExportOutcome>.failure(error);
      }
      final ExportedFile file = (result as Success<ExportedFile>).value;
      paths.add(file.path);
      reports.add(_report(asset, file, ExportDestinationKind.appManaged));
    }
    if (operation?.isCancelled ?? false) {
      await _cleanup(paths);
      return _cancelledExport();
    }
    return Result<ExportOutcome>.success(
      ExportOutcome(
        paths: paths,
        report: ExportReport(
          items: reports,
          destination: ExportDestinationKind.appManaged,
          createdAt: now().toUtc(),
        ),
      ),
    );
  }

  @override
  Future<Result<ShareOutcome>> share(
    ShareRequest request, {
    ShareExportOperation? operation,
  }) async {
    final Result<void> validation = await security.validateShareRequest(
      request,
    );
    if (validation.isFailure) {
      return Result<ShareOutcome>.failure((validation as Failure<void>).error);
    }
    final List<SharePayloadFile> files = <SharePayloadFile>[];
    final List<ExportItemReport> reports = <ExportItemReport>[];
    final List<String> stagedPaths = <String>[];
    for (final ShareAsset asset in request.assets) {
      if (operation?.isCancelled ?? false) {
        await _cleanup(stagedPaths);
        return _cancelledShare();
      }
      final List<({ExportAsset item, bool isCompressed})> toShare =
          <({ExportAsset item, bool isCompressed})>[
            if (request.payload == SharePayload.originalAndCompressed &&
                asset.original != null)
              (item: asset.original!, isCompressed: false),
            (item: asset.compressed, isCompressed: true),
          ];
      for (final ({ExportAsset item, bool isCompressed}) payload in toShare) {
        if (operation?.isCancelled ?? false) {
          await _cleanup(stagedPaths);
          return _cancelledShare();
        }
        final ExportAsset item = payload.item;
        final Result<ExportedFile> result = await exporter.prepareShareCopy(
          item.filePath,
          naming: _naming(item, request.naming, temporary: true),
        );
        if (result case Failure<ExportedFile>(error: final AppError error)) {
          await _cleanup(stagedPaths);
          return Result<ShareOutcome>.failure(error);
        }
        final ExportedFile file = (result as Success<ExportedFile>).value;
        stagedPaths.add(file.path);
        files.add(
          SharePayloadFile(
            path: file.path,
            name: file.name,
            mimeType: _mimeType(item.format),
            bytes: file.bytes,
          ),
        );
        // The compressed asset owns the before/after metrics. The original
        // is a second payload file, not a second compression event.
        if (payload.isCompressed) {
          reports.add(
            _report(item, file, ExportDestinationKind.temporaryShare),
          );
        }
      }
    }
    late final Result<ShareDispatchStatus> dispatched;
    try {
      dispatched = await dispatcher.dispatch(
        SharePayloadBundle(
          files: files,
          subject: request.subject,
          message: request.message,
        ),
      );
    } on Object {
      await _cleanup(stagedPaths);
      return const Result<ShareOutcome>.failure(
        AppError(
          code: ErrorCode.unavailable,
          message: 'The system share sheet is unavailable.',
        ),
      );
    }
    if (dispatched case Failure<ShareDispatchStatus>(
      error: final AppError error,
    )) {
      await _cleanup(stagedPaths);
      return Result<ShareOutcome>.failure(error);
    }
    final ShareDispatchStatus dispatchStatus =
        (dispatched as Success<ShareDispatchStatus>).value;
    if (dispatchStatus != ShareDispatchStatus.shared) {
      await _cleanup(stagedPaths);
    }
    if (operation?.isCancelled ?? false) {
      await _cleanup(stagedPaths);
      return _cancelledShare();
    }
    return Result<ShareOutcome>.success(
      ShareOutcome(
        files: files,
        status: dispatchStatus,
        report: ExportReport(
          items: reports,
          destination: ExportDestinationKind.temporaryShare,
          createdAt: now().toUtc(),
        ),
      ),
    );
  }

  FileNameRequest _naming(
    ExportAsset asset,
    ExportNamingOptions options, {
    required bool temporary,
  }) {
    final String extension = _extension(asset.format);
    final String baseName = p.basenameWithoutExtension(asset.displayName);
    final String preset = asset.preset?.trim() ?? '';
    final String timestamp = options.includeTimestamp
        ? now().toUtc().toIso8601String().replaceAll(RegExp(r'[^0-9]'), '')
        : '';
    final String template = options.filenameTemplate.trim().isEmpty
        ? '{name}'
        : options.filenameTemplate;
    String resolved = template
        .replaceAll('{name}', baseName)
        .replaceAll('{timestamp}', timestamp)
        .replaceAll('{preset}', options.includePreset ? preset : '')
        .replaceAll('{format}', extension);
    if (options.includeTimestamp && !template.contains('{timestamp}')) {
      resolved = '${resolved}_$timestamp';
    }
    if (options.includePreset &&
        preset.isNotEmpty &&
        !template.contains('{preset}')) {
      resolved = '${resolved}_$preset';
    }
    final String suffix = options.suffix.trim().isEmpty
        ? 'Comprezza'
        : options.suffix;
    final String safeResolved = security.sanitizeFilename(resolved);
    return FileNameRequest(
      // Temporary share files are deliberately prefixed so the existing
      // startup cache policy can reclaim successful shares after their TTL.
      originalName: security.sanitizeFilename(
        temporary ? 'comprezza_$safeResolved' : safeResolved,
      ),
      suffix: suffix,
      extension: extension,
      version: options.versionNumber,
    );
  }

  ExportItemReport _report(
    ExportAsset asset,
    ExportedFile output,
    ExportDestinationKind destination,
  ) {
    final int compressedBytes = output.bytes;
    final int originalBytes = asset.originalBytes ?? compressedBytes;
    final int savedBytes = (originalBytes - compressedBytes)
        .clamp(0, originalBytes)
        .toInt();
    return ExportItemReport(
      assetId: asset.id,
      outputName: output.name,
      originalBytes: originalBytes,
      compressedBytes: compressedBytes,
      savedBytes: savedBytes,
      compressionRatio: compressedBytes <= 0
          ? 0
          : originalBytes / compressedBytes,
      processingTime: asset.processingTime,
      format: asset.format,
      width: asset.width,
      height: asset.height,
      preset: asset.preset,
      metadataStatus: asset.metadataStatus,
      destination: destination,
    );
  }

  Result<ExportOutcome> _cancelledExport() =>
      const Result<ExportOutcome>.failure(
        AppError(
          code: ErrorCode.cancelled,
          message: 'The export was cancelled.',
        ),
      );

  Result<ShareOutcome> _cancelledShare() => const Result<ShareOutcome>.failure(
    AppError(code: ErrorCode.cancelled, message: 'Sharing was cancelled.'),
  );

  Future<void> _cleanup(Iterable<String> paths) async {
    for (final String path in paths) {
      try {
        await cleanup.deleteGenerated(path);
      } on Object {
        // Never replace the primary export/share error with cleanup failure.
      }
    }
  }

  String _extension(ExportImageFormat format) => switch (format) {
    ExportImageFormat.jpeg => 'jpg',
    ExportImageFormat.png => 'png',
    ExportImageFormat.webp => 'webp',
    ExportImageFormat.heic => 'heic',
    ExportImageFormat.avif => 'avif',
    ExportImageFormat.unknown => 'bin',
  };

  String _mimeType(ExportImageFormat format) => switch (format) {
    ExportImageFormat.jpeg => 'image/jpeg',
    ExportImageFormat.png => 'image/png',
    ExportImageFormat.webp => 'image/webp',
    ExportImageFormat.heic => 'image/heic',
    ExportImageFormat.avif => 'image/avif',
    ExportImageFormat.unknown => 'application/octet-stream',
  };
}
