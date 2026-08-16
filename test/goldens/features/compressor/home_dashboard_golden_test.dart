import 'package:comprezza/features/compressor/presentation/home_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../golden_test_utils.dart';

void _noop() {}

void main() {
  setUpAll(loadGoldenFonts);

  testWidgets('home dashboard matches the light golden', (
    WidgetTester tester,
  ) async {
    await captureGolden(
      tester,
      const HomeDashboard(onSelectImages: _noop),
      'home_dashboard_light.png',
    );
  });

  testWidgets('home dashboard matches the dark golden', (
    WidgetTester tester,
  ) async {
    await captureGolden(
      tester,
      const HomeDashboard(onSelectImages: _noop),
      'home_dashboard_dark.png',
      brightness: Brightness.dark,
    );
  });
}
