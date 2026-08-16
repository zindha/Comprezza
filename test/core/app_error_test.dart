import 'dart:io';

import 'package:comprezza/core/errors/app_exception.dart';
import 'package:comprezza/core/errors/error_code.dart';
import 'package:comprezza/core/errors/error_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps filesystem failures to ioFailure', () {
    final AppException exception = ErrorMapper.map(
      const FileSystemException('failed'),
    );
    expect(exception.code, ErrorCode.ioFailure);
    expect(exception.isRecoverable, isTrue);
  });
}
