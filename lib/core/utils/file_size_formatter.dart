/// Formats byte counts for compact, human-readable UI labels.
abstract final class FileSizeFormatter {
  /// Returns a rounded value in B, KB, or MB.
  static String format(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  /// Returns the percentage of bytes removed, clamped to a useful range.
  static int savingsPercent({
    required int originalBytes,
    required int compressedBytes,
  }) {
    if (originalBytes <= 0) return 0;
    final double saved =
        (originalBytes - compressedBytes) / originalBytes * 100;
    return saved.round().clamp(0, 100).toInt();
  }
}
