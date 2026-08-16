import 'dart:io';

import 'package:comprezza/app/di/batch_compression_adapter.dart';
import 'package:comprezza/core/models/result.dart';
import 'package:comprezza/features/compressor/data/services/file_management/interfaces/file_management_interfaces.dart';
import 'package:comprezza/features/compressor/data/services/file_management/models/file_management_models.dart';
import 'package:comprezza/features/compressor/domain/compression_models.dart';
import 'package:comprezza/features/compressor/domain/gateways/compressor_gateways.dart';
import 'package:comprezza/features/compressor/domain/share_export/share_export_interfaces.dart';
import 'package:comprezza/features/compressor/domain/share_export/share_export_models.dart';
import 'package:comprezza/features/compressor/presentation/batch_compression_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'batch adapter picker converts picked files into inspected items',
    () async {
      final _FakePickerService picker = _FakePickerService(<SelectedFile>[
        const SelectedFile(path: '/tmp/a.jpg', name: 'a.jpg'),
        const SelectedFile(path: '/tmp/b.png', name: 'b.png'),
      ]);
      final BatchCompressionAdapter adapter = BatchCompressionAdapter(
        picker: picker,
        compression: _FakeCompression(),
      );
      addTearDown(adapter.dispose);

      await adapter.controller.selectImages();

      expect(adapter.controller.items, hasLength(2));
      expect(adapter.controller.items[0].name, 'a.jpg');
      expect(adapter.controller.items[0].bytes, 8000);
      expect(adapter.controller.items[0].width, 1200);
      expect(adapter.controller.items[0].height, 900);
      expect(adapter.controller.items[0].format, 'jpg');
      expect(adapter.controller.items[1].name, 'b.png');
      expect(adapter.controller.items[1].format, 'png');
    },
  );

  test('batch adapter processor maps settings onto engine requests', () async {
    final _FakePickerService picker = _FakePickerService(const <SelectedFile>[
      SelectedFile(path: '/tmp/a.jpg', name: 'a.jpg'),
    ]);
    final _FakeCompression compression = _FakeCompression();
    final BatchCompressionAdapter adapter = BatchCompressionAdapter(
      picker: picker,
      compression: compression,
    );
    addTearDown(adapter.dispose);

    await adapter.controller.selectImages();
    adapter.controller.updateSettings(
      const BatchCompressionSettings(
        quality: 60,
        format: BatchOutputFormat.webp,
        resize: BatchResizeChoice.percent50,
        keepMetadata: true,
        targetBytes: 200000,
      ),
    );
    await adapter.controller.startProcessing();

    final BatchImageItem item = adapter.controller.items.single;
    expect(item.status, BatchQueueStatus.completed);
    expect(item.outputPath, '/cache/out.webp');
    expect(item.outputBytes, 5000);
    final _Request captured = compression.lastRequest!;
    expect(captured.quality, 60);
    expect(captured.format, CompressorFormat.webp);
    expect(captured.scale, .5);
    expect(captured.keepExif, isTrue);
    expect(captured.targetBytes, 200000);
  });

  test(
    'batch adapter skips unreadable files without failing the selection',
    () async {
      final _FakePickerService picker = _FakePickerService(const <SelectedFile>[
        SelectedFile(path: '/tmp/ok.jpg', name: 'ok.jpg'),
        SelectedFile(path: '/tmp/broken.png', name: 'broken.png'),
      ]);
      final _FakeCompression compression = _FakeCompression();
      final BatchCompressionAdapter adapter = BatchCompressionAdapter(
        picker: picker,
        compression: compression,
      );
      addTearDown(adapter.dispose);

      compression.failInspectFor = '/tmp/broken.png';
      await adapter.controller.selectImages();

      expect(adapter.controller.items, hasLength(1));
      expect(adapter.controller.items.single.name, 'ok.jpg');
    },
  );
  test(
    'batch adapter saveAll persists outputs through the export gateway',
    () async {
      final _FakePickerService picker = _FakePickerService(const <SelectedFile>[
        SelectedFile(path: '/tmp/a.jpg', name: 'a.jpg'),
      ]);
      final _FakeExportGateway gateway = _FakeExportGateway();
      final BatchCompressionAdapter adapter = BatchCompressionAdapter(
        picker: picker,
        compression: _FakeCompression(),
        exportGateway: gateway,
      );
      addTearDown(adapter.dispose);

      await adapter.controller.selectImages();
      await adapter.controller.startProcessing();

      expect(await adapter.controller.saveAll(), 1);
      expect(gateway.savedPaths, equals(<String>['/cache/out.webp']));
    },
  );

  test(
    'batch adapter shareSelected dispatches inspected share assets',
    () async {
      final _FakeShareService share = _FakeShareService();
      final BatchCompressionAdapter adapter = BatchCompressionAdapter(
        picker: _FakePickerService(const <SelectedFile>[
          SelectedFile(path: '/tmp/a.jpg', name: 'a.jpg'),
        ]),
        compression: _FakeCompression(),
        shareService: share,
      );
      addTearDown(adapter.dispose);

      await adapter.controller.selectImages();
      await adapter.controller.startProcessing();

      expect(await adapter.controller.shareSelected(), 1);
      expect(share.requests, hasLength(1));
      final ShareRequest request = share.requests.single;
      expect(request.assets, hasLength(1));
      expect(request.assets.single.compressed.displayName, 'out.webp');
      expect(request.scope, ShareScope.single);
    },
  );

  test(
    'batch adapter prepareZip writes a real archive into managed exports',
    () async {
      final Directory temp = await Directory.systemTemp.createTemp(
        'batch_zip_adapter_test',
      );
      addTearDown(() async {
        if (await temp.exists()) {
          await temp.delete(recursive: true);
        }
      });
      final BatchCompressionAdapter adapter = BatchCompressionAdapter(
        picker: _FakePickerService(const <SelectedFile>[
          SelectedFile(path: '/tmp/a.jpg', name: 'a.jpg'),
        ]),
        compression: _WritingCompression(temp),
        storage: _FakeStorageManager(temp),
      );
      addTearDown(adapter.dispose);

      await adapter.controller.selectImages();
      await adapter.controller.startProcessing();
      final BatchZipResult zip = await adapter.controller.prepareZip();

      expect(zip.fileCount, 1);
      expect(zip.name, endsWith('.zip'));
      expect(zip.bytes, greaterThan(0));
      final File archive = File(zip.path);
      expect(await archive.exists(), isTrue);
      // ZIP local file header signature: PK\x03\x04.
      expect(archive.readAsBytesSync().sublist(0, 4), <int>[
        0x50,
        0x4B,
        0x03,
        0x04,
      ]);
    },
  );
}

final class _FakePickerService implements ImagePickerService {
  _FakePickerService(this.files);

  final List<SelectedFile> files;

  @override
  Future<Result<List<SelectedFile>>> pick(
    ImageSelectionRequest request,
  ) async => Result<List<SelectedFile>>.success(files);

  @override
  Future<Result<List<SelectedFile>>> recoverLostSelection() async =>
      const Result<List<SelectedFile>>.success(<SelectedFile>[]);
}

final class _FakeCompression implements ImageCompressionGateway {
  _Request? lastRequest;
  String? failInspectFor;

  @override
  Future<PhotoAsset> inspect(String sourcePath) async {
    if (failInspectFor == sourcePath) {
      throw const FileSystemException('unreadable');
    }
    return PhotoAsset(
      filePath: sourcePath,
      bytes: sourcePath.endsWith('.png') ? 9000 : 8000,
      width: 1200,
      height: 900,
    );
  }

  @override
  Future<CompressedAsset> compress(
    PhotoAsset source, {
    int quality = 72,
    CompressorFormat format = CompressorFormat.jpeg,
    double scale = 1,
    int? targetBytes,
    bool keepExif = false,
  }) async {
    lastRequest = _Request(
      quality: quality,
      format: format,
      scale: scale,
      targetBytes: targetBytes,
      keepExif: keepExif,
    );
    return CompressedAsset(
      filePath: '/cache/out.webp',
      bytes: 5000,
      width: (source.width * scale).round(),
      height: (source.height * scale).round(),
      quality: quality,
      format: CompressorFormat.webp,
    );
  }

  @override
  Future<void> deleteTemporaryOutput(String filePath) async {}
}

final class _Request {
  const _Request({
    required this.quality,
    required this.format,
    required this.scale,
    required this.targetBytes,
    required this.keepExif,
  });

  final int quality;
  final CompressorFormat format;
  final double scale;
  final int? targetBytes;
  final bool keepExif;
}

final class _FakeExportGateway implements ImageExportGateway {
  final List<String> savedPaths = <String>[];

  @override
  Future<void> saveToDevice(String filePath) async => savedPaths.add(filePath);

  @override
  Future<void> share(String filePath) async {}
}

final class _FakeShareService implements ShareExportService {
  final List<ShareRequest> requests = <ShareRequest>[];

  @override
  Future<Result<ShareOutcome>> share(
    ShareRequest request, {
    ShareExportOperation? operation,
  }) async {
    requests.add(request);
    return Result<ShareOutcome>.success(
      ShareOutcome(
        files: const <SharePayloadFile>[],
        status: ShareDispatchStatus.shared,
        report: ExportReport(
          items: const <ExportItemReport>[],
          destination: ExportDestinationKind.temporaryShare,
          createdAt: DateTime.now(),
        ),
      ),
    );
  }

  @override
  Future<Result<ExportOutcome>> export(
    ExportRequest request, {
    ShareExportOperation? operation,
  }) async {
    return Result<ExportOutcome>.success(
      ExportOutcome(
        paths: const <String>[],
        report: ExportReport(
          items: const <ExportItemReport>[],
          destination: ExportDestinationKind.appManaged,
          createdAt: DateTime.now(),
        ),
      ),
    );
  }
}

final class _FakeStorageManager implements StorageManager {
  _FakeStorageManager(this.root);

  final Directory root;

  @override
  Future<Result<Map<StorageLocation, Directory>>> directories() async =>
      Result<Map<StorageLocation, Directory>>.success(
        <StorageLocation, Directory>{
          for (final StorageLocation location in StorageLocation.values)
            location: root,
        },
      );

  @override
  Future<Result<Directory>> directory(StorageLocation location) async =>
      Result<Directory>.success(root);
}

/// Compression fake that writes a real output file so ZIP building has actual
/// payload bytes to archive.
final class _WritingCompression implements ImageCompressionGateway {
  _WritingCompression(this.root);

  final Directory root;

  @override
  Future<PhotoAsset> inspect(String sourcePath) async =>
      PhotoAsset(filePath: sourcePath, bytes: 8000, width: 1200, height: 900);

  @override
  Future<CompressedAsset> compress(
    PhotoAsset source, {
    int quality = 72,
    CompressorFormat format = CompressorFormat.jpeg,
    double scale = 1,
    int? targetBytes,
    bool keepExif = false,
  }) async {
    final File output = File('${root.path}/out.${_extension(format)}');
    await output.writeAsBytes(
      List<int>.generate(256, (int index) => index % 251),
    );
    return CompressedAsset(
      filePath: output.path,
      bytes: 256,
      width: (source.width * scale).round(),
      height: (source.height * scale).round(),
      quality: quality,
      format: format,
    );
  }

  String _extension(CompressorFormat format) => switch (format) {
    CompressorFormat.jpeg => 'jpg',
    CompressorFormat.png => 'png',
    CompressorFormat.webp => 'webp',
  };

  @override
  Future<void> deleteTemporaryOutput(String filePath) async {}
}
