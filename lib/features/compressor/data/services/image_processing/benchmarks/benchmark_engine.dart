import '../../../../../../core/errors/app_error.dart';
import '../../../../../../core/errors/error_code.dart';
import '../../../../../../core/models/result.dart';
import '../../../../../../core/services/benchmark_timer.dart';
import '../../../../../../core/services/file_system_service.dart';
import '../interfaces/processing_engine.dart';
import '../models/image_processing_models.dart';

/// Benchmark adapter that uses the existing development-only timer.
final class LocalBenchmarkEngine implements BenchmarkEngine {
  /// Creates a benchmark engine.
  const LocalBenchmarkEngine({required this.timer, required this.fileSystem});

  /// Injected local timer.
  final BenchmarkTimer timer;

  /// Injected filesystem boundary for future safe input metrics.
  final FileSystemService fileSystem;

  @override
  Future<Result<({ProcessingOutput output, ProcessingBenchmark benchmark})>>
  measure(
    String name,
    String sourcePath,
    int? inputBytes,
    Future<Result<ProcessingOutput>> Function() operation,
  ) async {
    try {
      final result = await timer.measure(name, operation);
      return result.value.fold(
        onSuccess: (ProcessingOutput output) {
          final int input = inputBytes ?? 0;
          final ProcessingBenchmark benchmark = ProcessingBenchmark(
            name: name,
            elapsed: result.measurement.elapsed,
            inputBytes: input,
            outputBytes: output.bytes,
            compressionRatio: input == 0 || output.bytes == 0
                ? 0
                : input / output.bytes,
            memoryDeltaBytes: result.measurement.memoryDeltaBytes,
            qualityScore: output.quality / 100,
          );
          return Result<
            ({ProcessingOutput output, ProcessingBenchmark benchmark})
          >.success((output: output, benchmark: benchmark));
        },
        onFailure: (AppError error) =>
            Result<
              ({ProcessingOutput output, ProcessingBenchmark benchmark})
            >.failure(error),
      );
    } catch (error, stackTrace) {
      return Result<
        ({ProcessingOutput output, ProcessingBenchmark benchmark})
      >.failure(
        AppError(
          code: ErrorCode.unknown,
          message: 'Benchmark execution failed.',
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }
}
