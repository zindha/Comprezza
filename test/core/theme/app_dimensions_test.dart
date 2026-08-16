import 'package:comprezza/core/theme/app_dimensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('uses calm phone, tablet, and wide page gutters', () {
    expect(AppDimensions.pageHorizontal(390), AppDimensions.spacingMd);
    expect(AppDimensions.pageHorizontal(840), AppDimensions.spacingLg);
    expect(AppDimensions.pageHorizontal(1200), AppDimensions.spacingXl);
  });

  test('pageInsets keeps system insets out of the shared content token', () {
    expect(
      AppDimensions.pageInsets(390),
      const EdgeInsets.fromLTRB(16, 16, 16, 32),
    );
    expect(
      AppDimensions.pageInsets(900, top: 8, bottom: 48),
      const EdgeInsets.fromLTRB(24, 8, 24, 48),
    );
  });
}
