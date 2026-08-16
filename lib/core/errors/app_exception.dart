import 'error_code.dart';

/// Typed exception raised inside infrastructure boundaries.
class AppException implements Exception {
  /// Creates an application exception.
  const AppException({
    required this.code,
    required this.message,
    this.cause,
    this.stackTrace,
    this.isRecoverable = true,
  });

  /// Stable error code.
  final ErrorCode code;

  /// Safe diagnostic message.
  final String message;

  /// Original cause retained for diagnostics.
  final Object? cause;

  /// Original stack trace retained for diagnostics.
  final StackTrace? stackTrace;

  /// Whether recovery or retry is reasonable.
  final bool isRecoverable;

  @override
  String toString() => 'AppException(code: $code, message: $message)';
}
