import 'dart:developer' as developer;
import 'dart:io';

/// Immutable measurement returned by a benchmark.
class BenchmarkMeasurement {
  /// Creates a benchmark measurement.
  const BenchmarkMeasurement({
    required this.name,
    required this.elapsed,
    this.memoryBeforeBytes,
    this.memoryAfterBytes,
  });

  /// Operation name.
  final String name;

  /// Elapsed wall-clock duration.
  final Duration elapsed;

  /// RSS before the operation when available.
  final int? memoryBeforeBytes;

  /// RSS after the operation when available.
  final int? memoryAfterBytes;

  /// Approximate RSS delta when both samples exist.
  int? get memoryDeltaBytes =>
      memoryBeforeBytes == null || memoryAfterBytes == null
      ? null
      : memoryAfterBytes! - memoryBeforeBytes!;
}

/// Aggregate timing summary for repeated named operations.
class BenchmarkSummary {
  /// Creates a benchmark summary.
  const BenchmarkSummary({
    required this.name,
    required this.count,
    required this.average,
  });

  /// Operation name.
  final String name;

  /// Number of recorded measurements.
  final int count;

  /// Average elapsed duration.
  final Duration average;
}

/// Measures local operation timing without analytics or network reporting.
abstract interface class BenchmarkTimer {
  /// Measures an asynchronous operation.
  Future<({T value, BenchmarkMeasurement measurement})> measure<T>(
    String name,
    Future<T> Function() operation,
  );

  /// Measures a synchronous operation.
  ({T value, BenchmarkMeasurement measurement}) measureSync<T>(
    String name,
    T Function() operation,
  );

  /// Returns the average of measurements recorded for [name].
  BenchmarkSummary? average(String name);
}

/// Stopwatch/DevTools-backed benchmark implementation.
final class LocalBenchmarkTimer implements BenchmarkTimer {
  /// Creates a local benchmark timer.
  LocalBenchmarkTimer({this.enableTimeline = false});

  /// Whether to emit local DevTools timeline events.
  final bool enableTimeline;
  final Map<String, List<Duration>> _samples = <String, List<Duration>>{};

  @override
  Future<({T value, BenchmarkMeasurement measurement})> measure<T>(
    String name,
    Future<T> Function() operation,
  ) async {
    final Stopwatch stopwatch = Stopwatch()..start();
    final int? before = _rss();
    try {
      final T value = await operation();
      stopwatch.stop();
      final BenchmarkMeasurement measurement = BenchmarkMeasurement(
        name: name,
        elapsed: stopwatch.elapsed,
        memoryBeforeBytes: before,
        memoryAfterBytes: _rss(),
      );
      _record(measurement);
      return (value: value, measurement: measurement);
    } finally {
      // Async operations use Stopwatch so timeline events never cross await boundaries.
    }
  }

  @override
  ({T value, BenchmarkMeasurement measurement}) measureSync<T>(
    String name,
    T Function() operation,
  ) {
    final Stopwatch stopwatch = Stopwatch()..start();
    final int? before = _rss();
    final T value = enableTimeline
        ? developer.Timeline.timeSync(name, operation)
        : operation();
    stopwatch.stop();
    final BenchmarkMeasurement measurement = BenchmarkMeasurement(
      name: name,
      elapsed: stopwatch.elapsed,
      memoryBeforeBytes: before,
      memoryAfterBytes: _rss(),
    );
    _record(measurement);
    return (value: value, measurement: measurement);
  }

  @override
  BenchmarkSummary? average(String name) {
    final List<Duration>? samples = _samples[name];
    if (samples == null || samples.isEmpty) return null;
    final int totalMicros = samples.fold(
      0,
      (int sum, Duration value) => sum + value.inMicroseconds,
    );
    return BenchmarkSummary(
      name: name,
      count: samples.length,
      average: Duration(microseconds: totalMicros ~/ samples.length),
    );
  }

  void _record(BenchmarkMeasurement measurement) {
    (_samples[measurement.name] ??= <Duration>[]).add(measurement.elapsed);
  }

  int? _rss() {
    try {
      return ProcessInfo.currentRss;
    } on Object {
      return null;
    }
  }
}
