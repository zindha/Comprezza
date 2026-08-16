import 'package:comprezza/core/errors/app_error.dart';
import 'package:comprezza/core/errors/error_code.dart';
import 'package:comprezza/core/models/result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('folds a successful result', () {
    const Result<int> result = Result<int>.success(42);
    expect(
      result.fold(onSuccess: (int value) => value, onFailure: (_) => 0),
      42,
    );
  });

  test('folds a failure result', () {
    const Result<int> result = Result<int>.failure(
      AppError(code: ErrorCode.unknown, message: 'failed'),
    );
    expect(
      result.fold(
        onSuccess: (_) => 'success',
        onFailure: (AppError error) => error.code,
      ),
      ErrorCode.unknown,
    );
  });
}
