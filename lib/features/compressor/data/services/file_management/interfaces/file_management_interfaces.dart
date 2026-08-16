import 'dart:io';

import '../../../../../../core/models/result.dart';
import '../models/file_management_models.dart';

/// Selects images through user-mediated platform APIs.
abstract interface class ImagePickerService {
  /// Selects one or more images.
  Future<Result<List<SelectedFile>>> pick(ImageSelectionRequest request);

  /// Recovers a selection after activity recreation.
  Future<Result<List<SelectedFile>>> recoverLostSelection();
}

/// Scans a user-selected folder without taking ownership of it.
abstract interface class FolderPickerService {
  /// Scans a folder path according to [options].
  Future<Result<List<String>>> scan(
    String folderPath, {
    FolderScanOptions options = const FolderScanOptions(),
  });
}

/// Validates and fingerprints files.
abstract interface class FileValidator {
  /// Validates one local image file.
  Future<Result<ManagedFile>> validate(
    String path, {
    FileValidationPolicy policy = const FileValidationPolicy(),
  });

  /// Validates a collection without throwing for an individual bad file.
  Future<Result<FileOperationSummary>> validateMany(
    Iterable<String> paths, {
    FileValidationPolicy policy = const FileValidationPolicy(),
  });
}

/// Resolves app-owned storage locations.
abstract interface class StorageManager {
  /// Creates and returns all app-managed directories.
  Future<Result<Map<StorageLocation, Directory>>> directories();

  /// Resolves one app-managed directory.
  Future<Result<Directory>> directory(StorageLocation location);
}

/// Generates collision-safe app filenames.
abstract interface class FileNamingStrategy {
  /// Creates a sanitized file name from [request].
  String create(FileNameRequest request);

  /// Returns a non-colliding path in [directory].
  Future<Result<File>> collisionSafePath(
    Directory directory,
    FileNameRequest request,
  );
}

/// Stores and retrieves local history records.
abstract interface class HistoryStorage {
  /// Persists one history record.
  Future<Result<void>> save(CompressionHistoryRecord record);

  /// Reads all valid records in newest-first order.
  Future<Result<List<CompressionHistoryRecord>>> readAll();

  /// Deletes a record by id.
  Future<Result<void>> delete(String id);
}

/// Imports a picker result into app-private temporary storage.
abstract interface class ImportService {
  /// Copies one user-selected file into managed temporary storage.
  Future<Result<ExportedFile>> importExternal(SelectedFile selected);
}

/// Copies generated files to app-owned export staging.
abstract interface class ExportService {
  /// Exports one file with a collision-safe name.
  Future<Result<ExportedFile>> export(
    String sourcePath, {
    required FileNameRequest naming,
  });

  /// Creates a temporary share copy.
  Future<Result<ExportedFile>> prepareShareCopy(
    String sourcePath, {
    required FileNameRequest naming,
  });
}

/// Removes expired and orphaned generated files.
abstract interface class FileCleanupService {
  /// Applies [policy] to generated storage.
  Future<Result<FileCleanupReport>> cleanup({
    FileCleanupPolicy policy = const FileCleanupPolicy(),
  });
}

/// Provides permission state without requesting broad storage access.
abstract interface class PermissionService {
  /// Returns whether user-mediated file access is available.
  Future<Result<bool>> canAccessSelectedFile(String path);

  /// Requests no broad storage permission; returns the policy result.
  Future<Result<bool>> requestManagedAccess();
}

/// Provides reusable file operations at the file-management boundary.
abstract interface class FileUtilities {
  /// Normalizes a path for comparison.
  String normalizePath(String path);

  /// Returns a best-effort MIME type.
  String mimeType(String path);

  /// Calculates a streaming SHA-256 checksum.
  Future<Result<String>> checksum(String path);

  /// Performs a bounded decode probe without retaining image pixels.
  Future<Result<bool>> isDecodableImage(String path);

  /// Copies a file using the managed filesystem boundary.
  Future<Result<File>> safeCopy(String sourcePath, String destinationPath);

  /// Moves a managed file to another managed location.
  Future<Result<File>> safeMove(String sourcePath, String destinationPath);

  /// Estimates storage occupied by a file.
  Future<Result<int>> estimateStorage(String path);

  /// Deletes a generated file using the managed filesystem boundary.
  Future<Result<void>> safeDelete(String path);
}

/// Central file-management facade consumed by future use cases.
abstract interface class FileManager {
  /// Selects and validates images.
  Future<Result<FileOperationSummary>> selectImages(
    ImageSelectionRequest request,
  );

  /// Validates one path.
  Future<Result<ManagedFile>> validate(String path);

  /// Exports a generated file.
  Future<Result<ExportedFile>> export(
    String sourcePath, {
    required FileNameRequest naming,
  });

  /// Prepares a shareable temporary copy.
  Future<Result<ExportedFile>> prepareShareCopy(
    String sourcePath, {
    required FileNameRequest naming,
  });

  /// Recovers a lost picker selection.
  Future<Result<FileOperationSummary>> recoverLostSelection();

  /// Scans a caller-selected folder.
  Future<Result<List<String>>> scanFolder(
    String folderPath, {
    FolderScanOptions options = const FolderScanOptions(),
  });

  /// Persists a local history record.
  Future<Result<void>> saveHistory(CompressionHistoryRecord record);

  /// Reads local history records.
  Future<Result<List<CompressionHistoryRecord>>> readHistory();

  /// Deletes a local history record.
  Future<Result<void>> deleteHistory(String id);

  /// Returns whether a selected path is currently readable.
  Future<Result<bool>> canAccessSelectedFile(String path);

  /// Runs generated-file cleanup.
  Future<Result<FileCleanupReport>> cleanup({
    FileCleanupPolicy policy = const FileCleanupPolicy(),
  });
}
