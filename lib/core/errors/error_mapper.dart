import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';

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
    if (error is OutOfMemoryError) {
      return _exception(
        ErrorCode.outOfMemory,
        'The device ran out of memory while processing this image.',
        error,
        stackTrace,
      );
    }
    if (error is FileSystemException) {
      final String osMessage = error.osError?.message.toLowerCase() ?? '';
      final ErrorCode? classified = _classify(osMessage);
      if (classified != null) {
        return _exception(
          classified,
          _messageFor(classified),
          error,
          stackTrace,
        );
      }
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
    if (error is PlatformException) {
      final String haystack = <String>[
        error.code,
        error.message ?? '',
        '${error.details ?? ''}',
      ].join(' ').toLowerCase();
      final ErrorCode? classified = _classify(haystack);
      if (classified != null) {
        return _exception(
          classified,
          _messageFor(classified),
          error,
          stackTrace,
        );
      }
      return AppException(
        code: ErrorCode.ioFailure,
        message: error.message ?? 'The image operation failed.',
        cause: error,
        stackTrace: stackTrace,
      );
    }
    // The final fallback classifies infrastructure failures that reach the
    // boundary as plain objects (e.g. native codec exceptions) by message.
    final ErrorCode? classified = _classify(error.toString().toLowerCase());
    if (classified != null) {
      return _exception(classified, _messageFor(classified), error, stackTrace);
    }
    return AppException(
      code: ErrorCode.unknown,
      message: 'An unexpected error occurred.',
      cause: error,
      stackTrace: stackTrace,
    );
  }

  static ErrorCode? _classify(String haystack) {
    if (_isNoSpace(haystack)) return ErrorCode.storageFull;
    if (_isPermissionDenied(haystack)) return ErrorCode.permissionDenied;
    if (_isOutOfMemory(haystack)) return ErrorCode.outOfMemory;
    if (_isUnsupportedFormat(haystack)) return ErrorCode.unsupportedFormat;
    return null;
  }

  static String _messageFor(ErrorCode code) => switch (code) {
    ErrorCode.storageFull => 'There is not enough storage space available.',
    ErrorCode.permissionDenied =>
      'Comprezza does not have permission to access that file.',
    ErrorCode.outOfMemory =>
      'The device ran out of memory while processing this image.',
    ErrorCode.unsupportedFormat => 'This image format is not supported.',
    _ => 'The image operation failed.',
  };

  static AppException _exception(
    ErrorCode code,
    String message,
    Object cause,
    StackTrace? stackTrace,
  ) => AppException(
    code: code,
    message: message,
    cause: cause,
    stackTrace: stackTrace,
    isRecoverable: code != ErrorCode.unsupportedFormat,
  );

  static bool _isNoSpace(String haystack) =>
      haystack.contains('no space') ||
      haystack.contains('enospc') ||
      haystack.contains('not enough space');

  static bool _isPermissionDenied(String haystack) =>
      haystack.contains('permission') ||
      haystack.contains('denied') ||
      haystack.contains('eacces');

  static bool _isOutOfMemory(String haystack) =>
      haystack.contains('out of memory') ||
      haystack.contains('enomem') ||
      haystack.contains('oom');

  static bool _isUnsupportedFormat(String haystack) =>
      haystack.contains('invalid image') ||
      haystack.contains('cannot decode') ||
      haystack.contains('decode failed') ||
      haystack.contains('unsupported format') ||
      (haystack.contains('format') && haystack.contains('unsupported'));
}
