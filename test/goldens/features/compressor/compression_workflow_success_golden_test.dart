import 'package:comprezza/features/compressor/domain/compression_models.dart';
import 'package:comprezza/features/compressor/domain/gateways/compressor_gateways.dart';
import 'package:comprezza/features/compressor/presentation/compression_workflow_screen.dart';
import 'package:comprezza/features/compressor/presentation/compressor_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../golden_test_utils.dart';

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

void main() {
  setUpAll(loadGoldenFonts);

  CompressorController makeController() => CompressorController(
    pickerGateway: _FakePicker(),
    compressionGateway: _FakeCompression(),
    exportGateway: _FakeExport(),
  );

  Widget successWorkflow(CompressorController controller) =>
      CompressionWorkflowScreen(
        controller: controller,
        isDarkMode: false,
        onThemeToggle: () {},
      );

  testWidgets('workflow success matches the light golden', (
    WidgetTester tester,
  ) async {
    final CompressorController controller = makeController();
    addTearDown(controller.dispose);
    controller
      ..original = const PhotoAsset(
        filePath: '/missing/original.jpg',
        bytes: 2 * 1024 * 1024,
        width: 2400,
        height: 1600,
      )
      ..compressed = const CompressedAsset(
        filePath: '/missing/compressed.png',
        bytes: 500 * 1024,
        width: 2400,
        height: 1600,
        quality: 72,
        format: CompressorFormat.png,
      )
      ..status = CompressorStatus.ready;
    await captureGolden(
      tester,
      successWorkflow(controller),
      'compression_workflow_success_light.png',
    );
  });

  testWidgets('workflow success matches the dark golden', (
    WidgetTester tester,
  ) async {
    final CompressorController controller = makeController();
    addTearDown(controller.dispose);
    controller
      ..original = const PhotoAsset(
        filePath: '/missing/original.jpg',
        bytes: 2 * 1024 * 1024,
        width: 2400,
        height: 1600,
      )
      ..compressed = const CompressedAsset(
        filePath: '/missing/compressed.png',
        bytes: 500 * 1024,
        width: 2400,
        height: 1600,
        quality: 72,
        format: CompressorFormat.png,
      )
      ..status = CompressorStatus.ready;
    await captureGolden(
      tester,
      successWorkflow(controller),
      'compression_workflow_success_dark.png',
      brightness: Brightness.dark,
    );
  });
}
