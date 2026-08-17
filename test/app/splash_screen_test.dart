import 'package:comprezza/app/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Minimal harness that hosts the splash inside a MaterialApp with a stub
/// home route so the handoff navigation can be observed.
class _SplashHost extends StatelessWidget {
  const _SplashHost({required this.splash, required this.onHomeReached});

  final Widget splash;
  final VoidCallback onHomeReached;

  @override
  Widget build(BuildContext context) {
    final GoRouter router = GoRouter(
      initialLocation: '/splash',
      routes: <RouteBase>[
        GoRoute(
          path: '/splash',
          builder: (BuildContext context, GoRouterState state) => splash,
        ),
        GoRoute(
          path: '/',
          builder: (BuildContext context, GoRouterState state) {
            // Notify the test the splash handed off to home.
            WidgetsBinding.instance.addPostFrameCallback(
              (_) => onHomeReached(),
            );
            return const Scaffold(body: Center(child: Text('Home reached')));
          },
        ),
      ],
    );
    return MaterialApp.router(routerConfig: router);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('splash renders the app name and tagline', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _SplashHost(splash: const SplashScreen(), onHomeReached: () {}),
    );
    await tester.pump();

    expect(find.text('Comprezza'), findsOneWidget);
    expect(find.text('Compress. Convert. Optimize.'), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
  });

  testWidgets('splash hands off to home after the minimum duration', (
    WidgetTester tester,
  ) async {
    bool homeReached = false;
    await tester.pumpWidget(
      _SplashHost(
        splash: const SplashScreen(
          minimumDuration: Duration(milliseconds: 300),
        ),
        onHomeReached: () => homeReached = true,
      ),
    );

    // Before the minimum duration elapses the splash is still visible.
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Comprezza'), findsOneWidget);
    expect(homeReached, isFalse);

    // After the duration plus the fade the handoff has happened.
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(homeReached, isTrue);
    expect(find.text('Home reached'), findsOneWidget);
  });

  testWidgets('splash skips the branding wait when reduce motion is on', (
    WidgetTester tester,
  ) async {
    bool homeReached = false;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: _SplashHost(
          splash: const SplashScreen(
            minimumDuration: Duration(milliseconds: 10000),
          ),
          onHomeReached: () => homeReached = true,
        ),
      ),
    );
    await tester.pump();
    await tester.pumpAndSettle();

    expect(homeReached, isTrue);
    expect(find.text('Home reached'), findsOneWidget);
  });
}
