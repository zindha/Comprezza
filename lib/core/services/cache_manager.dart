import 'dart:io';

import '../constants/app_constants.dart';
import '../errors/app_error.dart';
import '../errors/app_exception.dart';
import '../errors/error_code.dart';
import '../errors/error_mapper.dart';
import '../errors/result_error_adapter.dart';
import '../models/result.dart';
import 'cache_categories.dart';
import 'file_system_service.dart';

/// Configurable cache retention policy.
class CachePolicy {
  /// Creates a cache policy.
  const CachePolicy({
    this.maxAge = AppConstants.temporaryFileMaxAge,
    this.maxBytes = 256 * 1024 * 1024,
  });

  /// Maximum age of generated entries.
  final Duration maxAge;

  /// Maximum total cache bytes where measurable.
  final int maxBytes;
}

/// Cache statistics returned by cleanup operations.
class CacheCleanupReport {
  /// Creates a cleanup report.
  const CacheCleanupReport({
    required this.removedFiles,
    required this.removedBytes,
  });

  /// Number of removed files.
  final int removedFiles;

  /// Number of removed bytes.
  final int removedBytes;
}

/// Manages generated cache entries without touching user originals.
abstract interface class CacheManager {
  /// Removes expired or over-limit generated entries.
  Future<Result<CacheCleanupReport>> cleanup({
    CachePolicy policy = const CachePolicy(),
  });
}

/// Filesystem-backed cache manager with injectable directory and clock.
final class LocalCacheManager implements CacheManager {
  /// Creates a local cache manager.
  const LocalCacheManager({
    required this.fileSystem,
    required this.directories,
    this.now = DateTime.now,
  });

  /// Filesystem service.
  final FileSystemService fileSystem;

  /// Application directories provider.
  final Future<Result<AppDirectories>> Function() directories;

  /// Injectable clock.
  final DateTime Function() now;

  @override
  Future<Result<CacheCleanupReport>> cleanup({
    CachePolicy policy = const CachePolicy(),
  }) async {
    try {
      final Result<AppDirectories> result = await directories();
      if (result case Failure<AppDirectories>(error: final AppError error)) {
        return Result<CacheCleanupReport>.failure(error);
      }
      final AppDirectories paths = (result as Success<AppDirectories>).value;
      final DateTime cutoff = now().subtract(policy.maxAge);
      final List<File> files = <File>[];
      await _collectFiles(
        paths.cache,
        files,
        category: CacheCategory.unusedCache,
      );
      await _collectFiles(
        paths.compression,
        files,
        category: CacheCategory.temporaryOutput,
      );
      await _collectFiles(
        paths.exports,
        files,
        category: CacheCategory.temporaryOutput,
      );
      await _collectFiles(
        paths.thumbnails,
        files,
        category: CacheCategory.thumbnail,
      );
      final List<_CacheEntry> entries = <_CacheEntry>[];
      for (final File file in files) {
        final FileMetadata stat = await fileSystem.stat(file);
        entries.add(
          _CacheEntry(file: file, modified: stat.modified, bytes: stat.size),
        );
      }
      entries.sort(
        (_CacheEntry a, _CacheEntry b) => a.modified.compareTo(b.modified),
      );
      int totalBytes = entries.fold(
        0,
        (int sum, _CacheEntry entry) => sum + entry.bytes,
      );
      int removedFiles = 0;
      int removedBytes = 0;
      for (final _CacheEntry entry in entries) {
        final bool expired = entry.modified.isBefore(cutoff);
        final bool overLimit = totalBytes > policy.maxBytes;
        if (!expired && !overLimit) continue;
        final Result<void> deletion = await fileSystem.safeDelete(entry.file);
        if (deletion.isSuccess) {
          removedFiles++;
          removedBytes += entry.bytes;
          totalBytes -= entry.bytes;
        }
      }
      return Result<CacheCleanupReport>.success(
        CacheCleanupReport(
          removedFiles: removedFiles,
          removedBytes: removedBytes,
        ),
      );
    } catch (error, stackTrace) {
      final AppException exception = ErrorMapper.map(error, stackTrace);
      return Result<CacheCleanupReport>.failure(
        ResultErrorAdapter.fromException(
          AppException(
            code: ErrorCode.cacheCleanupFailed,
            message: exception.message,
            cause: exception.cause,
            stackTrace: exception.stackTrace,
          ),
        ),
      );
    }
  }

  Future<void> _collectFiles(
    Directory directory,
    List<File> files, {
    required CacheCategory category,
  }) async {
    final List<File> candidates = await fileSystem.listFiles(directory);
    for (final File file in candidates) {
      final String name = file.uri.pathSegments.last.toLowerCase();
      final bool matches = switch (category) {
        CacheCategory.temporaryOutput => name.startsWith(
          AppConstants.temporaryOutputPrefix,
        ),
        CacheCategory.thumbnail => name.contains('thumb'),
        CacheCategory.unusedCache => name.startsWith(
          AppConstants.temporaryOutputPrefix,
        ),
      };
      if (matches) files.add(file);
    }
  }
}

final class _CacheEntry {
  const _CacheEntry({
    required this.file,
    required this.modified,
    required this.bytes,
  });

  final File file;
  final DateTime modified;
  final int bytes;
}
