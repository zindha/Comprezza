import '../../../../../../core/errors/app_error.dart';
import '../../../../../../core/errors/error_code.dart';
import '../../../../../../core/models/result.dart';
import '../models/image_processing_models.dart';
import 'processing_engine.dart';

/// Resolves processing implementations without hard-coded codec dependencies.
abstract interface class EngineRegistry {
  /// Registers or replaces an engine under its stable identifier.
  void register(ProcessingEngine engine);

  /// Registers or replaces an analyzer.
  void registerAnalyzer(ImageAnalyzerEngine analyzer);

  /// Registers or replaces a specialized engine.
  void registerSpecialized<T extends Object>(T engine);

  /// Resolves a processing engine for [request].
  Result<ProcessingEngine> resolve(ProcessingRequest request);

  /// Resolves the analyzer engine.
  Result<ImageAnalyzerEngine> resolveAnalyzer();

  /// Resolves a specialized engine by type.
  Result<T> resolveSpecialized<T extends Object>();
}

/// In-memory registry scoped to one application dependency graph.
final class InMemoryEngineRegistry implements EngineRegistry {
  /// Creates an empty registry.
  InMemoryEngineRegistry();

  final Map<String, ProcessingEngine> _engines = <String, ProcessingEngine>{};
  final Map<Type, Object> _specialized = <Type, Object>{};
  ImageAnalyzerEngine? _analyzer;

  @override
  void register(ProcessingEngine engine) => _engines[engine.id] = engine;

  @override
  void registerAnalyzer(ImageAnalyzerEngine analyzer) => _analyzer = analyzer;

  @override
  void registerSpecialized<T extends Object>(T engine) =>
      _specialized[T] = engine;

  @override
  Result<ProcessingEngine> resolve(ProcessingRequest request) {
    for (final ProcessingEngine engine in _engines.values) {
      if (engine.supports(request)) {
        return Result<ProcessingEngine>.success(engine);
      }
    }
    return const Result<ProcessingEngine>.failure(
      AppError(
        code: ErrorCode.unavailable,
        message: 'No registered engine supports this processing request.',
        isRecoverable: false,
      ),
    );
  }

  @override
  Result<ImageAnalyzerEngine> resolveAnalyzer() {
    final ImageAnalyzerEngine? analyzer = _analyzer;
    if (analyzer != null) return Result<ImageAnalyzerEngine>.success(analyzer);
    return const Result<ImageAnalyzerEngine>.failure(
      AppError(
        code: ErrorCode.unavailable,
        message: 'No image analyzer engine is registered.',
        isRecoverable: false,
      ),
    );
  }

  @override
  Result<T> resolveSpecialized<T extends Object>() {
    final T? engine = _specialized[T] as T?;
    if (engine != null) return Result<T>.success(engine);
    return Result<T>.failure(
      AppError(
        code: ErrorCode.unavailable,
        message: 'No specialized engine is registered for $T.',
        isRecoverable: false,
      ),
    );
  }
}
