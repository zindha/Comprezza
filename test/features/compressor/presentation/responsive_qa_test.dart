import 'package:comprezza/app/config/app_environment.dart';
import 'package:comprezza/core/services/benchmark_timer.dart';
import 'package:comprezza/features/compressor/domain/compression_models.dart';
import 'package:comprezza/features/compressor/domain/entities/application_entities.dart';
import 'package:comprezza/features/compressor/domain/gateways/compressor_gateways.dart';
import 'package:comprezza/features/compressor/presentation/about/about_screen.dart';
import 'package:comprezza/features/compressor/presentation/batch_compression_controller.dart';
import 'package:comprezza/features/compressor/presentation/batch_compression_screen.dart';
import 'package:comprezza/features/compressor/presentation/benchmark/benchmark_screen.dart';
import 'package:comprezza/features/compressor/presentation/compression_workflow_screen.dart';
import 'package:comprezza/features/compressor/presentation/compressor_controller.dart';
import 'package:comprezza/features/compressor/presentation/history_insights_controller.dart';
import 'package:comprezza/features/compressor/presentation/history_insights_screen.dart';
import 'package:comprezza/features/compressor/presentation/home_dashboard.dart';
import 'package:comprezza/features/compressor/presentation/settings/settings_controller.dart';
import 'package:comprezza/features/compressor/presentation/settings/settings_screen.dart';
import 'package:comprezza/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Redesign QA matrix.
///
/// Every primary screen is rendered at small/normal/large phone widths, in
/// light and dark themes, and at 1.0 / 1.3 / 2.0 text scales. Flutter throws
/// a [FlutterError] on any RenderFlex overflow, so `takeException()` must stay
/// null for each combination. Lazy lists/slivers are scrolled to the bottom so
/// below-the-fold content participates in the check.
const List<Size> _sizes = <Size>[
  Size(320, 568), // small phone
  Size(360, 640), // normal phone
  Size(414, 896), // large phone
];

const List<Brightness> _themes = <Brightness>[
  Brightness.light,
  Brightness.dark,
];

const List<double> _scales = <double>[1.0, 1.3, 2.0];

void _noop() {}

Future<void> _runMatrix(
  WidgetTester tester,
  Widget Function() build, {

  /// Optional interaction applied after the initial settle, before the lazy
  /// scroll pass — for example switching to a secondary tab so its content
  /// participates in the overflow check at every combination.
  Future<void> Function(WidgetTester tester)? afterSettle,
}) async {
  for (final Size size in _sizes) {
    for (final Brightness theme in _themes) {
      for (final double scale in _scales) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          MediaQuery(
            data: MediaQueryData(
              size: size,
              textScaler: TextScaler.linear(scale),
              disableAnimations: true,
            ),
            child: MaterialApp(
              theme: ThemeData(useMaterial3: true, brightness: theme),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              // A unique key per combo forces a full teardown + fresh
              // initState. Without it, structurally identical trees reuse the
              // previous State, so controllers whose load() runs in initState
              // never start (and their loading spinners animate forever).
              home: KeyedSubtree(
                key: ValueKey<String>('$size-$theme-$scale'),
                child: build(),
              ),
            ),
          ),
        );
        try {
          await tester.pumpAndSettle();
        } on FlutterError {
          fail(
            'pumpAndSettle timed out at ${size.width.toInt()}x'
            '${size.height.toInt()} · '
            '${theme == Brightness.dark ? 'dark' : 'light'} · '
            'textScale $scale',
          );
        }

        if (afterSettle != null) {
          try {
            await afterSettle(tester);
          } on FlutterError {
            fail(
              'interaction timed out at ${size.width.toInt()}x'
              '${size.height.toInt()} · '
              '${theme == Brightness.dark ? 'dark' : 'light'} · '
              'textScale $scale',
            );
          }
        }

        // Force lazy vertical content (lists, slivers) to build below the fold.
        final Finder vertical = find.byWidgetPredicate(
          (Widget widget) =>
              widget is Scrollable &&
              widget.axisDirection == AxisDirection.down,
        );
        if (vertical.evaluate().isNotEmpty) {
          await tester.drag(vertical.first, const Offset(0, -3000));
          await tester.pumpAndSettle();
          await tester.drag(vertical.first, const Offset(0, -3000));
          await tester.pumpAndSettle();
          // Return to the top: PageStorageKey'd scroll views persist their
          // offset across combos, so a scrolled-out insights header would be
          // unmounted for every later combo.
          await tester.drag(vertical.first, const Offset(0, 3000));
          await tester.pumpAndSettle();
          await tester.drag(vertical.first, const Offset(0, 3000));
          await tester.pumpAndSettle();
        }

        // Flush one-shot debounce timers (e.g. analysis/recompress debounce).
        await tester.pump(const Duration(seconds: 1));

        expect(
          tester.takeException(),
          isNull,
          reason:
              'overflow at ${size.width.toInt()}x${size.height.toInt()} · '
              '${theme == Brightness.dark ? 'dark' : 'light'} · '
              'textScale $scale',
        );
      }
    }
  }
}

// ---------------------------------------------------------------------------
// Workflow fakes.
// ---------------------------------------------------------------------------

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
    bytes: (source.bytes * quality / 100).round(),
    width: source.width,
    height: source.height,
    quality: quality,
    format: format,
  );

  @override
  Future<void> deleteTemporaryOutput(String filePath) async {}

  @override
  Future<PhotoAsset> inspect(String sourcePath) async => const PhotoAsset(
    filePath: '/missing/original.jpg',
    bytes: 2 * 1024 * 1024,
    width: 2400,
    height: 1600,
  );
}

final class _FakeExport implements ImageExportGateway {
  @override
  Future<void> saveToDevice(String filePath) async {}

  @override
  Future<void> share(String filePath) async {}
}

// ---------------------------------------------------------------------------
// Shared fixtures.
// ---------------------------------------------------------------------------

BatchImageItem _batchItem(String id) => BatchImageItem(
  id: id,
  path: '/missing/$id.jpg',
  name: '$id.jpg',
  width: 2400,
  height: 1600,
  format: 'JPEG',
);

HistoryEntry _entry(String id) => HistoryEntry(
  id: id,
  sourceName: '$id.jpg',
  outputName: '$id.webp',
  createdAt: DateTime(2026, 8, 6),
  preset: const CompressionPreset(
    id: 'balanced',
    name: 'Balanced',
    quality: 72,
  ),
  statistics: const CompressionStatistics(
    inputBytes: 10000,
    outputBytes: 4000,
    savedBytes: 6000,
    savingsRatio: 2.5,
    processedFiles: 1,
    duration: Duration(milliseconds: 300),
  ),
);

AppConfig _debugConfig() => const AppConfig(
  environment: AppEnvironment.debug,
  enableDiagnostics: true,
  enablePerformanceMonitoring: true,
);

void main() {
  testWidgets('home dashboard survives the responsive matrix', (
    WidgetTester tester,
  ) async {
    await _runMatrix(tester, () => const HomeDashboard(onSelectImages: _noop));
  });

  testWidgets('workflow import state survives the responsive matrix', (
    WidgetTester tester,
  ) async {
    await _runMatrix(tester, () {
      final CompressorController controller = CompressorController(
        pickerGateway: _FakePicker(),
        compressionGateway: _FakeCompression(),
        exportGateway: _FakeExport(),
      );
      addTearDown(controller.dispose);
      return CompressionWorkflowScreen(
        controller: controller,
        isDarkMode: false,
        onThemeToggle: _noop,
      );
    });
  });

  testWidgets('workflow full state (analysis, options, preview, success) '
      'survives the responsive matrix', (WidgetTester tester) async {
    await _runMatrix(tester, () {
      final CompressorController controller = CompressorController(
        pickerGateway: _FakePicker(),
        compressionGateway: _FakeCompression(),
        exportGateway: _FakeExport(),
      );
      addTearDown(controller.dispose);
      controller
        ..original = const PhotoAsset(
          filePath: '/missing/original.jpg',
          bytes: 2 * 1024 * 1024,
          width: 2400,
          height: 1600,
        )
        ..compressed = const CompressedAsset(
          filePath: '/missing/compressed.webp',
          bytes: 500 * 1024,
          width: 2400,
          height: 1600,
          quality: 72,
          format: CompressorFormat.webp,
        )
        ..status = CompressorStatus.ready;
      return CompressionWorkflowScreen(
        controller: controller,
        isDarkMode: false,
        onThemeToggle: _noop,
      );
    });
  });

  testWidgets('batch empty state survives the responsive matrix', (
    WidgetTester tester,
  ) async {
    await _runMatrix(tester, () {
      final BatchCompressionController controller = BatchCompressionController(
        picker: () async => <BatchImageItem>[],
        processor:
            (BatchImageItem item, BatchCompressionSettings settings) async =>
                BatchImageResult(
                  outputPath: '${item.path}.compressed',
                  outputBytes: 600 * 1024,
                ),
      );
      addTearDown(controller.dispose);
      return BatchCompressionScreen(controller: controller);
    });
  });

  testWidgets('batch populated state survives the responsive matrix', (
    WidgetTester tester,
  ) async {
    await _runMatrix(tester, () {
      final BatchCompressionController controller = BatchCompressionController(
        picker: () async => <BatchImageItem>[],
        processor:
            (BatchImageItem item, BatchCompressionSettings settings) async =>
                BatchImageResult(
                  outputPath: '${item.path}.compressed',
                  outputBytes: 600 * 1024,
                ),
      );
      addTearDown(controller.dispose);
      controller.addImages(<BatchImageItem>[
        _batchItem('one'),
        _batchItem('two'),
        _batchItem('three'),
      ]);
      return BatchCompressionScreen(controller: controller);
    });
  });

  testWidgets('history and insights tabs survive the responsive matrix', (
    WidgetTester tester,
  ) async {
    await _runMatrix(
      tester,
      () {
        final HistoryInsightsController controller = HistoryInsightsController(
          entries: <HistoryEntry>[_entry('a'), _entry('b'), _entry('c')],
        );
        addTearDown(controller.dispose);
        return HistoryInsightsScreen(controller: controller);
      },
      // The insights tab is one tap away; switch to it at every combination so
      // its charts, achievements, and insights content participate in the
      // overflow and settle checks instead of a single spot-check. The tap
      // target is unambiguous (the AppBar title is bound to initialTab, the
      // insights page uses insightsTitle), and asserting the page content
      // after the switch ensures a future change can't silently stop
      // exercising the tab.
      afterSettle: (WidgetTester tester) async {
        await tester.tap(find.text('Insights'));
        await tester.pumpAndSettle();
        expect(
          find.text('Your storage impact'),
          findsOneWidget,
          reason: 'insights page not shown after tab switch',
        );
      },
    );
  });

  testWidgets('settings survives the responsive matrix', (
    WidgetTester tester,
  ) async {
    await _runMatrix(tester, () {
      final SettingsController controller = SettingsController(
        store: MemorySettingsStore(),
        configuration: _debugConfig(),
      );
      addTearDown(controller.dispose);
      return SettingsScreen(controller: controller);
    });
  });

  testWidgets('benchmark survives the responsive matrix', (
    WidgetTester tester,
  ) async {
    await _runMatrix(
      tester,
      () => BenchmarkScreen(
        pickerGateway: _FakePicker(),
        compressionGateway: _FakeCompression(),
        timer: LocalBenchmarkTimer(),
      ),
    );
  });

  testWidgets('about survives the responsive matrix', (
    WidgetTester tester,
  ) async {
    await _runMatrix(tester, () => const AboutScreen());
  });
}
