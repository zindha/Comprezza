import 'dart:io';

import 'package:comprezza/app/theme/app_theme_builder.dart';
import 'package:comprezza/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fixed phone-surface used by every golden capture so files stay comparable.
const Size goldenPhoneSize = Size(390, 844);

/// Loads the vendored Roboto and MaterialIcons fonts for golden rendering.
///
/// Widget tests otherwise rasterize text with the blocky Ahem placeholder and
/// icons as empty boxes. Registering the real fonts makes captures faithful to
/// production. Fonts live under `test/goldens/fonts/` (dev-only, read from
/// disk) so the shipping app bundle stays untouched.
Future<void> loadGoldenFonts() async {
  Future<ByteData> readFont(String name) async {
    final Uint8List bytes = await File(
      'test/goldens/fonts/$name',
    ).readAsBytes();
    return ByteData.sublistView(bytes);
  }

  // Register every weight so w400–w800 resolve to real faces instead of
  // synthetic bold.
  final FontLoader roboto = FontLoader('Roboto')
    ..addFont(readFont('Roboto-Regular.ttf'))
    ..addFont(readFont('Roboto-Medium.ttf'))
    ..addFont(readFont('Roboto-Bold.ttf'))
    ..addFont(readFont('Roboto-Black.ttf'));
  await roboto.load();

  final FontLoader icons = FontLoader('MaterialIcons')
    ..addFont(readFont('MaterialIcons-Regular.otf'));
  await icons.load();
}

/// Wraps [child] in the real Comprezza theme at a fixed phone size with
/// animations disabled, so captures are deterministic across runs.
Widget goldenHost(Widget child, {Brightness brightness = Brightness.light}) {
  return MediaQuery(
    data: const MediaQueryData(
      size: goldenPhoneSize,
      textScaler: TextScaler.linear(1.0),
      disableAnimations: true,
    ),
    child: MaterialApp(
      theme: brightness == Brightness.dark
          ? AppThemeBuilder.dark()
          : AppThemeBuilder.light(),
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    ),
  );
}

/// Sets up the fixed golden surface and captures [child] against [name].
Future<void> captureGolden(
  WidgetTester tester,
  Widget child,
  String name, {
  Brightness brightness = Brightness.light,
}) async {
  tester.view.physicalSize = goldenPhoneSize;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(goldenHost(child, brightness: brightness));
  await tester.pumpAndSettle();
  await expectLater(find.byType(MaterialApp), matchesGoldenFile(name));
}
