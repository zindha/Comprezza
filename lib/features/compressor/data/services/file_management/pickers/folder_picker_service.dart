import 'dart:io';

import 'package:path/path.dart' as p;

import '../../../../../../core/constants/app_constants.dart';
import '../../../../../../core/errors/app_error.dart';
import '../../../../../../core/errors/error_code.dart';
import '../../../../../../core/errors/error_mapper.dart';
import '../../../../../../core/errors/result_error_adapter.dart';
import '../../../../../../core/models/result.dart';
import '../interfaces/file_management_interfaces.dart';
import '../models/file_management_models.dart';

/// Scans a caller-provided folder path without implementing a folder UI.
final class LocalFolderPickerService implements FolderPickerService {
  /// Creates a folder scanner.
  const LocalFolderPickerService();

  @override
  Future<Result<List<String>>> scan(
    String folderPath, {
    FolderScanOptions options = const FolderScanOptions(),
  }) async {
    try {
      final Directory root = Directory(folderPath);
      if (!await root.exists()) {
        return const Result<List<String>>.failure(
          AppError(
            code: ErrorCode.notFound,
            message: 'The selected folder does not exist.',
            isRecoverable: false,
          ),
        );
      }
      final List<String> paths = <String>[];
      final List<Directory> pending = <Directory>[root];
      while (pending.isNotEmpty) {
        final Directory current = pending.removeLast();
        await for (final FileSystemEntity entity in current.list(
          followLinks: false,
        )) {
          final String name = p.basename(entity.path);
          if (!options.includeHidden && name.startsWith('.')) continue;
          if (entity is Directory) {
            if (options.recursive) pending.add(entity);
            continue;
          }
          if (entity is! File) continue;
          final String extension = p
              .extension(name)
              .toLowerCase()
              .replaceFirst('.', '');
          if (AppConstants.supportedImageExtensions.contains(extension)) {
            paths.add(entity.path);
          }
        }
      }
      paths.sort();
      return Result<List<String>>.success(List<String>.unmodifiable(paths));
    } catch (error, stackTrace) {
      final exception = ErrorMapper.map(error, stackTrace);
      return Result<List<String>>.failure(
        ResultErrorAdapter.fromException(exception),
      );
    }
  }
}
