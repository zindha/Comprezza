import 'package:comprezza/features/compressor/domain/compression_models.dart';
import 'package:comprezza/features/compressor/domain/gateways/compressor_gateways.dart';
import 'package:comprezza/features/compressor/presentation/compression_workflow_screen.dart';
import 'package:comprezza/features/compressor/presentation/compressor_controller.dart';
import 'package:comprezza/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget host(
    CompressorController controller, {
    Size size = const Size(390, 844),
  }) {
    return MediaQuery(
      data: MediaQueryData(size: size, disableAnimations: true),
      child: MaterialApp(
        theme: ThemeData(useMaterial3: true),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: CompressionWorkflowScreen(
          controller: controller,
          isDarkMode: false,
          onThemeToggle: () {},
        ),
      ),
    );
  }

  CompressorController controller() => CompressorController(
    pickerGateway: _FakePicker(),
    compressionGateway: _FakeCompression(),
    exportGateway: _FakeExport(),
  );

  testWidgets('presents selection actions and accessible workflow steps', (
    WidgetTester tester,
  ) async {
    final CompressorController featureController = controller();
    addTearDown(featureController.dispose);
    await tester.pumpWidget(host(featureController));

    expect(find.text('Compress your image'), findsOneWidget);
    expect(find.text('Choose from gallery'), findsOneWidget);
    expect(find.text('Use camera'), findsOneWidget);
    expect(find.text('Batch compress multiple photos'), findsOneWidget);
    // The step indicator announces the current workflow step accessibly.
    expect(
      find.byWidgetPredicate(
        (Widget widget) =>
            widget is Semantics &&
            widget.properties.label == 'Select images' &&
            widget.properties.value != null,
      ),
      findsOneWidget,
    );

    // The camera entry now opens the real system camera through the picker
    // gateway; the fake returns no capture, so the workflow stays put.
    await tester.tap(find.text('Use camera'));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text('Compress your image'), findsOneWidget);
  });

  testWidgets('renders live controls and success actions on a phone', (
    WidgetTester tester,
  ) async {
    // The workflow is a scrollable page; use a tall phone-width surface so
    // every card participates in the frame without lazy-list folding.
    tester.view.physicalSize = const Size(390, 4600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final CompressorController featureController = controller();
    addTearDown(featureController.dispose);
    featureController
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

    await tester.pumpWidget(host(featureController));
    await tester.pumpAndSettle();

    // The savings ring animates to its final percentage (2 MB → 500 KB = 76%).
    expect(find.text('76%'), findsWidgets);
    // The caption reports the actual output format, not a hardcoded JPEG.
    expect(find.text('Quality used 72% · Format PNG'), findsOneWidget);
    expect(find.text('Image analysis'), findsOneWidget);
    expect(find.text('Compression options'), findsOneWidget);
    expect(find.text('Live estimate'), findsOneWidget);
    expect(find.text('Compression complete'), findsOneWidget);
    expect(find.text('Save to device'), findsOneWidget);
    expect(find.text('Share'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('500 KB'));
    // Let the target-size debounce timer fire so no timer is left pending.
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump();
    expect(find.text('500 KB'), findsOneWidget);
  });

  testWidgets('uses a side-by-side preview at wide constraints', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final CompressorController featureController = controller();
    addTearDown(featureController.dispose);
    featureController
      ..original = const PhotoAsset(
        filePath: '/missing/original.jpg',
        bytes: 1000000,
        width: 1200,
        height: 800,
      )
      ..compressed = const CompressedAsset(
        filePath: '/missing/compressed.jpg',
        bytes: 400000,
        width: 1200,
        height: 800,
        quality: 72,
        format: CompressorFormat.jpeg,
      )
      ..status = CompressorStatus.ready;

    await tester.pumpWidget(
      host(featureController, size: const Size(1000, 800)),
    );

    expect(find.byIcon(Icons.arrow_forward_rounded), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
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
