import 'dart:convert';

import '../entities/application_entities.dart';

/// Settings operation failures represented without localized strings.
enum SettingsControllerError {
  loadFailed,
  saveFailed,
  exportFailed,
  importFailed,
  storageActionFailed,
}

/// Theme selection exposed by the settings experience.
enum SettingsTheme { system, light, dark }

/// Compression algorithm preference.
enum CompressionAlgorithm { automatic, jpeg, png, webp }

/// Resize behavior applied to new workflows.
enum SettingsResizeMode { original, percentage75, percentage50, percentage25 }

/// Cleanup cadence for app-generated temporary files.
enum CleanupInterval { never, daily, weekly, monthly }

/// Motion preference exposed to users.
enum SettingsAnimationSpeed { full, reduced, off }

/// Density preference for settings and workflow surfaces.
enum SettingsDisplayDensity { comfortable, compact }

/// A typed, immutable snapshot of all user-controlled settings.
final class SettingsPreferences {
  const SettingsPreferences({
    this.theme = SettingsTheme.system,
    this.defaultPreset = 'balanced',
    this.defaultFormat = ImageFormat.jpeg,
    this.compressionQuality = 72,
    this.defaultTargetFileSizeKb,
    this.resizeMode = SettingsResizeMode.original,
    this.rememberLastUsedSettings = true,
    this.openLastScreen = false,
    this.autoAnalyzeImages = true,
    this.autoRecommendCompression = true,
    this.preferredAlgorithm = CompressionAlgorithm.automatic,
    this.alwaysKeepMetadata = false,
    this.alwaysRemoveMetadata = true,
    this.enableSmartRecommendations = true,
    this.enableLiveSizeEstimation = true,
    this.enableCompressionBenchmark = false,
    this.qualityPreview = true,
    this.compressToTargetSizeByDefault = false,
    this.autoDeleteTemporaryFiles = true,
    this.cleanupInterval = CleanupInterval.daily,
    this.maximumCacheSizeMb = 256,
    this.compressionHistorySizeLimit = 500,
    this.autoDeleteOldHistory = false,
    this.dynamicColors = true,
    this.adaptiveIcons = true,
    this.largeUiMode = false,
    this.compactUiMode = false,
    this.animationSpeed = SettingsAnimationSpeed.full,
    this.reduceMotion = false,
    this.fontScale = 1,
    this.displayDensity = SettingsDisplayDensity.comfortable,
    this.screenReaders = true,
    this.highContrast = false,
    this.largeTouchTargets = true,
    this.dynamicTextScaling = true,
    this.reduceAnimations = false,
    this.colorBlindFriendlyPalette = false,
    this.accessibleProgressAnnouncements = true,
    this.accessibleErrorAnnouncements = true,
    this.semanticLabels = true,
    this.offlineProcessing = true,
    this.noCloudUpload = true,
    this.noAnalytics = true,
    this.noTracking = true,
    this.noUserAccounts = true,
    this.benchmarkMode = false,
    this.developerLogging = false,
    this.verboseLogging = false,
    this.futureFeatureFlags = const <String, bool>{},
    this.developerOptionsUnlocked = false,
    this.recommendationsEnabled = true,
  });

  final SettingsTheme theme;
  final String defaultPreset;
  final ImageFormat defaultFormat;
  final int compressionQuality;
  final int? defaultTargetFileSizeKb;
  final SettingsResizeMode resizeMode;
  final bool rememberLastUsedSettings;
  final bool openLastScreen;
  final bool autoAnalyzeImages;
  final bool autoRecommendCompression;
  final CompressionAlgorithm preferredAlgorithm;
  final bool alwaysKeepMetadata;
  final bool alwaysRemoveMetadata;
  final bool enableSmartRecommendations;
  final bool enableLiveSizeEstimation;
  final bool enableCompressionBenchmark;
  final bool qualityPreview;
  final bool compressToTargetSizeByDefault;
  final bool autoDeleteTemporaryFiles;
  final CleanupInterval cleanupInterval;
  final int maximumCacheSizeMb;
  final int compressionHistorySizeLimit;
  final bool autoDeleteOldHistory;
  final bool dynamicColors;
  final bool adaptiveIcons;
  final bool largeUiMode;
  final bool compactUiMode;
  final SettingsAnimationSpeed animationSpeed;
  final bool reduceMotion;
  final double fontScale;
  final SettingsDisplayDensity displayDensity;
  final bool screenReaders;
  final bool highContrast;
  final bool largeTouchTargets;
  final bool dynamicTextScaling;
  final bool reduceAnimations;
  final bool colorBlindFriendlyPalette;
  final bool accessibleProgressAnnouncements;
  final bool accessibleErrorAnnouncements;
  final bool semanticLabels;
  final bool offlineProcessing;
  final bool noCloudUpload;
  final bool noAnalytics;
  final bool noTracking;
  final bool noUserAccounts;
  final bool benchmarkMode;
  final bool developerLogging;
  final bool verboseLogging;
  final Map<String, bool> futureFeatureFlags;
  final bool developerOptionsUnlocked;
  final bool recommendationsEnabled;

  SettingsPreferences copyWith({
    SettingsTheme? theme,
    String? defaultPreset,
    ImageFormat? defaultFormat,
    int? compressionQuality,
    int? defaultTargetFileSizeKb,
    bool clearDefaultTargetFileSize = false,
    SettingsResizeMode? resizeMode,
    bool? rememberLastUsedSettings,
    bool? openLastScreen,
    bool? autoAnalyzeImages,
    bool? autoRecommendCompression,
    CompressionAlgorithm? preferredAlgorithm,
    bool? alwaysKeepMetadata,
    bool? alwaysRemoveMetadata,
    bool? enableSmartRecommendations,
    bool? enableLiveSizeEstimation,
    bool? enableCompressionBenchmark,
    bool? qualityPreview,
    bool? compressToTargetSizeByDefault,
    bool? autoDeleteTemporaryFiles,
    CleanupInterval? cleanupInterval,
    int? maximumCacheSizeMb,
    int? compressionHistorySizeLimit,
    bool? autoDeleteOldHistory,
    bool? dynamicColors,
    bool? adaptiveIcons,
    bool? largeUiMode,
    bool? compactUiMode,
    SettingsAnimationSpeed? animationSpeed,
    bool? reduceMotion,
    double? fontScale,
    SettingsDisplayDensity? displayDensity,
    bool? screenReaders,
    bool? highContrast,
    bool? largeTouchTargets,
    bool? dynamicTextScaling,
    bool? reduceAnimations,
    bool? colorBlindFriendlyPalette,
    bool? accessibleProgressAnnouncements,
    bool? accessibleErrorAnnouncements,
    bool? semanticLabels,
    bool? offlineProcessing,
    bool? noCloudUpload,
    bool? noAnalytics,
    bool? noTracking,
    bool? noUserAccounts,
    bool? benchmarkMode,
    bool? developerLogging,
    bool? verboseLogging,
    Map<String, bool>? futureFeatureFlags,
    bool? developerOptionsUnlocked,
    bool? recommendationsEnabled,
  }) {
    final SettingsPreferences next = SettingsPreferences(
      theme: theme ?? this.theme,
      defaultPreset: defaultPreset ?? this.defaultPreset,
      defaultFormat: defaultFormat ?? this.defaultFormat,
      compressionQuality: compressionQuality ?? this.compressionQuality,
      defaultTargetFileSizeKb: clearDefaultTargetFileSize
          ? null
          : defaultTargetFileSizeKb ?? this.defaultTargetFileSizeKb,
      resizeMode: resizeMode ?? this.resizeMode,
      rememberLastUsedSettings:
          rememberLastUsedSettings ?? this.rememberLastUsedSettings,
      openLastScreen: openLastScreen ?? this.openLastScreen,
      autoAnalyzeImages: autoAnalyzeImages ?? this.autoAnalyzeImages,
      autoRecommendCompression:
          autoRecommendCompression ?? this.autoRecommendCompression,
      preferredAlgorithm: preferredAlgorithm ?? this.preferredAlgorithm,
      alwaysKeepMetadata: alwaysKeepMetadata ?? this.alwaysKeepMetadata,
      alwaysRemoveMetadata: alwaysRemoveMetadata ?? this.alwaysRemoveMetadata,
      enableSmartRecommendations:
          enableSmartRecommendations ?? this.enableSmartRecommendations,
      enableLiveSizeEstimation:
          enableLiveSizeEstimation ?? this.enableLiveSizeEstimation,
      enableCompressionBenchmark:
          enableCompressionBenchmark ?? this.enableCompressionBenchmark,
      qualityPreview: qualityPreview ?? this.qualityPreview,
      compressToTargetSizeByDefault:
          compressToTargetSizeByDefault ?? this.compressToTargetSizeByDefault,
      autoDeleteTemporaryFiles:
          autoDeleteTemporaryFiles ?? this.autoDeleteTemporaryFiles,
      cleanupInterval: cleanupInterval ?? this.cleanupInterval,
      maximumCacheSizeMb: maximumCacheSizeMb ?? this.maximumCacheSizeMb,
      compressionHistorySizeLimit:
          compressionHistorySizeLimit ?? this.compressionHistorySizeLimit,
      autoDeleteOldHistory: autoDeleteOldHistory ?? this.autoDeleteOldHistory,
      dynamicColors: dynamicColors ?? this.dynamicColors,
      adaptiveIcons: adaptiveIcons ?? this.adaptiveIcons,
      largeUiMode: largeUiMode ?? this.largeUiMode,
      compactUiMode: compactUiMode ?? this.compactUiMode,
      animationSpeed: animationSpeed ?? this.animationSpeed,
      reduceMotion: reduceMotion ?? this.reduceMotion,
      fontScale: fontScale ?? this.fontScale,
      displayDensity: displayDensity ?? this.displayDensity,
      screenReaders: screenReaders ?? this.screenReaders,
      highContrast: highContrast ?? this.highContrast,
      largeTouchTargets: largeTouchTargets ?? this.largeTouchTargets,
      dynamicTextScaling: dynamicTextScaling ?? this.dynamicTextScaling,
      reduceAnimations: reduceAnimations ?? this.reduceAnimations,
      colorBlindFriendlyPalette:
          colorBlindFriendlyPalette ?? this.colorBlindFriendlyPalette,
      accessibleProgressAnnouncements:
          accessibleProgressAnnouncements ??
          this.accessibleProgressAnnouncements,
      accessibleErrorAnnouncements:
          accessibleErrorAnnouncements ?? this.accessibleErrorAnnouncements,
      semanticLabels: semanticLabels ?? this.semanticLabels,
      offlineProcessing: offlineProcessing ?? this.offlineProcessing,
      noCloudUpload: noCloudUpload ?? this.noCloudUpload,
      noAnalytics: noAnalytics ?? this.noAnalytics,
      noTracking: noTracking ?? this.noTracking,
      noUserAccounts: noUserAccounts ?? this.noUserAccounts,
      benchmarkMode: benchmarkMode ?? this.benchmarkMode,
      developerLogging: developerLogging ?? this.developerLogging,
      verboseLogging: verboseLogging ?? this.verboseLogging,
      futureFeatureFlags: futureFeatureFlags ?? this.futureFeatureFlags,
      developerOptionsUnlocked:
          developerOptionsUnlocked ?? this.developerOptionsUnlocked,
      recommendationsEnabled:
          recommendationsEnabled ?? this.recommendationsEnabled,
    );
    if (next.alwaysKeepMetadata && next.alwaysRemoveMetadata) {
      return next.copyWith(alwaysRemoveMetadata: false);
    }
    return next;
  }

  @override
  bool operator ==(Object other) {
    return other is SettingsPreferences &&
        theme == other.theme &&
        defaultPreset == other.defaultPreset &&
        defaultFormat == other.defaultFormat &&
        compressionQuality == other.compressionQuality &&
        defaultTargetFileSizeKb == other.defaultTargetFileSizeKb &&
        resizeMode == other.resizeMode &&
        rememberLastUsedSettings == other.rememberLastUsedSettings &&
        openLastScreen == other.openLastScreen &&
        autoAnalyzeImages == other.autoAnalyzeImages &&
        autoRecommendCompression == other.autoRecommendCompression &&
        preferredAlgorithm == other.preferredAlgorithm &&
        alwaysKeepMetadata == other.alwaysKeepMetadata &&
        alwaysRemoveMetadata == other.alwaysRemoveMetadata &&
        enableSmartRecommendations == other.enableSmartRecommendations &&
        enableLiveSizeEstimation == other.enableLiveSizeEstimation &&
        enableCompressionBenchmark == other.enableCompressionBenchmark &&
        qualityPreview == other.qualityPreview &&
        compressToTargetSizeByDefault == other.compressToTargetSizeByDefault &&
        autoDeleteTemporaryFiles == other.autoDeleteTemporaryFiles &&
        cleanupInterval == other.cleanupInterval &&
        maximumCacheSizeMb == other.maximumCacheSizeMb &&
        compressionHistorySizeLimit == other.compressionHistorySizeLimit &&
        autoDeleteOldHistory == other.autoDeleteOldHistory &&
        dynamicColors == other.dynamicColors &&
        adaptiveIcons == other.adaptiveIcons &&
        largeUiMode == other.largeUiMode &&
        compactUiMode == other.compactUiMode &&
        animationSpeed == other.animationSpeed &&
        reduceMotion == other.reduceMotion &&
        fontScale == other.fontScale &&
        displayDensity == other.displayDensity &&
        screenReaders == other.screenReaders &&
        highContrast == other.highContrast &&
        largeTouchTargets == other.largeTouchTargets &&
        dynamicTextScaling == other.dynamicTextScaling &&
        reduceAnimations == other.reduceAnimations &&
        colorBlindFriendlyPalette == other.colorBlindFriendlyPalette &&
        accessibleProgressAnnouncements ==
            other.accessibleProgressAnnouncements &&
        accessibleErrorAnnouncements == other.accessibleErrorAnnouncements &&
        semanticLabels == other.semanticLabels &&
        offlineProcessing == other.offlineProcessing &&
        noCloudUpload == other.noCloudUpload &&
        noAnalytics == other.noAnalytics &&
        noTracking == other.noTracking &&
        noUserAccounts == other.noUserAccounts &&
        benchmarkMode == other.benchmarkMode &&
        developerLogging == other.developerLogging &&
        verboseLogging == other.verboseLogging &&
        _mapsEqual(futureFeatureFlags, other.futureFeatureFlags) &&
        developerOptionsUnlocked == other.developerOptionsUnlocked &&
        recommendationsEnabled == other.recommendationsEnabled;
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[
    theme,
    defaultPreset,
    defaultFormat,
    compressionQuality,
    defaultTargetFileSizeKb,
    resizeMode,
    rememberLastUsedSettings,
    openLastScreen,
    autoAnalyzeImages,
    autoRecommendCompression,
    preferredAlgorithm,
    alwaysKeepMetadata,
    alwaysRemoveMetadata,
    enableSmartRecommendations,
    enableLiveSizeEstimation,
    enableCompressionBenchmark,
    qualityPreview,
    compressToTargetSizeByDefault,
    autoDeleteTemporaryFiles,
    cleanupInterval,
    maximumCacheSizeMb,
    compressionHistorySizeLimit,
    autoDeleteOldHistory,
    dynamicColors,
    adaptiveIcons,
    largeUiMode,
    compactUiMode,
    animationSpeed,
    reduceMotion,
    fontScale,
    displayDensity,
    screenReaders,
    highContrast,
    largeTouchTargets,
    dynamicTextScaling,
    reduceAnimations,
    colorBlindFriendlyPalette,
    accessibleProgressAnnouncements,
    accessibleErrorAnnouncements,
    semanticLabels,
    offlineProcessing,
    noCloudUpload,
    noAnalytics,
    noTracking,
    noUserAccounts,
    benchmarkMode,
    developerLogging,
    verboseLogging,
    Object.hashAll(futureFeatureFlags.entries),
    developerOptionsUnlocked,
    recommendationsEnabled,
  ]);

  static bool _mapsEqual(Map<String, bool> left, Map<String, bool> right) {
    if (left.length != right.length) return false;
    for (final MapEntry<String, bool> entry in left.entries) {
      if (right[entry.key] != entry.value) return false;
    }
    return true;
  }
}

/// App-owned storage usage shown in the storage section.
final class SettingsStorageUsage {
  const SettingsStorageUsage({
    this.cacheBytes = 0,
    this.temporaryBytes = 0,
    this.historyBytes = 0,
    this.exportsBytes = 0,
  });

  final int cacheBytes;
  final int temporaryBytes;
  final int historyBytes;
  final int exportsBytes;

  int get totalBytes =>
      cacheBytes + temporaryBytes + historyBytes + exportsBytes;
}

/// Local usage signals used by the offline recommendation engine.
final class SettingsIntelligenceSignals {
  const SettingsIntelligenceSignals({
    this.cacheBytes = 0,
    this.freeStorageBytes,
    this.screenshotCount = 0,
    this.photoCount = 0,
    this.websiteImageCount = 0,
  });

  final int cacheBytes;
  final int? freeStorageBytes;
  final int screenshotCount;
  final int photoCount;
  final int websiteImageCount;
}

/// Stable recommendation categories mapped to localized copy in presentation.
enum SettingsRecommendationKind {
  largeCache,
  screenshots,
  photos,
  websiteImages,
  lowStorage,
}

/// A localized-ready recommendation descriptor identified by a stable key.
final class SettingsRecommendation {
  const SettingsRecommendation({required this.kind, required this.priority});

  final SettingsRecommendationKind kind;
  final int priority;
}

/// Offline, deterministic recommendations based only on local aggregate signals.
abstract final class SettingsIntelligence {
  static List<SettingsRecommendation> recommend(
    SettingsIntelligenceSignals signals,
  ) {
    final List<SettingsRecommendation> result = <SettingsRecommendation>[];
    if (signals.cacheBytes >= 512 * 1024 * 1024) {
      result.add(
        const SettingsRecommendation(
          kind: SettingsRecommendationKind.largeCache,
          priority: 100,
        ),
      );
    }
    if (signals.screenshotCount >= 3) {
      result.add(
        const SettingsRecommendation(
          kind: SettingsRecommendationKind.screenshots,
          priority: 80,
        ),
      );
    }
    if (signals.photoCount >= 3) {
      result.add(
        const SettingsRecommendation(
          kind: SettingsRecommendationKind.photos,
          priority: 70,
        ),
      );
    }
    if (signals.websiteImageCount >= 3) {
      result.add(
        const SettingsRecommendation(
          kind: SettingsRecommendationKind.websiteImages,
          priority: 60,
        ),
      );
    }
    if (signals.freeStorageBytes != null &&
        signals.freeStorageBytes! < 2 * 1024 * 1024 * 1024) {
      result.add(
        const SettingsRecommendation(
          kind: SettingsRecommendationKind.lowStorage,
          priority: 90,
        ),
      );
    }
    result.sort(
      (SettingsRecommendation a, SettingsRecommendation b) =>
          b.priority.compareTo(a.priority),
    );
    return List<SettingsRecommendation>.unmodifiable(result);
  }
}

/// Privacy-safe export bundle. Paths, secrets, logs, and debug payloads are excluded.
final class SettingsExportBundle {
  const SettingsExportBundle({
    required this.settings,
    this.compressionPresets = const <Map<String, Object?>>[],
    this.historyMetadata = const <Map<String, Object?>>[],
  });

  final SettingsPreferences settings;
  final List<Map<String, Object?>> compressionPresets;
  final List<Map<String, Object?>> historyMetadata;

  Map<String, Object?> toJson() => <String, Object?>{
    'schemaVersion': 1,
    'settings': SettingsJsonCodec.toExportMap(settings),
    'compressionPresets': compressionPresets
        .take(256)
        .map(_sanitizeMap)
        .toList(growable: false),
    'historyMetadata': historyMetadata
        .take(256)
        .map(_sanitizeMap)
        .toList(growable: false),
  };

  String encode() => const JsonEncoder.withIndent('  ').convert(toJson());

  static Map<String, Object?> _sanitizeMap(
    Map<String, Object?> input, [
    int depth = 0,
  ]) {
    if (depth >= 8) return <String, Object?>{};
    final Map<String, Object?> output = <String, Object?>{};
    for (final MapEntry<String, Object?> entry in input.entries.take(256)) {
      final String key = entry.key.toLowerCase();
      if (_isSensitiveKey(key)) continue;
      output[entry.key] = _sanitizeValue(entry.value, depth + 1);
    }
    return output;
  }

  static Object? _sanitizeValue(Object? value, [int depth = 0]) {
    if (depth >= 8) return null;
    if (value is Map) {
      final Map<Object?, Object?> map = value.cast<Object?, Object?>();
      final Map<String, Object?> stringMap = <String, Object?>{};
      for (final MapEntry<Object?, Object?> entry in map.entries.take(256)) {
        if (entry.key is String) {
          stringMap[entry.key! as String] = entry.value;
        }
      }
      return _sanitizeMap(stringMap, depth);
    }
    if (value is List) {
      return value
          .take(256)
          .map((Object? item) => _sanitizeValue(item, depth + 1))
          .toList(growable: false);
    }
    return value is String || value is num || value is bool || value == null
        ? value
        : value.toString();
  }

  static bool _isSensitiveKey(String key) =>
      key.contains('path') ||
      key.contains('uri') ||
      key.contains('secret') ||
      key.contains('token') ||
      key.contains('log');
}

/// JSON codec kept independent from platform storage for deterministic tests.
abstract final class SettingsJsonCodec {
  static Map<String, Object?> toMap(
    SettingsPreferences value,
  ) => <String, Object?>{
    'theme': value.theme.name,
    'defaultPreset': value.defaultPreset,
    'defaultFormat': value.defaultFormat.name,
    'compressionQuality': value.compressionQuality,
    'defaultTargetFileSizeKb': value.defaultTargetFileSizeKb,
    'resizeMode': value.resizeMode.name,
    'rememberLastUsedSettings': value.rememberLastUsedSettings,
    'openLastScreen': value.openLastScreen,
    'autoAnalyzeImages': value.autoAnalyzeImages,
    'autoRecommendCompression': value.autoRecommendCompression,
    'preferredAlgorithm': value.preferredAlgorithm.name,
    'alwaysKeepMetadata': value.alwaysKeepMetadata,
    'alwaysRemoveMetadata': value.alwaysRemoveMetadata,
    'enableSmartRecommendations': value.enableSmartRecommendations,
    'enableLiveSizeEstimation': value.enableLiveSizeEstimation,
    'enableCompressionBenchmark': value.enableCompressionBenchmark,
    'qualityPreview': value.qualityPreview,
    'compressToTargetSizeByDefault': value.compressToTargetSizeByDefault,
    'autoDeleteTemporaryFiles': value.autoDeleteTemporaryFiles,
    'cleanupInterval': value.cleanupInterval.name,
    'maximumCacheSizeMb': value.maximumCacheSizeMb,
    'compressionHistorySizeLimit': value.compressionHistorySizeLimit,
    'autoDeleteOldHistory': value.autoDeleteOldHistory,
    'dynamicColors': value.dynamicColors,
    'adaptiveIcons': value.adaptiveIcons,
    'largeUiMode': value.largeUiMode,
    'compactUiMode': value.compactUiMode,
    'animationSpeed': value.animationSpeed.name,
    'reduceMotion': value.reduceMotion,
    'fontScale': value.fontScale,
    'displayDensity': value.displayDensity.name,
    'screenReaders': value.screenReaders,
    'highContrast': value.highContrast,
    'largeTouchTargets': value.largeTouchTargets,
    'dynamicTextScaling': value.dynamicTextScaling,
    'reduceAnimations': value.reduceAnimations,
    'colorBlindFriendlyPalette': value.colorBlindFriendlyPalette,
    'accessibleProgressAnnouncements': value.accessibleProgressAnnouncements,
    'accessibleErrorAnnouncements': value.accessibleErrorAnnouncements,
    'semanticLabels': value.semanticLabels,
    'offlineProcessing': value.offlineProcessing,
    'noCloudUpload': value.noCloudUpload,
    'noAnalytics': value.noAnalytics,
    'noTracking': value.noTracking,
    'noUserAccounts': value.noUserAccounts,
    'benchmarkMode': value.benchmarkMode,
    'developerLogging': value.developerLogging,
    'verboseLogging': value.verboseLogging,
    'futureFeatureFlags': value.futureFeatureFlags,
    'developerOptionsUnlocked': value.developerOptionsUnlocked,
    'recommendationsEnabled': value.recommendationsEnabled,
  };

  static Map<String, Object?> toExportMap(SettingsPreferences value) {
    final Map<String, Object?> map = toMap(value);
    map.remove('benchmarkMode');
    map.remove('developerLogging');
    map.remove('verboseLogging');
    map.remove('developerOptionsUnlocked');
    return map;
  }

  static String encode(SettingsPreferences value) => jsonEncode(toMap(value));

  static SettingsPreferences decode(String encoded) {
    if (encoded.length > 1024 * 1024) {
      throw const FormatException('Settings document is too large.');
    }
    final Object? decoded = jsonDecode(encoded);
    if (decoded is! Map<String, Object?>) {
      throw const FormatException('Invalid settings document.');
    }
    final Object? nestedSettings = decoded['settings'];
    if (nestedSettings is Map<String, Object?>) return fromMap(nestedSettings);
    return fromMap(decoded);
  }

  static String _safePreset(String? value) =>
      <String>{'balanced', 'web', 'lossless'}.contains(value)
      ? value!
      : 'balanced';

  static int? _safeTargetSize(Object? value) {
    if (value is! num) return null;
    final int target = value.toInt();
    return <int>[100, 250, 500, 1024].contains(target) ? target : null;
  }

  static SettingsPreferences fromMap(Map<String, Object?> map) {
    T enumValue<T extends Enum>(Iterable<T> values, String? value, T fallback) {
      return values.firstWhere(
        (T item) => item.name == value,
        orElse: () => fallback,
      );
    }

    String? string(String key) =>
        map[key] is String ? map[key]! as String : null;
    bool boolean(String key, bool fallback) =>
        map[key] is bool ? map[key]! as bool : fallback;
    int integer(String key, int fallback) =>
        map[key] is num ? (map[key]! as num).toInt() : fallback;
    double decimal(String key, double fallback) =>
        map[key] is num ? (map[key]! as num).toDouble() : fallback;
    final Object? rawFlags = map['futureFeatureFlags'];
    final Map<String, bool> flags = rawFlags is Map<String, Object?>
        ? <String, bool>{
            for (final MapEntry<String, Object?> item in rawFlags.entries.take(
              128,
            ))
              if (item.key.length <= 128 && item.value is bool)
                item.key: item.value! as bool,
          }
        : const <String, bool>{};
    return SettingsPreferences(
      theme: enumValue(
        SettingsTheme.values,
        string('theme'),
        SettingsTheme.system,
      ),
      defaultPreset: _safePreset(string('defaultPreset')),
      defaultFormat: enumValue(
        const <ImageFormat>[
          ImageFormat.jpeg,
          ImageFormat.png,
          ImageFormat.webp,
        ],
        string('defaultFormat'),
        ImageFormat.jpeg,
      ),
      compressionQuality: integer(
        'compressionQuality',
        72,
      ).clamp(1, 100).toInt(),
      defaultTargetFileSizeKb: _safeTargetSize(map['defaultTargetFileSizeKb']),
      resizeMode: enumValue(
        SettingsResizeMode.values,
        string('resizeMode'),
        SettingsResizeMode.original,
      ),
      rememberLastUsedSettings: boolean('rememberLastUsedSettings', true),
      openLastScreen: boolean('openLastScreen', false),
      autoAnalyzeImages: boolean('autoAnalyzeImages', true),
      autoRecommendCompression: boolean('autoRecommendCompression', true),
      preferredAlgorithm: enumValue(
        CompressionAlgorithm.values,
        string('preferredAlgorithm'),
        CompressionAlgorithm.automatic,
      ),
      alwaysKeepMetadata: boolean('alwaysKeepMetadata', false),
      alwaysRemoveMetadata: boolean('alwaysRemoveMetadata', true),
      enableSmartRecommendations: boolean('enableSmartRecommendations', true),
      enableLiveSizeEstimation: boolean('enableLiveSizeEstimation', true),
      enableCompressionBenchmark: boolean('enableCompressionBenchmark', false),
      qualityPreview: boolean('qualityPreview', true),
      compressToTargetSizeByDefault: boolean(
        'compressToTargetSizeByDefault',
        false,
      ),
      autoDeleteTemporaryFiles: boolean('autoDeleteTemporaryFiles', true),
      cleanupInterval: enumValue(
        CleanupInterval.values,
        string('cleanupInterval'),
        CleanupInterval.daily,
      ),
      // Bounds match the storage sliders' min/max so an imported or legacy
      // value can never crash the settings screen with a Slider assertion.
      maximumCacheSizeMb: integer(
        'maximumCacheSizeMb',
        256,
      ).clamp(32, 1024).toInt(),
      compressionHistorySizeLimit: integer(
        'compressionHistorySizeLimit',
        500,
      ).clamp(50, 2000).toInt(),
      autoDeleteOldHistory: boolean('autoDeleteOldHistory', false),
      dynamicColors: boolean('dynamicColors', true),
      adaptiveIcons: boolean('adaptiveIcons', true),
      largeUiMode: boolean('largeUiMode', false),
      compactUiMode: boolean('compactUiMode', false),
      animationSpeed: enumValue(
        SettingsAnimationSpeed.values,
        string('animationSpeed'),
        SettingsAnimationSpeed.full,
      ),
      reduceMotion: boolean('reduceMotion', false),
      fontScale: decimal('fontScale', 1).clamp(.85, 1.5).toDouble(),
      displayDensity: enumValue(
        SettingsDisplayDensity.values,
        string('displayDensity'),
        SettingsDisplayDensity.comfortable,
      ),
      screenReaders: boolean('screenReaders', true),
      highContrast: boolean('highContrast', false),
      largeTouchTargets: boolean('largeTouchTargets', true),
      dynamicTextScaling: boolean('dynamicTextScaling', true),
      reduceAnimations: boolean('reduceAnimations', false),
      colorBlindFriendlyPalette: boolean('colorBlindFriendlyPalette', false),
      accessibleProgressAnnouncements: boolean(
        'accessibleProgressAnnouncements',
        true,
      ),
      accessibleErrorAnnouncements: boolean(
        'accessibleErrorAnnouncements',
        true,
      ),
      semanticLabels: boolean('semanticLabels', true),
      // Keep the complete schema round-trippable. The controller enforces
      // these product privacy guarantees before persistence or use.
      offlineProcessing: boolean('offlineProcessing', true),
      noCloudUpload: boolean('noCloudUpload', true),
      noAnalytics: boolean('noAnalytics', true),
      noTracking: boolean('noTracking', true),
      noUserAccounts: boolean('noUserAccounts', true),
      benchmarkMode: boolean('benchmarkMode', false),
      developerLogging: boolean('developerLogging', false),
      verboseLogging: boolean('verboseLogging', false),
      futureFeatureFlags: flags,
      developerOptionsUnlocked: boolean('developerOptionsUnlocked', false),
      recommendationsEnabled: boolean('recommendationsEnabled', true),
    ).copyWith(
      alwaysRemoveMetadata: boolean('alwaysKeepMetadata', false) ? false : null,
    );
  }
}
