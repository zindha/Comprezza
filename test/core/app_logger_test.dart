import 'package:comprezza/core/services/app_logger.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('disabled logger accepts diagnostics without throwing', () {
    const AppLogger logger = ConsoleAppLogger(enabled: false);

    expect(
      () => logger.error(
        'test',
        cause: StateError('private detail'),
        context: <String, Object?>{'path': '/private/path'},
      ),
      returnsNormally,
    );
  });
}
