import '../../../domain/share_export/share_export_interfaces.dart';

/// Explicitly disabled until a separate privacy and Play review approves ads.
final class NoOpAdManager implements AdManager {
  const NoOpAdManager();

  @override
  bool get enabled => false;

  @override
  Future<void> request(AdPlacement placement) async {}
}
