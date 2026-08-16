import 'dart:io';

import 'package:comprezza/core/models/result.dart';
import 'package:comprezza/core/services/file_system_service.dart';
import 'package:comprezza/core/services/path_provider_service.dart';
import 'package:comprezza/features/compressor/data/services/settings/local_settings_store.dart';
import 'package:comprezza/features/compressor/domain/settings/settings_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'replaces an existing settings snapshot and preserves the latest values',
    () async {
      final Directory root = await Directory.systemTemp.createTemp(
        'comprezza_settings_save_test_',
      );
      addTearDown(() async {
        if (await root.exists()) await root.delete(recursive: true);
      });

      final LocalFileSystemService fileSystem = LocalFileSystemService(
        pathProvider: _FakePathProvider(root),
      );
      final LocalSettingsStore store = LocalSettingsStore(
        fileSystem: fileSystem,
      );

      await store.save(const SettingsPreferences(compressionQuality: 55));
      await store.save(const SettingsPreferences(compressionQuality: 91));

      expect((await store.load()).compressionQuality, 91);
    },
  );

  test('recovers a backup after an interrupted settings replacement', () async {
    final Directory root = await Directory.systemTemp.createTemp(
      'comprezza_settings_recovery_test_',
    );
    addTearDown(() async {
      if (await root.exists()) await root.delete(recursive: true);
    });

    final LocalFileSystemService fileSystem = LocalFileSystemService(
      pathProvider: _FakePathProvider(root),
    );
    final LocalSettingsStore store = LocalSettingsStore(fileSystem: fileSystem);
    final Result<AppDirectories> directoryResult = await fileSystem
        .directories();
    final AppDirectories directories =
        (directoryResult as Success<AppDirectories>).value;
    final File backup = File('${directories.backup.path}/settings.json.backup')
      ..writeAsStringSync(
        SettingsJsonCodec.encode(
          const SettingsPreferences(compressionQuality: 83),
        ),
      );

    expect(await store.load().then((value) => value.compressionQuality), 83);
    expect(
      await File('${directories.backup.path}/settings.json').exists(),
      isTrue,
    );
    expect(await backup.exists(), isFalse);
  });

  test(
    'clear cache preserves exports and temporary compression files',
    () async {
      final Directory root = await Directory.systemTemp.createTemp(
        'comprezza_settings_store_test_',
      );
      addTearDown(() async {
        if (await root.exists()) await root.delete(recursive: true);
      });

      final LocalFileSystemService fileSystem = LocalFileSystemService(
        pathProvider: _FakePathProvider(root),
      );
      final LocalSettingsStore store = LocalSettingsStore(
        fileSystem: fileSystem,
      );
      final Result<AppDirectories> directoryResult = await fileSystem
          .directories();
      expect(directoryResult, isA<Success<AppDirectories>>());
      final AppDirectories directories =
          (directoryResult as Success<AppDirectories>).value;

      final File cacheFile = File('${directories.cache.path}/cache.bin')
        ..writeAsStringSync('cache');
      final File thumbnailFile = File(
        '${directories.thumbnails.path}/thumbnail.bin',
      )..writeAsStringSync('thumbnail');
      final File exportFile = File('${directories.exports.path}/export.jpg')
        ..writeAsStringSync('export');
      final File temporaryFile = File(
        '${directories.compression.path}/temporary.part',
      )..writeAsStringSync('temporary');
      final File historyFile = File(
        '${directories.history.path}/compression_history.json',
      )..writeAsStringSync('history');

      await store.clearCache();

      expect(await cacheFile.exists(), isFalse);
      expect(await thumbnailFile.exists(), isFalse);
      expect(await exportFile.exists(), isTrue);
      expect(await temporaryFile.exists(), isTrue);
      expect(await historyFile.exists(), isTrue);

      await store.clearHistory();

      expect(await historyFile.exists(), isFalse);
      expect(await exportFile.exists(), isTrue);
      expect(await temporaryFile.exists(), isTrue);

      final File resetCacheFile = File('${directories.cache.path}/reset.bin')
        ..writeAsStringSync('cache');
      final File resetThumbnailFile = File(
        '${directories.thumbnails.path}/reset.bin',
      )..writeAsStringSync('thumbnail');
      final File resetHistoryFile = File(
        '${directories.history.path}/compression_history.json',
      )..writeAsStringSync('history');

      await store.clearCache();
      await store.clearHistory();

      expect(await resetCacheFile.exists(), isFalse);
      expect(await resetThumbnailFile.exists(), isFalse);
      expect(await resetHistoryFile.exists(), isFalse);
      expect(await exportFile.exists(), isTrue);
      expect(await temporaryFile.exists(), isTrue);
    },
  );
}

final class _FakePathProvider implements AppPathProvider {
  const _FakePathProvider(this.root);

  final Directory root;

  @override
  Future<Directory> temporaryDirectory() async =>
      Directory('${root.path}/temporary');

  @override
  Future<Directory> applicationSupportDirectory() async =>
      Directory('${root.path}/support');
}
