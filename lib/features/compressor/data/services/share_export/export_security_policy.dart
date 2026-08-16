import 'dart:io';

import 'package:path/path.dart' as p;

import '../../../../../core/errors/app_error.dart';
import '../../../../../core/errors/error_code.dart';
import '../../../../../core/models/result.dart';
import '../../../domain/share_export/share_export_interfaces.dart';
import '../../../domain/share_export/share_export_models.dart';
import '../file_management/interfaces/file_management_interfaces.dart';
import '../file_management/models/file_management_models.dart';

/// Validates user-controlled export input before it reaches filesystem APIs.
final class LocalExportSecurityPolicy implements ExportSecurityPolicy {
  LocalExportSecurityPolicy({required this.storage, this.maxAssets = 256});

  /// Trusted app-managed storage boundary. Callers cannot supply arbitrary
  /// authorization roots; roots are resolved from this owned service.
  final StorageManager storage;

  /// Bounds work and prevents unbounded list allocation from callers.
  final int maxAssets;

  @override
  Future<Result<void>> validateRequest(ExportRequest request) async {
    if (request.assets.isEmpty || request.assets.length > maxAssets) {
      return _invalid('The export selection is outside the supported limit.');
    }
    if (request.naming.overwrite || !request.naming.createFolderAutomatically) {
      return _invalid('The requested export naming policy is unavailable.');
    }
    if (request.destination.kind == ExportDestinationKind.userSelectedFolder) {
      final String? identifier = request.destination.identifier;
      if (identifier == null || identifier.trim().isEmpty) {
        return _invalid('The selected export folder is unavailable.');
      }
      if (identifier.contains('\u0000') || identifier.contains('..')) {
        return _unsafe('The export folder is not a safe destination.');
      }
    }
    final Result<List<String>> roots = await _trustedRoots();
    if (roots case Failure<List<String>>(error: final AppError error)) {
      return Result<void>.failure(error);
    }
    for (final ExportAsset asset in request.assets) {
      final Result<void> result = await _validateAsset(
        asset,
        (roots as Success<List<String>>).value,
      );
      if (result.isFailure) return result;
    }
    return const Result<void>.success(null);
  }

  @override
  Future<Result<void>> validateShareRequest(ShareRequest request) async {
    if (request.assets.isEmpty || request.assets.length > maxAssets) {
      return _invalid('The share selection is outside the supported limit.');
    }
    if (request.scope == ShareScope.single && request.assets.length != 1) {
      return _invalid('A single-image share requires one image.');
    }
    if (request.scope == ShareScope.multiple && request.assets.length < 2) {
      return _invalid('A multiple-image share requires at least two images.');
    }
    if (request.naming.overwrite || !request.naming.createFolderAutomatically) {
      return _invalid('The requested share naming policy is unavailable.');
    }
    final Result<List<String>> roots = await _trustedRoots();
    if (roots case Failure<List<String>>(error: final AppError error)) {
      return Result<void>.failure(error);
    }
    final List<String> trustedRoots = (roots as Success<List<String>>).value;
    for (final ShareAsset asset in request.assets) {
      final Result<void> compressed = await _validateAsset(
        asset.compressed,
        trustedRoots,
      );
      if (compressed.isFailure) return compressed;
      if (request.payload == SharePayload.originalAndCompressed &&
          asset.original == null) {
        return _invalid(
          'An original image is required for comparison sharing.',
        );
      }
      if (asset.original != null) {
        final Result<void> original = await _validateAsset(
          asset.original!,
          trustedRoots,
        );
        if (original.isFailure) return original;
      }
    }
    return const Result<void>.success(null);
  }

  @override
  String sanitizeFilename(String value) {
    final String basename = p.basename(value.replaceAll('\\', '/'));
    final String sanitized = basename
        .replaceAll(RegExp(r'[^A-Za-z0-9._-]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^\.+'), '')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    if (sanitized.isEmpty || sanitized == '.' || sanitized == '..') {
      return 'image';
    }
    return sanitized.length > 180 ? sanitized.substring(0, 180) : sanitized;
  }

  Future<Result<void>> _validateAsset(
    ExportAsset asset,
    List<String> trustedRoots,
  ) async {
    if (asset.id.trim().isEmpty || asset.filePath.trim().isEmpty) {
      return _invalid('An export item is missing its local identity.');
    }
    if (asset.filePath.contains('\u0000') ||
        asset.filePath.startsWith('content://') ||
        asset.filePath.startsWith('http://') ||
        asset.filePath.startsWith('https://')) {
      return _unsafe('Only local file paths can be exported offline.');
    }
    final String normalized = p.normalize(p.absolute(asset.filePath));
    if (!await _isAuthorized(normalized, trustedRoots)) {
      return _unsafe('The source file is not authorized.');
    }
    if (!asset.hasValidSize || !asset.hasValidDimensions) {
      return _invalid('An export item has invalid image metadata.');
    }
    if (asset.bytes > 1024 * 1024 * 1024) {
      return _invalid('An export item exceeds the supported file size.');
    }
    return const Result<void>.success(null);
  }

  Future<Result<List<String>>> _trustedRoots() async {
    final Result<Map<StorageLocation, Directory>> result = await storage
        .directories();
    if (result case Failure<Map<StorageLocation, Directory>>(
      error: final AppError error,
    )) {
      return Result<List<String>>.failure(error);
    }
    final Map<StorageLocation, Directory> directories =
        (result as Success<Map<StorageLocation, Directory>>).value;
    final List<String> roots = <String>[];
    for (final StorageLocation location in <StorageLocation>[
      StorageLocation.temporary,
      StorageLocation.compression,
      StorageLocation.exports,
    ]) {
      final Directory? directory = directories[location];
      if (directory != null) roots.add(directory.path);
    }
    if (roots.isEmpty) {
      return const Result<List<String>>.failure(
        AppError(
          code: ErrorCode.unsafePath,
          message: 'Managed export storage is unavailable.',
          isRecoverable: false,
        ),
      );
    }
    return Result<List<String>>.success(List<String>.unmodifiable(roots));
  }

  Future<bool> _isAuthorized(
    String normalized,
    List<String> trustedRoots,
  ) async {
    for (final String root in trustedRoots) {
      final Directory rootDirectory = Directory(root);
      final String lexicalRoot = p.normalize(p.absolute(root));
      if (!_within(normalized, lexicalRoot)) continue;
      try {
        final String canonicalRoot = await rootDirectory.exists()
            ? p.normalize(
                p.absolute(await rootDirectory.resolveSymbolicLinks()),
              )
            : lexicalRoot;
        final File source = File(normalized);
        final String candidate = await source.exists()
            ? p.normalize(p.absolute(await source.resolveSymbolicLinks()))
            : normalized;
        if (_within(candidate, canonicalRoot)) return true;
      } on Object {
        return false;
      }
    }
    return false;
  }

  bool _within(String path, String root) {
    final String relative = p.relative(path, from: root);
    return relative != '..' &&
        !relative.startsWith('..${p.separator}') &&
        !p.isAbsolute(relative);
  }

  Result<void> _invalid(String message) => Result<void>.failure(
    AppError(
      code: ErrorCode.invalidArgument,
      message: message,
      isRecoverable: false,
    ),
  );

  Result<void> _unsafe(String message) => Result<void>.failure(
    AppError(
      code: ErrorCode.unsafePath,
      message: message,
      isRecoverable: false,
    ),
  );
}
