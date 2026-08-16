import 'app_error.dart';
import 'app_exception.dart';

/// Converts typed infrastructure exceptions to Result error values.
abstract final class ResultErrorAdapter {
  /// Converts [exception] without exposing raw plugin details to callers.
  static AppError fromException(AppException exception) {
    return AppError(
      code: exception.code,
      message: exception.message,
      cause: exception.cause,
      stackTrace: exception.stackTrace,
      isRecoverable: exception.isRecoverable,
    );
  }
}
