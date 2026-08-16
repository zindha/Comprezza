import '../../../../core/models/result.dart';
import 'share_export_models.dart';

/// Opens the operating-system Sharesheet using local content URIs or files.
abstract interface class ShareDispatcher {
  Future<Result<ShareDispatchStatus>> dispatch(SharePayloadBundle payload);
}

/// Exports generated files through the existing managed file boundary.
/// Cooperative cancellation for local staging work.
abstract interface class ShareExportOperation {
  bool get isCancelled;
  void cancel();
}

abstract interface class ShareExportService {
  Future<Result<ExportOutcome>> export(
    ExportRequest request, {
    ShareExportOperation? operation,
  });
  Future<Result<ShareOutcome>> share(
    ShareRequest request, {
    ShareExportOperation? operation,
  });
}

/// Validates names and destination identifiers before any file operation.
abstract interface class ExportSecurityPolicy {
  Future<Result<void>> validateRequest(ExportRequest request);
  Future<Result<void>> validateShareRequest(ShareRequest request);
  String sanitizeFilename(String value);
}

/// Computes local, privacy-preserving sharing suggestions.
abstract interface class ShareRecommendationEngine {
  List<ShareRecommendation> recommend(Iterable<ExportAsset> assets);
}

/// Identifies premium capabilities without implementing payments or billing.
enum PremiumFeature {
  unlimitedBatch,
  unlimitedFolderCompression,
  advancedStatistics,
  advancedBenchmark,
  unlimitedHistory,
  priorityQueue,
  advancedExport,
  futureAiFeatures,
  adFree,
}

enum SubscriptionStatus { free, premium, unknown }

/// Local entitlement manager. Billing is deliberately a future adapter.
abstract interface class PremiumManager {
  SubscriptionStatus get status;
  bool isAvailable(PremiumFeature feature);
}

/// Stable capability snapshot used by UI and future billing adapters.
abstract interface class PremiumCapabilities {
  bool allows(PremiumFeature feature);
}

/// Central feature-gating port. Existing free functionality must remain open.
abstract interface class FeatureGate {
  bool isEnabled(PremiumFeature feature);
}

/// Safe placement contract for future ads. Implementations must never block
/// compression, export, sharing, settings, history, or app startup.
enum AdPlacement { banner, interstitial, rewarded, native }

abstract interface class AdManager {
  bool get enabled;
  Future<void> request(AdPlacement placement);
}

/// Deletes staged artifacts after a failed or expired operation.
abstract interface class ShareExportCleanup {
  Future<void> deleteGenerated(String path);
}

/// Versioned local/cloud backup boundary. No cloud implementation is included.
abstract interface class BackupAdapter {
  Future<Result<String>> createBackup();
  Future<Result<void>> restoreBackup(String encodedBackup);
}

/// Future Comprezza product family identifier.
enum EcosystemProduct { photo, video, pdf, convert, resize }

/// Shared ecosystem contract for future product modules.
abstract interface class EcosystemAdapter {
  EcosystemProduct get product;
  Map<String, Object?> get sharedSettings;
}
