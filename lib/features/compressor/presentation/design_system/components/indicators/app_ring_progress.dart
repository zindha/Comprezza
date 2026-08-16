import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A circular progress ring with centered content.
///
/// Used for savings, completion, and achievement surfaces where a plain
/// percentage bar would read as too mechanical.
class AppRingProgress extends StatelessWidget {
  /// Creates a ring progress.
  const AppRingProgress({
    required this.progress,
    required this.child,
    this.size = 88,
    this.strokeWidth = 8,
    this.color,
    this.backgroundColor,
    super.key,
  });

  /// Progress from 0 to 1; values outside are clamped.
  final double progress;

  /// Centered content (for example the percentage text).
  final Widget child;

  /// Outer diameter.
  final double size;

  /// Ring stroke thickness.
  final double strokeWidth;

  /// Foreground ring color; defaults to the theme primary.
  final Color? color;

  /// Background track color; defaults to a translucent primary.
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final double clamped = progress.clamp(0, 1).toDouble();
    final Color ringColor = color ?? colors.primary;
    return Semantics(
      value: '${(clamped * 100).round()}%',
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _RingPainter(
            progress: clamped,
            color: ringColor,
            backgroundColor:
                backgroundColor ?? ringColor.withValues(alpha: .16),
            strokeWidth: strokeWidth,
          ),
          child: Center(child: child),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
    required this.strokeWidth,
  });

  final double progress;
  final Color color;
  final Color backgroundColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = size.center(Offset.zero);
    final double radius = (size.shortestSide - strokeWidth) / 2;
    final Paint track = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, track);
    if (progress <= 0) return;
    final Paint fill = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      progress * 2 * math.pi,
      false,
      fill,
    );
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.color != color ||
      oldDelegate.backgroundColor != backgroundColor ||
      oldDelegate.strokeWidth != strokeWidth;
}
