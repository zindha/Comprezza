import 'package:comprezza/core/services/benchmark_timer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('measures synchronous operation and calculates average', () {
    final LocalBenchmarkTimer timer = LocalBenchmarkTimer();
    final ({int value, BenchmarkMeasurement measurement}) result = timer
        .measureSync<int>('test', () => 42);
    timer.measureSync<int>('test', () => 43);

    expect(result.value, 42);
    expect(result.measurement.name, 'test');
    expect(result.measurement.elapsed, isA<Duration>());
    expect(timer.average('test')?.count, 2);
  });
}
