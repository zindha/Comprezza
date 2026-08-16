import 'package:comprezza/core/errors/app_error.dart';
import 'package:comprezza/core/errors/error_code.dart';
import 'package:comprezza/core/models/result.dart';
import 'package:comprezza/core/services/startup_initialization_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('runs startup tasks in order', () async {
    final List<String> calls = <String>[];
    final DefaultStartupInitializationService service =
        DefaultStartupInitializationService(
          tasks: <StartupTask>[_Task('one', calls), _Task('two', calls)],
        );

    final Result<void> result = await service.initialize();

    expect(result.isSuccess, isTrue);
    expect(calls, <String>['one', 'two']);
  });

  test('stops after the first failure', () async {
    final List<String> calls = <String>[];
    final DefaultStartupInitializationService service =
        DefaultStartupInitializationService(
          tasks: <StartupTask>[
            _Task('one', calls, fail: true),
            _Task('two', calls),
          ],
        );

    final Result<void> result = await service.initialize();

    expect(result.isFailure, isTrue);
    expect(calls, <String>['one']);
  });

  test('retries after a failed initialization result', () async {
    final _RetryTask task = _RetryTask();
    final DefaultStartupInitializationService service =
        DefaultStartupInitializationService(tasks: <StartupTask>[task]);

    expect((await service.initialize()).isFailure, isTrue);
    expect((await service.initialize()).isSuccess, isTrue);
    expect(task.runs, 2);
  });

  test('shares one in-flight initialization and caches its result', () async {
    final _DelayedTask task = _DelayedTask();
    final DefaultStartupInitializationService service =
        DefaultStartupInitializationService(tasks: <StartupTask>[task]);

    final Future<Result<void>> first = service.initialize();
    final Future<Result<void>> second = service.initialize();

    expect(await first, isA<Success<void>>());
    expect(await second, isA<Success<void>>());
    expect(task.runs, 1);
  });
}

class _Task implements StartupTask {
  _Task(this.name, this.calls, {this.fail = false});

  @override
  final String name;
  final List<String> calls;
  final bool fail;

  @override
  Future<Result<void>> run() async {
    calls.add(name);
    if (fail) {
      return const Result<void>.failure(
        AppError(code: ErrorCode.unknown, message: 'failed'),
      );
    }
    return const Result<void>.success(null);
  }
}

class _RetryTask implements StartupTask {
  int runs = 0;

  @override
  String get name => 'retry';

  @override
  Future<Result<void>> run() async {
    runs++;
    if (runs == 1) {
      return const Result<void>.failure(
        AppError(code: ErrorCode.unknown, message: 'failed'),
      );
    }
    return const Result<void>.success(null);
  }
}

class _DelayedTask implements StartupTask {
  int runs = 0;

  @override
  String get name => 'delayed';

  @override
  Future<Result<void>> run() async {
    runs++;
    await Future<void>.delayed(Duration.zero);
    return const Result<void>.success(null);
  }
}
