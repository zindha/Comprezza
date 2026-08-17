import 'dart:io';

import 'package:comprezza/core/errors/app_exception.dart';
import 'package:comprezza/core/errors/error_code.dart';
import 'package:comprezza/core/errors/error_mapper.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps filesystem failures to ioFailure', () {
    final AppException exception = ErrorMapper.map(
      const FileSystemException('failed'),
    );
    expect(exception.code, ErrorCode.ioFailure);
    expect(exception.isRecoverable, isTrue);
  });

  test(
    'maps storage, permission, memory, and format failures to friendly codes',
    () {
      final AppException noSpace = ErrorMapper.map(
        const FileSystemException(
          'write',
          '',
          OSError('No space left on device', 28),
        ),
      );
      expect(noSpace.code, ErrorCode.storageFull);
      expect(noSpace.message, 'There is not enough storage space available.');

      final AppException denied = ErrorMapper.map(
        const FileSystemException('open', '', OSError('Permission denied', 13)),
      );
      expect(denied.code, ErrorCode.permissionDenied);
      expect(
        denied.message,
        'Comprezza does not have permission to access that file.',
      );

      final AppException oom = ErrorMapper.map(const OutOfMemoryError());
      expect(oom.code, ErrorCode.outOfMemory);

      final AppException unsupported = ErrorMapper.map(
        PlatformException(code: 'unsupported format', message: 'Bad format'),
      );
      expect(unsupported.code, ErrorCode.unsupportedFormat);
      expect(unsupported.isRecoverable, isFalse);
    },
  );
}
