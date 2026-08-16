import 'package:comprezza/core/utils/file_size_formatter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FileSizeFormatter', () {
    test('formats bytes, kilobytes, and megabytes', () {
      expect(FileSizeFormatter.format(512), '512 B');
      expect(FileSizeFormatter.format(2048), '2.0 KB');
      expect(FileSizeFormatter.format(2 * 1024 * 1024), '2.00 MB');
    });

    test('calculates savings and clamps negative savings', () {
      expect(
        FileSizeFormatter.savingsPercent(
          originalBytes: 1000,
          compressedBytes: 250,
        ),
        75,
      );
      expect(
        FileSizeFormatter.savingsPercent(
          originalBytes: 1000,
          compressedBytes: 1200,
        ),
        0,
      );
    });
  });
}
