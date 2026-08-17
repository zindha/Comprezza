import 'package:comprezza/core/models/result.dart';
import 'package:comprezza/features/compressor/data/services/file_management/interfaces/file_management_interfaces.dart';
import 'package:comprezza/features/compressor/data/services/file_management/models/file_management_models.dart';
import 'package:comprezza/features/compressor/domain/compression_models.dart';
import 'package:comprezza/features/compressor/domain/gateways/compressor_gateways.dart';
import 'package:comprezza/features/compressor/presentation/compressor_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CompressorController history recording', () {
    test('records the session metrics after a successful save', () async {
      final _RecordingHistory history = _RecordingHistory();
      final CompressorController controller = CompressorController(
        pickerGateway: _FakePicker(),
        compressionGateway: _FakeCompression(),
        exportGateway: _FakeExport(),
        history: history,
      );
      addTearDown(controller.dispose);
      controller
        ..original = const PhotoAsset(
          filePath: '/original/photo.jpg',
          bytes: 2000000,
          width: 2400,
          height: 1600,
        )
        ..compressed = const CompressedAsset(
          filePath: '/output/photo.jpg',
          bytes: 500000,
          width: 2400,
          height: 1600,
          quality: 72,
          format: CompressorFormat.jpeg,
        )
        ..status = CompressorStatus.ready;

      final bool saved = await controller.saveToDevice();
      await _waitForSaved(history, 1);

      expect(saved, isTrue);
      expect(history.saved, hasLength(1));
      final CompressionHistoryRecord record = history.saved.single;
      expect(record.originalPath, '/original/photo.jpg');
      expect(record.compressedPath, '/output/photo.jpg');
      expect(record.compressionRatio, closeTo(4, .0001));
      expect(record.savedBytes, 1500000);
      expect(record.preset, 'Quality 72');
      expect(record.checksum, isNotEmpty);
    });

    test('records a session after a successful share', () async {
      final _RecordingHistory history = _RecordingHistory();
      final CompressorController controller = CompressorController(
        pickerGateway: _FakePicker(),
        compressionGateway: _FakeCompression(),
        exportGateway: _FakeExport(),
        history: history,
      );
      addTearDown(controller.dispose);
      controller
        ..original = const PhotoAsset(
          filePath: '/original/photo.jpg',
          bytes: 1000,
          width: 100,
          height: 100,
        )
        ..compressed = const CompressedAsset(
          filePath: '/output/photo.webp',
          bytes: 250,
          width: 100,
          height: 100,
          quality: 80,
          format: CompressorFormat.webp,
        )
        ..status = CompressorStatus.ready;

      final bool shared = await controller.shareImage();
      await _waitForSaved(history, 1);

      expect(shared, isTrue);
      expect(history.saved, hasLength(1));
      expect(history.saved.single.compressionRatio, closeTo(4, .0001));
      expect(history.saved.single.savedBytes, 750);
    });

    test('does not record when the export fails', () async {
      final _RecordingHistory history = _RecordingHistory();
      final CompressorController controller = CompressorController(
        pickerGateway: _FakePicker(),
        compressionGateway: _FakeCompression(),
        exportGateway: _ThrowingExport(),
        history: history,
      );
      addTearDown(controller.dispose);
      controller
        ..original = const PhotoAsset(
          filePath: '/original/photo.jpg',
          bytes: 1000,
          width: 100,
          height: 100,
        )
        ..compressed = const CompressedAsset(
          filePath: '/output/photo.jpg',
          bytes: 250,
          width: 100,
          height: 100,
          quality: 80,
          format: CompressorFormat.jpeg,
        )
        ..status = CompressorStatus.ready;

      final bool saved = await controller.saveToDevice();
      await pumpEventQueue();

      expect(saved, isFalse);
      expect(history.saved, isEmpty);
      expect(controller.exportFailed, isTrue);
    });

    test(
      'recompressing the same source with the same settings replaces the record',
      () async {
        final _RecordingHistory history = _RecordingHistory();
        final CompressorController controller = CompressorController(
          pickerGateway: _FakePicker(),
          compressionGateway: _FakeCompression(),
          exportGateway: _FakeExport(),
          history: history,
        );
        addTearDown(controller.dispose);
        controller
          ..original = const PhotoAsset(
            filePath: '/original/photo.jpg',
            bytes: 2000000,
            width: 2400,
            height: 1600,
          )
          ..compressed = const CompressedAsset(
            filePath: '/output/photo.jpg',
            bytes: 500000,
            width: 2400,
            height: 1600,
            quality: 72,
            format: CompressorFormat.jpeg,
          )
          ..status = CompressorStatus.ready;

        // The record identity is a content hash of the source plus settings:
        // a second export of the same source+settings updates the existing
        // record instead of inserting a duplicate.
        await controller.saveToDevice();
        await _waitForSaved(history, 1);
        await controller.saveToDevice();
        await _waitForSaved(history, 1);

        expect(history.saved, hasLength(1));
        expect(history.saved.single.savedBytes, 1500000);
      },
    );

    test(
      'different settings on the same source produce distinct records',
      () async {
        final _RecordingHistory history = _RecordingHistory();
        final CompressorController controller = CompressorController(
          pickerGateway: _FakePicker(),
          compressionGateway: _FakeCompression(),
          exportGateway: _FakeExport(),
          history: history,
        );
        addTearDown(controller.dispose);
        controller
          ..original = const PhotoAsset(
            filePath: '/original/photo.jpg',
            bytes: 2000000,
            width: 2400,
            height: 1600,
          )
          ..compressed = const CompressedAsset(
            filePath: '/output/photo.jpg',
            bytes: 500000,
            width: 2400,
            height: 1600,
            quality: 72,
            format: CompressorFormat.jpeg,
          )
          ..status = CompressorStatus.ready;

        await controller.saveToDevice();
        await _waitForSaved(history, 1);
        final String firstId = history.saved.single.id;

        // A different quality yields a different record id, so both entries
        // coexist in history.
        controller.quality = 88;
        controller.compressed = const CompressedAsset(
          filePath: '/output/photo.jpg',
          bytes: 400000,
          width: 2400,
          height: 1600,
          quality: 88,
          format: CompressorFormat.jpeg,
        );
        await controller.saveToDevice();
        await _waitForSaved(history, 2);

        expect(history.saved, hasLength(2));
        expect(history.saved[1].id, isNot(firstId));
      },
    );

    test('uses a target-size preset label when targetBytes is set', () async {
      final _RecordingHistory history = _RecordingHistory();
      final CompressorController controller = CompressorController(
        pickerGateway: _FakePicker(),
        compressionGateway: _FakeCompression(),
        exportGateway: _FakeExport(),
        history: history,
      );
      addTearDown(controller.dispose);
      controller
        ..targetBytes = 500 * 1024
        ..original = const PhotoAsset(
          filePath: '/original/photo.jpg',
          bytes: 1000,
          width: 100,
          height: 100,
        )
        ..compressed = const CompressedAsset(
          filePath: '/output/photo.jpg',
          bytes: 250,
          width: 100,
          height: 100,
          quality: 80,
          format: CompressorFormat.jpeg,
        )
        ..status = CompressorStatus.ready;

      final bool saved = await controller.saveToDevice();
      await _waitForSaved(history, 1);

      expect(saved, isTrue);
      expect(history.saved.single.preset, startsWith('Target '));
    });
  });
}

/// Waits until [history] contains at least [count] records.
///
/// Recording is unawaited by design and hashes the source on a spawned
/// isolate, so a fixed pump count is not enough to guarantee the write landed
/// under load. Poll with a deadline instead.
Future<void> _waitForSaved(_RecordingHistory history, int count) async {
  final DateTime deadline = DateTime.now().add(const Duration(seconds: 5));
  while (history.saved.length < count && DateTime.now().isBefore(deadline)) {
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}

final class _RecordingHistory implements HistoryStorage {
  final List<CompressionHistoryRecord> saved = <CompressionHistoryRecord>[];

  @override
  Future<Result<void>> save(CompressionHistoryRecord record) async {
    // Mirror JsonHistoryStorage: the record id is the identity and saving
    // replaces any previous record with the same id.
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

final class _FakePicker implements ImagePickerGateway {
  @override
  Future<String?> pickImagePath() async => null;

  @override
  Future<String?> pickCameraImagePath() async => null;

  @override
  Future<String?> recoverLostImagePath() async => null;
}

final class _FakeCompression implements ImageCompressionGateway {
  @override
  Future<CompressedAsset> compress(
    PhotoAsset source, {
    int quality = 72,
    CompressorFormat format = CompressorFormat.jpeg,
    double scale = 1,
    int? targetBytes,
    bool keepExif = false,
  }) async => CompressedAsset(
    filePath: '/missing/output.jpg',
    bytes: 400,
    width: source.width,
    height: source.height,
    quality: quality,
    format: CompressorFormat.jpeg,
  );

  @override
  Future<void> deleteTemporaryOutput(String filePath) async {}

  @override
  Future<PhotoAsset> inspect(String sourcePath) async => const PhotoAsset(
    filePath: '/missing/original.jpg',
    bytes: 1000,
    width: 100,
    height: 100,
  );
}

final class _FakeExport implements ImageExportGateway {
  @override
  Future<void> saveToDevice(String filePath) async {}

  @override
  Future<void> share(String filePath) async {}
}

final class _ThrowingExport implements ImageExportGateway {
  @override
  Future<void> saveToDevice(String filePath) async =>
      throw StateError('export failed');

  @override
  Future<void> share(String filePath) async =>
      throw StateError('export failed');
}
