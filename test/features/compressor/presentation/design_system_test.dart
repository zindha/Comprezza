import 'package:comprezza/features/compressor/presentation/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget host(Widget child) => MaterialApp(
    theme: ThemeData(useMaterial3: true),
    home: Scaffold(body: child),
  );

  test('breakpoints classify phone, tablet, and large widths', () {
    expect(AppBreakpoints.fromWidth(599), AppBreakpoint.phone);
    expect(AppBreakpoints.fromWidth(840), AppBreakpoint.tablet);
    expect(AppBreakpoints.fromWidth(1200), AppBreakpoint.large);
  });

  test('icon styles resolve to distinct Material icon families', () {
    expect(
      AppIcons.resolve(AppIcon.success, style: AppIconStyle.filled),
      isNot(AppIcons.resolve(AppIcon.success, style: AppIconStyle.outlined)),
    );
    expect(
      AppIcons.resolve(AppIcon.success),
      isNot(AppIcons.resolve(AppIcon.success, style: AppIconStyle.outlined)),
    );
  });

  testWidgets('button preserves the minimum touch target and loading state', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      host(const AppButton(label: 'Compress', onPressed: null, loading: true)),
    );

    expect(find.text('Compress'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(
      tester.getSize(find.byType(FilledButton)).height,
      greaterThanOrEqualTo(48),
    );
  });

  testWidgets('responsive layout selects the phone variant', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      host(
        const SizedBox(
          width: 500,
          child: AppResponsiveLayout(
            phone: Text('phone'),
            tablet: Text('tablet'),
            large: Text('large'),
          ),
        ),
      ),
    );

    expect(find.text('phone'), findsOneWidget);
    expect(find.text('tablet'), findsNothing);
    expect(find.text('large'), findsNothing);
  });

  testWidgets('state cards use the active semantic foreground', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      host(
        const AppInformationCard(
          title: 'Complete',
          message: 'Ready to share.',
          tone: AppStateTone.success,
        ),
      ),
    );

    final ThemeData theme = Theme.of(tester.element(find.text('Complete')));
    final Text title = tester.widget<Text>(find.text('Complete'));
    expect(
      title.style?.color,
      AppColors.stateForeground(theme.colorScheme, AppStateTone.success),
    );
  });

  testWidgets('loading animation honors reduced-motion settings', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: host(const AppFade(child: Text('content'))),
      ),
    );

    expect(find.text('content'), findsOneWidget);
  });

  testWidgets('queue progress clamps invalid values', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      host(const AppQueueProgress(completed: 8, total: 3)),
    );

    expect(find.text('3 of 3 complete'), findsOneWidget);
  });

  testWidgets('search clear action propagates an empty query', (
    WidgetTester tester,
  ) async {
    final TextEditingController controller = TextEditingController(text: 'raw');
    String? query;
    await tester.pumpWidget(
      host(
        AppSearchField(
          controller: controller,
          onChanged: (value) => query = value,
        ),
      ),
    );

    await tester.tap(find.byTooltip('Clear search'));
    expect(controller.text, isEmpty);
    expect(query, isEmpty);
    controller.dispose();
  });

  testWidgets('error view exposes retry action', (WidgetTester tester) async {
    var retries = 0;
    await tester.pumpWidget(
      host(
        AppErrorView(
          title: 'Could not process',
          message: 'Try again.',
          onRetry: () => retries++,
        ),
      ),
    );

    await tester.tap(find.text('Try again'));
    expect(retries, 1);
  });
}
