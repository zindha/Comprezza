import 'dart:io';

import 'package:comprezza/core/models/result.dart';
import 'package:comprezza/core/services/file_system_service.dart';
import 'package:comprezza/core/services/path_provider_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'resolves app directories through an injectable path provider',
    () async {
      final Directory root = await Directory.systemTemp.createTemp(
        'comprezza_fs_test_',
      );
      addTearDown(() async {
        if (await root.exists()) await root.delete(recursive: true);
      });

      final LocalFileSystemService service = LocalFileSystemService(
        pathProvider: _FakePathProvider(root),
      );

      final Result<AppDirectories> result = await service.directories();

      expect(result, isA<Success<AppDirectories>>());
      final AppDirectories directories =
          (result as Success<AppDirectories>).value;
      expect(await directories.cache.exists(), isTrue);
      expect(await directories.history.exists(), isTrue);
      expect(await directories.thumbnails.exists(), isTrue);
      expect(await directories.exports.exists(), isTrue);
      expect(await directories.compression.exists(), isTrue);
      expect(await directories.backup.exists(), isTrue);

      final File historyFile = File(
        '${directories.history.path}/compression_history.json',
      )..writeAsStringSync('[]');
      final Result<void> deleteResult = await service.safeDelete(historyFile);
      expect(deleteResult.isSuccess, isTrue);
      expect(await historyFile.exists(), isFalse);
    },
  );

  test('reads and writes succeed when the support root is reached through a '
      'symlink (Android /data/user/0 regression)', () async {
    final Directory realRoot = await Directory.systemTemp.createTemp(
      'comprezza_fs_symlink_real_',
    );
    addTearDown(() async {
      if (await realRoot.exists()) await realRoot.delete(recursive: true);
    });
    final String linkPath =
        '${realRoot.parent.path}/comprezza_fs_link_'
        '${DateTime.now().microsecondsSinceEpoch}';
    final Link link = Link(linkPath);
    try {
      await link.create(realRoot.path);
    } on FileSystemException {
      markTestSkipped('Symlinks are not supported on this platform.');
      return;
    }
    addTearDown(() async {
      if (await link.exists()) await link.delete();
    });

    final LocalFileSystemService service = LocalFileSystemService(
      // The app-facing root is the symlink; the OS resolves it to realRoot.
      pathProvider: _FakePathProvider(link),
    );
    final Result<AppDirectories> directoriesResult = await service
        .directories();
    expect(directoriesResult, isA<Success<AppDirectories>>());
    final AppDirectories directories =
        (directoriesResult as Success<AppDirectories>).value;
    final File file = File('${directories.backup.path}/settings.json');

    expect(
      (await service.writeTextAtomic(file, '{"saved":true}')).isSuccess,
      isTrue,
      reason: 'Settings must persist when the support dir is a symlink.',
    );
    expect(await file.readAsString(), '{"saved":true}');
    expect((await service.readText(file)).isSuccess, isTrue);
  });

  test('atomic text writes replace an existing app-owned file', () async {
    final Directory root = await Directory.systemTemp.createTemp(
      'comprezza_fs_atomic_write_test_',
    );
    addTearDown(() async {
      if (await root.exists()) await root.delete(recursive: true);
    });

    final LocalFileSystemService service = LocalFileSystemService(
      pathProvider: _FakePathProvider(root),
    );
    final Result<AppDirectories> directoriesResult = await service
        .directories();
    final AppDirectories directories =
        (directoriesResult as Success<AppDirectories>).value;
    final File file = File('${directories.backup.path}/settings.json');

    expect((await service.writeTextAtomic(file, 'first')).isSuccess, isTrue);
    expect((await service.writeTextAtomic(file, 'second')).isSuccess, isTrue);
    expect(await file.readAsString(), 'second');
    expect(
      (await directories.backup.list().toList()).whereType<File>(),
      hasLength(1),
    );
  });
}

final class _FakePathProvider implements AppPathProvider {
  const _FakePathProvider(this.root);

  final FileSystemEntity root;

  @override
  Future<Directory> temporaryDirectory() async =>
      Directory('${root.path}/temporary');

  @override
  Future<Directory> applicationSupportDirectory() async =>
      Directory('${root.path}/support');
}
