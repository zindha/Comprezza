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
      await pumpEventQueue();

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
      await pumpEventQueue();

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
      await pumpEventQueue();

      expect(saved, isTrue);
      expect(history.saved.single.preset, startsWith('Target '));
    });
  });
}

final class _RecordingHistory implements HistoryStorage {
  final List<CompressionHistoryRecord> saved = <CompressionHistoryRecord>[];

  @override
  Future<Result<void>> save(CompressionHistoryRecord record) async {
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
