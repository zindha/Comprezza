import 'package:flutter/material.dart';

/// Wraps [child] with a subtle press-scale micro-interaction.
///
/// Scales the child down slightly while the pointer is held and springs it
/// back on release. The animation is fast and respects reduced-motion
/// settings; tap semantics and ripple feedback stay owned by the child's own
/// Material/InkWell so accessibility is unchanged.
class AppPressable extends StatefulWidget {
  /// Creates a pressable wrapper.
  const AppPressable({
    required this.child,
    this.enabled = true,
    this.scale = .985,
    super.key,
  });

  /// The surface that receives press feedback.
  final Widget child;

  /// When false, the press animation is disabled.
  final bool enabled;

  /// Target scale while pressed.
  final double scale;

  @override
  State<AppPressable> createState() => _AppPressableState();
}

class _AppPressableState extends State<AppPressable> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bool reduceMotion = MediaQuery.disableAnimationsOf(context);
    final bool interactive = widget.enabled;
    return Listener(
      onPointerDown: interactive ? (_) => _setPressed(true) : null,
      onPointerUp: interactive && _pressed ? (_) => _setPressed(false) : null,
      onPointerCancel: interactive && _pressed
          ? (_) => _setPressed(false)
          : null,
      child: AnimatedScale(
        scale: _pressed ? widget.scale : 1,
        duration: reduceMotion ? Duration.zero : AppPressableDurations.press,
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }

  void _setPressed(bool value) {
    if (!mounted || _pressed == value) return;
    setState(() => _pressed = value);
  }
}

/// Motion durations shared by press feedback.
abstract final class AppPressableDurations {
  /// Press-down spring duration.
  static const Duration press = Duration(milliseconds: 110);

  /// Release duration.
  static const Duration release = Duration(milliseconds: 180);
}
