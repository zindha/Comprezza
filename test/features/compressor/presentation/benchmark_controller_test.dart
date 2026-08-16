import 'package:comprezza/core/services/benchmark_timer.dart';
import 'package:comprezza/features/compressor/domain/compression_models.dart';
import 'package:comprezza/features/compressor/domain/gateways/compressor_gateways.dart';
import 'package:comprezza/features/compressor/presentation/benchmark/benchmark_screen.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakePickerGateway implements ImagePickerGateway {
  _FakePickerGateway(this.path);

  String? path;

  @override
  Future<String?> pickImagePath() async => path;

  @override
  Future<String?> pickCameraImagePath() async => null;

  @override
  Future<String?> recoverLostImagePath() async => null;
}

class _FakeCompressionGateway implements ImageCompressionGateway {
  final List<int> requestedQualities = <int>[];
  final List<String> deletedOutputs = <String>[];
  bool throwOnCompress = false;

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
    if (throwOnCompress) throw StateError('encode failed');
    requestedQualities.add(quality);
    // Real-world shape: higher quality keeps more bytes, so the lowest
    // quality produces the best ratio and the highest the worst.
    return CompressedAsset(
      filePath: '/cache/out_$quality.jpg',
      bytes: (source.bytes * quality / 100).round(),
      width: source.width,
      height: source.height,
      quality: quality,
      format: CompressorFormat.jpeg,
    );
  }

  @override
  Future<void> deleteTemporaryOutput(String filePath) async {
    deletedOutputs.add(filePath);
  }
}

void main() {
  late _FakePickerGateway picker;
  late _FakeCompressionGateway compression;
  late BenchmarkController controller;

  BenchmarkController build({List<int>? qualities}) => BenchmarkController(
    pickerGateway: picker,
    compressionGateway: compression,
    timer: LocalBenchmarkTimer(),
    qualities: qualities ?? const <int>[50, 72, 90],
  );

  setUp(() {
    picker = _FakePickerGateway('/photos/vacation.jpg');
    compression = _FakeCompressionGateway();
    controller = build();
  });

  tearDown(() => controller.dispose());

  test('runs every configured quality and exposes derived metrics', () async {
    await controller.run();

    expect(controller.status, BenchmarkStatus.done);
    expect(compression.requestedQualities, <int>[50, 72, 90]);
    expect(controller.runs, hasLength(3));
    expect(controller.sourceName, 'vacation.jpg');
    expect(controller.sourceBytes, 8000);
    expect(controller.runs[0].quality, 50);
    expect(controller.runs[0].outputBytes, 4000);
    expect(controller.runs[0].savedBytes, 4000);
    expect(controller.runs[0].ratio, closeTo(2, .001));
    expect(controller.fastestRun, isNotNull);
    expect(controller.bestRatio!.quality, 50);
    expect(controller.totalSaved, greaterThan(0));
    // Temporary outputs are cleaned up after measuring.
    expect(compression.deletedOutputs, hasLength(3));
  });

  test('stays idle when the picker is dismissed', () async {
    picker.path = null;

    await controller.run();

    expect(controller.status, BenchmarkStatus.idle);
    expect(controller.runs, isEmpty);
    expect(compression.requestedQualities, isEmpty);
  });

  test('reports a user-safe error when compression fails', () async {
    compression.throwOnCompress = true;

    await controller.run();

    expect(controller.status, BenchmarkStatus.error);
    expect(controller.errorMessage, isNotNull);
    expect(controller.runs, isEmpty);
  });
}
