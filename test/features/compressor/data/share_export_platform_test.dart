import 'dart:io';

import 'package:comprezza/core/errors/error_code.dart';
import 'package:comprezza/core/models/result.dart';
import 'package:comprezza/features/compressor/data/services/file_management/interfaces/file_management_interfaces.dart';
import 'package:comprezza/features/compressor/data/services/file_management/models/file_management_models.dart';
import 'package:comprezza/features/compressor/data/services/share_export/export_security_policy.dart';
import 'package:comprezza/features/compressor/data/services/share_export/local_premium_manager.dart';
import 'package:comprezza/features/compressor/data/services/share_export/local_share_export_service.dart';
import 'package:comprezza/features/compressor/data/services/share_export/local_share_recommendation_engine.dart';
import 'package:comprezza/features/compressor/data/services/share_export/noop_ad_manager.dart';
import 'package:comprezza/features/compressor/domain/share_export/share_export_interfaces.dart';
import 'package:comprezza/features/compressor/domain/share_export/share_export_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  ExportAsset asset({
    String path = '/private/source/photo.jpg',
    String name = 'photo.jpg',
    int bytes = 400,
    int? originalBytes = 1000,
    ExportImageFormat format = ExportImageFormat.jpeg,
    bool hasAlpha = false,
  }) => ExportAsset(
    id: 'photo-1',
    filePath: path,
    displayName: name,
    bytes: bytes,
    originalBytes: originalBytes,
    width: 1200,
    height: 800,
    format: format,
    preset: 'Balanced',
    metadataStatus: ExportMetadataStatus.removed,
    hasAlpha: hasAlpha,
  );

  test(
    'security policy rejects traversal, remote paths, and invalid assets',
    () async {
      final LocalExportSecurityPolicy policy = LocalExportSecurityPolicy(
        storage: _FakeStorageManager(),
      );

      final Result<void> traversal = await policy.validateRequest(
        ExportRequest(assets: <ExportAsset>[asset(name: '../../escape.jpg')]),
      );
      final Result<void> remote = await policy.validateRequest(
        ExportRequest(
          assets: <ExportAsset>[asset(path: 'https://example.test/a')],
        ),
      );
      final Result<void> empty = await policy.validateRequest(
        ExportRequest(assets: <ExportAsset>[asset(bytes: 0)]),
      );

      expect(traversal, isA<Success<void>>());
      expect(remote, isA<Failure<void>>());
      expect((remote as Failure<void>).error.code, ErrorCode.unsafePath);
      expect(empty, isA<Failure<void>>());
      expect(policy.sanitizeFilename('../../photo?.jpg'), 'photo_.jpg');
    },
  );

  test('rejects a symlink escaping the authorized source root', () async {
    final Directory root = await Directory.systemTemp.createTemp('share_');
    final Directory outside = await Directory.systemTemp.createTemp('outside_');
    addTearDown(() async {
      if (await root.exists()) await root.delete(recursive: true);
      if (await outside.exists()) await outside.delete(recursive: true);
    });
    final File target = File('${outside.path}/photo.jpg')
      ..writeAsStringSync('image');
    final String linkPath = '${root.path}/link.jpg';
    await Link(linkPath).create(target.path);
    final LocalExportSecurityPolicy policy = LocalExportSecurityPolicy(
      storage: _FakeStorageManager(roots: <String>[root.path]),
    );

    final Result<void> result = await policy.validateRequest(
      ExportRequest(assets: <ExportAsset>[asset(path: linkPath)]),
    );

    expect(result, isA<Failure<void>>());
    expect((result as Failure<void>).error.code, ErrorCode.unsafePath);
  });

  test('security policy requires originals for comparison sharing', () async {
    final LocalExportSecurityPolicy policy = LocalExportSecurityPolicy(
      storage: _FakeStorageManager(),
    );

    final Result<void> result = await policy.validateShareRequest(
      ShareRequest(
        assets: <ShareAsset>[ShareAsset(compressed: asset())],
        payload: SharePayload.originalAndCompressed,
      ),
    );

    expect(result, isA<Failure<void>>());
    expect((result as Failure<void>).error.code, ErrorCode.invalidArgument);
  });

  test(
    'local share/export service produces bounded reports and paths',
    () async {
      final _FakeExportService exporter = _FakeExportService();
      final _FakeDispatcher dispatcher = _FakeDispatcher();
      final LocalShareExportService service = LocalShareExportService(
        exporter: exporter,
        dispatcher: dispatcher,
        security: LocalExportSecurityPolicy(storage: _FakeStorageManager()),
        cleanup: const _FakeCleanup(),
        now: () => DateTime.utc(2026, 8, 6),
      );

      final Result<ExportOutcome> exported = await service.export(
        ExportRequest(assets: <ExportAsset>[asset()]),
      );
      final Result<ShareOutcome> shared = await service.share(
        ShareRequest(assets: <ShareAsset>[ShareAsset(compressed: asset())]),
      );

      expect(exported, isA<Success<ExportOutcome>>());
      final ExportOutcome exportOutcome =
          (exported as Success<ExportOutcome>).value;
      expect(exportOutcome.paths.single, contains('/managed/'));
      expect(exportOutcome.report.savedBytes, 600);
      expect(shared, isA<Success<ShareOutcome>>());
      final ShareOutcome shareOutcome = (shared as Success<ShareOutcome>).value;
      expect(shareOutcome.files, hasLength(1));
      expect(dispatcher.payload?.files, hasLength(1));
      expect(shareOutcome.status, ShareDispatchStatus.shared);
      expect(exporter.requests.single.originalName, startsWith('photo'));
      expect(
        exporter.shareRequests.single.originalName,
        startsWith('comprezza_'),
      );
    },
  );

  test('comparison sharing reports only compressed metrics', () async {
    final _FakeExportService exporter = _FakeExportService();
    final LocalShareExportService service = LocalShareExportService(
      exporter: exporter,
      dispatcher: _FakeDispatcher(),
      security: LocalExportSecurityPolicy(storage: _FakeStorageManager()),
      cleanup: const _FakeCleanup(),
    );

    final ShareAsset value = ShareAsset(
      original: asset(path: '/private/source/original.jpg', bytes: 1000),
      compressed: asset(),
    );
    final Result<ShareOutcome> result = await service.share(
      ShareRequest(
        assets: <ShareAsset>[value],
        payload: SharePayload.originalAndCompressed,
      ),
    );

    expect(result, isA<Success<ShareOutcome>>());
    final ShareOutcome outcome = (result as Success<ShareOutcome>).value;
    expect(outcome.files, hasLength(2));
    expect(outcome.report.items, hasLength(1));
    expect(outcome.report.savedBytes, 600);
  });

  test('report serialization includes required export metadata', () {
    final ExportReport report = ExportReport(
      items: <ExportItemReport>[
        const ExportItemReport(
          assetId: '1',
          outputName: 'photo_Comprezza.jpg',
          originalBytes: 1000,
          compressedBytes: 400,
          savedBytes: 600,
          compressionRatio: 2.5,
          processingTime: Duration(milliseconds: 42),
          format: ExportImageFormat.jpeg,
          width: 1200,
          height: 800,
          preset: 'Balanced',
          metadataStatus: ExportMetadataStatus.removed,
          destination: ExportDestinationKind.appManaged,
        ),
      ],
      destination: ExportDestinationKind.appManaged,
      createdAt: DateTime.utc(2026, 8, 6),
    );

    final String encoded = report.encode();

    expect(encoded, contains('originalBytes'));
    expect(encoded, contains('processingTimeMs'));
    expect(encoded, contains('metadataStatus'));
    expect(report.compressionRatio, 2.5);
  });

  test('smart sharing stays deterministic and local', () {
    const LocalShareRecommendationEngine engine =
        LocalShareRecommendationEngine();

    final List<ShareRecommendation> recommendations = engine.recommend(
      <ExportAsset>[
        asset(
          bytes: 12 * 1024 * 1024,
          format: ExportImageFormat.png,
          hasAlpha: true,
        ),
      ],
    );

    expect(
      recommendations.map((ShareRecommendation item) => item.kind),
      containsAll(<ShareRecommendationKind>[
        ShareRecommendationKind.largeFile,
        ShareRecommendationKind.transparentPng,
        ShareRecommendationKind.websiteImage,
      ]),
    );
  });

  test(
    'premium foundation does not restrict the free baseline and ads stay off',
    () async {
      const LocalPremiumManager premium = LocalPremiumManager();
      const NoOpAdManager ads = NoOpAdManager();

      expect(premium.status, SubscriptionStatus.free);
      expect(premium.isAvailable(PremiumFeature.advancedExport), isFalse);
      expect(premium.isAvailable(PremiumFeature.adFree), isFalse);
      expect(ads.enabled, isFalse);
      await ads.request(AdPlacement.interstitial);
    },
  );
}

final class _FakeStorageManager implements StorageManager {
  _FakeStorageManager({List<String>? roots})
    : roots = roots ?? <String>['/private/source'];

  final List<String> roots;

  @override
  Future<Result<Map<StorageLocation, Directory>>> directories() async {
    final Map<StorageLocation, Directory> value = <StorageLocation, Directory>{
      for (final String root in roots)
        StorageLocation.temporary: Directory(root),
    };
    if (roots.isNotEmpty) {
      value[StorageLocation.compression] = Directory(roots.first);
      value[StorageLocation.exports] = Directory(roots.first);
    }
    return Result<Map<StorageLocation, Directory>>.success(value);
  }

  @override
  Future<Result<Directory>> directory(StorageLocation location) async =>
      Result<Directory>.success(Directory(roots.first));
}

final class _FakeExportService implements ExportService {
  int _counter = 0;
  final List<FileNameRequest> requests = <FileNameRequest>[];
  final List<FileNameRequest> shareRequests = <FileNameRequest>[];

  @override
  Future<Result<ExportedFile>> export(
    String sourcePath, {
    required FileNameRequest naming,
  }) async {
    requests.add(naming);
    return _file(StorageLocation.exports);
  }

  @override
  Future<Result<ExportedFile>> prepareShareCopy(
    String sourcePath, {
    required FileNameRequest naming,
  }) async {
    shareRequests.add(naming);
    return _file(StorageLocation.temporary);
  }

  Result<ExportedFile> _file(StorageLocation location) {
    _counter++;
    return Result<ExportedFile>.success(
      ExportedFile(
        path: '/managed/$_counter.jpg',
        name: 'photo_Comprezza.jpg',
        bytes: 400,
        location: location,
      ),
    );
  }
}

final class _FakeCleanup implements ShareExportCleanup {
  const _FakeCleanup();

  @override
  Future<void> deleteGenerated(String path) async {}
}

final class _FakeDispatcher implements ShareDispatcher {
  SharePayloadBundle? payload;

  @override
  Future<Result<ShareDispatchStatus>> dispatch(SharePayloadBundle next) async {
    payload = next;
    return const Result<ShareDispatchStatus>.success(
      ShareDispatchStatus.shared,
    );
  }
}
