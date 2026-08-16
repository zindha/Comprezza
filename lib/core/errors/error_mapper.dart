import 'dart:async';
import 'dart:io';

import 'app_exception.dart';
import 'error_code.dart';

/// Converts platform and Dart errors into safe application exceptions.
abstract final class ErrorMapper {
  /// Maps [error] while preserving the original [stackTrace] for diagnostics.
  static AppException map(Object error, [StackTrace? stackTrace]) {
    if (error is AppException) return error;
    if (error is TimeoutException) {
      return AppException(
        code: ErrorCode.timeout,
        message: 'The operation timed out.',
        cause: error,
        stackTrace: stackTrace,
      );
    }
    if (error is FileSystemException) {
      return AppException(
        code: ErrorCode.ioFailure,
        message: 'A local file operation failed.',
        cause: error,
        stackTrace: stackTrace,
      );
    }
    if (error is FormatException) {
      return AppException(
        code: ErrorCode.corruptedFile,
        message: 'A local file contained invalid data.',
        cause: error,
        stackTrace: stackTrace,
        isRecoverable: false,
      );
    }
    if (error is UnsupportedError) {
      return AppException(
        code: ErrorCode.unsupportedPlatform,
        message: 'This operation is not supported on this device.',
        cause: error,
        stackTrace: stackTrace,
        isRecoverable: false,
      );
    }
    return AppException(
      code: ErrorCode.unknown,
      message: 'An unexpected error occurred.',
      cause: error,
      stackTrace: stackTrace,
    );
  }
}
