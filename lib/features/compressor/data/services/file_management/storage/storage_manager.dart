import 'dart:io';

import '../../../../../../core/errors/app_error.dart';
import '../../../../../../core/errors/error_code.dart';
import '../../../../../../core/models/result.dart';
import '../../../../../../core/services/file_system_service.dart';
import '../interfaces/file_management_interfaces.dart';
import '../models/file_management_models.dart';

/// Resolves all directories owned by the file-management platform.
final class LocalStorageManager implements StorageManager {
  /// Creates a storage manager backed by the shared filesystem service.
  const LocalStorageManager({required this.fileSystem});

  /// Shared app-private filesystem boundary.
  final FileSystemService fileSystem;

  @override
  Future<Result<Map<StorageLocation, Directory>>> directories() async {
    final Result<AppDirectories> result = await fileSystem.directories();
    return result.fold(
      onSuccess: (AppDirectories paths) =>
          Result.success(<StorageLocation, Directory>{
            StorageLocation.temporary: paths.cache,
            StorageLocation.compression: paths.compression,
            StorageLocation.exports: paths.exports,
            StorageLocation.history: paths.history,
            StorageLocation.cache: paths.thumbnails,
            StorageLocation.backup: paths.backup,
          }),
      onFailure: (AppError error) =>
          Result<Map<StorageLocation, Directory>>.failure(error),
    );
  }

  @override
  Future<Result<Directory>> directory(StorageLocation location) async {
    final Result<Map<StorageLocation, Directory>> result = await directories();
    return result.fold(
      onSuccess: (Map<StorageLocation, Directory> paths) {
        final Directory? directory = paths[location];
        if (directory == null) {
          return const Result<Directory>.failure(
            AppError(
              code: ErrorCode.notFound,
              message: 'The requested storage location is unavailable.',
              isRecoverable: false,
            ),
          );
        }
        return Result<Directory>.success(directory);
      },
      onFailure: (AppError error) => Result<Directory>.failure(error),
    );
  }
}
