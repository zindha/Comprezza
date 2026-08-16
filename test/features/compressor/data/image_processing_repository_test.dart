import 'package:comprezza/core/models/result.dart';
import 'package:comprezza/features/compressor/data/datasources/image_processing_data_source.dart';
import 'package:comprezza/features/compressor/data/repositories/image_processing_repository_impl.dart';
import 'package:comprezza/features/compressor/domain/entities/image_processing_request.dart';
import 'package:comprezza/features/compressor/domain/entities/image_processing_result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('delegates processing to the datasource', () async {
    final _FakeDataSource dataSource = _FakeDataSource();
    final ImageProcessingRepositoryImpl repository =
        ImageProcessingRepositoryImpl(dataSource);
    const ImageProcessingRequest request = ImageProcessingRequest(
      sourcePath: 'input.jpg',
      quality: 80,
    );

    final Result<ImageProcessingResult> result = await repository.process(
      request,
    );

    expect(dataSource.lastRequest, same(request));
    expect(result, isA<Success<ImageProcessingResult>>());
  });
}

class _FakeDataSource implements ImageProcessingDataSource {
  ImageProcessingRequest? lastRequest;

  @override
  Future<Result<ImageProcessingResult>> process(
    ImageProcessingRequest request,
  ) async {
    lastRequest = request;
    return const Result<ImageProcessingResult>.success(
      ImageProcessingResult(outputPath: 'output.jpg', byteLength: 12),
    );
  }
}
