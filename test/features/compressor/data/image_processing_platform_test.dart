import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:comprezza/core/errors/app_error.dart';
import 'package:comprezza/core/errors/error_code.dart';
import 'package:comprezza/core/models/result.dart';
import 'package:comprezza/core/services/file_system_service.dart';
import 'package:comprezza/features/compressor/data/services/image_processing/analyzers/heuristic_analyzer_engine.dart';
import 'package:comprezza/features/compressor/data/services/image_processing/engine_manager.dart';
import 'package:comprezza/features/compressor/data/services/image_processing/estimators/estimation_engine.dart';
import 'package:comprezza/features/compressor/data/services/image_processing/interfaces/engine_registry.dart';
import 'package:comprezza/features/compressor/data/services/image_processing/interfaces/processing_engine.dart';
import 'package:comprezza/features/compressor/data/services/image_processing/models/image_processing_models.dart';
import 'package:comprezza/features/compressor/data/services/image_processing/queue/priority_processing_queue.dart';
import 'package:comprezza/features/compressor/data/services/image_processing/resizers/resize_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('format resolution and presets remain deterministic', () {
    expect(ImageFormatX.fromPath('photo.JPEG'), ImageFormat.jpeg);
    expect(ImageFormatX.fromPath('image.webp')?.isImplemented, isTrue);
    expect(ImageFormatX.fromPath('image.avif')?.isImplemented, isFalse);
    expect(
      const CompressionOptions(
        preset: CompressionPreset.extremeCompression,
      ).effectiveQuality,
      20,
    );
  });

  test('estimator returns bounded savings and quality scores', () {
    const LocalEstimationEngine engine = LocalEstimationEngine();
    final Result<Estimation> result = engine.estimate(
      const EstimationRequest(
        originalBytes: 1_000_000,
        quality: 72,
        format: ImageFormat.jpeg,
        uploadBytesPerSecond: 100_000,
      ),
    );

    expect(result, isA<Success<Estimation>>());
    final Estimation estimation = (result as Success<Estimation>).value;
    expect(estimation.estimatedOutputBytes, lessThan(1_000_000));
    expect(estimation.storageSavingsRatio, inInclusiveRange(0, 1));
    expect(estimation.qualityScore, closeTo(0.72, 0.001));
  });

  test('analyzer keeps zero-byte estimates finite', () async {
    const HeuristicImageAnalyzerEngine analyzer =
        HeuristicImageAnalyzerEngine();
    final Result<ImageAnalysis> result = await analyzer.analyze(
      const AnalysisRequest('unknown.jpg'),
    );

    expect(result, isA<Success<ImageAnalysis>>());
    final ImageAnalysis analysis = (result as Success<ImageAnalysis>).value;
    expect(analysis.estimatedOutputBytes, 0);
    expect(analysis.expectedSavingsRatio, 0);
  });

  test('resize planner rejects invalid target dimensions', () async {
    const PlannedResizeEngine engine = PlannedResizeEngine();
    final Result<ProcessingOutput> result = await engine.process(
      const ProcessingRequest(
        sourcePath: 'input.jpg',
        operation: ProcessingOperation.resize,
        sourceWidth: 4000,
        sourceHeight: 2000,
        resize: ResizeOptions.width(0),
      ),
    );

    expect(result, isA<Failure<ProcessingOutput>>());
    expect(
      (result as Failure<ProcessingOutput>).error.code,
      ErrorCode.invalidArgument,
    );
  });

  test('resize planner preserves aspect ratio for width requests', () async {
    const PlannedResizeEngine engine = PlannedResizeEngine();
    final Result<ProcessingOutput> result = await engine.process(
      const ProcessingRequest(
        sourcePath: 'input.jpg',
        operation: ProcessingOperation.resize,
        sourceWidth: 4000,
        sourceHeight: 2000,
        resize: ResizeOptions.width(1000),
      ),
    );

    expect(result, isA<Success<ProcessingOutput>>());
    final ProcessingOutput output = (result as Success<ProcessingOutput>).value;
    expect(output.width, 1000);
    expect(output.height, 500);
  });

  test(
    'registry resolves registered engines and reports unsupported requests',
    () {
      final InMemoryEngineRegistry registry = InMemoryEngineRegistry();
      final _FakeEngine engine = _FakeEngine();
      registry.register(engine);

      final Result<ProcessingEngine> supported = registry.resolve(
        const ProcessingRequest(
          sourcePath: 'input.jpg',
          operation: ProcessingOperation.compress,
        ),
      );
      final Result<ProcessingEngine> unsupported = registry.resolve(
        const ProcessingRequest(
          sourcePath: 'input.jpg',
          operation: ProcessingOperation.convert,
          compression: CompressionOptions(format: ImageFormat.avif),
        ),
      );

      expect(supported, isA<Success<ProcessingEngine>>());
      expect(unsupported, isA<Failure<ProcessingEngine>>());
    },
  );

  test('queue honors priority and returns typed cancellation', () async {
    final PriorityProcessingQueue queue = PriorityProcessingQueue();
    final Completer<void> gate = Completer<void>();
    final List<String> started = <String>[];
    final CancellationToken cancelled = CancellationToken()..cancel();

    final Future<Result<String>> first = queue.enqueue<String>(
      QueuePriority.low,
      (CancellationToken token) async {
        started.add('low');
        await gate.future;
        return const Result<String>.success('low');
      },
    );
    final Future<Result<String>> high = queue.enqueue<String>(
      QueuePriority.high,
      (CancellationToken token) async {
        started.add('high');
        return const Result<String>.success('high');
      },
    );
    final Future<Result<String>> cancelledResult = queue.enqueue<String>(
      QueuePriority.normal,
      (CancellationToken token) async =>
          const Result<String>.success('not-run'),
      token: cancelled,
    );

    gate.complete();
    expect(await first, isA<Success<String>>());
    expect(await high, isA<Success<String>>());
    expect(await cancelledResult, isA<Failure<String>>());
    expect(started, <String>['low', 'high']);
    expect(
      (await cancelledResult as Failure<String>).error.code,
      ErrorCode.cancelled,
    );
  });

  test(
    'queue pause, resume, retry, and cancellation are deterministic',
    () async {
      final PriorityProcessingQueue queue = PriorityProcessingQueue();
      queue.pause();
      bool started = false;
      final Future<Result<String>> paused = queue.enqueue<String>(
        QueuePriority.normal,
        (CancellationToken token) async {
          started = true;
          return const Result<String>.success('started');
        },
      );
      await Future<void>.delayed(Duration.zero);
      expect(started, isFalse);
      queue.resume();
      expect(await paused, isA<Success<String>>());

      int attempts = 0;
      final Result<String> retried = await queue.enqueue<String>(
        QueuePriority.normal,
        (CancellationToken token) async {
          attempts++;
          if (attempts == 1) {
            return const Result<String>.failure(
              AppError(code: ErrorCode.ioFailure, message: 'retry'),
            );
          }
          return const Result<String>.success('recovered');
        },
        maxRetries: 1,
      );
      expect(retried, isA<Success<String>>());
      expect(attempts, 2);

      queue.pause();
      final CancellationToken token = CancellationToken()..cancel();
      final Future<Result<String>> cancelled = queue.enqueue<String>(
        QueuePriority.normal,
        (CancellationToken value) async =>
            const Result<String>.success('not-run'),
        token: token,
      );
      queue.resume();
      expect(
        (await cancelled as Failure<String>).error.code,
        ErrorCode.cancelled,
      );
    },
  );

  test(
    'target-size processing benchmarks iterations and cleans intermediates',
    () async {
      final _TargetEngine engine = _TargetEngine();
      final InMemoryEngineRegistry registry = InMemoryEngineRegistry();
      registry.register(engine);
      final _FakeFileSystem fileSystem = _FakeFileSystem();
      final DefaultEngineManager manager = DefaultEngineManager(
        registry: registry,
        queue: PriorityProcessingQueue(),
        fileSystem: fileSystem,
        benchmark: _ExecutingBenchmarkEngine(),
      );

      final Result<ProcessingOutput> result = await manager.process(
        const ProcessingRequest(
          sourcePath: 'input.jpg',
          operation: ProcessingOperation.compress,
          compression: CompressionOptions(
            quality: 100,
            preset: CompressionPreset.custom,
            targetBytes: 500,
          ),
        ),
      );

      expect(result, isA<Success<ProcessingOutput>>());
      expect(
        (result as Success<ProcessingOutput>).value.bytes,
        lessThanOrEqualTo(500),
      );
      expect(engine.calls, greaterThan(1));
      expect(fileSystem.deleted, isNotEmpty);
    },
  );

  test(
    'engine manager converts engine exceptions into Result failures',
    () async {
      final _ThrowingEngine engine = _ThrowingEngine();
      final InMemoryEngineRegistry registry = InMemoryEngineRegistry();
      registry.register(engine);
      final DefaultEngineManager manager = DefaultEngineManager(
        registry: registry,
        queue: PriorityProcessingQueue(),
        fileSystem: _FakeFileSystem(),
        benchmark: _FakeBenchmarkEngine(),
      );

      final Result<ProcessingOutput> result = await manager.process(
        const ProcessingRequest(
          sourcePath: 'input.jpg',
          operation: ProcessingOperation.compress,
        ),
      );

      expect(result, isA<Failure<ProcessingOutput>>());
      expect(
        (result as Failure<ProcessingOutput>).error.code,
        ErrorCode.unknown,
      );
    },
  );
}

final class _FakeEngine implements CompressionEngine {
  @override
  String get id => 'fake';

  @override
  bool supports(ProcessingRequest request) =>
      request.operation == ProcessingOperation.compress &&
      request.compression.format.isImplemented;

  @override
  Future<Result<ProcessingOutput>> process(ProcessingRequest request) async =>
      const Result<ProcessingOutput>.success(
        ProcessingOutput(
          outputPath: 'output.jpg',
          bytes: 10,
          width: 100,
          height: 100,
          format: ImageFormat.jpeg,
          quality: 80,
        ),
      );
}

final class _TargetEngine implements CompressionEngine {
  int calls = 0;

  @override
  String get id => 'target';

  @override
  bool supports(ProcessingRequest request) => true;

  @override
  Future<Result<ProcessingOutput>> process(ProcessingRequest request) async {
    calls++;
    final int quality = request.compression.effectiveQuality;
    return Result<ProcessingOutput>.success(
      ProcessingOutput(
        outputPath: 'output_$quality.jpg',
        bytes: quality * 10,
        width: 100,
        height: 100,
        format: ImageFormat.jpeg,
        quality: quality,
      ),
    );
  }
}

final class _ThrowingEngine implements CompressionEngine {
  @override
  String get id => 'throwing';

  @override
  bool supports(ProcessingRequest request) => true;

  @override
  Future<Result<ProcessingOutput>> process(ProcessingRequest request) {
    throw StateError('codec failure');
  }
}

final class _FakeBenchmarkEngine implements BenchmarkEngine {
  @override
  Future<Result<({ProcessingOutput output, ProcessingBenchmark benchmark})>>
  measure(
    String name,
    String sourcePath,
    int? inputBytes,
    Future<Result<ProcessingOutput>> Function() operation,
  ) async =>
      const Result<
        ({ProcessingOutput output, ProcessingBenchmark benchmark})
      >.failure(AppError(code: ErrorCode.unknown, message: 'unused'));
}

final class _ExecutingBenchmarkEngine implements BenchmarkEngine {
  @override
  Future<Result<({ProcessingOutput output, ProcessingBenchmark benchmark})>>
  measure(
    String name,
    String sourcePath,
    int? inputBytes,
    Future<Result<ProcessingOutput>> Function() operation,
  ) async {
    final Result<ProcessingOutput> result = await operation();
    return result.fold(
      onSuccess: (ProcessingOutput output) =>
          Result<
            ({ProcessingOutput output, ProcessingBenchmark benchmark})
          >.success((
            output: output,
            benchmark: ProcessingBenchmark(
              name: name,
              elapsed: Duration.zero,
              inputBytes: inputBytes ?? 0,
              outputBytes: output.bytes,
              compressionRatio: 0,
            ),
          )),
      onFailure: (AppError error) =>
          Result<
            ({ProcessingOutput output, ProcessingBenchmark benchmark})
          >.failure(error),
    );
  }
}

final class _FakeFileSystem implements FileSystemService {
  final List<File> deleted = <File>[];

  @override
  Future<Result<AppDirectories>> directories() async =>
      const Result<AppDirectories>.failure(
        AppError(code: ErrorCode.unavailable, message: 'unused'),
      );

  @override
  Future<List<File>> listFiles(
    Directory directory, {
    bool recursive = true,
  }) async => <File>[];

  @override
  Future<FileMetadata> stat(File file) async =>
      FileMetadata(size: 0, modified: DateTime(2026));

  @override
  Future<Result<String>> readText(File file) async =>
      const Result<String>.failure(
        AppError(code: ErrorCode.unavailable, message: 'unused'),
      );

  @override
  Future<Result<Uint8List>> readBytes(File file) async =>
      const Result<Uint8List>.failure(
        AppError(code: ErrorCode.unavailable, message: 'unused'),
      );

  @override
  Future<Result<File>> writeBytes(File file, Uint8List bytes) async =>
      const Result<File>.failure(
        AppError(code: ErrorCode.unavailable, message: 'unused'),
      );

  @override
  Future<Result<File>> copyFromExternal(File source, File destination) async =>
      const Result<File>.failure(
        AppError(code: ErrorCode.unavailable, message: 'unused'),
      );

  @override
  Future<Result<File>> writeTextAtomic(File file, String contents) async =>
      const Result<File>.failure(
        AppError(code: ErrorCode.unavailable, message: 'unused'),
      );

  @override
  Future<Result<File>> copy(File source, File destination) async =>
      const Result<File>.failure(
        AppError(code: ErrorCode.unavailable, message: 'unused'),
      );

  @override
  Future<Result<File>> move(File source, File destination) async =>
      const Result<File>.failure(
        AppError(code: ErrorCode.unavailable, message: 'unused'),
      );

  @override
  Future<Result<Directory>> ensureChildDirectory(
    Directory parent,
    String name,
  ) async => const Result<Directory>.failure(
    AppError(code: ErrorCode.unavailable, message: 'unused'),
  );

  @override
  Future<Result<void>> safeDelete(
    FileSystemEntity entity, {
    bool recursive = false,
  }) async {
    deleted.add(entity as File);
    return const Result<void>.success(null);
  }
}
