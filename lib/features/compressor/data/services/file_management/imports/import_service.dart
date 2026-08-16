import 'dart:io';

import 'package:path/path.dart' as p;

import '../../../../../../core/errors/app_error.dart';
import '../../../../../../core/errors/error_code.dart';
import '../../../../../../core/errors/error_mapper.dart';
import '../../../../../../core/errors/result_error_adapter.dart';
import '../../../../../../core/models/result.dart';
import '../../../../../../core/services/file_system_service.dart';
import '../interfaces/file_management_interfaces.dart';
import '../models/file_management_models.dart';

/// Copies transient picker results into app-private temporary storage.
final class LocalImportService implements ImportService {
  /// Creates an import service.
  const LocalImportService({
    required this.storage,
    required this.fileSystem,
    required this.naming,
  });

  /// Managed storage resolver.
  final StorageManager storage;

  /// Managed filesystem boundary.
  final FileSystemService fileSystem;

  /// Collision-safe naming strategy.
  final FileNamingStrategy naming;

  @override
  Future<Result<ExportedFile>> importExternal(SelectedFile selected) async {
    try {
      final File source = File(selected.path);
      if (!await source.exists()) {
        return const Result<ExportedFile>.failure(
          AppError(
            code: ErrorCode.notFound,
            message: 'The selected file is no longer available.',
            isRecoverable: false,
          ),
        );
      }
      final Result<Directory> directoryResult = await storage.directory(
        StorageLocation.temporary,
      );
      if (directoryResult case Failure<Directory>(
        error: final AppError error,
      )) {
        return Result<ExportedFile>.failure(error);
      }
      final Directory directory = (directoryResult as Success<Directory>).value;
      final Result<File> targetResult = await naming.collisionSafePath(
        directory,
        FileNameRequest(
          originalName: selected.name,
          suffix: 'Imported',
          extension: p.extension(selected.name).replaceFirst('.', ''),
        ),
      );
      if (targetResult case Failure<File>(error: final AppError error)) {
        return Result<ExportedFile>.failure(error);
      }
      File target = (targetResult as Success<File>).value;
      Result<File> copyResult = await fileSystem.copyFromExternal(
        source,
        target,
      );
      // A concurrent writer may claim the selected name after the naming
      // check. Re-select a bounded number of times rather than overwriting.
      retry:
      for (int attempt = 0; attempt < 3; attempt++) {
        if (copyResult case Success<File>()) break retry;
        if (copyResult case Failure<File>(
          error: final AppError error,
        ) when error.code != ErrorCode.conflict) {
          break retry;
        }
        final Result<File> retryTarget = await naming.collisionSafePath(
          directory,
          FileNameRequest(
            originalName: selected.name,
            suffix: 'Imported',
            extension: p.extension(selected.name).replaceFirst('.', ''),
          ),
        );
        if (retryTarget case Failure<File>(error: final AppError retryError)) {
          return Result<ExportedFile>.failure(retryError);
        }
        target = (retryTarget as Success<File>).value;
        copyResult = await fileSystem.copyFromExternal(source, target);
      }
      if (copyResult case Failure<File>(error: final AppError error)) {
        return Result<ExportedFile>.failure(error);
      }
      final File imported = (copyResult as Success<File>).value;
      return Result<ExportedFile>.success(
        ExportedFile(
          path: imported.path,
          name: p.basename(imported.path),
          bytes: await imported.length(),
          location: StorageLocation.temporary,
        ),
      );
    } catch (error, stackTrace) {
      final exception = ErrorMapper.map(error, stackTrace);
      return Result<ExportedFile>.failure(
        ResultErrorAdapter.fromException(exception),
      );
    }
  }
}
