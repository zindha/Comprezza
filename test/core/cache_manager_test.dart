import 'dart:io';
import 'dart:typed_data';

import 'package:comprezza/core/models/result.dart';
import 'package:comprezza/core/services/cache_manager.dart';
import 'package:comprezza/core/services/file_system_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('removes expired entries through the filesystem abstraction', () async {
    final _FakeFileSystem fileSystem = _FakeFileSystem();
    final DateTime now = DateTime(2026, 1, 2);
    final LocalCacheManager manager = LocalCacheManager(
      fileSystem: fileSystem,
      directories: () async =>
          Result<AppDirectories>.success(fileSystem.appDirectories),
      now: () => now,
    );

    final Result<CacheCleanupReport> result = await manager.cleanup(
      policy: const CachePolicy(maxAge: Duration(hours: 1), maxBytes: 1000),
    );

    expect(result, isA<Success<CacheCleanupReport>>());
    expect(fileSystem.deleted, hasLength(1));
  });
}

class _FakeFileSystem implements FileSystemService {
  _FakeFileSystem()
    : appDirectories = AppDirectories(
        cache: Directory('/cache'),
        history: Directory('/history'),
        thumbnails: Directory('/history/thumbnails'),
        exports: Directory('/exports'),
        compression: Directory('/compression'),
        backup: Directory('/backup'),
      ) {
    expired = File('/cache/comprezza_old.jpg');
  }

  late final File expired;
  final List<File> deleted = <File>[];

  final AppDirectories appDirectories;

  @override
  Future<Result<AppDirectories>> directories() async =>
      Result<AppDirectories>.success(appDirectories);

  @override
  Future<List<File>> listFiles(
    Directory directory, {
    bool recursive = true,
  }) async {
    if (directory.path == appDirectories.cache.path) return <File>[expired];
    return <File>[];
  }

  @override
  Future<FileMetadata> stat(File file) async =>
      FileMetadata(size: 20, modified: DateTime(2026));

  @override
  Future<Result<String>> readText(File file) async =>
      Result<String>.success(await file.readAsString());

  @override
  Future<Result<Uint8List>> readBytes(File file) async =>
      Result<Uint8List>.success(Uint8List(0));

  @override
  Future<Result<File>> writeBytes(File file, Uint8List bytes) async =>
      Result<File>.success(file);

  @override
  Future<Result<File>> copy(File source, File destination) async =>
      Result<File>.success(destination);

  @override
  Future<Result<File>> copyFromExternal(File source, File destination) async =>
      Result<File>.success(destination);

  @override
  Future<Result<File>> writeTextAtomic(File file, String contents) async =>
      Result<File>.success(file);

  @override
  Future<Result<File>> move(File source, File destination) async =>
      Result<File>.success(destination);

  @override
  Future<Result<Directory>> ensureChildDirectory(
    Directory parent,
    String name,
  ) async => Result<Directory>.success(Directory('${parent.path}/$name'));

  @override
  Future<Result<void>> safeDelete(
    FileSystemEntity entity, {
    bool recursive = false,
  }) async {
    deleted.add(entity as File);
    return const Result<void>.success(null);
  }
}
