import 'package:comprezza/core/utilities/formatters.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formats sizes and dimensions', () {
    expect(Formatters.fileSize(1024), '1.0 KB');
    expect(Formatters.dimensions(1920, 1080), '1920 × 1080');
  });

  test('calculates savings, ratios, percentages, and upload time', () {
    expect(
      Formatters.storageSavingsPercent(
        originalBytes: 1000,
        compressedBytes: 250,
      ),
      75,
    );
    expect(
      Formatters.compressionRatio(originalBytes: 1000, compressedBytes: 250),
      .25,
    );
    expect(Formatters.percentage(74), '74%');
    expect(
      Formatters.uploadTime(bytes: 1000, bitsPerSecond: 1000),
      const Duration(seconds: 8),
    );
  });
}
