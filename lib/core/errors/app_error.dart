import 'error_code.dart';

/// A safe, serializable error returned through a [Result] boundary.
///
/// [AppException] is used for thrown infrastructure failures. This value
/// object is used when an operation deliberately returns a failure result.
class AppError {
  /// Creates an application error.
  const AppError({
    required this.code,
    required this.message,
    this.cause,
    this.stackTrace,
    this.isRecoverable = true,
  });

  /// Stable machine-readable error code.
  final ErrorCode code;

  /// Safe developer-facing diagnostic message.
  final String message;

  /// Original error when available for local diagnostics.
  final Object? cause;

  /// Original stack trace when available for local diagnostics.
  final StackTrace? stackTrace;

  /// Whether the caller can reasonably retry or recover.
  final bool isRecoverable;

  @override
  String toString() => 'AppError(code: ${code.name}, message: $message)';
}
