import 'dart:async';

import 'package:comprezza/core/models/result.dart';
import 'package:comprezza/features/compressor/data/services/file_management/interfaces/file_management_interfaces.dart';
import 'package:comprezza/features/compressor/data/services/file_management/models/file_management_models.dart';
import 'package:comprezza/features/compressor/presentation/batch_compression_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  BatchImageItem image(String id, {int bytes = 1000}) => BatchImageItem(
    id: id,
    path: '/photos/$id.jpg',
    name: '$id.jpg',
    bytes: bytes,
    width: 1200,
    height: 800,
    format: 'JPEG',
  );

  BatchCompressionController controller({
    BatchImagePicker? picker,
    BatchImageProcessor? processor,
    HistoryStorage? history,
  }) {
    return BatchCompressionController(
      picker: picker ?? () async => <BatchImageItem>[],
      processor:
          processor ??
          (BatchImageItem item, BatchCompressionSettings settings) async =>
              BatchImageResult(
                outputPath: '${item.path}.compressed',
                outputBytes: 400,
              ),
      history: history,
    );
  }

  test('deduplicates paths and tracks selection independently', () {
    final BatchCompressionController featureController = controller();
    addTearDown(featureController.dispose);

    featureController.addImages(<BatchImageItem>[
      image('one'),
      image('one'),
      image('two'),
    ]);

    expect(featureController.items, hasLength(2));
    expect(featureController.selectedCount, 2);
    featureController.toggleSelection('one');
    expect(featureController.selectedCount, 1);
    featureController.selectAll();
    expect(featureController.selectedCount, 2);
    featureController.deselectAll();
    expect(featureController.selectedCount, 0);
  });

  test('normalizes duplicate IDs without coupling selection state', () {
    final BatchCompressionController featureController = controller();
    addTearDown(featureController.dispose);
    featureController.addImages(<BatchImageItem>[
      image('same'),
      const BatchImageItem(
        id: 'same',
        path: '/photos/other.jpg',
        name: 'other.jpg',
        bytes: 1000,
        width: 1200,
        height: 800,
        format: 'JPEG',
      ),
    ]);

    expect(
      featureController.items.map((BatchImageItem item) => item.id).toSet(),
      hasLength(2),
    );
    featureController.toggleSelection('same');
    expect(featureController.selectedCount, 1);
  });

  test('analysis exposes recommendations and can be cancelled', () async {
    final BatchCompressionController featureController = controller();
    addTearDown(featureController.dispose);
    featureController.addImages(<BatchImageItem>[
      image('large', bytes: 10 * 1024 * 1024),
    ]);

    final Future<bool> analysis = featureController.analyze();
    featureController.cancelAnalysis();

    expect(await analysis, isFalse);
    expect(featureController.phase, BatchWorkflowPhase.preview);
  });

  test(
    'continues after an individual failure and retries only failed work',
    () async {
      final attempts = <String, int>{};
      final BatchCompressionController featureController = controller(
        processor:
            (BatchImageItem item, BatchCompressionSettings settings) async {
              attempts[item.id] = (attempts[item.id] ?? 0) + 1;
              if (item.id == 'bad' && attempts[item.id] == 1) {
                throw StateError('codec failure');
              }
              return BatchImageResult(
                outputPath: '${item.path}.compressed',
                outputBytes: 400,
              );
            },
      );
      addTearDown(featureController.dispose);
      featureController.addImages(<BatchImageItem>[
        image('bad'),
        image('good'),
      ]);

      await featureController.startProcessing();

      expect(featureController.phase, BatchWorkflowPhase.completed);
      expect(featureController.failedCount, 1);
      expect(featureController.completedCount, 1);
      expect(attempts['good'], 1);

      await featureController.retryFailed();

      expect(featureController.failedCount, 0);
      expect(featureController.completedCount, 2);
      expect(attempts['bad'], 2);
      expect(attempts['good'], 1);
    },
  );

  test('skips deselected entries and produces a truthful summary', () async {
    final BatchCompressionController featureController = controller();
    addTearDown(featureController.dispose);
    featureController.addImages(<BatchImageItem>[
      image('kept'),
      image('skipped'),
    ]);
    featureController.toggleSelection('skipped');

    await featureController.startProcessing();

    expect(featureController.summary.processed, 1);
    expect(featureController.summary.skipped, 1);
    expect(featureController.summary.originalBytes, 1000);
    expect(featureController.summary.compressedBytes, 400);
  });

  test(
    'cancel completes the queue without processing remaining entries',
    () async {
      final Completer<void> started = Completer<void>();
      final Completer<void> release = Completer<void>();
      var processed = 0;
      final BatchCompressionController featureController = controller(
        processor:
            (BatchImageItem item, BatchCompressionSettings settings) async {
              processed++;
              started.complete();
              await release.future;
              return const BatchImageResult(
                outputPath: '/output.jpg',
                outputBytes: 400,
              );
            },
      );
      addTearDown(featureController.dispose);
      featureController.addImages(<BatchImageItem>[image('one'), image('two')]);
      final Future<void> processing = featureController.startProcessing();
      await started.future;
      featureController.cancel();
      release.complete();
      await processing;

      expect(processed, 1);
      expect(featureController.items.last.status, BatchQueueStatus.cancelled);
      expect(featureController.overallProgress, 1);
    },
  );

  test('retains metadata-only state for a 500-image simulation', () {
    final BatchCompressionController featureController = controller();
    addTearDown(featureController.dispose);
    featureController.addImages(
      List<BatchImageItem>.generate(500, (int index) => image('image-$index')),
    );

    expect(featureController.items, hasLength(500));
    expect(featureController.totalBytes, 500000);
    expect(
      featureController.items.every(
        (BatchImageItem item) => item.outputPath == null,
      ),
      isTrue,
    );
  });

  test('coalesces burst queue notifications to protect frame time', () async {
    final Completer<void> started = Completer<void>();
    final Completer<void> release = Completer<void>();
    final BatchCompressionController featureController = controller(
      processor:
          (BatchImageItem item, BatchCompressionSettings settings) async {
            started.complete();
            await release.future;
            return const BatchImageResult(
              outputPath: '/output.jpg',
              outputBytes: 400,
            );
          },
    );
    addTearDown(featureController.dispose);
    int notifications = 0;
    featureController.addListener(() => notifications++);
    featureController.addImages(<BatchImageItem>[image('one')]);
    final Future<void> processing = featureController.startProcessing();
    await started.future;

    featureController.setItemProgress('one', .1);
    featureController.setItemProgress('one', .2);
    featureController.setItemProgress('one', .3);
    await Future<void>.delayed(const Duration(milliseconds: 24));
    release.complete();
    await processing;

    expect(notifications, lessThan(12));
    expect(featureController.items.single.progress, 1);
  });

  test('start over releases the presentation queue state', () async {
    final BatchCompressionController featureController = controller();
    addTearDown(featureController.dispose);
    featureController.addImages(<BatchImageItem>[image('one')]);
    await featureController.startProcessing();

    featureController.startOver();

    expect(featureController.items, isEmpty);
    expect(featureController.phase, BatchWorkflowPhase.selection);
    expect(featureController.summary.total, 0);
  });

  test(
    'regression: full workflow completes within a real-time bound',
    () async {
      // The controller's analysis loop yields via a zero-duration timer.
      // Running in a plain test() (real async) with a real-time timeout
      // guarantees that a future edit introducing a never-completing future
      // or timer fails fast instead of hanging the suite.
      final BatchCompressionController featureController = controller();
      addTearDown(featureController.dispose);
      featureController.addImages(<BatchImageItem>[
        image('one'),
        image('two'),
        image('three'),
      ]);

      await featureController.startProcessing().timeout(
        const Duration(seconds: 5),
      );

      expect(featureController.phase, BatchWorkflowPhase.completed);
      expect(featureController.completedCount, 3);
    },
  );

  test(
    'settings and per-image quality override update estimates and processing input',
    () async {
      final BatchCompressionController featureController = controller();
      addTearDown(featureController.dispose);
      featureController.addImages(<BatchImageItem>[image('one')]);
      final int initial = featureController.estimatedBytes;

      featureController.updateSettings(
        featureController.settings.copyWith(quality: 20),
      );
      final int globalEstimate = featureController.estimatedBytes;
      featureController.setItemQualityOverride('one', 90);

      expect(globalEstimate, lessThan(initial));
      expect(featureController.items.single.effectiveQuality, 90);
      expect(featureController.estimatedBytes, greaterThan(globalEstimate));

      int? receivedQuality;
      final BatchCompressionController processingController = controller(
        processor:
            (BatchImageItem item, BatchCompressionSettings settings) async {
              receivedQuality = settings.quality;
              return const BatchImageResult(
                outputPath: '/output.jpg',
                outputBytes: 400,
              );
            },
      );
      addTearDown(processingController.dispose);
      processingController.addImages(<BatchImageItem>[image('override')]);
      processingController.setItemQualityOverride('override', 91);
      await processingController.startProcessing();
      expect(receivedQuality, 91);
    },
  );

  group('history recording', () {
    test('records one aggregated session for a completed batch', () async {
      final _RecordingHistory history = _RecordingHistory();
      final BatchCompressionController featureController = controller(
        history: history,
      );
      addTearDown(featureController.dispose);
      featureController.addImages(<BatchImageItem>[image('one'), image('two')]);

      await featureController.startProcessing();
      await pumpEventQueue();

      expect(history.saved, hasLength(1));
      final CompressionHistoryRecord record = history.saved.single;
      expect(record.processedFiles, 2);
      expect(record.originalPath, '/photos/one.jpg');
      expect(record.savedBytes, 1200);
      expect(record.compressionRatio, closeTo(2000 / 800, .001));
      expect(record.preset, 'Batch · Quality 72');
      expect(record.checksum, isNotEmpty);
    });

    test('records nothing when every item failed', () async {
      final _RecordingHistory history = _RecordingHistory();
      final BatchCompressionController featureController = controller(
        history: history,
        processor:
            (BatchImageItem item, BatchCompressionSettings settings) async =>
                throw StateError('codec failure'),
      );
      addTearDown(featureController.dispose);
      featureController.addImages(<BatchImageItem>[image('one'), image('two')]);

      await featureController.startProcessing();
      await pumpEventQueue();

      expect(featureController.completedCount, 0);
      expect(history.saved, isEmpty);
    });

    test(
      'retrying failed items replaces the session record in place',
      () async {
        final _RecordingHistory history = _RecordingHistory();
        final attempts = <String, int>{};
        final BatchCompressionController featureController = controller(
          history: history,
          processor:
              (BatchImageItem item, BatchCompressionSettings settings) async {
                attempts[item.id] = (attempts[item.id] ?? 0) + 1;
                if (item.id == 'bad' && attempts[item.id] == 1) {
                  throw StateError('codec failure');
                }
                return BatchImageResult(
                  outputPath: '${item.path}.compressed',
                  outputBytes: 400,
                );
              },
        );
        addTearDown(featureController.dispose);
        featureController.addImages(<BatchImageItem>[
          image('bad'),
          image('good'),
        ]);

        await featureController.startProcessing();
        await featureController.retryFailed();
        await pumpEventQueue();

        expect(history.saved, hasLength(1));
        expect(history.saved.single.processedFiles, 2);
        expect(history.saved.single.savedBytes, 1200);
      },
    );
  });

  group('batch export seams', () {
    test('saveAll routes only completed outputs to the gallery seam', () async {
      final List<String> saved = <String>[];
      final BatchCompressionController featureController =
          BatchCompressionController(
            picker: () async => const <BatchImageItem>[],
            processor:
                (
                  BatchImageItem item,
                  BatchCompressionSettings settings,
                ) async => BatchImageResult(
                  outputPath: '${item.path}.compressed',
                  outputBytes: 400,
                ),
            saveAllHandler: (List<String> paths) async => saved.addAll(paths),
          );
      addTearDown(featureController.dispose);

      // Nothing completed yet: the operation is a no-op.
      featureController.addImages(<BatchImageItem>[image('one')]);
      expect(await featureController.saveAll(), 0);
      expect(saved, isEmpty);

      await featureController.startProcessing();
      expect(featureController.completedCount, 1);
      expect(await featureController.saveAll(), 1);
      expect(saved, equals(<String>['/photos/one.jpg.compressed']));
    });

    test(
      'shareSelected honors selection and falls back to all completed',
      () async {
        final List<String> shared = <String>[];
        final BatchCompressionController featureController =
            BatchCompressionController(
              picker: () async => const <BatchImageItem>[],
              processor:
                  (
                    BatchImageItem item,
                    BatchCompressionSettings settings,
                  ) async => BatchImageResult(
                    outputPath: '${item.path}.compressed',
                    outputBytes: 400,
                  ),
              shareHandler: (List<String> paths) async => shared.addAll(paths),
            );
        addTearDown(featureController.dispose);
        featureController.addImages(<BatchImageItem>[
          image('one'),
          image('two'),
        ]);
        await featureController.startProcessing();

        // Deselecting one completed item restricts the share to the other.
        featureController.toggleSelection('two');
        expect(await featureController.shareSelected(), 1);
        expect(shared, equals(<String>['/photos/one.jpg.compressed']));

        // An empty selection falls back to every completed output.
        shared.clear();
        featureController.deselectAll();
        expect(await featureController.shareSelected(), 2);
        expect(shared, hasLength(2));
      },
    );

    test(
      'prepareZip delegates to the builder and reports the archive',
      () async {
        BatchZipResult? built;
        final BatchCompressionController featureController =
            BatchCompressionController(
              picker: () async => const <BatchImageItem>[],
              processor:
                  (
                    BatchImageItem item,
                    BatchCompressionSettings settings,
                  ) async => BatchImageResult(
                    outputPath: '${item.path}.compressed',
                    outputBytes: 400,
                  ),
              zipBuilder: (List<String> paths) async {
                built = BatchZipResult(
                  path: '/tmp/batch.zip',
                  name: 'batch.zip',
                  bytes: 1024,
                  fileCount: paths.length,
                );
                return built!;
              },
            );
        addTearDown(featureController.dispose);
        featureController.addImages(<BatchImageItem>[image('one')]);

        // No completed outputs yet: building is rejected.
        expect(featureController.prepareZip(), throwsA(isA<StateError>()));

        await featureController.startProcessing();
        final BatchZipResult result = await featureController.prepareZip();
        expect(result.fileCount, 1);
        expect(result.name, 'batch.zip');
        expect(built, isNotNull);
      },
    );

    test('saveZip and shareZip route through their seams', () async {
      final List<String> savedZips = <String>[];
      final List<String> sharedZips = <String>[];
      final BatchCompressionController featureController =
          BatchCompressionController(
            picker: () async => const <BatchImageItem>[],
            processor:
                (
                  BatchImageItem item,
                  BatchCompressionSettings settings,
                ) async => BatchImageResult(
                  outputPath: '${item.path}.compressed',
                  outputBytes: 400,
                ),
            zipSaver: (String path) async => savedZips.add(path),
            shareHandler: (List<String> paths) async =>
                sharedZips.addAll(paths),
          );
      addTearDown(featureController.dispose);

      await featureController.saveZip('/tmp/a.zip');
      expect(savedZips, equals(<String>['/tmp/a.zip']));
      await featureController.shareZip('/tmp/a.zip');
      expect(sharedZips, equals(<String>['/tmp/a.zip']));
    });

    test('isExporting is surfaced while a seam is in flight', () async {
      final Completer<void> gate = Completer<void>();
      final BatchCompressionController featureController =
          BatchCompressionController(
            picker: () async => const <BatchImageItem>[],
            processor:
                (
                  BatchImageItem item,
                  BatchCompressionSettings settings,
                ) async => BatchImageResult(
                  outputPath: '${item.path}.compressed',
                  outputBytes: 400,
                ),
            zipSaver: (String path) => gate.future,
          );
      addTearDown(featureController.dispose);

      final Future<void> pending = featureController.saveZip('/tmp/a.zip');
      expect(featureController.isExporting, isTrue);
      gate.complete();
      await pending;
      expect(featureController.isExporting, isFalse);
    });
  });
}

final class _RecordingHistory implements HistoryStorage {
  final List<CompressionHistoryRecord> saved = <CompressionHistoryRecord>[];

  @override
  Future<Result<void>> save(CompressionHistoryRecord record) async {
    // Mirror JsonHistoryStorage: a record id is the session identity and
    // saving replaces any previous record with the same id.
    saved.removeWhere((CompressionHistoryRecord item) => item.id == record.id);
    saved.add(record);
    return const Result<void>.success(null);
  }

  @override
  Future<Result<List<CompressionHistoryRecord>>> readAll() async =>
      const Result<List<CompressionHistoryRecord>>.success(
        <CompressionHistoryRecord>[],
      );

  @override
  Future<Result<void>> delete(String id) async =>
      const Result<void>.success(null);
}
