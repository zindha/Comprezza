import '../../../domain/share_export/share_export_interfaces.dart';

/// Free baseline entitlement manager. All existing functionality remains free.
final class LocalPremiumManager implements PremiumManager {
  /// Creates a fail-closed manager. Premium status must come from a future
  /// verified billing adapter; it cannot be supplied by an arbitrary caller.
  const LocalPremiumManager({
    this.subscriptionStatus = SubscriptionStatus.free,
  });

  final SubscriptionStatus subscriptionStatus;

  @override
  SubscriptionStatus get status => subscriptionStatus;

  @override
  bool isAvailable(PremiumFeature feature) => false;
}

/// Immutable capability view derived from the local entitlement manager.
final class LocalPremiumCapabilities implements PremiumCapabilities {
  const LocalPremiumCapabilities({required this.manager});

  final PremiumManager manager;

  @override
  bool allows(PremiumFeature feature) => manager.isAvailable(feature);
}

/// Feature gate that fails closed for future premium-only capabilities.
final class LocalFeatureGate implements FeatureGate {
  const LocalFeatureGate({required this.capabilities});

  final PremiumCapabilities capabilities;

  @override
  bool isEnabled(PremiumFeature feature) => capabilities.allows(feature);
}
