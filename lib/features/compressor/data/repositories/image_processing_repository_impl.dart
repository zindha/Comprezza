import '../../../../core/models/result.dart';
import '../../domain/entities/image_processing_request.dart';
import '../../domain/entities/image_processing_result.dart';
import '../../domain/repositories/image_processing_repository.dart';
import '../datasources/image_processing_data_source.dart';

/// Concrete repository that delegates engine work to a data source.
final class ImageProcessingRepositoryImpl implements ImageProcessingRepository {
  /// Creates a repository adapter.
  const ImageProcessingRepositoryImpl(this.dataSource);

  /// Injected engine data source.
  final ImageProcessingDataSource dataSource;

  @override
  Future<Result<ImageProcessingResult>> process(
    ImageProcessingRequest request,
  ) {
    return dataSource.process(request);
  }
}
