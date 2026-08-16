import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:comprezza/core/models/result.dart';
import 'package:comprezza/core/services/file_system_service.dart';
import 'package:comprezza/core/services/path_provider_service.dart';
import 'package:comprezza/features/compressor/data/services/file_management/history/history_storage.dart';
import 'package:comprezza/features/compressor/data/services/file_management/interfaces/file_management_interfaces.dart';
import 'package:comprezza/features/compressor/data/services/file_management/models/file_management_models.dart';
import 'package:comprezza/features/compressor/data/services/file_management/storage/storage_manager.dart';
import 'package:comprezza/features/compressor/presentation/history/history_entry_mapper.dart';
import 'package:comprezza/features/compressor/presentation/history_insights_controller.dart';
import 'package:flutter_test/flutter_test.dart';

/// Profiles the History first-load path so regressions in UI-isolate work are
/// visible. This is a diagnostic benchmark: it prints timings and asserts
/// correctness, without brittle wall-clock thresholds.
///
/// The measured synchronous block mirrors exactly what `HistoryScreen._load`
/// runs on the UI isolate once the storage read completes: JSON decode,
/// record parsing, newest-first sort, presentation mapping, and the insights
/// controller construction.
void main() {
  const int recordCount = 400;

  List<CompressionHistoryRecord> makeRecords(int count) =>
      List<CompressionHistoryRecord>.generate(
        count,
        (int index) => CompressionHistoryRecord(
          id: 'record-$index',
          originalPath: '/storage/emulated/0/Pictures/original_$index.jpg',
          compressedPath:
              '/data/user/0/app/comprezza/history/compressed_$index.webp',
          createdAt: DateTime(2026, 8).add(Duration(minutes: index)),
          preset: 'balanced',
          compressionRatio: 3.2,
          savedBytes: 2048000,
          checksum: 'sha256-$index',
          processedFiles: index.isEven ? 1 : 8,
        ),
      );

  Future<void> seedHistoryFile(
    LocalFileSystemService fileSystem,
    StorageManager storage,
    List<CompressionHistoryRecord> records,
  ) async {
    final Success<Directory> directory =
        await storage.directory(StorageLocation.history) as Success<Directory>;
    final File file = File('${directory.value.path}/compression_history.json');
    await file.writeAsString(
      jsonEncode(
        records.map((CompressionHistoryRecord r) => r.toJson()).toList(),
      ),
    );
  }

  test('history first-load UI-isolate cost profile', () async {
    final Directory root = await Directory.systemTemp.createTemp(
      'comprezza_history_bench_',
    );
    addTearDown(() async {
      if (await root.exists()) await root.delete(recursive: true);
    });

    // ---- Warm the filesystem (mimics the app after its first storage use). ----
    final LocalFileSystemService fileSystem = LocalFileSystemService(
      pathProvider: _FakePathProvider(root),
    );
    final LocalStorageManager storage = LocalStorageManager(
      fileSystem: fileSystem,
    );
    final JsonHistoryStorage history = JsonHistoryStorage(
      storage: storage,
      fileSystem: fileSystem,
    );
    final List<CompressionHistoryRecord> records = makeRecords(recordCount);
    await seedHistoryFile(fileSystem, storage, records);

    // ---- 1. Per-read directory resolution (runs on every readAll). ----
    final Stopwatch directoryWatch = Stopwatch()..start();
    for (int i = 0; i < 5; i++) {
      await storage.directory(StorageLocation.history);
    }
    directoryWatch.stop();
    // ignore: avoid_print
    print(
      'directory() resolution × 5: ${directoryWatch.elapsedMilliseconds}ms '
      '(${(directoryWatch.elapsedMilliseconds / 5).toStringAsFixed(1)}ms per read)',
    );

    // ---- 2. The synchronous UI-isolate block in the current load path. ----
    final String contents = await File(
      '${(await storage.directory(StorageLocation.history) as Success<Directory>).value.path}/'
      'compression_history.json',
    ).readAsString();
    final Stopwatch parseWatch = Stopwatch()..start();
    final Object? decoded = jsonDecode(contents);
    final List<CompressionHistoryRecord> parsed = <CompressionHistoryRecord>[];
    for (final Object? entry in decoded as List<Object?>) {
      parsed.add(
        CompressionHistoryRecord.fromJson(entry as Map<String, Object?>)!,
      );
    }
    parsed.sort(
      (CompressionHistoryRecord a, CompressionHistoryRecord b) =>
          b.createdAt.compareTo(a.createdAt),
    );
    parseWatch.stop();
    // ignore: avoid_print
    print(
      'reference: synchronous decode + parse + sort ($recordCount records) '
      'cost if run on the UI isolate (pre-fix behavior): '
      '${parseWatch.elapsedMicroseconds ~/ 1000}ms',
    );

    final Stopwatch transformWatch = Stopwatch()..start();
    final entries = parsed.map(historyEntryFromRecord).toList(growable: false);
    final HistoryInsightsController controller = HistoryInsightsController(
      entries: entries,
    );
    controller.dispose();
    transformWatch.stop();
    // ignore: avoid_print
    print(
      'reference: synchronous map + insights aggregation cost if run on the '
      'UI isolate (pre-fix behavior): ${transformWatch.elapsedMicroseconds ~/ 1000}ms',
    );

    // ---- 3. End-to-end readAll wall time. ----
    final Stopwatch readWatch = Stopwatch()..start();
    final result = await history.readAll();
    readWatch.stop();
    expect(result, isA<Success<List<CompressionHistoryRecord>>>());
    expect(
      (result as Success<List<CompressionHistoryRecord>>).value,
      hasLength(recordCount),
    );
    // ignore: avoid_print
    print('readAll() end-to-end: ${readWatch.elapsedMilliseconds}ms');

    // ---- 4. UI-thread responsiveness while the load runs (cold read). ----
    final LocalFileSystemService coldFileSystem = LocalFileSystemService(
      pathProvider: _FakePathProvider(root),
    );
    final LocalStorageManager coldStorage = LocalStorageManager(
      fileSystem: coldFileSystem,
    );
    final JsonHistoryStorage coldHistory = JsonHistoryStorage(
      storage: coldStorage,
      fileSystem: coldFileSystem,
    );
    await seedHistoryFile(coldFileSystem, coldStorage, records);
    int ticks = 0;
    final Timer timer = Timer.periodic(
      const Duration(milliseconds: 1),
      (_) => ticks++,
    );
    final Stopwatch responsiveWatch = Stopwatch()..start();
    await coldHistory.readAll();
    responsiveWatch.stop();
    timer.cancel();
    final int expectedTicks = responsiveWatch.elapsedMilliseconds;
    // ignore: avoid_print
    print(
      'cold readAll(): ${responsiveWatch.elapsedMilliseconds}ms, timer ticks '
      '$ticks / expected ~$expectedTicks (gap = timer stalls while the UI '
      'isolate is blocked)',
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
