import '../../../../core/models/result.dart';
import '../entities/entities.dart';

/// Selects and validates user-owned images.
abstract interface class ImageSelectionRepository {
  Future<Result<List<SelectedImage>>> selectImages({bool multiple = true});
  Future<Result<List<SelectedImage>>> recoverSelection();
  Future<Result<SelectedImage>> validateImage(SelectedImage image);
}

/// Performs image analysis and processing through the data boundary.
abstract interface class CompressionRepository {
  Future<Result<CompressionResult>> compress(
    CompressionRequest request, {
    void Function(ProcessingProgress progress)? onProgress,
    OperationControl? control,
  });

  Future<Result<CompressionResult>> convert(
    CompressionRequest request, {
    void Function(ProcessingProgress progress)? onProgress,
    OperationControl? control,
  });

  Future<Result<CompressionResult>> resize(
    CompressionRequest request, {
    void Function(ProcessingProgress progress)? onProgress,
    OperationControl? control,
  });

  Future<Result<ImageAnalysis>> analyze(SelectedImage image);
}

/// Persists and removes completed workflow records.
abstract interface class HistoryRepository {
  Future<Result<void>> save(HistoryEntry entry);
  Future<Result<List<HistoryEntry>>> load();
  Future<Result<void>> delete(String id);
}

/// Reads and updates user preferences.
abstract interface class SettingsRepository {
  Future<Result<Settings>> load();
  Future<Result<void>> update(Settings settings);
}

/// Owns app-managed files and cache cleanup.
abstract interface class StorageRepository {
  Future<Result<void>> save(CompressedImage image);
  Future<Result<void>> delete(String path);
  Future<Result<void>> clearCache();
}

/// Provides aggregate local statistics.
abstract interface class AnalysisRepository {
  Future<Result<CompressionStatistics>> loadStatistics();
}

/// Exports or shares generated images.
abstract interface class ExportRepository {
  Future<Result<List<CompressedImage>>> export(ExportRequest request);
  Future<Result<void>> share(CompressedImage image);
}
