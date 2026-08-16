import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;

import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/errors/app_error.dart';
import '../../../../../core/errors/error_code.dart';
import '../../../../../core/models/result.dart';
import '../../../domain/compression_models.dart';
import '../../../domain/gateways/compressor_gateways.dart';
import '../../../domain/share_export/share_export_interfaces.dart';
import '../../../domain/share_export/share_export_models.dart';
import '../file_management/interfaces/file_management_interfaces.dart';
import '../file_management/models/file_management_models.dart';

const MethodChannel _mediaStoreChannel = MethodChannel(
  AppStrings.deviceExportChannel,
);

/// Bridges the existing compressor gateway to the Phase 11 share/export port.
///
/// The adapter preserves the frozen controller contract while ensuring every
/// production save/share operation uses the secure managed export service.
final class ShareExportGatewayAdapter
    implements ImageExportGateway, CancellableImageExportGateway {
  ShareExportGatewayAdapter({
    required this.service,
    required this.inspector,
    required this.cleanup,
    required this.storage,
  });

  final ShareExportService service;
  final ImageCompressionGateway inspector;
  final ShareExportCleanup cleanup;
  final StorageManager storage;

  ShareExportCancellation? _cancellation;

  @override
  void cancelExport() => _cancellation?.cancel();

  @override
  Future<void> saveToDevice(String filePath) async {
    _ensureAndroid();
    final ShareExportCancellation cancellation = ShareExportCancellation();
    _cancellation = cancellation;
    try {
      await _ensureManagedSource(filePath);
      final ExportAsset asset = await _asset(filePath);
      final Result<ExportOutcome> result = await service.export(
        ExportRequest(assets: <ExportAsset>[asset]),
        operation: cancellation,
      );
      if (cancellation.isCancelled) {
        if (result case Success<ExportOutcome>(
          value: final ExportOutcome outcome,
        )) {
          for (final String path in outcome.paths) {
            await _deleteBestEffort(path);
          }
        }
        throw const _ExportOperationException(
          AppError(
            code: ErrorCode.cancelled,
            message: 'The export was cancelled.',
          ),
        );
      }
      if (result case Failure<ExportOutcome>(error: final AppError error)) {
        throw _ExportOperationException(error);
      }
      final ExportOutcome outcome = (result as Success<ExportOutcome>).value;
      if (outcome.paths.length != 1) {
        throw const _ExportOperationException(
          AppError(
            code: ErrorCode.ioFailure,
            message: 'The export did not produce exactly one image.',
          ),
        );
      }
      try {
        await _publishToMediaStore(outcome.paths.single);
      } catch (_) {
        await _deleteBestEffort(outcome.paths.single);
        rethrow;
      }
    } finally {
      if (identical(_cancellation, cancellation)) _cancellation = null;
    }
  }

  @override
  Future<void> share(String filePath) async {
    final ShareExportCancellation cancellation = ShareExportCancellation();
    _cancellation = cancellation;
    try {
      await _ensureManagedSource(filePath);
      final ExportAsset asset = await _asset(filePath);
      final Result<ShareOutcome> result = await service.share(
        ShareRequest(
          assets: <ShareAsset>[ShareAsset(compressed: asset)],
          scope: ShareScope.single,
        ),
        operation: cancellation,
      );
      if (result case Failure<ShareOutcome>(error: final AppError error)) {
        throw _ExportOperationException(error);
      }
      if (cancellation.isCancelled) {
        throw const _ExportOperationException(
          AppError(
            code: ErrorCode.cancelled,
            message: 'Sharing was cancelled.',
          ),
        );
      }
      final ShareOutcome outcome = (result as Success<ShareOutcome>).value;
      if (outcome.status != ShareDispatchStatus.shared) {
        throw _ExportOperationException(
          AppError(
            code: outcome.status == ShareDispatchStatus.dismissed
                ? ErrorCode.cancelled
                : ErrorCode.unavailable,
            message: outcome.status == ShareDispatchStatus.dismissed
                ? 'Sharing was dismissed.'
                : 'The system share sheet is unavailable.',
          ),
        );
      }
    } finally {
      if (identical(_cancellation, cancellation)) _cancellation = null;
    }
  }

  Future<void> _ensureManagedSource(String filePath) async {
    final File source = File(filePath);
    if (!await source.exists()) {
      throw const _ExportOperationException(
        AppError(
          code: ErrorCode.notFound,
          message: 'The export source does not exist.',
        ),
      );
    }
    final Result<Map<StorageLocation, Directory>> result = await storage
        .directories();
    if (result case Failure<Map<StorageLocation, Directory>>(
      error: final AppError error,
    )) {
      throw _ExportOperationException(error);
    }
    final Map<StorageLocation, Directory> directories =
        (result as Success<Map<StorageLocation, Directory>>).value;
    final String candidate = p.normalize(
      p.absolute(await source.resolveSymbolicLinks()),
    );
    for (final StorageLocation location in <StorageLocation>[
      StorageLocation.temporary,
      StorageLocation.compression,
      StorageLocation.exports,
    ]) {
      final Directory? root = directories[location];
      if (root == null) continue;
      final String canonicalRoot = p.normalize(
        p.absolute(await root.resolveSymbolicLinks()),
      );
      final String relative = p.relative(candidate, from: canonicalRoot);
      if (relative != '..' &&
          !relative.startsWith('..${p.separator}') &&
          !p.isAbsolute(relative)) {
        return;
      }
    }
    throw const _ExportOperationException(
      AppError(
        code: ErrorCode.unsafePath,
        message: 'The export source is not authorized.',
        isRecoverable: false,
      ),
    );
  }

  Future<void> _deleteBestEffort(String path) async {
    try {
      await cleanup.deleteGenerated(path);
    } on Object {
      // Preserve the primary export/cancellation error.
    }
  }

  Future<ExportAsset> _asset(String filePath) async {
    final File file = File(filePath);
    final PhotoAsset inspected = await inspector.inspect(filePath);
    final ExportImageFormat format = switch (p
        .extension(filePath)
        .toLowerCase()) {
      '.jpg' || '.jpeg' => ExportImageFormat.jpeg,
      '.png' => ExportImageFormat.png,
      '.webp' => ExportImageFormat.webp,
      '.heic' => ExportImageFormat.heic,
      '.avif' => ExportImageFormat.avif,
      _ => ExportImageFormat.unknown,
    };
    final int bytes = inspected.bytes > 0
        ? inspected.bytes
        : await file.length();
    return ExportAsset(
      id: file.path,
      filePath: file.path,
      displayName: p.basename(file.path),
      bytes: bytes,
      originalBytes: bytes,
      width: inspected.width,
      height: inspected.height,
      format: format,
      preset: null,
      metadataStatus: ExportMetadataStatus.unknown,
    );
  }

  Future<void> _publishToMediaStore(String path) async {
    final File file = File(path);
    if (!await file.exists()) {
      throw const _ExportOperationException(
        AppError(
          code: ErrorCode.notFound,
          message: 'The exported image is no longer available.',
        ),
      );
    }
    await _mediaStoreChannel.invokeMethod<void>(
      'saveToMediaStore',
      <String, Object>{'path': file.path},
    );
  }

  void _ensureAndroid() {
    if (!Platform.isAndroid) {
      throw UnsupportedError(
        'Gallery export is currently available on Android.',
      );
    }
  }
}

/// Cooperative cancellation for local staging work. The OS Sharesheet itself
/// owns its lifecycle and may only be dismissed by the recipient/system UI.
final class ShareExportCancellation implements ShareExportOperation {
  bool _cancelled = false;

  @override
  bool get isCancelled => _cancelled;

  @override
  void cancel() => _cancelled = true;
}

final class _ExportOperationException implements Exception {
  const _ExportOperationException(this.error);

  final AppError error;

  @override
  String toString() => error.message;
}
