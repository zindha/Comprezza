import 'package:flutter/material.dart';

import '../../tokens/tokens.dart';

/// Builds one of three layouts based on available width.
class AppResponsiveLayout extends StatelessWidget {
  const AppResponsiveLayout({
    required this.phone,
    this.tablet,
    this.large,
    super.key,
  });
  final Widget phone;
  final Widget? tablet;
  final Widget? large;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (BuildContext context, BoxConstraints constraints) {
      final AppBreakpoint breakpoint = AppBreakpoints.fromWidth(
        constraints.maxWidth,
      );
      return switch (breakpoint) {
        AppBreakpoint.large => large ?? tablet ?? phone,
        AppBreakpoint.tablet => tablet ?? phone,
        AppBreakpoint.phone => phone,
      };
    },
  );
}

/// A token-driven responsive grid with intrinsic-height children.
///
/// `GridView.count` gives every child a forced aspect ratio, which is a poor
/// fit for localized, text-scaled action cards. This wrapping layout keeps the
/// same column behavior while allowing each row to grow to its tallest card.
class AppResponsiveGrid extends StatelessWidget {
  const AppResponsiveGrid({
    required this.children,
    this.phoneColumns = 1,
    this.tabletColumns = 2,
    this.largeColumns = 3,
    this.spacing = AppSpacing.md,
    super.key,
  });
  final List<Widget> children;
  final int phoneColumns;
  final int tabletColumns;
  final int largeColumns;
  final double spacing;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (BuildContext context, BoxConstraints constraints) {
      final int columns = switch (AppBreakpoints.fromWidth(
        constraints.maxWidth,
      )) {
        AppBreakpoint.phone => phoneColumns,
        AppBreakpoint.tablet => tabletColumns,
        AppBreakpoint.large => largeColumns,
      };
      final double width = constraints.maxWidth.isFinite
          ? constraints.maxWidth
          : MediaQuery.sizeOf(context).width;
      final double itemWidth = ((width - spacing * (columns - 1)) / columns)
          .clamp(0, width)
          .toDouble();
      return Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: children
            .map((Widget child) => SizedBox(width: itemWidth, child: child))
            .toList(growable: false),
      );
    },
  );
}
