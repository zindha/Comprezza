import '../../../../../core/errors/app_error.dart';
import '../../../../../core/models/result.dart';
import 'interfaces/file_management_interfaces.dart';
import 'models/file_management_models.dart';

/// Coordinates all file-management operations for future use cases.
final class DefaultFileManager implements FileManager {
  /// Creates a file manager from replaceable service contracts.
  const DefaultFileManager({
    required this.picker,
    required this.importer,
    required this.validator,
    required this.exporter,
    required this.cleanupService,
    required this.folderPicker,
    required this.history,
    required this.permissions,
  });

  /// User-mediated image picker.
  final ImagePickerService picker;

  /// Imports transient picker files into managed storage.
  final ImportService importer;

  /// File validator and duplicate detector.
  final FileValidator validator;

  /// Export and share-copy service.
  final ExportService exporter;

  /// Generated-file cleanup service.
  final FileCleanupService cleanupService;

  /// Folder scan foundation.
  final FolderPickerService folderPicker;

  /// Local history store.
  final HistoryStorage history;

  /// User-mediated access policy.
  final PermissionService permissions;

  @override
  Future<Result<FileOperationSummary>> selectImages(
    ImageSelectionRequest request,
  ) async {
    final Result<List<SelectedFile>> selection = await picker.pick(request);
    return _importAndValidate(selection);
  }

  @override
  Future<Result<FileOperationSummary>> recoverLostSelection() async {
    final Result<List<SelectedFile>> selection = await picker
        .recoverLostSelection();
    return _importAndValidate(selection);
  }

  Future<Result<FileOperationSummary>> _importAndValidate(
    Result<List<SelectedFile>> selection,
  ) async {
    if (selection case Failure<List<SelectedFile>>(
      error: final AppError error,
    )) {
      return Result<FileOperationSummary>.failure(error);
    }
    final List<String> importedPaths = <String>[];
    final Map<String, String> importFailures = <String, String>{};
    for (final SelectedFile selected
        in (selection as Success<List<SelectedFile>>).value) {
      final Result<ExportedFile> imported = await importer.importExternal(
        selected,
      );
      if (imported case Success<ExportedFile>(value: final ExportedFile file)) {
        importedPaths.add(file.path);
      } else if (imported case Failure<ExportedFile>(
        error: final AppError error,
      )) {
        importFailures[selected.path] = error.message;
      }
    }
    final Result<FileOperationSummary> validation = await validator
        .validateMany(importedPaths);
    if (validation case Failure<FileOperationSummary>(
      error: final AppError error,
    )) {
      return Result<FileOperationSummary>.failure(error);
    }
    final FileOperationSummary summary =
        (validation as Success<FileOperationSummary>).value;
    return Result<FileOperationSummary>.success(
      FileOperationSummary(
        accepted: summary.accepted,
        rejected: <String, String>{...importFailures, ...summary.rejected},
      ),
    );
  }

  @override
  Future<Result<List<String>>> scanFolder(
    String folderPath, {
    FolderScanOptions options = const FolderScanOptions(),
  }) => folderPicker.scan(folderPath, options: options);

  @override
  Future<Result<void>> saveHistory(CompressionHistoryRecord record) =>
      history.save(record);

  @override
  Future<Result<List<CompressionHistoryRecord>>> readHistory() =>
      history.readAll();

  @override
  Future<Result<void>> deleteHistory(String id) => history.delete(id);

  @override
  Future<Result<bool>> canAccessSelectedFile(String path) =>
      permissions.canAccessSelectedFile(path);

  @override
  Future<Result<ManagedFile>> validate(String path) => validator.validate(path);

  @override
  Future<Result<ExportedFile>> export(
    String sourcePath, {
    required FileNameRequest naming,
  }) => exporter.export(sourcePath, naming: naming);

  @override
  Future<Result<ExportedFile>> prepareShareCopy(
    String sourcePath, {
    required FileNameRequest naming,
  }) => exporter.prepareShareCopy(sourcePath, naming: naming);

  @override
  Future<Result<FileCleanupReport>> cleanup({
    FileCleanupPolicy policy = const FileCleanupPolicy(),
  }) => cleanupService.cleanup(policy: policy);
}
