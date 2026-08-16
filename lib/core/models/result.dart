import '../errors/app_error.dart';

/// Represents either a successful value or a structured application error.
sealed class Result<T> {
  /// Creates a result.
  const Result();

  /// Creates a successful result.
  const factory Result.success(T value) = Success<T>;

  /// Creates a failed result.
  const factory Result.failure(AppError error) = Failure<T>;

  /// Whether this result contains a successful value.
  bool get isSuccess => this is Success<T>;

  /// Whether this result contains an error.
  bool get isFailure => this is Failure<T>;

  /// Applies the appropriate callback to this result.
  R fold<R>({
    required R Function(T value) onSuccess,
    required R Function(AppError error) onFailure,
  }) {
    return switch (this) {
      Success<T>(value: final T value) => onSuccess(value),
      Failure<T>(error: final AppError error) => onFailure(error),
    };
  }
}

/// Successful [Result] value.
final class Success<T> extends Result<T> {
  /// Creates a successful result.
  const Success(this.value);

  /// The successful value.
  final T value;
}

/// Failed [Result] value.
final class Failure<T> extends Result<T> {
  /// Creates a failed result.
  const Failure(this.error);

  /// The structured error.
  final AppError error;
}
