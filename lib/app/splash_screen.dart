import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/app_constants.dart';
import 'routing/app_routes.dart';

/// Full-screen branded launch surface shown after the native splash.
///
/// The native Android 12+ splash always masks its icon into a circle, which
/// distorts the square logo. This screen renders the real logo asset unmasked
/// together with the product name and tagline, then hands off to home.
class SplashScreen extends StatefulWidget {
  /// Creates the splash screen. [minimumDuration] is how long the branding
  /// stays visible before navigating to the home destination.
  const SplashScreen({
    super.key,
    this.minimumDuration = const Duration(milliseconds: 1400),
  });

  /// Minimum time the branding remains on screen before handoff.
  final Duration minimumDuration;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;
  bool _leaving = false;
  @override
  void initState() {
    super.initState();
    // MediaQuery cannot be read before initState completes, so the timer (and
    // the reduce-motion check it depends on) starts in didChangeDependencies.
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _startTimer();
  }

  void _startTimer() {
    // Respect the platform reduce-motion preference: skip the minimum-branding
    // wait so the app hands off to home as fast as possible.
    final bool reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final Duration delay = reduceMotion
        ? Duration.zero
        : widget.minimumDuration;
    _timer?.cancel();
    _timer = Timer(delay, _goHome);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _goHome() {
    if (!mounted || _leaving) return;
    _leaving = true;
    context.go(AppRoutes.homeLocation);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final bool reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final Widget content = Scaffold(
      // Matches the native splash backgrounds (comprezza_splash_background is
      // #F6F7FB light / #0B1226 dark) for a seamless native-to-Flutter handoff.
      backgroundColor: colors.surface,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              // Bound the decode to the display size: the source logo is large
              // and must never be decoded at full resolution on startup.
              Image.asset(
                'assets/brand/logo.png',
                width: 120,
                height: 120,
                cacheWidth: (120 * MediaQuery.of(context).devicePixelRatio)
                    .round(),
              ),
              const SizedBox(height: 24),
              Text(
                AppConstants.appName,
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Compress. Convert. Optimize.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (reduceMotion) return content;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
      builder: (BuildContext context, double opacity, Widget? child) =>
          Opacity(opacity: opacity, child: child),
      child: content,
    );
  }
}
