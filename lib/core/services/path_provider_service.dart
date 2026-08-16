import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Resolves platform-managed directories needed by app-private storage.
abstract interface class AppPathProvider {
  /// Returns the process temporary directory.
  Future<Directory> temporaryDirectory();

  /// Returns the application support directory.
  Future<Directory> applicationSupportDirectory();
}

/// Production path provider backed by the path_provider plugin.
final class PlatformAppPathProvider implements AppPathProvider {
  /// Creates the platform path provider.
  const PlatformAppPathProvider();

  @override
  Future<Directory> temporaryDirectory() => getTemporaryDirectory();

  @override
  Future<Directory> applicationSupportDirectory() =>
      getApplicationSupportDirectory();
}
