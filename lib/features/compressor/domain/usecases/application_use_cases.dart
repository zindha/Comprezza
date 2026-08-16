import '../../../../core/errors/app_error.dart';
import '../../../../core/errors/error_code.dart';
import '../../../../core/models/result.dart';
import '../entities/entities.dart';
import '../repositories/repositories.dart';
import 'request_validation.dart';

AppError _invalid(String message) => AppError(
  code: ErrorCode.invalidArgument,
  message: message,
  isRecoverable: false,
);

/// Selects one or more images.
final class SelectImagesUseCase {
  const SelectImagesUseCase(this.repository);
  final ImageSelectionRepository repository;
  Future<Result<List<SelectedImage>>> execute({bool multiple = true}) =>
      repository.selectImages(multiple: multiple);
}

/// Validates a selected image against application limits and the repository.
final class ValidateImageUseCase {
  const ValidateImageUseCase(this.repository);
  final ImageSelectionRepository repository;
  Future<Result<SelectedImage>> execute(SelectedImage image) async {
    final AppError? validationError = validateSelectedImage(image);
    if (validationError != null) {
      return Result<SelectedImage>.failure(validationError);
    }
    return repository.validateImage(image);
  }
}

/// Analyzes a selected image.
final class AnalyzeImagesUseCase {
  const AnalyzeImagesUseCase(this.repository);
  final CompressionRepository repository;
  Future<Result<ImageAnalysis>> execute(SelectedImage image) =>
      repository.analyze(image);
}

/// Compresses a request after applying shared validation.
final class CompressImagesUseCase {
  const CompressImagesUseCase(this.repository);
  final CompressionRepository repository;
  Future<Result<CompressionResult>> execute(
    CompressionRequest request, {
    void Function(ProcessingProgress progress)? onProgress,
    OperationControl? control,
  }) {
    final AppError? validationError = validateCompressionRequest(request);
    if (validationError != null) {
      return Future.value(Result<CompressionResult>.failure(validationError));
    }
    return repository.compress(
      request,
      onProgress: onProgress,
      control: control,
    );
  }
}

/// Compresses to an explicit target size.
final class CompressToTargetSizeUseCase {
  const CompressToTargetSizeUseCase(this.repository);
  final CompressionRepository repository;
  Future<Result<CompressionResult>> execute(
    CompressionRequest request, {
    void Function(ProcessingProgress progress)? onProgress,
    OperationControl? control,
  }) {
    if (request.effectiveTargetBytes == null) {
      return Future.value(
        Result<CompressionResult>.failure(
          _invalid('A target size is required for this operation.'),
        ),
      );
    }
    final AppError? validationError = validateCompressionRequest(request);
    if (validationError != null) {
      return Future.value(Result<CompressionResult>.failure(validationError));
    }
    return repository.compress(
      request,
      onProgress: onProgress,
      control: control,
    );
  }
}

/// Converts selected image(s) to a requested output format.
final class ConvertImageFormatUseCase {
  const ConvertImageFormatUseCase(this.repository);
  final CompressionRepository repository;
  Future<Result<CompressionResult>> execute(
    CompressionRequest request, {
    void Function(ProcessingProgress progress)? onProgress,
    OperationControl? control,
  }) {
    if (request.outputFormat == null) {
      return Future.value(
        Result<CompressionResult>.failure(
          _invalid('An output format is required.'),
        ),
      );
    }
    final AppError? validationError = validateCompressionRequest(request);
    if (validationError != null) {
      return Future.value(Result<CompressionResult>.failure(validationError));
    }
    return repository.convert(
      request,
      onProgress: onProgress,
      control: control,
    );
  }
}

/// Resizes selected image(s) using validated resize constraints.
final class ResizeImageUseCase {
  const ResizeImageUseCase(this.repository);
  final CompressionRepository repository;
  Future<Result<CompressionResult>> execute(
    CompressionRequest request, {
    void Function(ProcessingProgress progress)? onProgress,
    OperationControl? control,
  }) {
    if (request.resize == null || request.resize!.isEmpty) {
      return Future.value(
        Result<CompressionResult>.failure(
          _invalid('Resize values are required.'),
        ),
      );
    }
    final AppError? validationError = validateCompressionRequest(request);
    if (validationError != null) {
      return Future.value(Result<CompressionResult>.failure(validationError));
    }
    return repository.resize(request, onProgress: onProgress, control: control);
  }
}

/// Saves one generated image through storage.
final class SaveCompressedImageUseCase {
  const SaveCompressedImageUseCase(this.repository);
  final StorageRepository repository;
  Future<Result<void>> execute(CompressedImage image) => repository.save(image);
}

/// Shares one generated image.
final class ShareCompressedImageUseCase {
  const ShareCompressedImageUseCase(this.repository);
  final ExportRepository repository;
  Future<Result<void>> execute(CompressedImage image) =>
      repository.share(image);
}

/// Deletes a history entry.
final class DeleteHistoryUseCase {
  const DeleteHistoryUseCase(this.repository);
  final HistoryRepository repository;
  Future<Result<void>> execute(String id) => repository.delete(id);
}

/// Loads local history entries.
final class LoadHistoryUseCase {
  const LoadHistoryUseCase(this.repository);
  final HistoryRepository repository;
  Future<Result<List<HistoryEntry>>> execute() => repository.load();
}

/// Loads persisted settings.
final class LoadSettingsUseCase {
  const LoadSettingsUseCase(this.repository);
  final SettingsRepository repository;
  Future<Result<Settings>> execute() => repository.load();
}

/// Loads aggregate compression statistics.
final class LoadStatisticsUseCase {
  const LoadStatisticsUseCase(this.repository);
  final AnalysisRepository repository;
  Future<Result<CompressionStatistics>> execute() =>
      repository.loadStatistics();
}

/// Exports generated images.
final class ExportImagesUseCase {
  const ExportImagesUseCase(this.repository);
  final ExportRepository repository;
  Future<Result<List<CompressedImage>>> execute(ExportRequest request) =>
      repository.export(request);
}

/// Updates persisted preferences after validating supported values.
final class UpdateSettingsUseCase {
  const UpdateSettingsUseCase(this.repository);
  final SettingsRepository repository;
  Future<Result<void>> execute(Settings settings) {
    if (settings.compressionQuality < 1 || settings.compressionQuality > 100) {
      return Future.value(
        Result<void>.failure(
          _invalid('Compression quality must be between 1 and 100.'),
        ),
      );
    }
    if (settings.theme != 'system' &&
        settings.theme != 'light' &&
        settings.theme != 'dark') {
      return Future.value(
        Result<void>.failure(_invalid('The selected theme is not supported.')),
      );
    }
    if (!isApplicationFormatSupported(settings.defaultFormat)) {
      return Future.value(
        Result<void>.failure(
          _invalid('The selected default format is unavailable.'),
        ),
      );
    }
    return repository.update(settings);
  }
}

/// Clears app-managed generated cache.
final class ClearCacheUseCase {
  const ClearCacheUseCase(this.repository);
  final StorageRepository repository;
  Future<Result<void>> execute() => repository.clearCache();
}

/// Recovers a lost picker selection.
final class RecoverSelectionUseCase {
  const RecoverSelectionUseCase(this.repository);
  final ImageSelectionRepository repository;
  Future<Result<List<SelectedImage>>> execute() =>
      repository.recoverSelection();
}
