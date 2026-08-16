import 'dart:io';

import '../../../../../core/errors/app_error.dart';
import '../../../../../core/errors/error_code.dart';
import '../../../../../core/errors/error_mapper.dart';
import '../../../../../core/errors/result_error_adapter.dart';
import '../../../../../core/models/result.dart';
import '../../../../../core/services/file_system_service.dart';
import 'interfaces/engine_manager.dart';
import 'interfaces/engine_registry.dart';
import 'interfaces/processing_engine.dart';
import 'models/image_processing_models.dart';

/// Coordinates registered engines while keeping repositories engine-agnostic.
final class DefaultEngineManager implements EngineManager {
  /// Creates an engine manager.
  const DefaultEngineManager({
    required this.registry,
    required this.queue,
    required this.fileSystem,
    required this.benchmark,
  });

  /// Replaceable processing engine registry.
  final EngineRegistry registry;

  /// Bounded processing queue.
  final QueueEngine queue;

  /// App-owned filesystem boundary.
  final FileSystemService fileSystem;

  /// Local benchmark adapter.
  final BenchmarkEngine benchmark;

  @override
  Future<Result<ProcessingOutput>> process(
    ProcessingRequest request, {
    QueuePriority priority = QueuePriority.normal,
    CancellationToken? token,
  }) {
    return queue.enqueue<ProcessingOutput>(priority, (
      CancellationToken cancellation,
    ) async {
      if (cancellation.isCancelled) {
        return const Result<ProcessingOutput>.failure(
          AppError(
            code: ErrorCode.cancelled,
            message: 'The processing operation was cancelled.',
          ),
        );
      }
      final Result<ProcessingEngine> resolved = registry.resolve(request);
      if (resolved case Failure<ProcessingEngine>(
        error: final AppError error,
      )) {
        return Result<ProcessingOutput>.failure(error);
      }
      final ProcessingEngine engine =
          (resolved as Success<ProcessingEngine>).value;
      try {
        if (request.compression.targetBytes case final int target
            when target > 0 &&
                request.operation == ProcessingOperation.compress) {
          return await _processToTargetSize(
            engine,
            request,
            target,
            cancellation,
          );
        }
        return await _runMeasured(engine, request);
      } catch (error, stackTrace) {
        final exception = ErrorMapper.map(error, stackTrace);
        return Result<ProcessingOutput>.failure(
          ResultErrorAdapter.fromException(exception),
        );
      }
    }, token: token);
  }

  Future<Result<ProcessingOutput>> _processToTargetSize(
    ProcessingEngine engine,
    ProcessingRequest request,
    int targetBytes,
    CancellationToken token,
  ) async {
    int low = 1;
    int high = 100;
    ProcessingOutput? best;
    final List<ProcessingOutput> generated = <ProcessingOutput>[];
    try {
      while (low <= high && !token.isCancelled) {
        final int quality = (low + high) ~/ 2;
        final Result<ProcessingOutput> result = await _runMeasured(
          engine,
          ProcessingRequest(
            sourcePath: request.sourcePath,
            operation: request.operation,
            compression: CompressionOptions(
              quality: quality,
              preset: CompressionPreset.custom,
              mode: request.compression.mode,
              format: request.compression.format,
              keepExif: request.compression.keepExif,
              targetBytes: targetBytes,
              maxWidth: request.compression.maxWidth,
              maxHeight: request.compression.maxHeight,
            ),
            resize: request.resize,
            metadataPolicy: request.metadataPolicy,
            sourceWidth: request.sourceWidth,
            sourceHeight: request.sourceHeight,
            sourceBytes: request.sourceBytes,
          ),
        );
        if (result case Failure<ProcessingOutput>(
          error: final AppError error,
        )) {
          return Result<ProcessingOutput>.failure(error);
        }
        final ProcessingOutput output =
            (result as Success<ProcessingOutput>).value;
        generated.add(output);
        if (output.bytes <= targetBytes) {
          best = output;
          low = quality + 1;
        } else {
          high = quality - 1;
        }
      }
      if (token.isCancelled) {
        return const Result<ProcessingOutput>.failure(
          AppError(
            code: ErrorCode.cancelled,
            message: 'The processing operation was cancelled.',
          ),
        );
      }
      best ??= generated.isEmpty ? null : generated.last;
      if (best == null) {
        return const Result<ProcessingOutput>.failure(
          AppError(
            code: ErrorCode.ioFailure,
            message: 'No target-size output was produced.',
          ),
        );
      }
      return Result<ProcessingOutput>.success(best);
    } finally {
      final String? retainedPath = best?.outputPath;
      final Set<String> generatedPaths = generated
          .map((ProcessingOutput output) => output.outputPath)
          .toSet();
      for (final String path in generatedPaths) {
        if (path == retainedPath) continue;
        await fileSystem.safeDelete(File(path));
      }
    }
  }

  Future<Result<ProcessingOutput>> _runMeasured(
    ProcessingEngine engine,
    ProcessingRequest request,
  ) async {
    final Result<({ProcessingOutput output, ProcessingBenchmark benchmark})>
    measured = await benchmark.measure(
      engine.id,
      request.sourcePath,
      request.sourceBytes,
      () => engine.process(request),
    );
    return measured.fold(
      onSuccess: (value) => Result<ProcessingOutput>.success(value.output),
      onFailure: (error) => Result<ProcessingOutput>.failure(error),
    );
  }

  @override
  Future<Result<ImageAnalysis>> analyze(AnalysisRequest request) async {
    final Result<ImageAnalyzerEngine> resolved = registry.resolveAnalyzer();
    if (resolved case Failure<ImageAnalyzerEngine>(
      error: final AppError error,
    )) {
      return Result<ImageAnalysis>.failure(error);
    }
    try {
      return await (resolved as Success<ImageAnalyzerEngine>).value.analyze(
        request,
      );
    } catch (error, stackTrace) {
      final exception = ErrorMapper.map(error, stackTrace);
      return Result<ImageAnalysis>.failure(
        ResultErrorAdapter.fromException(exception),
      );
    }
  }

  @override
  Result<Estimation> estimate(EstimationRequest request) {
    final Result<EstimationEngine> resolved = registry
        .resolveSpecialized<EstimationEngine>();
    if (resolved case Failure<EstimationEngine>(error: final AppError error)) {
      return Result<Estimation>.failure(error);
    }
    return (resolved as Success<EstimationEngine>).value.estimate(request);
  }
}
