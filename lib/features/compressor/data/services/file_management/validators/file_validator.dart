import 'dart:io';

import 'package:path/path.dart' as p;

import '../../../../../../core/errors/app_error.dart';
import '../../../../../../core/errors/error_code.dart';
import '../../../../../../core/errors/error_mapper.dart';
import '../../../../../../core/errors/result_error_adapter.dart';
import '../../../../../../core/models/result.dart';
import '../interfaces/file_management_interfaces.dart';
import '../models/file_management_models.dart';

/// Validates image files before they enter processing workflows.
final class LocalFileValidator implements FileValidator {
  /// Creates a validator with injectable utilities.
  const LocalFileValidator({required this.utilities});

  /// File utility boundary used for MIME and checksum operations.
  final FileUtilities utilities;

  @override
  Future<Result<ManagedFile>> validate(
    String path, {
    FileValidationPolicy policy = const FileValidationPolicy(),
  }) async {
    try {
      final File file = File(path);
      if (!await file.exists()) {
        return const Result<ManagedFile>.failure(
          AppError(
            code: ErrorCode.notFound,
            message: 'The selected file does not exist.',
            isRecoverable: false,
          ),
        );
      }
      final FileStat stat = await file.stat();
      if (stat.type != FileSystemEntityType.file) {
        return const Result<ManagedFile>.failure(
          AppError(
            code: ErrorCode.invalidArgument,
            message: 'The selected path is not a regular file.',
            isRecoverable: false,
          ),
        );
      }
      if (stat.size <= 0) {
        return const Result<ManagedFile>.failure(
          AppError(
            code: ErrorCode.invalidArgument,
            message: 'The selected file is empty.',
            isRecoverable: false,
          ),
        );
      }
      if (stat.size > policy.maxBytes) {
        return const Result<ManagedFile>.failure(
          AppError(
            code: ErrorCode.invalidArgument,
            message: 'The selected file exceeds the configured size limit.',
            isRecoverable: false,
          ),
        );
      }
      final String extension = p
          .extension(path)
          .toLowerCase()
          .replaceFirst('.', '');
      if (!policy.supportedExtensions.contains(extension)) {
        return const Result<ManagedFile>.failure(
          AppError(
            code: ErrorCode.unsupportedPlatform,
            message: 'The selected file format is not supported.',
            isRecoverable: false,
          ),
        );
      }
      // Reject malformed images before performing the full streaming hash.
      final Result<bool> imageResult = await utilities.isDecodableImage(path);
      if (imageResult case Failure<bool>(error: final AppError error)) {
        return Result<ManagedFile>.failure(error);
      }
      if (!(imageResult as Success<bool>).value) {
        return const Result<ManagedFile>.failure(
          AppError(
            code: ErrorCode.corruptedFile,
            message: 'The file is not a readable supported image.',
            isRecoverable: false,
          ),
        );
      }
      final Result<String> checksumResult = await utilities.checksum(path);
      if (checksumResult case Failure<String>(error: final AppError error)) {
        return Result<ManagedFile>.failure(error);
      }
      final String name = p.basename(path);
      return Result<ManagedFile>.success(
        ManagedFile(
          path: path,
          name: name,
          extension: extension,
          mimeType: utilities.mimeType(path),
          bytes: stat.size,
          checksum: (checksumResult as Success<String>).value,
          modified: stat.modified,
        ),
      );
    } catch (error, stackTrace) {
      final exception = ErrorMapper.map(error, stackTrace);
      return Result<ManagedFile>.failure(
        ResultErrorAdapter.fromException(exception),
      );
    }
  }

  @override
  Future<Result<FileOperationSummary>> validateMany(
    Iterable<String> paths, {
    FileValidationPolicy policy = const FileValidationPolicy(),
  }) async {
    final List<ManagedFile> accepted = <ManagedFile>[];
    final Map<String, String> rejected = <String, String>{};
    final Set<String> seenChecksums = <String>{};
    for (final String path in paths) {
      final Result<ManagedFile> result = await validate(path, policy: policy);
      if (result case Success<ManagedFile>(value: final ManagedFile file)) {
        if (!seenChecksums.add('${file.bytes}:${file.checksum}')) {
          rejected[path] = 'Duplicate file.';
          continue;
        }
        accepted.add(file);
      } else if (result case Failure<ManagedFile>(
        error: final AppError error,
      )) {
        rejected[path] = error.message;
      }
    }
    return Result<FileOperationSummary>.success(
      FileOperationSummary(
        accepted: List<ManagedFile>.unmodifiable(accepted),
        rejected: Map<String, String>.unmodifiable(rejected),
      ),
    );
  }
}
