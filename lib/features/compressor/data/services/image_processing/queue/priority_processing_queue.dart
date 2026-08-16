import 'dart:async';

import '../../../../../../core/errors/app_error.dart';
import '../../../../../../core/errors/error_code.dart';
import '../../../../../../core/models/result.dart';
import '../interfaces/processing_engine.dart';
import '../models/image_processing_models.dart';

/// FIFO queue with priority ordering and a configurable concurrency ceiling.
final class PriorityProcessingQueue implements QueueEngine {
  /// Creates a processing queue.
  PriorityProcessingQueue({int maxConcurrent = 1})
    : assert(maxConcurrent > 0),
      _maxConcurrent = maxConcurrent;

  final int _maxConcurrent;
  final List<_PendingEntry<dynamic>> _pending = <_PendingEntry<dynamic>>[];
  int _active = 0;
  int _sequence = 0;
  bool _paused = false;

  /// Number of operations currently executing.
  int get activeCount => _active;

  /// Number of operations waiting to execute.
  int get pendingCount => _pending.length;

  @override
  Future<Result<T>> enqueue<T>(
    QueuePriority priority,
    Future<Result<T>> Function(CancellationToken token) operation, {
    CancellationToken? token,
    int maxRetries = 0,
  }) {
    final CancellationToken effectiveToken = token ?? CancellationToken();
    final _PendingEntry<T> entry = _PendingEntry<T>(
      priority: priority,
      operation: operation,
      token: effectiveToken,
      sequence: _sequence++,
      maxRetries: maxRetries < 0 ? 0 : maxRetries,
    );
    _pending.add(entry);
    _pending.sort(_compare);
    _pump();
    return entry.completer.future;
  }

  int _compare(_PendingEntry<dynamic> a, _PendingEntry<dynamic> b) {
    final int priority = b.priority.index.compareTo(a.priority.index);
    return priority == 0 ? a.sequence.compareTo(b.sequence) : priority;
  }

  @override
  void pause() => _paused = true;

  @override
  void resume() {
    _paused = false;
    _pump();
  }

  void _pump() {
    while (!_paused && _active < _maxConcurrent && _pending.isNotEmpty) {
      final _PendingEntry<dynamic> entry = _pending.removeAt(0);
      _active++;
      unawaited(_runEntry(entry));
    }
  }

  Future<void> _runEntry(_PendingEntry<dynamic> entry) async {
    try {
      await entry.run();
    } finally {
      _active--;
      _pump();
    }
  }
}

final class _PendingEntry<T> {
  _PendingEntry({
    required this.priority,
    required this.operation,
    required this.token,
    required this.sequence,
    required this.maxRetries,
  });

  final QueuePriority priority;
  final Future<Result<T>> Function(CancellationToken token) operation;
  final CancellationToken token;
  final int sequence;
  final int maxRetries;
  int attempts = 0;
  final Completer<Result<T>> completer = Completer<Result<T>>();

  Future<void> run() async {
    try {
      if (token.isCancelled) {
        completer.complete(
          Result<T>.failure(
            const AppError(
              code: ErrorCode.cancelled,
              message: 'The queued operation was cancelled.',
            ),
          ),
        );
        return;
      }
      final Result<T> result = await operation(token);
      if (result case Failure<T>() when attempts < maxRetries) {
        attempts++;
        await run();
        return;
      }
      completer.complete(result);
    } catch (error, stackTrace) {
      completer.complete(
        Result<T>.failure(
          AppError(
            code: ErrorCode.unknown,
            message: 'The queued operation failed.',
            cause: error,
            stackTrace: stackTrace,
          ),
        ),
      );
    }
  }
}
