import 'package:comprezza/app/config/app_environment.dart';
import 'package:comprezza/features/compressor/domain/entities/application_entities.dart';
import 'package:comprezza/features/compressor/domain/settings/settings_models.dart';
import 'package:comprezza/features/compressor/domain/settings/settings_store.dart';
import 'package:comprezza/features/compressor/presentation/settings/settings_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  AppConfig config({BuildType type = BuildType.debug}) => AppConfig(
    environment: type == BuildType.release
        ? AppEnvironment.release
        : AppEnvironment.debug,
    buildType: type,
    runtimeEnvironment: type == BuildType.release
        ? Environment.production
        : Environment.local,
    enableDiagnostics: type != BuildType.release,
    enablePerformanceMonitoring: type == BuildType.debug,
  );

  test('JSON codec round trips preferences and clamps unsafe values', () {
    final SettingsPreferences source = const SettingsPreferences(
      theme: SettingsTheme.dark,
      compressionQuality: 88,
      defaultFormat: ImageFormat.webp,
      offlineProcessing: false,
      noCloudUpload: false,
      noAnalytics: false,
      noTracking: false,
      noUserAccounts: false,
      futureFeatureFlags: <String, bool>{'preview': true},
    );
    final SettingsPreferences decoded = SettingsJsonCodec.decode(
      SettingsJsonCodec.encode(source),
    );
    expect(decoded, source);
    expect(decoded.offlineProcessing, isFalse);
    expect(decoded.noCloudUpload, isFalse);
    expect(decoded.noAnalytics, isFalse);
    expect(decoded.noTracking, isFalse);
    expect(decoded.noUserAccounts, isFalse);
    final SettingsPreferences clamped = SettingsJsonCodec.fromMap(
      <String, Object?>{
        'compressionQuality': 999,
        'maximumCacheSizeMb': 1,
        'fontScale': 4,
      },
    );
    expect(clamped.compressionQuality, 100);
    expect(clamped.maximumCacheSizeMb, 32);
    expect(clamped.fontScale, 1.5);
    final SettingsPreferences sanitized =
        SettingsJsonCodec.fromMap(<String, Object?>{
          'defaultPreset': 'unknown',
          'defaultFormat': 'heic',
          'defaultTargetFileSizeKb': 999,
        });
    expect(sanitized.defaultPreset, 'balanced');
    expect(sanitized.defaultFormat, ImageFormat.jpeg);
    expect(sanitized.defaultTargetFileSizeKb, isNull);
  });

  test('JSON codec bounds future flags and resolves metadata conflicts', () {
    final Map<String, Object?> flags = <String, Object?>{
      for (int index = 0; index < 200; index++) 'flag_$index': true,
      List<String>.filled(129, 'x').join(): true,
    };
    final SettingsPreferences decoded =
        SettingsJsonCodec.fromMap(<String, Object?>{
          'alwaysKeepMetadata': true,
          'alwaysRemoveMetadata': true,
          'futureFeatureFlags': flags,
        });
    expect(decoded.alwaysKeepMetadata, isTrue);
    expect(decoded.alwaysRemoveMetadata, isFalse);
    expect(decoded.futureFeatureFlags.length, 128);
  });

  test(
    'controller preserves privacy guarantees when loading and updating',
    () async {
      final SettingsController controller = SettingsController(
        store: MemorySettingsStore(
          initial: const SettingsPreferences(
            offlineProcessing: false,
            noCloudUpload: false,
            noAnalytics: false,
            noTracking: false,
            noUserAccounts: false,
          ),
        ),
        configuration: config(),
      );
      addTearDown(controller.dispose);
      await controller.load();
      expect(controller.state.preferences.offlineProcessing, isTrue);
      expect(controller.state.preferences.noCloudUpload, isTrue);
      expect(controller.state.preferences.noAnalytics, isTrue);
      expect(controller.state.preferences.noTracking, isTrue);
      expect(controller.state.preferences.noUserAccounts, isTrue);
      await controller.update(
        controller.state.preferences.copyWith(noAnalytics: false),
      );
      expect(controller.state.preferences.noAnalytics, isTrue);
    },
  );

  test('export excludes sensitive metadata recursively', () {
    final String encoded = const SettingsExportBundle(
      settings: SettingsPreferences(),
      historyMetadata: <Map<String, Object?>>[
        <String, Object?>{
          'name': 'photo.jpg',
          'path': '/private/photo.jpg',
          'nested': <String, Object?>{'token': 'secret', 'bytes': 10},
        },
      ],
    ).encode();
    expect(encoded, contains('photo.jpg'));
    expect(encoded, contains('bytes'));
    expect(encoded, isNot(contains('/private/photo.jpg')));
    expect(encoded, isNot(contains('secret')));
  });

  test('recommendations are deterministic and prioritized', () {
    final List<SettingsRecommendation> recommendations =
        SettingsIntelligence.recommend(
          const SettingsIntelligenceSignals(
            cacheBytes: 600 * 1024 * 1024,
            freeStorageBytes: 1 * 1024 * 1024 * 1024,
            screenshotCount: 4,
            photoCount: 4,
            websiteImageCount: 4,
          ),
        );
    expect(
      recommendations.map((SettingsRecommendation item) => item.kind),
      <SettingsRecommendationKind>[
        SettingsRecommendationKind.largeCache,
        SettingsRecommendationKind.lowStorage,
        SettingsRecommendationKind.screenshots,
        SettingsRecommendationKind.photos,
        SettingsRecommendationKind.websiteImages,
      ],
    );
  });

  test('release builds remove developer options on load and import', () async {
    final MemorySettingsStore store = MemorySettingsStore(
      initial: const SettingsPreferences(
        developerOptionsUnlocked: true,
        developerLogging: true,
        verboseLogging: true,
        benchmarkMode: true,
      ),
    );
    final SettingsController controller = SettingsController(
      store: store,
      configuration: config(type: BuildType.release),
    );
    addTearDown(controller.dispose);
    await controller.load();
    expect(controller.state.developerOptionsVisible, isFalse);
    expect(controller.state.preferences.developerLogging, isFalse);
    await controller.importSettings(
      SettingsJsonCodec.encode(
        const SettingsPreferences(
          developerOptionsUnlocked: true,
          developerLogging: true,
        ),
      ),
    );
    expect(controller.state.developerOptionsVisible, isFalse);
    expect(controller.state.preferences.developerLogging, isFalse);
  });

  test(
    'debug version unlock persists and factory reset clears storage',
    () async {
      final MemorySettingsStore store = MemorySettingsStore();
      final SettingsController controller = SettingsController(
        store: store,
        configuration: config(),
        intelligenceSignals: const SettingsIntelligenceSignals(
          cacheBytes: 600 * 1024 * 1024,
        ),
      );
      addTearDown(controller.dispose);
      await controller.load();
      for (int i = 0; i < 7; i++) {
        await controller.tapVersion();
      }
      expect(controller.state.developerOptionsVisible, isTrue);
      expect((await store.load()).developerOptionsUnlocked, isTrue);
      await controller.factoryReset();
      expect(store.clearCacheCount, 1);
      expect(store.clearHistoryCount, 1);
      expect(controller.state.preferences, const SettingsPreferences());
    },
  );

  test('compression reset restores every compression preference', () async {
    final SettingsController controller = SettingsController(
      store: MemorySettingsStore(),
      configuration: config(),
    );
    addTearDown(controller.dispose);
    await controller.load();
    await controller.update(
      controller.state.preferences.copyWith(
        qualityPreview: false,
        enableSmartRecommendations: false,
        enableLiveSizeEstimation: false,
        enableCompressionBenchmark: true,
        compressToTargetSizeByDefault: true,
      ),
    );

    await controller.resetCompression();

    expect(controller.state.preferences.qualityPreview, isTrue);
    expect(controller.state.preferences.enableSmartRecommendations, isTrue);
    expect(controller.state.preferences.enableLiveSizeEstimation, isTrue);
    expect(controller.state.preferences.enableCompressionBenchmark, isFalse);
    expect(controller.state.preferences.compressToTargetSizeByDefault, isFalse);
  });

  test('restores the last persisted snapshot after a save failure', () async {
    final _FailingSettingsStore store = _FailingSettingsStore();
    final SettingsController controller = SettingsController(
      store: store,
      configuration: config(),
    );
    addTearDown(controller.dispose);
    await controller.load();

    store.failNextSave = true;
    await controller.update(
      controller.state.preferences.copyWith(compressionQuality: 91),
    );

    expect(controller.state.preferences.compressionQuality, 72);
    expect(controller.state.error, SettingsControllerError.saveFailed);
  });

  test('coalesces rapid updates instead of dropping the last value', () async {
    final SettingsController controller = SettingsController(
      store: MemorySettingsStore(),
      configuration: config(),
    );
    addTearDown(controller.dispose);
    await controller.load();
    final Future<void> first = controller.update(
      controller.state.preferences.copyWith(compressionQuality: 60),
    );
    final Future<void> second = controller.update(
      controller.state.preferences.copyWith(compressionQuality: 80),
    );
    await Future.wait(<Future<void>>[first, second]);
    expect(controller.state.preferences.compressionQuality, 80);
  });

  test(
    'import persists sanitized values and supports reset to no target',
    () async {
      final MemorySettingsStore store = MemorySettingsStore();
      final SettingsController controller = SettingsController(
        store: store,
        configuration: config(type: BuildType.release),
      );
      addTearDown(controller.dispose);
      await controller.load();
      await controller.importSettings(
        '{"defaultPreset":"unknown","defaultFormat":"heic","defaultTargetFileSizeKb":999}',
      );
      expect(controller.state.preferences.defaultPreset, 'balanced');
      expect(controller.state.preferences.defaultFormat, ImageFormat.jpeg);
      expect(controller.state.preferences.defaultTargetFileSizeKb, isNull);
      expect((await store.load()).defaultPreset, 'balanced');
    },
  );

  test('invalid import always clears the importing state', () async {
    final SettingsController controller = SettingsController(
      store: MemorySettingsStore(),
      configuration: config(),
    );
    addTearDown(controller.dispose);
    await controller.load();

    await controller.importSettings('{invalid');

    expect(controller.state.isImporting, isFalse);
    expect(controller.state.error, SettingsControllerError.importFailed);
  });

  test('recommendations follow the user toggle', () async {
    final SettingsController controller = SettingsController(
      store: MemorySettingsStore(),
      configuration: config(),
      intelligenceSignals: const SettingsIntelligenceSignals(
        cacheBytes: 600 * 1024 * 1024,
      ),
    );
    addTearDown(controller.dispose);
    await controller.load();
    expect(controller.state.recommendations, isNotEmpty);
    await controller.update(
      controller.state.preferences.copyWith(enableSmartRecommendations: false),
    );
    expect(controller.state.recommendations, isEmpty);

    await controller.update(
      controller.state.preferences.copyWith(
        enableSmartRecommendations: true,
        autoRecommendCompression: false,
      ),
    );
    expect(controller.state.recommendations, isEmpty);
  });
}

final class _FailingSettingsStore implements SettingsStore {
  final MemorySettingsStore _delegate = MemorySettingsStore();
  bool failNextSave = false;

  @override
  Future<SettingsPreferences> load() => _delegate.load();

  @override
  Future<SettingsStorageUsage> loadStorageUsage() =>
      _delegate.loadStorageUsage();

  @override
  Future<void> save(SettingsPreferences preferences) async {
    if (failNextSave) {
      failNextSave = false;
      throw StateError('test save failure');
    }
    await _delegate.save(preferences);
  }

  @override
  Future<String> export(SettingsExportBundle bundle) =>
      _delegate.export(bundle);

  @override
  Future<void> importSettings(String encoded) =>
      _delegate.importSettings(encoded);

  @override
  Future<void> clearCache() => _delegate.clearCache();

  @override
  Future<void> clearHistory() => _delegate.clearHistory();
}
