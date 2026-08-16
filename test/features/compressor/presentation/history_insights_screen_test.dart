import 'package:comprezza/features/compressor/domain/entities/application_entities.dart';
import 'package:comprezza/features/compressor/presentation/history_insights_controller.dart';
import 'package:comprezza/features/compressor/presentation/history_insights_screen.dart';
import 'package:comprezza/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  HistoryEntry entry(String id) => HistoryEntry(
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

  Widget host(
    HistoryInsightsController controller, {
    Size size = const Size(390, 844),
  }) => MediaQuery(
    data: MediaQueryData(size: size, disableAnimations: true),
    child: MaterialApp(
      theme: ThemeData(useMaterial3: true),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: HistoryInsightsScreen(controller: controller),
    ),
  );

  testWidgets('shows premium empty history state', (WidgetTester tester) async {
    // Use a tall phone-width surface so the lazy history list builds the
    // empty-state content instead of leaving it below the fold.
    tester.view.physicalSize = const Size(390, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final HistoryInsightsController controller = HistoryInsightsController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(host(controller));

    expect(find.text('Your compression history'), findsOneWidget);
    expect(find.text('Your compression story starts here'), findsOneWidget);
    expect(find.text('Choose photos'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'renders history, filters, details, and insights on a wide layout',
    (WidgetTester tester) async {
      // Match the surface to the intended wide layout so the history list
      // builds both entries and keeps their controls tappable.
      tester.view.physicalSize = const Size(1100, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      final HistoryInsightsController controller = HistoryInsightsController(
        entries: <HistoryEntry>[entry('holiday'), entry('work')],
      );
      addTearDown(controller.dispose);
      await tester.pumpWidget(host(controller, size: const Size(1100, 900)));

      expect(find.text('holiday.jpg'), findsOneWidget);
      expect(find.text('work.jpg'), findsOneWidget);
      expect(find.text('Pinned results'), findsNothing);
      expect(find.byType(CustomPaint), findsWidgets);
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('holiday.jpg'));
      await tester.pumpAndSettle();
      expect(find.text('Before image'), findsOneWidget);
      expect(find.text('After image'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('supports search and pinning', (WidgetTester tester) async {
    // Tall phone-width surface keeps the card's pin control on-screen.
    tester.view.physicalSize = const Size(390, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final HistoryInsightsController controller = HistoryInsightsController(
      entries: <HistoryEntry>[entry('holiday'), entry('work')],
    );
    addTearDown(controller.dispose);
    await tester.pumpWidget(host(controller));

    await tester.enterText(find.byType(TextField), 'holiday');
    await tester.pump();
    expect(find.text('holiday.jpg'), findsWidgets);
    expect(find.text('work.jpg'), findsNothing);

    await tester.tap(find.byTooltip('Pin result').first);
    await tester.pump();
    expect(find.text('Pinned results'), findsOneWidget);
  });
}
