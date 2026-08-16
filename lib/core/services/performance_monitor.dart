/// Measures named operations without introducing a production telemetry system.
abstract interface class PerformanceMonitor {
  /// Measures an asynchronous operation.
  Future<T> measure<T>(String name, Future<T> Function() operation);

  /// Records a lightweight synchronous event.
  void mark(String name);
}

/// No-op monitor used in profile/release builds unless explicitly enabled.
final class NoOpPerformanceMonitor implements PerformanceMonitor {
  /// Creates a no-op monitor.
  const NoOpPerformanceMonitor();

  @override
  Future<T> measure<T>(String name, Future<T> Function() operation) =>
      operation();

  @override
  void mark(String name) {}
}

/// Development monitor that reports durations through [onMeasurement].
final class DebugPerformanceMonitor implements PerformanceMonitor {
  /// Creates a debug monitor.
  const DebugPerformanceMonitor({required this.onMeasurement});

  /// Receives an operation name and elapsed duration.
  final void Function(String name, Duration elapsed) onMeasurement;

  @override
  Future<T> measure<T>(String name, Future<T> Function() operation) async {
    final Stopwatch stopwatch = Stopwatch()..start();
    try {
      return await operation();
    } finally {
      stopwatch.stop();
      onMeasurement(name, stopwatch.elapsed);
    }
  }

  @override
  void mark(String name) {}
}
