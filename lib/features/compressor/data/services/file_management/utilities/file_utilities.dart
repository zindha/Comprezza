import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

import '../../../../../../core/errors/app_error.dart';
import '../../../../../../core/errors/error_code.dart';
import '../../../../../../core/errors/error_mapper.dart';
import '../../../../../../core/errors/result_error_adapter.dart';
import '../../../../../../core/models/result.dart';
import '../../../../../../core/services/file_system_service.dart';
import '../interfaces/file_management_interfaces.dart';

/// Production file utilities scoped to the file-management platform.
final class LocalFileUtilities implements FileUtilities {
  /// Creates utilities backed by the app filesystem service.
  const LocalFileUtilities({required this.fileSystem});

  /// App-owned filesystem boundary.
  final FileSystemService fileSystem;

  @override
  String normalizePath(String path) => p.normalize(p.absolute(path));

  @override
  String mimeType(String path) {
    return switch (p.extension(path).toLowerCase()) {
      '.jpg' || '.jpeg' => 'image/jpeg',
      '.png' => 'image/png',
      '.webp' => 'image/webp',
      _ => 'application/octet-stream',
    };
  }

  @override
  Future<Result<String>> checksum(String path) async {
    try {
      final File file = File(path);
      if (!await file.exists()) {
        return const Result<String>.failure(
          AppError(
            code: ErrorCode.notFound,
            message: 'The file does not exist.',
            isRecoverable: false,
          ),
        );
      }
      final _DigestAccumulator output = _DigestAccumulator();
      final ByteConversionSink input = sha256.startChunkedConversion(output);
      await for (final List<int> chunk in file.openRead()) {
        input.add(chunk);
      }
      input.close();
      return Result<String>.success(output.value.toString());
    } catch (error, stackTrace) {
      final exception = ErrorMapper.map(error, stackTrace);
      return Result<String>.failure(
        ResultErrorAdapter.fromException(exception),
      );
    }
  }

  @override
  Future<Result<bool>> isDecodableImage(String path) async {
    ui.ImmutableBuffer? buffer;
    ui.ImageDescriptor? descriptor;
    try {
      final File file = File(path);
      if (!await file.exists()) return const Result<bool>.success(false);
      buffer = await ui.ImmutableBuffer.fromFilePath(file.path);
      descriptor = await ui.ImageDescriptor.encoded(buffer);
      return Result<bool>.success(
        descriptor.width > 0 && descriptor.height > 0,
      );
    } catch (error, stackTrace) {
      final exception = ErrorMapper.map(error, stackTrace);
      return Result<bool>.failure(
        ResultErrorAdapter.fromException(
          exception.code == ErrorCode.corruptedFile
              ? exception
              : ErrorMapper.map(
                  const FormatException('Image decode failed'),
                  stackTrace,
                ),
        ),
      );
    } finally {
      descriptor?.dispose();
      buffer?.dispose();
    }
  }

  @override
  Future<Result<File>> safeMove(String sourcePath, String destinationPath) =>
      fileSystem.move(File(sourcePath), File(destinationPath));

  @override
  Future<Result<int>> estimateStorage(String path) async {
    try {
      final File file = File(path);
      final Result<FileMetadata> metadata = Result<FileMetadata>.success(
        await fileSystem.stat(file),
      );
      return await metadata.fold(
        onSuccess: (FileMetadata value) => Result<int>.success(value.size),
        onFailure: (AppError error) => Result<int>.failure(error),
      );
    } catch (error, stackTrace) {
      final exception = ErrorMapper.map(error, stackTrace);
      return Result<int>.failure(ResultErrorAdapter.fromException(exception));
    }
  }

  @override
  Future<Result<File>> safeCopy(
    String sourcePath,
    String destinationPath,
  ) async {
    try {
      final File source = File(sourcePath);
      final File destination = File(destinationPath);
      if (!await source.exists()) {
        return const Result<File>.failure(
          AppError(
            code: ErrorCode.notFound,
            message: 'The source file does not exist.',
            isRecoverable: false,
          ),
        );
      }
      return await fileSystem.copyFromExternal(source, destination);
    } catch (error, stackTrace) {
      final exception = ErrorMapper.map(error, stackTrace);
      return Result<File>.failure(ResultErrorAdapter.fromException(exception));
    }
  }

  @override
  Future<Result<void>> safeDelete(String path) async {
    try {
      return await fileSystem.safeDelete(File(path));
    } catch (error, stackTrace) {
      final exception = ErrorMapper.map(error, stackTrace);
      return Result<void>.failure(ResultErrorAdapter.fromException(exception));
    }
  }
}

final class _DigestAccumulator implements Sink<Digest> {
  Digest? value;

  @override
  void add(Digest data) => value = data;

  @override
  void close() {}
}
