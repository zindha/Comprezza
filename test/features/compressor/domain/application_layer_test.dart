import 'package:comprezza/core/errors/app_error.dart';
import 'package:comprezza/core/errors/error_code.dart';
import 'package:comprezza/core/models/result.dart';
import 'package:comprezza/features/compressor/domain/entities/entities.dart';
import 'package:comprezza/features/compressor/domain/repositories/repositories.dart';
import 'package:comprezza/features/compressor/domain/usecases/usecases.dart';
import 'package:comprezza/features/compressor/presentation/providers/providers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final CompressionPreset preset = const CompressionPreset(
    id: 'balanced',
    name: 'Balanced',
    quality: 72,
  );

  SelectedImage image({String id = 'one', String path = 'one.jpg'}) =>
      SelectedImage(
        id: id,
        path: path,
        name: '$id.jpg',
        bytes: 1000,
        width: 100,
        height: 100,
        format: ImageFormat.jpeg,
        checksum: id,
      );

  test('entities use structural equality and defensive list copies', () {
    final List<SelectedImage> source = <SelectedImage>[image()];
    final CompressionRequest request = CompressionRequest(
      images: source,
      preset: preset,
    );
    source.clear();

    expect(request.images, hasLength(1));
    expect(
      request,
      equals(
        CompressionRequest(images: <SelectedImage>[image()], preset: preset),
      ),
    );
  });

  test('compression use case rejects invalid and duplicate requests', () async {
    final _FakeCompressionRepository repository = _FakeCompressionRepository();
    final CompressImagesUseCase useCase = CompressImagesUseCase(repository);

    final Result<CompressionResult> invalid = await useCase.execute(
      CompressionRequest(
        images: <SelectedImage>[image()],
        preset: preset,
        quality: 101,
      ),
    );
    final Result<CompressionResult> duplicate = await useCase.execute(
      CompressionRequest(
        images: <SelectedImage>[image(), image()],
        preset: preset,
      ),
    );

    expect(invalid, isA<Failure<CompressionResult>>());
    expect(duplicate, isA<Failure<CompressionResult>>());
    expect(repository.calls, 0);
  });

  test(
    'compression provider ignores duplicate in-flight request and exposes progress',
    () async {
      final _FakeCompressionRepository repository =
          _FakeCompressionRepository();
      final CompressionProvider provider = CompressionProvider(
        compressImages: CompressImagesUseCase(repository),
      );
      final CompressionRequest request = CompressionRequest(
        images: <SelectedImage>[image()],
        preset: preset,
      );

      final Future<void> first = provider.compress(request);
      final Future<void> second = provider.compress(request);
      await Future.wait<void>(<Future<void>>[first, second]);

      expect(repository.calls, 1);
      expect(provider.state.status, OperationStatus.completed);
      expect(provider.state.progress.overallProgress, 1);
      provider.dispose();
    },
  );

  test('provider maps failures to recoverable friendly state', () async {
    final CompressionProvider provider = CompressionProvider(
      compressImages: CompressImagesUseCase(
        _FakeCompressionRepository(
          failure: const AppError(
            code: ErrorCode.ioFailure,
            message: 'Try again later.',
          ),
        ),
      ),
    );

    await provider.compress(
      CompressionRequest(images: <SelectedImage>[image()], preset: preset),
    );

    expect(provider.state.status, OperationStatus.error);
    expect(provider.state.message, 'Try again later.');
    expect(provider.state.canRetry, isTrue);
    provider.dispose();
  });
}

final class _FakeCompressionRepository implements CompressionRepository {
  _FakeCompressionRepository({this.failure});
  final AppError? failure;
  int calls = 0;

  @override
  Future<Result<CompressionResult>> compress(
    CompressionRequest request, {
    void Function(ProcessingProgress progress)? onProgress,
    OperationControl? control,
  }) async {
    calls++;
    await Future<void>.delayed(Duration.zero);
    if (failure case final AppError error) {
      return Result<CompressionResult>.failure(error);
    }
    onProgress?.call(
      const ProcessingProgress(
        completedFiles: 1,
        totalFiles: 1,
        currentFileProgress: 1,
        overallProgress: 1,
        speedBytesPerSecond: 100,
        estimatedTimeRemaining: Duration.zero,
        queuePosition: 0,
      ),
    );
    return Result<CompressionResult>.success(
      CompressionResult(
        images: <CompressedImage>[
          CompressedImage(
            sourceId: request.images.single.id,
            path: 'out.jpg',
            name: 'out.jpg',
            bytes: 500,
            width: 100,
            height: 100,
            format: ImageFormat.jpeg,
            quality: request.effectiveQuality,
            createdAt: DateTime(2026),
          ),
        ],
        statistics: const CompressionStatistics(
          inputBytes: 1000,
          outputBytes: 500,
          savedBytes: 500,
          savingsRatio: .5,
          processedFiles: 1,
          duration: Duration.zero,
        ),
        benchmark: const BenchmarkResult(
          duration: Duration.zero,
          bytesPerSecond: 100,
          peakMemoryBytes: null,
        ),
      ),
    );
  }

  @override
  Future<Result<CompressionResult>> convert(
    CompressionRequest request, {
    void Function(ProcessingProgress progress)? onProgress,
    OperationControl? control,
  }) => compress(request, onProgress: onProgress, control: control);
  @override
  Future<Result<CompressionResult>> resize(
    CompressionRequest request, {
    void Function(ProcessingProgress progress)? onProgress,
    OperationControl? control,
  }) => compress(request, onProgress: onProgress, control: control);
  @override
  Future<Result<ImageAnalysis>> analyze(SelectedImage image) async =>
      throw UnimplementedError();
}
