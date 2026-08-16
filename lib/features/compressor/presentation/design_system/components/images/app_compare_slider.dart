import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../../core/theme/app_brand_colors.dart';
import '../../tokens/tokens.dart';

/// The signature Comprezza comparison control.
///
/// A draggable divider reveals the [after] image over [before], with a refined
/// circular grip, quiet corner labels, and edge-safe interaction. The handle
/// reports its position through [split] so callers can persist the value; the
/// widget itself animates programmatic changes.
class AppCompareSlider extends StatefulWidget {
  /// Creates a compare slider.
  const AppCompareSlider({
    required this.before,
    required this.after,
    this.split = .5,
    this.beforeLabel,
    this.afterLabel,
    this.beforeCaption,
    this.afterCaption,
    this.aspectRatio = 1,
    this.onSplitChanged,
    super.key,
  });

  /// Base image revealed on the left side.
  final Widget before;

  /// Overlay image revealed on the right side.
  final Widget after;

  /// Handle position from 0 to 1; values outside are clamped.
  final double split;

  /// Quiet label shown over the before side (e.g. "Original").
  final String? beforeLabel;

  /// Quiet label shown over the after side (e.g. "Compressed").
  final String? afterLabel;

  /// Optional size caption under the before label.
  final String? beforeCaption;

  /// Optional size caption under the after label.
  final String? afterCaption;

  /// Base aspect ratio of the comparison surface.
  final double aspectRatio;

  /// Called while the user drags the handle; not called for programmatic moves.
  final ValueChanged<double>? onSplitChanged;

  @override
  State<AppCompareSlider> createState() => _AppCompareSliderState();
}

class _AppCompareSliderState extends State<AppCompareSlider> {
  static const double _edgePadding = 14;

  late double _split;

  @override
  void initState() {
    super.initState();
    _split = widget.split.clamp(0, 1).toDouble();
  }

  @override
  void didUpdateWidget(covariant AppCompareSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.split != widget.split) {
      _split = widget.split.clamp(0, 1).toDouble();
    }
  }

  void _updateFromDrag(
    BuildContext context,
    Offset localPosition,
    double width,
  ) {
    if (width <= 0) return;
    final double span = width - _edgePadding * 2;
    if (span <= 0) return;
    final double next = ((localPosition.dx - _edgePadding) / span).clamp(0, 1);
    setState(() => _split = next);
    widget.onSplitChanged?.call(next);
  }

  void _handleTap(BuildContext context, Offset localPosition, double width) {
    if (width <= 0) return;
    final double span = width - _edgePadding * 2;
    if (span <= 0) return;
    final double next = ((localPosition.dx - _edgePadding) / span).clamp(0, 1);
    setState(() => _split = next);
    widget.onSplitChanged?.call(next);
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final bool isDark = colors.brightness == Brightness.dark;
    final double split = _split;
    return Semantics(
      label: '${widget.beforeLabel ?? ''} ${widget.afterLabel ?? ''}',
      value: '${(split * 100).round()}%',
      increasedValue: '${((split + .05) * 100).round()}%',
      decreasedValue: '${((split - .05) * 100).round()}%',
      slider: true,
      onIncrease: () => _stepSplit(.05),
      onDecrease: () => _stepSplit(-.05),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double width = constraints.maxWidth;
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragStart: (DragStartDetails details) {
              HapticFeedback.selectionClick();
              _updateFromDrag(context, details.localPosition, width);
            },
            onHorizontalDragUpdate: (DragUpdateDetails details) {
              _updateFromDrag(context, details.localPosition, width);
            },
            onHorizontalDragEnd: (_) => HapticFeedback.selectionClick(),
            onTapDown: (TapDownDetails details) {
              _handleTap(context, details.localPosition, width);
            },
            child: ClipRRect(
              borderRadius: AppRadii.large,
              child: AspectRatio(
                aspectRatio: widget.aspectRatio,
                child: Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    widget.before,
                    // Right slice of the after image. The child is laid out at
                    // full width (so it is never squeezed) and the clip reveals
                    // only the portion right of the handle. Positioned with an
                    // explicit width keeps the constraints loose, which a
                    // widthFactor on Align would not do inside this
                    // StackFit.expand surface.
                    Positioned(
                      top: 0,
                      bottom: 0,
                      right: 0,
                      width: width * (1 - split),
                      child: ClipRect(
                        child: OverflowBox(
                          alignment: Alignment.centerRight,
                          minWidth: width,
                          maxWidth: width,
                          child: widget.after,
                        ),
                      ),
                    ),
                    // Hairline divider at the handle.
                    Positioned(
                      left: split * width,
                      top: 0,
                      bottom: 0,
                      child: IgnorePointer(
                        child: Container(
                          width: 1.5,
                          color: AppBrandColors.cyan,
                        ),
                      ),
                    ),
                    // Refined grip handle, centered on the divider.
                    Positioned(
                      left: split * width - 20,
                      top: 0,
                      bottom: 0,
                      child: IgnorePointer(
                        child: Center(
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: colors.surface,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppBrandColors.cyan,
                                width: 1.4,
                              ),
                              boxShadow: <BoxShadow>[
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: .22),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.unfold_more_rounded,
                              size: 20,
                              color: isDark
                                  ? AppBrandColors.cyan
                                  : AppBrandColors.cyanDark,
                            ),
                          ),
                        ),
                      ),
                    ),
                    _CornerLabel(
                      alignment: Alignment.topLeft,
                      label: widget.beforeLabel,
                      caption: widget.beforeCaption,
                    ),
                    _CornerLabel(
                      alignment: Alignment.topRight,
                      label: widget.afterLabel,
                      caption: widget.afterCaption,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _stepSplit(double delta) {
    final double next = (_split + delta).clamp(0, 1);
    if (next == _split) return;
    setState(() => _split = next);
    widget.onSplitChanged?.call(next);
  }
}

class _CornerLabel extends StatelessWidget {
  const _CornerLabel({
    required this.alignment,
    required this.label,
    required this.caption,
  });

  final Alignment alignment;
  final String? label;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    if (label == null) return const SizedBox.shrink();
    final bool isLeft = alignment == Alignment.topLeft;
    return Align(
      alignment: alignment,
      child: Padding(
        padding: EdgeInsets.only(
          left: isLeft ? AppSpacing.sm : 0,
          right: isLeft ? 0 : AppSpacing.sm,
          top: AppSpacing.sm,
        ),
        child: Column(
          crossAxisAlignment: isLeft
              ? CrossAxisAlignment.start
              : CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs - 2,
              ),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: .55),
                borderRadius: AppRadii.small,
              ),
              child: Text(
                label!,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  letterSpacing: .6,
                ),
              ),
            ),
            if (caption != null) ...<Widget>[
              const SizedBox(height: AppSpacing.xxs),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: .4),
                  borderRadius: AppRadii.small,
                ),
                child: Text(
                  caption!,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.white.withValues(alpha: .92),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
