import 'package:comprezza/core/services/device_information_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('returns a non-sensitive capability snapshot without permissions', () {
    const PlatformDeviceInformationService service =
        PlatformDeviceInformationService();
    final DeviceInformation information = service.snapshot();

    expect(information.platform, isNotEmpty);
    expect(information.themeBrightness, isNotNull);
    expect(information.androidSdk, anyOf(isNull, isA<int>()));
  });
}
