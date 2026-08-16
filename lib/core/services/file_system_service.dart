import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:path/path.dart' as p;

import '../constants/app_strings.dart';
import '../errors/app_error.dart';
import '../errors/app_exception.dart';
import '../errors/error_code.dart';
import '../errors/error_mapper.dart';
import '../errors/result_error_adapter.dart';
import '../models/result.dart';
import 'path_provider_service.dart';

/// Named private directories owned by the application.
class AppDirectories {
  /// Creates application directory paths.
  const AppDirectories({
    required this.cache,
    required this.history,
    required this.thumbnails,
    required this.exports,
    required this.compression,
    required this.backup,
  });

  /// App-owned temporary cache directory.
  final Directory cache;

  /// Persistent local history directory.
  final Directory history;

  /// Persistent thumbnail directory.
  final Directory thumbnails;

  /// Persistent export staging directory.
  final Directory exports;

  /// Persistent compression working directory.
  final Directory compression;

  /// Reserved app-private backup directory.
  final Directory backup;
}

/// Platform-neutral file metadata used by cache and storage policies.
class FileMetadata {
  /// Creates file metadata.
  const FileMetadata({required this.size, required this.modified});

  /// File size in bytes.
  final int size;

  /// Last-modified timestamp.
  final DateTime modified;
}

/// Abstracts local storage operations for independent testing.
abstract interface class FileSystemService {
  /// Resolves and creates application-owned directories.
  Future<Result<AppDirectories>> directories();

  /// Lists files in an app-owned directory.
  Future<List<File>> listFiles(Directory directory, {bool recursive = true});

  /// Reads file metadata through the abstraction.
  Future<FileMetadata> stat(File file);

  /// Reads app-owned file bytes.
  Future<Result<Uint8List>> readBytes(File file);

  /// Reads UTF-8 text from an app-owned file.
  Future<Result<String>> readText(File file);

  /// Writes bytes to an app-owned file.
  Future<Result<File>> writeBytes(File file, Uint8List bytes);

  /// Copies an app-owned file to another app-owned location.
  Future<Result<File>> copy(File source, File destination);

  /// Copies a user-selected external file into an app-owned destination.
  Future<Result<File>> copyFromExternal(File source, File destination);

  /// Atomically writes UTF-8 text into an app-owned file.
  Future<Result<File>> writeTextAtomic(File file, String contents);

  /// Moves an app-owned file to another app-owned location.
  Future<Result<File>> move(File source, File destination);

  /// Creates a child directory inside [parent].
  Future<Result<Directory>> ensureChildDirectory(Directory parent, String name);

  /// Safely deletes a file or directory owned by the application.
  Future<Result<void>> safeDelete(
    FileSystemEntity entity, {
    bool recursive = false,
  });
}

/// Production filesystem implementation using app-private directories.
final class LocalFileSystemService implements FileSystemService {
  /// Creates the local filesystem service.
  LocalFileSystemService({AppPathProvider? pathProvider})
    : _pathProvider = pathProvider ?? const PlatformAppPathProvider();

  final AppPathProvider _pathProvider;

  final Set<String> _baseRoots = <String>{};
  final Set<String> _deletableRoots = <String>{};
  final Set<String> _ownedRoots = <String>{};
  final Random _random = Random.secure();
  Future<void> _writeTail = Future<void>.value();
  // App-private directories are stable for the process lifetime, so the
  // first successful resolution is memoized. Without this, every history read
  // re-created six directories and re-canonicalized their symlinks, adding
  // filesystem churn right on the navigation path.
  Future<Result<AppDirectories>>? _cachedDirectories;

  @override
  Future<Result<AppDirectories>> directories() {
    final Future<Result<AppDirectories>>? cached = _cachedDirectories;
    if (cached != null) return cached;
    final Future<Result<AppDirectories>> resolving = _resolveDirectories();
    _cachedDirectories = resolving.then((Result<AppDirectories> result) {
      if (result case Failure<AppDirectories>()) {
        // Transient failures stay retryable; only successes are stable.
        _cachedDirectories = null;
      }
      return result;
    });
    return _cachedDirectories!;
  }

  Future<Result<AppDirectories>> _resolveDirectories() async {
    try {
      final Directory temporaryRoot = await _pathProvider.temporaryDirectory();
      final Directory support = await _pathProvider
          .applicationSupportDirectory();
      final Directory cache = Directory(
        p.join(temporaryRoot.path, AppStrings.cacheDirectory),
      );
      final Directory history = Directory(
        p.join(support.path, AppStrings.historyDirectory),
      );
      final Directory thumbnails = Directory(
        p.join(history.path, AppStrings.thumbnailDirectory),
      );
      final Directory exports = Directory(
        p.join(support.path, AppStrings.exportDirectory),
      );
      final Directory compression = Directory(
        p.join(support.path, AppStrings.compressionDirectory),
      );
      final Directory backup = Directory(
        p.join(support.path, AppStrings.backupDirectory),
      );
      for (final Directory directory in <Directory>[
        cache,
        history,
        thumbnails,
        exports,
        compression,
        backup,
      ]) {
        await directory.create(recursive: true);
        // Register the canonical (symlink-resolved) location. On Android the
        // support root is reachable through /data/user/0/<pkg> which is a
        // symlink to /data/data/<pkg>. Validation below also resolves symlinks,
        // so both sides must live in the same canonical space or every read and
        // write is rejected as an unsafe path and settings never persist.
        final String canonical = await _canonicalize(directory);
        _baseRoots.add(canonical);
        _ownedRoots.add(canonical);
      }
      for (final Directory directory in <Directory>[
        cache,
        history,
        thumbnails,
        exports,
        compression,
        backup,
      ]) {
        _deletableRoots.add(await _canonicalize(directory));
      }
      return Result<AppDirectories>.success(
        AppDirectories(
          cache: cache,
          history: history,
          thumbnails: thumbnails,
          exports: exports,
          compression: compression,
          backup: backup,
        ),
      );
    } catch (error, stackTrace) {
      return _failure<AppDirectories>(error, stackTrace);
    }
  }

  @override
  Future<List<File>> listFiles(
    Directory directory, {
    bool recursive = true,
  }) async {
    if (!await directory.exists() ||
        !await _isOwnedEntity(directory, allowRoot: true)) {
      return <File>[];
    }
    final List<File> files = <File>[];
    await for (final FileSystemEntity entity in directory.list(
      recursive: recursive,
      followLinks: false,
    )) {
      if (entity is File && await _isOwnedEntity(entity)) files.add(entity);
    }
    return files;
  }

  @override
  Future<FileMetadata> stat(File file) async {
    if (!await _isOwnedEntity(file)) {
      throw const FileSystemException('The file is outside app-owned storage.');
    }
    final FileStat stat = await file.stat();
    return FileMetadata(size: stat.size, modified: stat.modified);
  }

  @override
  Future<Result<String>> readText(File file) async {
    try {
      if (!await _isOwnedEntity(file)) {
        return const Result<String>.failure(
          AppError(
            code: ErrorCode.unsafePath,
            message: 'The path is outside app-owned storage.',
            isRecoverable: false,
          ),
        );
      }
      return Result<String>.success(await file.readAsString());
    } catch (error, stackTrace) {
      return _failure<String>(error, stackTrace);
    }
  }

  @override
  Future<Result<Uint8List>> readBytes(File file) async {
    try {
      if (!await _isOwnedEntity(file)) {
        return const Result<Uint8List>.failure(
          AppError(
            code: ErrorCode.unsafePath,
            message: 'The path is outside app-owned storage.',
            isRecoverable: false,
          ),
        );
      }
      return Result<Uint8List>.success(await file.readAsBytes());
    } catch (error, stackTrace) {
      return _failure<Uint8List>(error, stackTrace);
    }
  }

  @override
  Future<Result<File>> writeBytes(File file, Uint8List bytes) async {
    try {
      if (!await _isOwnedEntity(file)) {
        return const Result<File>.failure(
          AppError(
            code: ErrorCode.unsafePath,
            message: 'The path is outside app-owned storage.',
            isRecoverable: false,
          ),
        );
      }
      await file.parent.create(recursive: true);
      return Result<File>.success(await file.writeAsBytes(bytes));
    } catch (error, stackTrace) {
      return _failure<File>(error, stackTrace);
    }
  }

  @override
  Future<Result<File>> copyFromExternal(File source, File destination) {
    return _withWriteLock<Result<File>>(() async {
      try {
        if (!await source.exists()) {
          return const Result<File>.failure(
            AppError(
              code: ErrorCode.notFound,
              message: 'The source file does not exist.',
              isRecoverable: false,
            ),
          );
        }
        if (!await _isOwnedEntity(destination)) {
          return const Result<File>.failure(
            AppError(
              code: ErrorCode.unsafePath,
              message: 'The destination is not app-owned.',
              isRecoverable: false,
            ),
          );
        }
        if (await destination.exists()) {
          return const Result<File>.failure(
            AppError(
              code: ErrorCode.conflict,
              message: 'The destination already exists.',
            ),
          );
        }
        await destination.parent.create(recursive: true);
        final File temporary = _temporaryFile(destination);
        try {
          await source.openRead().pipe(temporary.openWrite());
          await temporary.rename(destination.path);
          return Result<File>.success(destination);
        } finally {
          await _deleteTemporaryBestEffort(temporary);
        }
      } catch (error, stackTrace) {
        return _failure<File>(error, stackTrace);
      }
    });
  }

  @override
  Future<Result<File>> copy(File source, File destination) async {
    try {
      if (!await _isOwnedEntity(source) || !await _isOwnedEntity(destination)) {
        return const Result<File>.failure(
          AppError(
            code: ErrorCode.unsafePath,
            message: 'The source or destination is outside app-owned storage.',
            isRecoverable: false,
          ),
        );
      }
      await destination.parent.create(recursive: true);
      return Result<File>.success(await source.copy(destination.path));
    } catch (error, stackTrace) {
      return _failure<File>(error, stackTrace);
    }
  }

  @override
  Future<Result<File>> writeTextAtomic(File file, String contents) {
    return _withWriteLock<Result<File>>(() async {
      try {
        if (!await _isOwnedEntity(file)) {
          return const Result<File>.failure(
            AppError(
              code: ErrorCode.unsafePath,
              message: 'The destination is outside app-owned storage.',
              isRecoverable: false,
            ),
          );
        }
        await file.parent.create(recursive: true);
        final File temporary = _temporaryFile(file);
        try {
          await temporary.writeAsString(contents, flush: true);
          // The temporary file lives beside the destination, so Android/Linux
          // can replace the previous snapshot with one atomic rename. A few
          // filesystem providers reject replacement rename even on the same
          // volume; copy over the destination without deleting the last good
          // snapshot first, then let the temporary cleanup run.
          try {
            await temporary.rename(file.path);
          } on FileSystemException {
            // Some Android filesystem providers reject replacing an existing
            // file with rename(). Keep the last good snapshot safe while
            // moving the destination aside, then install the new snapshot.
            await _replaceExistingFileSafely(temporary, file);
          }
          return Result<File>.success(file);
        } finally {
          await _deleteTemporaryBestEffort(temporary);
        }
      } catch (error, stackTrace) {
        return _failure<File>(error, stackTrace);
      }
    });
  }

  @override
  Future<Result<File>> move(File source, File destination) async {
    try {
      if (!await _isOwnedEntity(source) || !await _isOwnedEntity(destination)) {
        return const Result<File>.failure(
          AppError(
            code: ErrorCode.unsafePath,
            message: 'The source or destination is outside app-owned storage.',
            isRecoverable: false,
          ),
        );
      }
      await destination.parent.create(recursive: true);
      return Result<File>.success(await source.rename(destination.path));
    } catch (error, stackTrace) {
      return _failure<File>(error, stackTrace);
    }
  }

  @override
  Future<Result<Directory>> ensureChildDirectory(
    Directory parent,
    String name,
  ) async {
    try {
      if (!_isSafeChildName(name) ||
          !await _isOwnedEntity(parent, allowRoot: true)) {
        return const Result<Directory>.failure(
          AppError(
            code: ErrorCode.unsafePath,
            message: 'The parent is outside app-owned storage.',
            isRecoverable: false,
          ),
        );
      }
      final Directory child = Directory(p.join(parent.path, name));
      if (!await _isOwnedEntity(child)) {
        return const Result<Directory>.failure(
          AppError(
            code: ErrorCode.unsafePath,
            message: 'The child is outside app-owned storage.',
            isRecoverable: false,
          ),
        );
      }
      await child.create(recursive: true);
      _ownedRoots.add(_normalized(child.path));
      return Result<Directory>.success(child);
    } catch (error, stackTrace) {
      return _failure<Directory>(error, stackTrace);
    }
  }

  @override
  Future<Result<void>> safeDelete(
    FileSystemEntity entity, {
    bool recursive = false,
  }) async {
    try {
      if (!await _isDeletableEntity(entity) || await _isBaseRoot(entity)) {
        return const Result<void>.failure(
          AppError(
            code: ErrorCode.unsafePath,
            message: 'Only generated app-owned paths may be deleted.',
            isRecoverable: false,
          ),
        );
      }
      try {
        await entity.delete(recursive: recursive);
      } on PathNotFoundException {
        // Another cleanup pass may have removed it already.
      }
      return const Result<void>.success(null);
    } catch (error, stackTrace) {
      return _failure<void>(error, stackTrace);
    }
  }

  Future<T> _withWriteLock<T>(Future<T> Function() operation) async {
    final Future<void> previous = _writeTail;
    final Completer<void> completed = Completer<void>();
    _writeTail = completed.future;
    await previous;
    try {
      return await operation();
    } finally {
      completed.complete();
    }
  }

  File _temporaryFile(File destination) => File(
    '${destination.path}.${DateTime.now().microsecondsSinceEpoch}_${_random.nextInt(1 << 32)}.part',
  );

  Future<void> _replaceExistingFileSafely(
    File temporary,
    File destination,
  ) async {
    // Keep this name deterministic so the owning store can recover it after
    // an interrupted process replacement on Android.
    final File backup = File('${destination.path}.backup');
    bool backupCreated = false;
    bool backupRestored = false;
    bool replacementInstalled = false;
    try {
      if (await destination.exists()) {
        await _deleteTemporaryBestEffort(backup);
        await destination.rename(backup.path);
        backupCreated = true;
      }
      try {
        await temporary.rename(destination.path);
        replacementInstalled = true;
      } catch (error) {
        if (backupCreated) {
          await _restoreBackup(backup, destination);
          backupRestored = true;
        }
        rethrow;
      }
    } finally {
      // If restoration failed, retain the backup for startup recovery instead
      // of deleting the only known-good settings snapshot.
      if (backupCreated && (replacementInstalled || backupRestored)) {
        await _deleteTemporaryBestEffort(backup);
      }
    }
  }

  Future<void> _restoreBackup(File backup, File destination) async {
    if (await destination.exists()) await destination.delete();
    await backup.rename(destination.path);
  }

  Future<void> _deleteTemporaryBestEffort(File temporary) async {
    try {
      if (await temporary.exists()) await temporary.delete();
    } on Object {
      // Never mask the original copy/write result with cleanup failure.
    }
  }

  Result<T> _failure<T>(Object error, StackTrace stackTrace) {
    final AppException exception = ErrorMapper.map(error, stackTrace);
    return Result<T>.failure(ResultErrorAdapter.fromException(exception));
  }

  String _normalized(String path) => p.normalize(p.absolute(path));

  bool _isWithin(String path, String root) {
    final String relative = p.relative(path, from: root);
    return relative != '..' &&
        !relative.startsWith('..${p.separator}') &&
        !p.isAbsolute(relative);
  }

  bool _isOwnedPath(String path, {bool allowRoot = false}) {
    final String normalized = _normalized(path);
    return _ownedRoots.any(
      (String root) =>
          _isWithin(normalized, root) && (allowRoot || normalized != root),
    );
  }

  /// Resolves [entity] to its canonical absolute path.
  ///
  /// Existing entries resolve their own symbolic links; entries that do not
  /// exist yet resolve their nearest existing parent and re-append the
  /// remainder, mirroring how the OS will materialize the path.
  Future<String> _canonicalize(FileSystemEntity entity) async {
    try {
      if (await entity.exists()) {
        return _normalized(await entity.resolveSymbolicLinks());
      }
      final String path = entity.path;
      final Directory parent = Directory(p.dirname(path));
      return _normalized(
        p.join(await parent.resolveSymbolicLinks(), p.basename(path)),
      );
    } on FileSystemException {
      return _normalized(entity.path);
    }
  }

  Future<bool> _isOwnedEntity(
    FileSystemEntity entity, {
    bool allowRoot = false,
  }) async {
    final String resolvedPath = await _canonicalize(entity);
    return _isOwnedPath(resolvedPath, allowRoot: allowRoot);
  }

  Future<bool> _isBaseRoot(FileSystemEntity entity) async {
    final String resolved = await _canonicalize(entity);
    return _baseRoots.contains(resolved);
  }

  Future<bool> _isDeletableEntity(FileSystemEntity entity) async {
    if (!await _isOwnedEntity(entity)) return false;
    final String path = await _canonicalize(entity);
    return _deletableRoots.any((String root) => _isWithin(path, root));
  }

  bool _isSafeChildName(String name) =>
      name.isNotEmpty &&
      name != '.' &&
      name != '..' &&
      !name.contains('/') &&
      !name.contains('\\');
}
