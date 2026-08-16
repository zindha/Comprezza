import 'dart:io';

import 'package:path/path.dart' as p;

import '../../../../../../core/errors/error_mapper.dart';
import '../../../../../../core/errors/result_error_adapter.dart';
import '../../../../../../core/models/result.dart';
import '../../../../../../core/services/file_system_service.dart';
import '../interfaces/file_management_interfaces.dart';
import '../models/file_management_models.dart';

/// Cleans only generated app-owned files and never user originals.
final class LocalFileCleanupService implements FileCleanupService {
  /// Creates a cleanup service.
  const LocalFileCleanupService({
    required this.storage,
    required this.fileSystem,
    required this.history,
    this.now = DateTime.now,
  });

  /// Managed storage resolver.
  final StorageManager storage;

  /// App-owned filesystem boundary.
  final FileSystemService fileSystem;

  /// Local history used to protect referenced outputs.
  final HistoryStorage history;

  /// Injectable clock for deterministic tests.
  final DateTime Function() now;

  @override
  Future<Result<FileCleanupReport>> cleanup({
    FileCleanupPolicy policy = const FileCleanupPolicy(),
  }) async {
    try {
      final List<File> candidates = <File>[];
      for (final StorageLocation location in <StorageLocation>[
        StorageLocation.temporary,
        StorageLocation.compression,
        if (policy.includeExports) StorageLocation.exports,
        if (policy.includeThumbnails) StorageLocation.cache,
      ]) {
        final Result<Directory> directoryResult = await storage.directory(
          location,
        );
        if (directoryResult case Success<Directory>(
          value: final Directory directory,
        )) {
          candidates.addAll(await fileSystem.listFiles(directory));
        }
      }
      final Set<String> protectedPaths = <String>{
        ...policy.protectedPaths.map(
          (String path) => p.normalize(p.absolute(path)),
        ),
      };
      final Result<List<CompressionHistoryRecord>> historyResult = await history
          .readAll();
      if (historyResult case Failure<List<CompressionHistoryRecord>>(
        error: final error,
      )) {
        // Never delete generated files when the reference index cannot be
        // read; protection data is required for a safe cleanup decision.
        return Result<FileCleanupReport>.failure(error);
      }
      if (historyResult case Success<List<CompressionHistoryRecord>>(
        value: final List<CompressionHistoryRecord> records,
      )) {
        for (final CompressionHistoryRecord record in records) {
          protectedPaths.add(p.normalize(p.absolute(record.compressedPath)));
          protectedPaths.add(p.normalize(p.absolute(record.originalPath)));
        }
      }
      final DateTime cutoff = now().subtract(policy.maxAge);
      final List<_Entry> entries = <_Entry>[];
      for (final File file in candidates) {
        try {
          final FileMetadata metadata = await fileSystem.stat(file);
          entries.add(
            _Entry(
              file: file,
              modified: metadata.modified,
              bytes: metadata.size,
            ),
          );
        } on Object {
          // A disappearing file is already clean; a later pass may retry others.
        }
      }
      entries.sort((_Entry a, _Entry b) => a.modified.compareTo(b.modified));
      int totalBytes = entries.fold(
        0,
        (int sum, _Entry entry) => sum + entry.bytes,
      );
      int removedFiles = 0;
      int removedBytes = 0;
      int failedFiles = 0;
      for (final _Entry entry in entries) {
        if (protectedPaths.contains(p.normalize(p.absolute(entry.file.path)))) {
          continue;
        }
        if (!entry.modified.isBefore(cutoff) && totalBytes <= policy.maxBytes) {
          continue;
        }
        final Result<void> deletion = await fileSystem.safeDelete(entry.file);
        if (deletion.isSuccess) {
          removedFiles++;
          removedBytes += entry.bytes;
          totalBytes -= entry.bytes;
        } else {
          failedFiles++;
        }
      }
      return Result<FileCleanupReport>.success(
        FileCleanupReport(
          removedFiles: removedFiles,
          removedBytes: removedBytes,
          failedFiles: failedFiles,
        ),
      );
    } catch (error, stackTrace) {
      final exception = ErrorMapper.map(error, stackTrace);
      return Result<FileCleanupReport>.failure(
        ResultErrorAdapter.fromException(exception),
      );
    }
  }
}

final class _Entry {
  const _Entry({
    required this.file,
    required this.modified,
    required this.bytes,
  });

  final File file;
  final DateTime modified;
  final int bytes;
}
