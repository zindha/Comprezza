import 'dart:io';

import 'package:path/path.dart' as p;

import '../../../../../../core/services/file_system_service.dart';
import '../../../domain/settings/settings_models.dart';
import '../../../domain/settings/settings_store.dart';

/// App-private JSON persistence for the isolated Settings experience.
final class LocalSettingsStore implements SettingsStore {
  LocalSettingsStore({required this.fileSystem});

  final FileSystemService fileSystem;
  static const String _settingsFileName = 'settings.json';
  static const String _exportFileName = 'settings_export.json';

  @override
  Future<SettingsPreferences> load() async {
    final AppDirectories directories = await _directories();
    final File file = File(p.join(directories.backup.path, _settingsFileName));
    await _recoverInterruptedSave(file);
    if (!await file.exists()) return const SettingsPreferences();
    final result = await fileSystem.readText(file);
    return result.fold(
      onSuccess: (String contents) {
        try {
          return SettingsJsonCodec.decode(contents);
        } on FormatException {
          return const SettingsPreferences();
        }
      },
      onFailure: (_) => const SettingsPreferences(),
    );
  }

  @override
  Future<SettingsStorageUsage> loadStorageUsage() async {
    final AppDirectories directories = await _directories();
    Future<int> bytes(Directory directory, {bool recursive = true}) async {
      int total = 0;
      for (final File file in await fileSystem.listFiles(
        directory,
        recursive: recursive,
      )) {
        total += (await fileSystem.stat(file)).size;
      }
      return total;
    }

    return SettingsStorageUsage(
      cacheBytes:
          await bytes(directories.cache) + await bytes(directories.thumbnails),
      temporaryBytes: await bytes(directories.compression),
      // Thumbnails are reported as cache, not history, so the categories and
      // total remain mutually exclusive.
      historyBytes: await bytes(directories.history, recursive: false),
      exportsBytes: await bytes(directories.exports),
    );
  }

  @override
  Future<void> save(SettingsPreferences preferences) async {
    final AppDirectories directories = await _directories();
    final File file = File(p.join(directories.backup.path, _settingsFileName));
    final result = await fileSystem.writeTextAtomic(
      file,
      SettingsJsonCodec.encode(preferences),
    );
    if (result.isFailure) throw StateError('Settings could not be saved.');
  }

  @override
  Future<void> clearCache() async {
    final AppDirectories directories = await _directories();
    // Cache cleanup must not remove exports or temporary working files. Those
    // categories have separate retention semantics and are shown separately in
    // the Settings storage overview.
    await _deleteFiles(directories.cache);
    await _deleteFiles(directories.thumbnails);
  }

  @override
  Future<void> clearHistory() async {
    final AppDirectories directories = await _directories();
    final File history = File(
      p.join(directories.history.path, 'compression_history.json'),
    );
    final result = await fileSystem.safeDelete(history);
    if (result.isFailure && await history.exists()) {
      throw StateError('History could not be cleared.');
    }
  }

  @override
  Future<String> export(SettingsExportBundle bundle) async {
    final AppDirectories directories = await _directories();
    final File file = File(p.join(directories.backup.path, _exportFileName));
    final String encoded = bundle.encode();
    final result = await fileSystem.writeTextAtomic(file, encoded);
    if (result.isFailure) {
      throw StateError('Settings export could not be written.');
    }
    return encoded;
  }

  @override
  Future<void> importSettings(String encoded) async {
    final SettingsPreferences preferences = SettingsJsonCodec.decode(encoded);
    await save(preferences);
  }

  Future<AppDirectories> _directories() async {
    final result = await fileSystem.directories();
    return result.fold(
      onSuccess: (AppDirectories value) => value,
      onFailure: (error) => throw StateError(error.message),
    );
  }

  Future<void> _recoverInterruptedSave(File file) async {
    final File backup = File('${file.path}.backup');
    if (await file.exists() || !await backup.exists()) return;
    try {
      await backup.rename(file.path);
    } on FileSystemException {
      // Loading will fall back to defaults if the backup is also unavailable.
    }
  }

  Future<void> _deleteFiles(Directory directory) async {
    for (final File file in await fileSystem.listFiles(directory)) {
      final result = await fileSystem.safeDelete(file);
      if (result.isFailure) {
        throw StateError('Generated storage could not be cleared.');
      }
    }
  }
}
