import 'package:comprezza/core/services/benchmark_timer.dart';
import 'package:comprezza/features/compressor/domain/compression_models.dart';
import 'package:comprezza/features/compressor/domain/gateways/compressor_gateways.dart';
import 'package:comprezza/features/compressor/presentation/benchmark/benchmark_screen.dart';
import 'package:comprezza/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
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
  Widget host(
    _FakePickerGateway picker,
    _FakeCompressionGateway compression, {
    Size size = const Size(390, 844),
  }) => MediaQuery(
    data: MediaQueryData(size: size, disableAnimations: true),
    child: MaterialApp(
      theme: ThemeData(useMaterial3: true),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: BenchmarkScreen(
        pickerGateway: picker,
        compressionGateway: compression,
        timer: LocalBenchmarkTimer(),
      ),
    ),
  );

  testWidgets('renders the empty state with a clear run action', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      host(
        _FakePickerGateway('/photos/vacation.jpg'),
        _FakeCompressionGateway(),
        size: const Size(390, 1600),
      ),
    );

    expect(find.text('Benchmark'), findsWidgets); // app bar + hero
    expect(find.text('No benchmark yet'), findsOneWidget);
    expect(find.text('Choose an image'), findsOneWidget);
    expect(find.text('Results'), findsNothing);
    expect(find.text('Quality comparison'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('runs the benchmark and presents results and comparison', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final _FakePickerGateway picker = _FakePickerGateway(
      '/photos/vacation.jpg',
    );
    final _FakeCompressionGateway compression = _FakeCompressionGateway();
    await tester.pumpWidget(
      host(picker, compression, size: const Size(390, 1600)),
    );

    await tester.tap(find.text('Choose an image'));
    await tester.pumpAndSettle();

    // All three configured qualities were measured.
    expect(compression.requestedQualities, <int>[50, 72, 90]);
    expect(compression.deletedOutputs, hasLength(3));
    // Source name replaces the empty-state copy.
    expect(find.text('vacation.jpg'), findsOneWidget);
    expect(find.text('No benchmark yet'), findsNothing);

    // Results stats.
    expect(find.text('Results'), findsOneWidget);
    expect(find.text('Fastest run'), findsOneWidget);
    expect(find.text('Best ratio'), findsOneWidget);
    expect(find.text('Total saved'), findsOneWidget);
    expect(find.text('Speed'), findsOneWidget);

    // Comparison rows show each quality and its ratio pill.
    expect(find.text('Quality comparison'), findsOneWidget);
    expect(find.text('50%'), findsOneWidget);
    expect(find.text('72%'), findsOneWidget);
    expect(find.text('90%'), findsOneWidget);
    // Best ratio is the 50% run: 8000 / 4000 = 2.0×.
    expect(find.text('2.0×'), findsWidgets);
    // Each row combines time and saved bytes into one label.
    expect(find.textContaining('Time'), findsWidgets);
    expect(find.textContaining('Saved'), findsWidgets);

    // The run button now offers a re-run.
    expect(find.text('Run benchmark'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows a human error card and retries after a failed run', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final _FakePickerGateway picker = _FakePickerGateway(
      '/photos/vacation.jpg',
    );
    final _FakeCompressionGateway compression = _FakeCompressionGateway()
      ..throwOnCompress = true;
    await tester.pumpWidget(
      host(picker, compression, size: const Size(390, 1600)),
    );

    await tester.tap(find.text('Choose an image'));
    await tester.pumpAndSettle();

    expect(
      find.text('Something went wrong. Please try again.'),
      findsOneWidget,
    );
    expect(find.text('Try again'), findsOneWidget);
    expect(find.text('Results'), findsNothing);

    // Recovery: clear the failure and re-run successfully.
    compression.throwOnCompress = false;
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.text('Results'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
