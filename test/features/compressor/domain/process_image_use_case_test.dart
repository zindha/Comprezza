import 'package:comprezza/core/models/result.dart';
import 'package:comprezza/features/compressor/domain/entities/image_processing_request.dart';
import 'package:comprezza/features/compressor/domain/entities/image_processing_result.dart';
import 'package:comprezza/features/compressor/domain/repositories/image_processing_repository.dart';
import 'package:comprezza/features/compressor/domain/usecases/process_image_use_case.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('forwards the request to the repository', () async {
    final _FakeRepository repository = _FakeRepository();
    final ProcessImageUseCase useCase = ProcessImageUseCase(repository);
    const ImageProcessingRequest request = ImageProcessingRequest(
      sourcePath: 'input.jpg',
      quality: 75,
    );

    final Result<ImageProcessingResult> result = await useCase(request);

    expect(repository.lastRequest, same(request));
    expect(result, isA<Success<ImageProcessingResult>>());
  });
}

class _FakeRepository implements ImageProcessingRepository {
  ImageProcessingRequest? lastRequest;

  @override
  Future<Result<ImageProcessingResult>> process(
    ImageProcessingRequest request,
  ) async {
    lastRequest = request;
    return const Result<ImageProcessingResult>.success(
      ImageProcessingResult(outputPath: 'output.jpg', byteLength: 10),
    );
  }
}
