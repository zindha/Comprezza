import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';

/// Immutable snapshot of non-sensitive device capabilities.
class DeviceInformation {
  /// Creates a device information snapshot.
  const DeviceInformation({
    required this.platform,
    required this.androidSdk,
    required this.availableStorageBytes,
    required this.ramBytes,
    required this.orientation,
    required this.themeBrightness,
  });

  /// Platform label.
  final String platform;

  /// Android SDK when available; null elsewhere.
  final int? androidSdk;

  /// Available storage when a platform adapter can provide it.
  final int? availableStorageBytes;

  /// Approximate process RSS when available.
  final int? ramBytes;

  /// Current orientation inferred from display metrics.
  final DeviceOrientation orientation;

  /// System theme brightness.
  final Brightness themeBrightness;
}

/// Device capability service that requests no permissions.
abstract interface class DeviceInformationService {
  /// Reads a current capability snapshot.
  DeviceInformation snapshot();

  /// Returns available app-visible storage when a platform adapter provides it.
  Future<int?> availableStorageBytes();
}

/// Flutter/Dart implementation with conservative nullable values.
final class PlatformDeviceInformationService
    implements DeviceInformationService {
  /// Creates the device information service.
  const PlatformDeviceInformationService();

  @override
  DeviceInformation snapshot() {
    final ui.PlatformDispatcher dispatcher = ui.PlatformDispatcher.instance;
    final ui.FlutterView? view = dispatcher.views.isEmpty
        ? null
        : dispatcher.views.first;
    final double width = view == null ? 0 : view.physicalSize.width;
    final double height = view == null ? 0 : view.physicalSize.height;
    return DeviceInformation(
      platform: Platform.operatingSystem,
      androidSdk: Platform.isAndroid ? _androidSdkFromEnvironment() : null,
      availableStorageBytes: null,
      ramBytes: _currentRss(),
      orientation: width > height
          ? DeviceOrientation.landscapeLeft
          : DeviceOrientation.portraitUp,
      themeBrightness: dispatcher.platformBrightness,
    );
  }

  @override
  Future<int?> availableStorageBytes() async => null;

  int? _androidSdkFromEnvironment() {
    // Android SDK is intentionally left nullable without a native permission/API bridge.
    return null;
  }

  int? _currentRss() {
    try {
      return ProcessInfo.currentRss;
    } on Object {
      return null;
    }
  }
}
