/// Pure formatting and calculation utilities.
abstract final class Formatters {
  /// Formats bytes as B, KB, MB, or GB.
  static String fileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  /// Formats a duration as milliseconds, seconds, or minutes.
  static String duration(Duration duration) {
    if (duration.inMilliseconds < 1000) return '${duration.inMilliseconds} ms';
    if (duration.inSeconds < 60) {
      return '${duration.inSeconds}.${(duration.inMilliseconds % 1000) ~/ 100} s';
    }
    return '${duration.inMinutes} min ${duration.inSeconds % 60} s';
  }

  /// Formats dimensions as width × height.
  static String dimensions(int width, int height) => '$width × $height';

  /// Formats a percentage with a clamped range.
  static String percentage(num value) =>
      '${value.clamp(0, 100).toStringAsFixed(0)}%';

  /// Returns a compressed/original ratio.
  static double compressionRatio({
    required int originalBytes,
    required int compressedBytes,
  }) {
    if (originalBytes <= 0) return 0;
    return compressedBytes / originalBytes;
  }

  /// Returns the percentage of bytes saved.
  static int storageSavingsPercent({
    required int originalBytes,
    required int compressedBytes,
  }) {
    if (originalBytes <= 0) return 0;
    return ((originalBytes - compressedBytes) / originalBytes * 100)
        .round()
        .clamp(0, 100)
        .toInt();
  }

  /// Estimates upload duration from bytes and bits-per-second bandwidth.
  static Duration uploadTime({required int bytes, required int bitsPerSecond}) {
    if (bytes <= 0 || bitsPerSecond <= 0) return Duration.zero;
    return Duration(milliseconds: (bytes * 8 / bitsPerSecond * 1000).round());
  }

  /// Formats a date using a stable local numeric representation.
  static String date(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
}
