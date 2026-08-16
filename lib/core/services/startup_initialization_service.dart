import '../errors/app_error.dart';
import '../errors/error_code.dart';
import '../errors/error_mapper.dart';
import '../errors/result_error_adapter.dart';
import '../models/result.dart';

/// One idempotent task executed during application startup.
abstract interface class StartupTask {
  /// Stable task name used in diagnostics.
  String get name;

  /// Executes this task.
  Future<Result<void>> run();
}

/// Runs startup tasks in deterministic order before the app is presented.
abstract interface class StartupInitializationService {
  /// Runs all registered startup tasks.
  Future<Result<void>> initialize();
}

/// Sequential startup runner that stops on the first failed task.
final class DefaultStartupInitializationService
    implements StartupInitializationService {
  /// Creates a startup runner.
  DefaultStartupInitializationService({required this.tasks});

  /// Ordered startup tasks.
  final List<StartupTask> tasks;
  Future<Result<void>>? _initialization;

  @override
  Future<Result<void>> initialize() {
    final Future<Result<void>>? current = _initialization;
    if (current != null) return current;
    final Future<Result<void>> result = _runTasks();
    _initialization = result;
    return result.then((Result<void> value) {
      if (value.isFailure) _initialization = null;
      return value;
    });
  }

  Future<Result<void>> _runTasks() async {
    try {
      for (final StartupTask task in tasks) {
        final Result<void> result = await task.run();
        if (result case Failure<void>(error: final AppError error)) {
          return Result<void>.failure(
            AppError(
              code: ErrorCode.startupTaskFailed,
              message: 'Startup task "${task.name}" failed.',
              cause: error,
              stackTrace: error.stackTrace,
              isRecoverable: error.isRecoverable,
            ),
          );
        }
      }
      return const Result<void>.success(null);
    } catch (error, stackTrace) {
      return Result<void>.failure(
        ResultErrorAdapter.fromException(ErrorMapper.map(error, stackTrace)),
      );
    }
  }
}

/// Adapts a cache cleanup service into a startup task.
final class CacheCleanupStartupTask implements StartupTask {
  /// Creates the cache cleanup startup task.
  const CacheCleanupStartupTask({required this.cleanup});

  /// Cleanup operation.
  final Future<Result<int>> Function() cleanup;

  @override
  String get name => 'cache_cleanup';

  @override
  Future<Result<void>> run() async {
    final Result<int> result = await cleanup();
    return result.fold(
      onSuccess: (_) => const Result<void>.success(null),
      onFailure: (AppError error) => Result<void>.failure(error),
    );
  }
}
