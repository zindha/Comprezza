import 'dart:io';

import '../../../../../../core/errors/app_error.dart';
import '../../../../../../core/errors/error_code.dart';
import '../../../../../../core/errors/error_mapper.dart';
import '../../../../../../core/errors/result_error_adapter.dart';
import '../../../../../../core/models/result.dart';
import '../../../../../../core/services/file_system_service.dart';
import '../interfaces/file_management_interfaces.dart';
import '../models/file_management_models.dart';

/// Copies generated outputs into managed export staging directories.
final class LocalExportService implements ExportService {
  /// Creates an export service.
  const LocalExportService({
    required this.storage,
    required this.naming,
    required this.fileSystem,
  });

  /// Managed storage resolver.
  final StorageManager storage;

  /// Collision-safe naming strategy.
  final FileNamingStrategy naming;

  /// Managed filesystem boundary.
  final FileSystemService fileSystem;

  @override
  Future<Result<ExportedFile>> export(
    String sourcePath, {
    required FileNameRequest naming,
  }) => _copy(sourcePath, naming: naming, location: StorageLocation.exports);

  @override
  Future<Result<ExportedFile>> prepareShareCopy(
    String sourcePath, {
    required FileNameRequest naming,
  }) => _copy(sourcePath, naming: naming, location: StorageLocation.temporary);

  Future<Result<ExportedFile>> _copy(
    String sourcePath, {
    required FileNameRequest naming,
    required StorageLocation location,
  }) async {
    try {
      final File source = File(sourcePath);
      if (!await source.exists()) {
        return const Result<ExportedFile>.failure(
          AppError(
            code: ErrorCode.notFound,
            message: 'The export source does not exist.',
            isRecoverable: false,
          ),
        );
      }
      final Result<Directory> directoryResult = await storage.directory(
        location,
      );
      if (directoryResult case Failure<Directory>(
        error: final AppError error,
      )) {
        return Result<ExportedFile>.failure(error);
      }
      final Directory directory = (directoryResult as Success<Directory>).value;
      final Result<File> targetResult = await this.naming.collisionSafePath(
        directory,
        naming,
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
        final Result<File> retryTarget = await this.naming.collisionSafePath(
          directory,
          naming,
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
      final int bytes = await (copyResult as Success<File>).value.length();
      return Result<ExportedFile>.success(
        ExportedFile(
          path: target.path,
          name: target.uri.pathSegments.last,
          bytes: bytes,
          location: location,
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
