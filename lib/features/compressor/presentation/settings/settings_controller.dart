import 'package:flutter/foundation.dart';

import '../../../../app/config/app_environment.dart';
import '../../domain/entities/application_entities.dart';
import '../../domain/settings/settings_models.dart';
import '../../domain/settings/settings_store.dart';

/// An in-memory store useful for previews and deterministic widget tests.
final class MemorySettingsStore implements SettingsStore {
  MemorySettingsStore({
    SettingsPreferences initial = const SettingsPreferences(),
  }) : _preferences = initial;

  SettingsPreferences _preferences;
  String? lastExport;
  int clearCacheCount = 0;
  int clearHistoryCount = 0;

  @override
  Future<SettingsPreferences> load() async => _preferences;

  @override
  Future<SettingsStorageUsage> loadStorageUsage() async =>
      const SettingsStorageUsage();

  @override
  Future<void> save(SettingsPreferences preferences) async =>
      _preferences = preferences;

  @override
  Future<void> clearCache() async => clearCacheCount++;

  @override
  Future<void> clearHistory() async => clearHistoryCount++;

  @override
  Future<String> export(SettingsExportBundle bundle) async {
    lastExport = bundle.encode();
    return lastExport!;
  }

  @override
  Future<void> importSettings(String encoded) async {
    _preferences = SettingsJsonCodec.decode(encoded);
  }
}

/// Presentation state for the Settings experience.
final class SettingsControllerState {
  const SettingsControllerState({
    this.preferences = const SettingsPreferences(),
    this.recommendations = const <SettingsRecommendation>[],
    this.storageUsage = const SettingsStorageUsage(),
    this.isLoading = true,
    this.isSaving = false,
    this.isImporting = false,
    this.isExporting = false,
    this.error,
    this.versionTapCount = 0,
  });

  final SettingsPreferences preferences;
  final List<SettingsRecommendation> recommendations;
  final SettingsStorageUsage storageUsage;
  final bool isLoading;
  final bool isSaving;
  final bool isImporting;
  final bool isExporting;
  final SettingsControllerError? error;
  final int versionTapCount;

  bool get developerOptionsVisible => preferences.developerOptionsUnlocked;

  SettingsControllerState copyWith({
    SettingsPreferences? preferences,
    List<SettingsRecommendation>? recommendations,
    SettingsStorageUsage? storageUsage,
    bool? isLoading,
    bool? isSaving,
    bool? isImporting,
    bool? isExporting,
    SettingsControllerError? error,
    bool clearError = false,
    int? versionTapCount,
  }) => SettingsControllerState(
    preferences: preferences ?? this.preferences,
    recommendations: recommendations ?? this.recommendations,
    storageUsage: storageUsage ?? this.storageUsage,
    isLoading: isLoading ?? this.isLoading,
    isSaving: isSaving ?? this.isSaving,
    isImporting: isImporting ?? this.isImporting,
    isExporting: isExporting ?? this.isExporting,
    error: clearError ? null : error ?? this.error,
    versionTapCount: versionTapCount ?? this.versionTapCount,
  );
}

/// Coordinates settings mutations without changing frozen application state.
final class SettingsController extends ChangeNotifier {
  SettingsController({
    required SettingsStore store,
    required AppConfig configuration,
    SettingsIntelligenceSignals intelligenceSignals =
        const SettingsIntelligenceSignals(),
  }) : _store = store,
       _configuration = configuration,
       _intelligenceSignals = intelligenceSignals,
       _state = const SettingsControllerState();

  final SettingsStore _store;
  final AppConfig _configuration;
  final SettingsIntelligenceSignals _intelligenceSignals;
  SettingsControllerState _state;
  SettingsPreferences _lastPersisted = const SettingsPreferences();
  SettingsPreferences? _pendingSave;
  bool _saveLoopActive = false;
  Future<void>? _saveFuture;
  Future<void> _persistenceTail = Future<void>.value();
  bool _disposed = false;
  bool _loadStarted = false;
  bool _loaded = false;
  Future<void>? _loadFuture;
  int _operation = 0;

  SettingsControllerState get state => _state;
  bool get isRelease => _configuration.isRelease;
  bool get hasLoaded => _loaded;

  Future<void> load({bool force = false}) {
    if (_disposed) return Future<void>.value();
    if (!force && _loaded) return Future<void>.value();
    if (!force && _loadStarted && _loadFuture != null) return _loadFuture!;
    _loadStarted = true;
    final Future<void> future = _loadInternal();
    _loadFuture = future;
    return future;
  }

  Future<void> _loadInternal() async {
    final int operation = ++_operation;
    _set(
      _state.copyWith(isLoading: true, isImporting: false, clearError: true),
    );
    try {
      final SettingsPreferences preferences = await _store.load();
      SettingsStorageUsage usage = _state.storageUsage;
      try {
        usage = await _store.loadStorageUsage();
      } catch (_) {
        // A storage scan must not discard otherwise valid preferences.
      }
      if (_disposed || operation != _operation) return;
      final SettingsPreferences safePreferences = _sanitizePreferences(
        preferences,
      );
      if (preferences != safePreferences) {
        try {
          await _enqueuePersistence(() => _store.save(safePreferences));
        } catch (_) {
          // Continue with the sanitized in-memory state; the next mutation retries.
        }
      }
      if (_disposed || operation != _operation) return;
      _lastPersisted = safePreferences;
      _loaded = true;
      _set(
        _state.copyWith(
          preferences: safePreferences,
          recommendations: _recommendationsFor(safePreferences),
          storageUsage: usage,
          isLoading: false,
          clearError: true,
        ),
      );
    } catch (_) {
      if (!_disposed && operation == _operation) {
        _set(
          _state.copyWith(
            isLoading: false,
            error: SettingsControllerError.loadFailed,
          ),
        );
      }
    } finally {
      if (operation == _operation) {
        _loadFuture = null;
        if (!_loaded) _loadStarted = false;
      }
    }
  }

  void clearError() {
    if (_state.error != null) _set(_state.copyWith(clearError: true));
  }

  Future<void> update(SettingsPreferences preferences) async {
    if (_disposed || _state.isImporting) return;
    ++_operation;
    // A mutation supersedes an in-flight initial load. Clear the deduplication
    // markers so a later explicit load cannot remain attached to a completed,
    // cancelled future.
    if (!_loaded) {
      _loadStarted = false;
      _loadFuture = null;
    }
    final SettingsPreferences safePreferences = _sanitizePreferences(
      preferences,
    );
    _loaded = true;
    _pendingSave = safePreferences;
    _set(
      _state.copyWith(
        preferences: safePreferences,
        recommendations: _recommendationsFor(safePreferences),
        isLoading: false,
        isSaving: true,
        isImporting: false,
        clearError: true,
      ),
    );
    if (_saveLoopActive) {
      final Future<void>? saveFuture = _saveFuture;
      if (saveFuture != null) await saveFuture;
      return;
    }
    _saveLoopActive = true;
    final Future<void> saveFuture = _drainPendingSaves();
    _saveFuture = saveFuture;
    try {
      await saveFuture;
    } finally {
      if (identical(_saveFuture, saveFuture)) _saveFuture = null;
    }
  }

  Future<void> tapVersion() async {
    if (_configuration.isRelease ||
        _state.preferences.developerOptionsUnlocked) {
      return;
    }
    final int taps = _state.versionTapCount + 1;
    if (taps >= 7) {
      await update(_state.preferences.copyWith(developerOptionsUnlocked: true));
      if (!_disposed) _set(_state.copyWith(versionTapCount: taps));
      return;
    }
    _set(_state.copyWith(versionTapCount: taps));
  }

  Future<void> resetAppearance() => update(
    _state.preferences.copyWith(
      theme: SettingsTheme.system,
      dynamicColors: true,
      adaptiveIcons: true,
      largeUiMode: false,
      compactUiMode: false,
      animationSpeed: SettingsAnimationSpeed.full,
      reduceMotion: false,
      fontScale: 1,
      displayDensity: SettingsDisplayDensity.comfortable,
    ),
  );

  Future<void> resetCompression() => update(
    _state.preferences.copyWith(
      defaultPreset: 'balanced',
      defaultFormat: ImageFormat.jpeg,
      compressionQuality: 72,
      clearDefaultTargetFileSize: true,
      resizeMode: SettingsResizeMode.original,
      alwaysKeepMetadata: false,
      alwaysRemoveMetadata: true,
      preferredAlgorithm: CompressionAlgorithm.automatic,
      qualityPreview: true,
      enableSmartRecommendations: true,
      enableLiveSizeEstimation: true,
      enableCompressionBenchmark: false,
      compressToTargetSizeByDefault: false,
    ),
  );

  Future<void> resetRecommendations() => update(
    _state.preferences.copyWith(
      enableSmartRecommendations: true,
      autoRecommendCompression: true,
      recommendationsEnabled: true,
    ),
  );

  Future<void> clearCache() async {
    await _runDataAction(_store.clearCache);
  }

  Future<void> clearHistory() async {
    await _runDataAction(_store.clearHistory);
  }

  Future<void> resetStorage() async {
    await _runDataAction(() async {
      await _store.clearCache();
      await _store.clearHistory();
    });
  }

  Future<void> factoryReset() async {
    if (_disposed) return;
    final bool cleared = await _runDataActionChecked(() async {
      await _store.clearCache();
      await _store.clearHistory();
    });
    if (!cleared || _disposed) return;
    await update(const SettingsPreferences());
  }

  Future<String?> exportSettings({
    List<Map<String, Object?>> compressionPresets =
        const <Map<String, Object?>>[],
    List<Map<String, Object?>> historyMetadata = const <Map<String, Object?>>[],
  }) async {
    if (_disposed || _state.isExporting) return null;
    _set(_state.copyWith(isExporting: true, clearError: true));
    try {
      final String result = await _store.export(
        SettingsExportBundle(
          settings: _state.preferences,
          compressionPresets: compressionPresets,
          historyMetadata: historyMetadata,
        ),
      );
      if (!_disposed) {
        _set(_state.copyWith(isExporting: false, clearError: true));
      }
      return result;
    } catch (_) {
      if (!_disposed) {
        _set(
          _state.copyWith(
            isExporting: false,
            error: SettingsControllerError.exportFailed,
          ),
        );
      }
      return null;
    }
  }

  Future<void> importSettings(String encoded) async {
    if (_disposed || _state.isImporting) return;
    final int operation = ++_operation;
    if (!_loaded) {
      _loadStarted = false;
      _loadFuture = null;
    }
    // An import is authoritative at the point it is requested. Drop only
    // unsaved intermediate values, then wait for the active save drain so an
    // older queued mutation cannot overwrite the imported snapshot.
    _pendingSave = null;
    final Future<void>? activeSave = _saveFuture;
    _set(
      _state.copyWith(isImporting: true, isLoading: false, clearError: true),
    );
    try {
      if (activeSave != null) await activeSave;
      if (_disposed) return;
      final SettingsPreferences loaded = SettingsJsonCodec.decode(encoded);
      if (_disposed) return;
      final SettingsPreferences preferences = _sanitizePreferences(loaded);
      if (_disposed || operation != _operation) return;
      await _enqueuePersistence(() => _store.save(preferences));
      if (_disposed || operation != _operation) return;
      _lastPersisted = preferences;
      _loaded = true;
      _set(
        _state.copyWith(
          preferences: preferences,
          recommendations: _recommendationsFor(preferences),
          isImporting: false,
          clearError: true,
        ),
      );
    } catch (_) {
      if (!_disposed) {
        _set(
          _state.copyWith(
            isImporting: false,
            error: SettingsControllerError.importFailed,
          ),
        );
      }
    } finally {
      if (!_disposed && _state.isImporting) {
        _set(_state.copyWith(isImporting: false));
      }
    }
  }

  SettingsPreferences _sanitizePreferences(SettingsPreferences preferences) {
    final SettingsPreferences developerSafe = _configuration.isRelease
        ? preferences.copyWith(
            developerOptionsUnlocked: false,
            developerLogging: false,
            verboseLogging: false,
            benchmarkMode: false,
          )
        : preferences;
    // These are product privacy guarantees, not user-configurable switches.
    return developerSafe.copyWith(
      offlineProcessing: true,
      noCloudUpload: true,
      noAnalytics: true,
      noTracking: true,
      noUserAccounts: true,
    );
  }

  List<SettingsRecommendation> _recommendationsFor(
    SettingsPreferences preferences,
  ) =>
      preferences.recommendationsEnabled &&
          preferences.enableSmartRecommendations &&
          preferences.autoRecommendCompression
      ? SettingsIntelligence.recommend(_intelligenceSignals)
      : const <SettingsRecommendation>[];

  Future<void> _drainPendingSaves() async {
    try {
      while (!_disposed && _pendingSave != null) {
        final SettingsPreferences next = _pendingSave!;
        _pendingSave = null;
        try {
          await _enqueuePersistence(() => _store.save(next));
          _lastPersisted = next;
          if (!_disposed) _set(_state.copyWith(clearError: true));
        } catch (_) {
          if (!_disposed) {
            if (_pendingSave == null) {
              _set(
                _state.copyWith(
                  preferences: _lastPersisted,
                  recommendations: _recommendationsFor(_lastPersisted),
                ),
              );
            }
            _set(
              _state.copyWith(
                isSaving: _pendingSave != null,
                error: SettingsControllerError.saveFailed,
              ),
            );
          }
        }
      }
    } finally {
      _saveLoopActive = false;
      if (!_disposed) _set(_state.copyWith(isSaving: false));
    }
  }

  Future<void> _runDataAction(Future<void> Function() action) async {
    await _runDataActionChecked(action);
  }

  Future<bool> _runDataActionChecked(Future<void> Function() action) async {
    if (_disposed) return false;
    try {
      await _enqueuePersistence(action);
      await _refreshStorageUsage();
      return !_disposed;
    } catch (_) {
      if (!_disposed) {
        _set(
          _state.copyWith(error: SettingsControllerError.storageActionFailed),
        );
      }
      return false;
    }
  }

  Future<void> _refreshStorageUsage() async {
    if (_disposed) return;
    try {
      final SettingsStorageUsage usage = await _store.loadStorageUsage();
      if (!_disposed) _set(_state.copyWith(storageUsage: usage));
    } catch (_) {
      // Storage cleanup succeeded even when a follow-up usage scan is unavailable.
    }
  }

  Future<void> _enqueuePersistence(Future<void> Function() action) {
    final Future<void> operation = _persistenceTail.then((_) async {
      if (_disposed) return;
      await action();
    });
    _persistenceTail = operation.then<void>((_) {}, onError: (_, _) {});
    return operation;
  }

  void _set(SettingsControllerState next) {
    if (_disposed) return;
    _state = next;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _operation++;
    _pendingSave = null;
    _saveFuture = null;
    super.dispose();
  }
}
