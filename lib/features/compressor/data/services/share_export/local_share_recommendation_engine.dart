import '../../../domain/share_export/share_export_interfaces.dart';
import '../../../domain/share_export/share_export_models.dart';

/// Produces explainable local suggestions without analytics, network, or IDs.
final class LocalShareRecommendationEngine
    implements ShareRecommendationEngine {
  const LocalShareRecommendationEngine();

  @override
  List<ShareRecommendation> recommend(Iterable<ExportAsset> assets) {
    final List<ExportAsset> values = assets.toList(growable: false);
    if (values.isEmpty) return const <ShareRecommendation>[];
    final List<ShareRecommendation> recommendations = <ShareRecommendation>[];
    final ExportAsset first = values.first;
    if (first.bytes >= 10 * 1024 * 1024) {
      recommendations.add(
        const ShareRecommendation(
          kind: ShareRecommendationKind.largeFile,
          confidence: 1,
        ),
      );
    } else if (first.bytes <= 1024 * 1024) {
      recommendations.add(
        const ShareRecommendation(
          kind: ShareRecommendationKind.smallFile,
          confidence: .8,
        ),
      );
    }
    if (first.format == ExportImageFormat.png && first.hasAlpha) {
      recommendations.add(
        const ShareRecommendation(
          kind: ShareRecommendationKind.transparentPng,
          confidence: .85,
        ),
      );
    }
    if (first.width >= 1200 || first.height >= 1200) {
      recommendations.add(
        const ShareRecommendation(
          kind: ShareRecommendationKind.websiteImage,
          confidence: .6,
        ),
      );
    }
    return List<ShareRecommendation>.unmodifiable(recommendations);
  }
}
