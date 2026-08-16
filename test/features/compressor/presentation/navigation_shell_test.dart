import 'package:comprezza/app/navigation/main_navigation_shell.dart';
import 'package:comprezza/app/routing/app_routes.dart';
import 'package:comprezza/app/theme/app_theme_builder.dart';
import 'package:comprezza/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget host({EdgeInsets padding = EdgeInsets.zero}) {
    return MediaQuery(
      data: MediaQueryData(
        size: const Size(390, 844),
        padding: padding,
        viewPadding: padding,
        disableAnimations: true,
      ),
      child: MaterialApp(
        theme: AppThemeBuilder.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const MainNavigationShell(
          currentLocation: AppRoutes.home,
          child: Text('destination'),
        ),
      ),
    );
  }

  testWidgets('bottom navigation owns the Android bottom inset once', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(host(padding: const EdgeInsets.only(bottom: 24)));

    final Size size = tester.getSize(find.byType(AppBottomNavigation));
    expect(size.height, 88);
  });

  testWidgets('bottom navigation has no extra inset on a flat-edge device', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(host());

    final Size size = tester.getSize(find.byType(AppBottomNavigation));
    expect(size.height, 64);
  });
}
