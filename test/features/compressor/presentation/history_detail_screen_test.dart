import 'package:comprezza/features/compressor/domain/entities/application_entities.dart';
import 'package:comprezza/features/compressor/presentation/history_insights_controller.dart';
import 'package:comprezza/features/compressor/presentation/history_insights_screen.dart';
import 'package:comprezza/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  HistoryEntry entry({String id = 'holiday'}) => HistoryEntry(
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

  Widget detailHost(
    HistoryEntry item,
    HistoryInsightsController controller, {
    Size size = const Size(390, 844),
  }) => MediaQuery(
    data: MediaQueryData(size: size, disableAnimations: true),
    child: MaterialApp(
      theme: ThemeData(useMaterial3: true),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: HistoryDetailScreen(entry: item, controller: controller),
    ),
  );

  // Pushes the detail screen from a stub home so confirm-delete can pop back
  // to a real route, mirroring the in-app navigation from a history card.
  Widget pushedDetailHost(
    HistoryEntry item,
    HistoryInsightsController controller,
  ) => MediaQuery(
    // Tall surface keeps the action row reachable without scrolling.
    data: const MediaQueryData(size: Size(390, 1600), disableAnimations: true),
    child: MaterialApp(
      theme: ThemeData(useMaterial3: true),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (BuildContext context) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) =>
                      HistoryDetailScreen(entry: item, controller: controller),
                ),
              ),
              child: const Text('open-detail'),
            ),
          ),
        ),
      ),
    ),
  );

  testWidgets('renders savings hero, compare panel, facts, and actions', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final HistoryInsightsController controller = HistoryInsightsController(
      entries: <HistoryEntry>[entry()],
    );
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      detailHost(entry(), controller, size: const Size(390, 1600)),
    );

    // Savings hero: 6000 / 10000 = 60%, with the original → compressed line.
    expect(find.text('SAVED'), findsOneWidget);
    expect(find.text('60%'), findsOneWidget);
    expect(find.text('9.8 KB → 3.9 KB'), findsOneWidget);

    // Compare panel: before/after placeholders plus the center knob.
    expect(find.text('Before image'), findsOneWidget);
    expect(find.text('After image'), findsOneWidget);
    expect(find.byIcon(Icons.compare_arrows_rounded), findsOneWidget);

    // Facts card: sizes, ratio, preset, timing, metadata status.
    expect(find.text('holiday.jpg'), findsNWidgets(2)); // app bar + facts card
    expect(find.text('WebP'), findsOneWidget); // format pill
    expect(find.text('Original size'), findsOneWidget);
    expect(find.text('9.8 KB'), findsOneWidget);
    expect(find.text('Output size'), findsOneWidget);
    expect(find.text('3.9 KB'), findsOneWidget);
    expect(find.text('Saved'), findsOneWidget);
    expect(find.text('5.9 KB'), findsOneWidget); // 6000 / 1024
    expect(find.text('Compression ratio'), findsOneWidget);
    expect(find.text('2.5×'), findsOneWidget);
    expect(find.text('Preset'), findsOneWidget);
    expect(find.text('Balanced'), findsOneWidget);
    expect(find.text('Processing time'), findsOneWidget);
    expect(find.text('300 ms'), findsOneWidget);
    expect(find.text('Metadata status'), findsOneWidget);
    // Two placeholders + the metadata row each show "Not available".
    expect(find.text('Not available'), findsNWidgets(3));

    // Actions.
    expect(find.text('Share'), findsOneWidget);
    expect(find.text('Compress again'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);

    expect(tester.takeException(), isNull);
  });

  testWidgets('renders a wide layout without overflow', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1100, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final HistoryInsightsController controller = HistoryInsightsController(
      entries: <HistoryEntry>[entry()],
    );
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      detailHost(entry(), controller, size: const Size(1100, 900)),
    );

    expect(find.text('60%'), findsOneWidget);
    expect(find.text('Before image'), findsOneWidget);
    expect(find.text('After image'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shares and recompresses through controller callbacks', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final List<String> shared = <String>[];
    final List<String> recompressed = <String>[];
    final HistoryInsightsController controller = HistoryInsightsController(
      entries: <HistoryEntry>[entry()],
      onShare: (HistoryEntry item) async => shared.add(item.id),
      onCompressAgain: (HistoryEntry item) async => recompressed.add(item.id),
    );
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      detailHost(entry(), controller, size: const Size(390, 1600)),
    );

    await tester.ensureVisible(find.text('Share'));
    await tester.tap(find.text('Share'));
    await tester.pump();
    expect(shared, <String>['holiday']);

    await tester.ensureVisible(find.text('Compress again'));
    await tester.tap(find.text('Compress again'));
    await tester.pump();
    expect(recompressed, <String>['holiday']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('delete requires confirmation and removes the entry', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final HistoryEntry item = entry();
    final HistoryInsightsController controller = HistoryInsightsController(
      entries: <HistoryEntry>[item],
    );
    controller.initialize(); // mirror HistoryInsightsScreen.initState
    addTearDown(controller.dispose);
    await tester.pumpWidget(pushedDetailHost(item, controller));
    await tester.tap(find.text('open-detail'));
    await tester.pumpAndSettle();

    // Cancel keeps the entry.
    await tester.ensureVisible(find.text('Delete'));
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(find.text('Delete history entry?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(
      controller.entries.map((HistoryEntry e) => e.id),
      contains('holiday'),
    );

    // Confirm deletes and pops back to the stub home.
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();
    expect(controller.entries, isEmpty);
    expect(find.text('open-detail'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
