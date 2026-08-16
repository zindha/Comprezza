import 'package:comprezza/app/navigation/main_navigation_shell.dart';
import 'package:comprezza/app/routing/app_routes.dart';
import 'package:comprezza/core/models/result.dart';
import 'package:comprezza/features/compressor/data/services/file_management/interfaces/file_management_interfaces.dart';
import 'package:comprezza/features/compressor/data/services/file_management/models/file_management_models.dart';
import 'package:comprezza/features/compressor/presentation/about/about_screen.dart';
import 'package:comprezza/features/compressor/presentation/history/history_screen.dart';
import 'package:comprezza/features/compressor/presentation/home_dashboard.dart';
import 'package:comprezza/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeHistoryStorage implements HistoryStorage {
  @override
  Future<Result<void>> save(CompressionHistoryRecord record) async =>
      const Result<void>.success(null);

  @override
  Future<Result<List<CompressionHistoryRecord>>> readAll() async =>
      const Result<List<CompressionHistoryRecord>>.success(
        <CompressionHistoryRecord>[],
      );

  @override
  Future<Result<void>> delete(String id) async =>
      const Result<void>.success(null);
}

void main() {
  Widget host(Widget child, {Size size = const Size(390, 844)}) {
    return MediaQuery(
      data: MediaQueryData(size: size, disableAnimations: true),
      child: MaterialApp(
        theme: ThemeData(useMaterial3: true),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: child,
      ),
    );
  }

  test('route locations cover the Phase 6 navigation contract', () {
    expect(AppRoutes.locationFor(AppRoute.home), '/');
    expect(AppRoutes.locationFor(AppRoute.compression), '/compression');
    expect(AppRoutes.locationFor(AppRoute.history), '/history');
    expect(AppRoutes.locationFor(AppRoute.statistics), '/statistics');
    expect(AppRoutes.locationFor(AppRoute.settings), '/settings');
    expect(AppRoutes.locationFor(AppRoute.benchmark), '/benchmark');
    expect(AppRoutes.locationFor(AppRoute.about), '/about');
    expect(AppRoutes.indexForLocation('/statistics'), 2);
  });

  testWidgets('home dashboard presents the premium first-run content', (
    WidgetTester tester,
  ) async {
    var selected = 0;
    await tester.pumpWidget(
      host(HomeDashboard(onSelectImages: () => selected++)),
    );

    expect(find.text('Comprezza'), findsNWidgets(2));
    expect(
      find.text('Compress photos privately on your device.'),
      findsOneWidget,
    );
    expect(find.text('Quick actions'), findsOneWidget);
    expect(find.text('Storage savings'), findsOneWidget);
    expect(find.text('No recent compressions yet'), findsOneWidget);
    expect(find.text('Images compressed'), findsOneWidget);
    expect(find.text('SMART TIP'), findsOneWidget);

    await tester.tap(find.text('Choose photos').first);
    expect(selected, 1);
  });

  testWidgets(
    'quick actions merge the batch shortcut with the primary action',
    (WidgetTester tester) async {
      var batchOpened = 0;
      await tester.pumpWidget(
        host(
          HomeDashboard(
            onSelectImages: () {},
            onOpenBatch: () => batchOpened++,
          ),
        ),
      );

      await tester.tap(find.text('Batch compress'));
      expect(batchOpened, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('home dashboard supports reduced motion and tip rotation', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(host(HomeDashboard(onSelectImages: () {})));

    expect(find.text('A lighter web, one image at a time'), findsOneWidget);
    // The dashboard scrolls; bring the carousel control into the viewport
    // before tapping it.
    await tester.ensureVisible(find.byTooltip('Next tip'));
    await tester.pump();
    await tester.tap(find.byTooltip('Next tip'));
    await tester.pump();
    expect(find.text('Keep screenshots crisp'), findsOneWidget);
  });

  testWidgets('navigation shell uses bottom navigation on phone widths', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      host(
        const MainNavigationShell(
          currentLocation: AppRoutes.home,
          child: Text('destination'),
        ),
      ),
    );

    expect(find.byType(AppBottomNavigation), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.byType(NavigationRail), findsNothing);
    expect(find.text('Home'), findsOneWidget);
  });

  testWidgets('navigation shell uses a rail on tablet widths', (
    WidgetTester tester,
  ) async {
    // The rail/bar decision reads the real surface size, so widen the test
    // view rather than only the surrounding MediaQuery.
    tester.view.physicalSize = const Size(1000, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      host(
        const MainNavigationShell(
          currentLocation: AppRoutes.home,
          child: Text('destination'),
        ),
        size: const Size(1000, 800),
      ),
    );

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('dashboard remains readable in dark theme at large text scale', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: Size(390, 844),
          disableAnimations: true,
          textScaler: TextScaler.linear(1.8),
        ),
        child: MaterialApp(
          theme: ThemeData(useMaterial3: true),
          darkTheme: ThemeData.dark(useMaterial3: true),
          themeMode: ThemeMode.dark,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: HomeDashboard(onSelectImages: () {}),
        ),
      ),
    );

    expect(find.text('Comprezza'), findsNWidgets(2));
    expect(find.text('Storage savings'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('history destination loads persisted sessions', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      host(HistoryScreen(history: _FakeHistoryStorage())),
    );
    await tester.pump();

    expect(find.text('Your compression history'), findsOneWidget);
    expect(find.text('Your compression story starts here'), findsOneWidget);
  });

  testWidgets('about destination presents product and legal information', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(host(const AboutScreen()));

    expect(find.text('Comprezza'), findsWidgets);
    expect(find.text('Compress. Convert. Optimize.'), findsOneWidget);
    expect(find.text('Version'), findsOneWidget);
    expect(find.text('1.0.0'), findsOneWidget);
    expect(find.text('Legal'), findsOneWidget);
    expect(find.text('Licenses'), findsOneWidget);
  });
}
