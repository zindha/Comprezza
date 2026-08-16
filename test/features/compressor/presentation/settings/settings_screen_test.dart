import 'package:comprezza/app/config/app_environment.dart';
import 'package:comprezza/features/compressor/domain/settings/settings_models.dart';
import 'package:comprezza/features/compressor/presentation/settings/settings_controller.dart';
import 'package:comprezza/features/compressor/presentation/settings/settings_screen.dart';
import 'package:comprezza/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> reveal(WidgetTester tester, Finder finder) async {
    final Finder settingsList = find.byKey(
      const ValueKey<String>('settings-list'),
    );
    final ScrollableState scrollable = tester.state<ScrollableState>(
      find.descendant(of: settingsList, matching: find.byType(Scrollable)),
    );
    final RenderObject renderObject = tester.renderObject(finder);
    await scrollable.position.ensureVisible(renderObject);
    await tester.pump();
  }

  AppConfig debugConfig() => const AppConfig(
    environment: AppEnvironment.debug,
    enableDiagnostics: true,
    enablePerformanceMonitoring: true,
  );

  Widget host(
    SettingsController controller, {
    Locale locale = const Locale('en'),
    Size size = const Size(390, 844),
  }) => MediaQuery(
    data: MediaQueryData(size: size, textScaler: const TextScaler.linear(1.3)),
    child: MaterialApp(
      theme: ThemeData(useMaterial3: true),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      home: SettingsScreen(controller: controller),
    ),
  );

  testWidgets('renders localized sections and semantics on a phone', (
    WidgetTester tester,
  ) async {
    final SettingsController controller = SettingsController(
      store: MemorySettingsStore(),
      configuration: debugConfig(),
    );
    addTearDown(controller.dispose);
    await tester.pumpWidget(host(controller));
    await tester.pumpAndSettle();

    expect(find.text('Make Comprezza yours'), findsOneWidget);
    expect(find.text('General'), findsOneWidget);
    expect(find.text('Compression'), findsOneWidget);
    expect(find.text('Accessibility'), findsOneWidget);
    expect(find.text('Privacy'), findsOneWidget);
    expect(find.text('About'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Settings personalization overview'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('supports Hindi strings and wide layouts without overflow', (
    WidgetTester tester,
  ) async {
    final SettingsController controller = SettingsController(
      store: MemorySettingsStore(),
      configuration: debugConfig(),
    );
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      host(
        controller,
        locale: const Locale('hi'),
        size: const Size(1200, 1000),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('सामान्य'), findsOneWidget);
    expect(find.text('कंप्रेशन'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'version unlock reveals developer options only after seven taps',
    (WidgetTester tester) async {
      final SettingsController controller = SettingsController(
        store: MemorySettingsStore(),
        configuration: debugConfig(),
      );
      addTearDown(controller.dispose);
      await tester.pumpWidget(host(controller));
      await tester.pumpAndSettle();
      expect(find.text('Developer options'), findsNothing);

      await reveal(tester, find.text('About'));
      await tester.tap(find.text('About'));
      await tester.pumpAndSettle();
      await reveal(tester, find.text('Version'));
      await tester.tap(find.text('Version'));
      await tester.tap(find.text('Version'));
      await tester.tap(find.text('Version'));
      await tester.tap(find.text('Version'));
      await tester.tap(find.text('Version'));
      await tester.tap(find.text('Version'));
      await tester.tap(find.text('Version'));
      await tester.pumpAndSettle();
      expect(find.text('Developer options'), findsOneWidget);
    },
  );

  testWidgets('metadata toggles are mutually exclusive and both changeable', (
    WidgetTester tester,
  ) async {
    final SettingsController controller = SettingsController(
      store: MemorySettingsStore(),
      configuration: debugConfig(),
    );
    addTearDown(controller.dispose);
    await tester.pumpWidget(host(controller));
    await tester.pumpAndSettle();

    await reveal(tester, find.text('Compression'));
    await tester.tap(find.text('Compression'));
    await tester.pumpAndSettle();

    // Turning on keep must turn off remove.
    await reveal(tester, find.text('Always keep metadata'));
    await tester.tap(find.text('Always keep metadata'));
    await tester.pumpAndSettle();
    expect(controller.state.preferences.alwaysKeepMetadata, isTrue);
    expect(controller.state.preferences.alwaysRemoveMetadata, isFalse);

    // Turning on remove must turn off keep (regression: the conflict
    // resolution used to force remove back off, so it could never be enabled).
    await reveal(tester, find.text('Always remove metadata'));
    await tester.tap(find.text('Always remove metadata'));
    await tester.pumpAndSettle();
    expect(controller.state.preferences.alwaysRemoveMetadata, isTrue);
    expect(controller.state.preferences.alwaysKeepMetadata, isFalse);
  });

  testWidgets(
    'sliders render imported values above the old UI cap without error',
    (WidgetTester tester) async {
      // The decoder accepts cache up to 4096 MB and history up to 10000 items,
      // while the sliders cap at 1024/2000. A stored value in between used to
      // crash the whole settings screen with a Slider assertion.
      final SettingsController controller = SettingsController(
        store: MemorySettingsStore(
          initial: SettingsJsonCodec.fromMap(<String, Object?>{
            'maximumCacheSizeMb': 2048,
            'compressionHistorySizeLimit': 5000,
          }),
        ),
        configuration: debugConfig(),
      );
      addTearDown(controller.dispose);
      await tester.pumpWidget(host(controller));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('destructive action requires confirmation', (
    WidgetTester tester,
  ) async {
    final MemorySettingsStore store = MemorySettingsStore();
    final SettingsController controller = SettingsController(
      store: store,
      configuration: debugConfig(),
    );
    addTearDown(controller.dispose);
    await tester.pumpWidget(host(controller));
    await tester.pumpAndSettle();
    await reveal(tester, find.text('Clear cache'));
    await tester.tap(find.text('Clear cache'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Only generated app cache will be removed. Original photos are never touched.',
        findRichText: true,
      ),
      findsOneWidget,
    );
    expect(store.clearCacheCount, 0);
    await tester.tap(find.widgetWithText(FilledButton, 'Confirm'));
    await tester.pumpAndSettle();
    expect(store.clearCacheCount, 1);
  });
}
