import 'dart:io';

import 'package:path/path.dart' as p;

import '../../../../../../core/errors/error_mapper.dart';
import '../../../../../../core/errors/result_error_adapter.dart';
import '../../../../../../core/models/result.dart';
import '../interfaces/file_management_interfaces.dart';
import '../models/file_management_models.dart';

/// Generates human-readable and collision-safe output names.
final class IntelligentFileNamingStrategy implements FileNamingStrategy {
  /// Creates a naming strategy.
  const IntelligentFileNamingStrategy();

  @override
  String create(FileNameRequest request) {
    final String base = _sanitize(
      p.basenameWithoutExtension(request.originalName),
    );
    final String suffix = _sanitize(request.suffix);
    final String extension = _sanitize(request.extension).toLowerCase();
    final String version = request.version == null
        ? ''
        : '_v${request.version}';
    return '${base.isEmpty ? 'Image' : base}_$suffix$version.$extension';
  }

  @override
  Future<Result<File>> collisionSafePath(
    Directory directory,
    FileNameRequest request,
  ) async {
    try {
      await directory.create(recursive: true);
      final String initial = create(request);
      final String stem = p.basenameWithoutExtension(initial);
      final String extension = p.extension(initial);
      File candidate = File(p.join(directory.path, initial));
      int version = 2;
      while (await candidate.exists()) {
        candidate = File(p.join(directory.path, '${stem}_v$version$extension'));
        version++;
      }
      return Result<File>.success(candidate);
    } catch (error, stackTrace) {
      final exception = ErrorMapper.map(error, stackTrace);
      return Result<File>.failure(ResultErrorAdapter.fromException(exception));
    }
  }

  String _sanitize(String value) => value
      .replaceAll(RegExp(r'[^A-Za-z0-9._-]+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');
}
