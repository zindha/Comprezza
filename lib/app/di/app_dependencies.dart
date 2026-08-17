import '../../core/models/result.dart';
import '../../core/services/app_logger.dart';
import '../../core/services/benchmark_timer.dart';
import '../../core/services/cache_manager.dart';
import '../../core/services/device_information_service.dart';
import '../../core/services/file_system_service.dart';
import '../../core/services/performance_monitor.dart';
import '../../core/services/startup_initialization_service.dart';
import '../../features/compressor/data/datasources/image_processing_data_source.dart';
import '../../features/compressor/data/image_compression_service.dart';
import '../../features/compressor/data/photo_picker_service.dart';
import '../../features/compressor/data/repositories/image_processing_repository_impl.dart';
import '../../features/compressor/data/services/file_management/cleanup/file_cleanup_service.dart';
import '../../features/compressor/data/services/file_management/exports/export_service.dart';
import '../../features/compressor/data/services/file_management/file_manager.dart';
import '../../features/compressor/data/services/file_management/history/history_storage.dart';
import '../../features/compressor/data/services/file_management/imports/import_service.dart';
import '../../features/compressor/data/services/file_management/interfaces/file_management_interfaces.dart';
import '../../features/compressor/data/services/file_management/naming/file_naming_strategy.dart';
import '../../features/compressor/data/services/file_management/permissions/permission_service.dart';
import '../../features/compressor/data/services/file_management/pickers/folder_picker_service.dart';
import '../../features/compressor/data/services/file_management/pickers/image_picker_service.dart';
import '../../features/compressor/data/services/file_management/storage/storage_manager.dart';
import '../../features/compressor/data/services/file_management/utilities/file_utilities.dart';
import '../../features/compressor/data/services/file_management/validators/file_validator.dart';
import '../../features/compressor/data/services/image_processing/analyzers/heuristic_analyzer_engine.dart';
import '../../features/compressor/data/services/image_processing/benchmarks/benchmark_engine.dart';
import '../../features/compressor/data/services/image_processing/compressors/flutter_image_compress_engine.dart';
import '../../features/compressor/data/services/image_processing/engine_manager.dart';
import '../../features/compressor/data/services/image_processing/engine_manager_data_source.dart';
import '../../features/compressor/data/services/image_processing/estimators/estimation_engine.dart';
import '../../features/compressor/data/services/image_processing/interfaces/engine_manager.dart';
import '../../features/compressor/data/services/image_processing/interfaces/engine_registry.dart';
import '../../features/compressor/data/services/image_processing/interfaces/processing_engine.dart';
import '../../features/compressor/data/services/image_processing/queue/priority_processing_queue.dart';
import '../../features/compressor/data/services/settings/local_settings_store.dart';
import '../../features/compressor/data/services/share_export/export_security_policy.dart';
import '../../features/compressor/data/services/share_export/local_premium_manager.dart';
import '../../features/compressor/data/services/share_export/local_share_export_service.dart';
import '../../features/compressor/data/services/share_export/managed_share_export_cleanup.dart';
import '../../features/compressor/data/services/share_export/share_export_gateway_adapter.dart';
import '../../features/compressor/data/services/share_export/share_plus_dispatcher.dart';
import '../../features/compressor/domain/gateways/compressor_gateways.dart';
import '../../features/compressor/domain/repositories/image_processing_repository.dart';
import '../../features/compressor/domain/settings/settings_store.dart';
import '../../features/compressor/domain/share_export/share_export_interfaces.dart';
import '../../features/compressor/domain/usecases/process_image_use_case.dart';
import '../../features/compressor/presentation/batch_compression_controller.dart';
import '../../features/compressor/presentation/settings/settings_controller.dart';
import '../config/app_configuration.dart';
import '../config/app_environment.dart';
import 'batch_compression_adapter.dart';
import 'legacy_compressor_adapter.dart';
import 'service_locator.dart';

/// The explicit application dependency graph and owner of the scoped locator.
final class AppDependencies implements Disposable {
  /// Creates and registers the application dependency graph.
  AppDependencies._({required this.locator});

  /// Creates a dependency graph with optional immutable configuration.
  factory AppDependencies.create({AppConfig? config}) {
    final ServiceLocator locator = ServiceLocator();
    locator.registerLazySingleton<AppConfiguration>(
      (_) => _FixedAppConfiguration(config ?? AppConfig.fromBuildMode()),
    );
    locator.registerLazySingleton<AppLogger>(
      (ServiceLocator services) => ConsoleAppLogger(
        enabled: services.get<AppConfiguration>().value.enableDiagnostics,
      ),
    );
    locator.registerLazySingleton<PerformanceMonitor>((
      ServiceLocator services,
    ) {
      final AppConfiguration configuration = services.get<AppConfiguration>();
      if (!configuration.value.enablePerformanceMonitoring) {
        return const NoOpPerformanceMonitor();
      }
      return DebugPerformanceMonitor(
        onMeasurement: (String name, Duration elapsed) {
          services.get<AppLogger>().debug(
            'Performance measurement',
            context: <String, Object?>{
              'name': name,
              'elapsed_us': elapsed.inMicroseconds,
            },
          );
        },
      );
    });
    locator.registerLazySingleton<FileSystemService>(
      (_) => LocalFileSystemService(),
    );
    locator.registerLazySingleton<SettingsStore>((ServiceLocator services) {
      return LocalSettingsStore(fileSystem: services.get<FileSystemService>());
    });
    locator.registerLazySingleton<SettingsController>((
      ServiceLocator services,
    ) {
      return SettingsController(
        store: services.get<SettingsStore>(),
        configuration: services.get<AppConfiguration>().value,
      );
    });
    locator.registerLazySingleton<CacheManager>((ServiceLocator services) {
      final FileSystemService fileSystem = services.get<FileSystemService>();
      return LocalCacheManager(
        fileSystem: fileSystem,
        directories: fileSystem.directories,
      );
    });
    locator.registerLazySingleton<StartupInitializationService>((
      ServiceLocator services,
    ) {
      final CacheManager cacheManager = services.get<CacheManager>();
      return DefaultStartupInitializationService(
        tasks: <StartupTask>[
          CacheCleanupStartupTask(
            cleanup: () async {
              final result = await cacheManager.cleanup();
              return result.fold(
                onSuccess: (CacheCleanupReport report) =>
                    Result<int>.success(report.removedFiles),
                onFailure: (error) => Result<int>.failure(error),
              );
            },
          ),
        ],
      );
    });
    locator.registerLazySingleton<DeviceInformationService>(
      (_) => const PlatformDeviceInformationService(),
    );
    locator.registerLazySingleton<BenchmarkTimer>((ServiceLocator services) {
      return LocalBenchmarkTimer(
        enableTimeline: services
            .get<AppConfiguration>()
            .value
            .enablePerformanceMonitoring,
      );
    });
    locator.registerLazySingleton<EngineRegistry>((ServiceLocator services) {
      final InMemoryEngineRegistry registry = InMemoryEngineRegistry();
      registry.register(
        FlutterImageCompressEngine(
          fileSystem: services.get<FileSystemService>(),
        ),
      );
      registry.registerAnalyzer(const HeuristicImageAnalyzerEngine());
      registry.registerSpecialized<EstimationEngine>(
        const LocalEstimationEngine(),
      );
      registry.registerSpecialized<BenchmarkEngine>(
        LocalBenchmarkEngine(
          timer: services.get<BenchmarkTimer>(),
          fileSystem: services.get<FileSystemService>(),
        ),
      );
      return registry;
    });
    locator.registerLazySingleton<QueueEngine>(
      (_) => PriorityProcessingQueue(),
    );
    locator.registerLazySingleton<EngineManager>((ServiceLocator services) {
      return DefaultEngineManager(
        registry: services.get<EngineRegistry>(),
        queue: services.get<QueueEngine>(),
        fileSystem: services.get<FileSystemService>(),
        benchmark: services.get<BenchmarkEngine>(),
      );
    });
    locator.registerLazySingleton<ImageProcessingDataSource>(
      (ServiceLocator services) =>
          EngineManagerDataSource(services.get<EngineManager>()),
    );
    locator.registerLazySingleton<ImageProcessingRepository>((
      ServiceLocator services,
    ) {
      return ImageProcessingRepositoryImpl(
        services.get<ImageProcessingDataSource>(),
      );
    });
    locator.registerLazySingleton<ProcessImageUseCase>((
      ServiceLocator services,
    ) {
      return ProcessImageUseCase(services.get<ImageProcessingRepository>());
    });
    locator.registerLazySingleton<FileUtilities>((ServiceLocator services) {
      return LocalFileUtilities(fileSystem: services.get<FileSystemService>());
    });
    locator.registerLazySingleton<StorageManager>((ServiceLocator services) {
      return LocalStorageManager(fileSystem: services.get<FileSystemService>());
    });
    locator.registerLazySingleton<ImagePickerService>(
      (_) => PlatformImagePickerService(),
    );
    locator.registerLazySingleton<FolderPickerService>(
      (_) => const LocalFolderPickerService(),
    );
    locator.registerLazySingleton<FileValidator>((ServiceLocator services) {
      return LocalFileValidator(utilities: services.get<FileUtilities>());
    });
    locator.registerLazySingleton<FileNamingStrategy>(
      (_) => const IntelligentFileNamingStrategy(),
    );
    locator.registerLazySingleton<ImportService>((ServiceLocator services) {
      return LocalImportService(
        storage: services.get<StorageManager>(),
        fileSystem: services.get<FileSystemService>(),
        naming: services.get<FileNamingStrategy>(),
      );
    });
    locator.registerLazySingleton<HistoryStorage>((ServiceLocator services) {
      return JsonHistoryStorage(
        storage: services.get<StorageManager>(),
        fileSystem: services.get<FileSystemService>(),
      );
    });
    locator.registerLazySingleton<ExportService>((ServiceLocator services) {
      return LocalExportService(
        storage: services.get<StorageManager>(),
        naming: services.get<FileNamingStrategy>(),
        fileSystem: services.get<FileSystemService>(),
      );
    });
    locator.registerLazySingleton<FileCleanupService>((
      ServiceLocator services,
    ) {
      return LocalFileCleanupService(
        storage: services.get<StorageManager>(),
        fileSystem: services.get<FileSystemService>(),
        history: services.get<HistoryStorage>(),
      );
    });
    locator.registerLazySingleton<PermissionService>(
      (_) => const ScopedStoragePermissionService(),
    );
    locator.registerLazySingleton<FileManager>((ServiceLocator services) {
      return DefaultFileManager(
        picker: services.get<ImagePickerService>(),
        importer: services.get<ImportService>(),
        validator: services.get<FileValidator>(),
        exporter: services.get<ExportService>(),
        cleanupService: services.get<FileCleanupService>(),
        folderPicker: services.get<FolderPickerService>(),
        history: services.get<HistoryStorage>(),
        permissions: services.get<PermissionService>(),
      );
    });
    locator.registerLazySingleton<ImagePickerGateway>(
      (_) => PhotoPickerService(),
    );
    locator.registerLazySingleton<ImageCompressionGateway>(
      (_) => ImageCompressionService(),
    );
    locator.registerLazySingleton<ShareDispatcher>(
      (_) => const SharePlusDispatcher(),
    );
    locator.registerLazySingleton<ExportSecurityPolicy>(
      (ServiceLocator services) =>
          LocalExportSecurityPolicy(storage: services.get<StorageManager>()),
    );
    locator.registerLazySingleton<ShareExportCleanup>(
      (ServiceLocator services) =>
          ManagedShareExportCleanup(utilities: services.get<FileUtilities>()),
    );
    locator.registerLazySingleton<ShareExportService>(
      (ServiceLocator services) => LocalShareExportService(
        exporter: services.get<ExportService>(),
        dispatcher: services.get<ShareDispatcher>(),
        security: services.get<ExportSecurityPolicy>(),
        cleanup: services.get<ShareExportCleanup>(),
      ),
    );
    locator.registerLazySingleton<PremiumManager>(
      (_) => const LocalPremiumManager(),
    );
    locator.registerLazySingleton<PremiumCapabilities>(
      (ServiceLocator services) =>
          LocalPremiumCapabilities(manager: services.get<PremiumManager>()),
    );
    locator.registerLazySingleton<FeatureGate>(
      (ServiceLocator services) =>
          LocalFeatureGate(capabilities: services.get<PremiumCapabilities>()),
    );
    locator.registerLazySingleton<ImageExportGateway>(
      (ServiceLocator services) => ShareExportGatewayAdapter(
        service: services.get<ShareExportService>(),
        inspector: services.get<ImageCompressionGateway>(),
        cleanup: services.get<ShareExportCleanup>(),
        storage: services.get<StorageManager>(),
      ),
    );
    locator.registerLazySingleton<LegacyCompressorAdapter>((
      ServiceLocator services,
    ) {
      return LegacyCompressorAdapter(
        pickerGateway: services.get<ImagePickerGateway>(),
        compressionGateway: services.get<ImageCompressionGateway>(),
        exportGateway: services.get<ImageExportGateway>(),
        history: services.get<HistoryStorage>(),
      );
    });
    locator.registerLazySingleton<BatchCompressionAdapter>((
      ServiceLocator services,
    ) {
      return BatchCompressionAdapter(
        picker: services.get<ImagePickerService>(),
        compression: services.get<ImageCompressionGateway>(),
        history: services.get<HistoryStorage>(),
        exportGateway: services.get<ImageExportGateway>(),
        shareService: services.get<ShareExportService>(),
        storage: services.get<StorageManager>(),
        // Persist in-flight batch state to app-private storage so re-entering
        // the screen (or relaunching the app) restores the queue.
        progressStore: FileBatchProgressStore(),
      );
    });
    return AppDependencies._(locator: locator);
  }

  /// Scoped service registry owned by this dependency graph.
  final ServiceLocator locator;

  /// Application configuration.
  AppConfiguration get configuration => locator.get<AppConfiguration>();

  /// Application logger.
  AppLogger get logger => locator.get<AppLogger>();

  /// Performance monitoring hooks.
  PerformanceMonitor get performanceMonitor =>
      locator.get<PerformanceMonitor>();

  /// Local filesystem service.
  FileSystemService get fileSystem => locator.get<FileSystemService>();

  /// Persisted Settings controller shared by the application scope.
  SettingsController get settingsController =>
      locator.get<SettingsController>();

  /// Cache manager.
  CacheManager get cacheManager => locator.get<CacheManager>();

  /// Startup initialization service.
  StartupInitializationService get startup =>
      locator.get<StartupInitializationService>();

  /// Device capability service.
  DeviceInformationService get deviceInformation =>
      locator.get<DeviceInformationService>();

  /// Benchmark timer.
  BenchmarkTimer get benchmarkTimer => locator.get<BenchmarkTimer>();

  /// Unified image-processing engine manager.
  EngineManager get engineManager => locator.get<EngineManager>();

  /// Replaceable image-processing engine registry.
  EngineRegistry get engineRegistry => locator.get<EngineRegistry>();

  /// Replaceable image-processing repository port.
  ImageProcessingRepository get imageProcessing =>
      locator.get<ImageProcessingRepository>();

  /// Replaceable image-processing use case.
  ProcessImageUseCase get processImage => locator.get<ProcessImageUseCase>();

  /// Central file-management facade.
  FileManager get fileManager => locator.get<FileManager>();

  /// Local history storage.
  HistoryStorage get history => locator.get<HistoryStorage>();

  /// Platform image picker gateway.
  ImagePickerGateway get imagePickerGateway =>
      locator.get<ImagePickerGateway>();

  /// Compression engine gateway used by the running workflow.
  ImageCompressionGateway get imageCompressionGateway =>
      locator.get<ImageCompressionGateway>();

  /// Production share/export coordinator.
  ShareExportService get shareExport => locator.get<ShareExportService>();

  /// Premium entitlement boundary.
  PremiumManager get premiumManager => locator.get<PremiumManager>();

  /// Premium capability snapshot.
  PremiumCapabilities get premiumCapabilities =>
      locator.get<PremiumCapabilities>();

  /// Fail-closed feature gate.
  FeatureGate get featureGate => locator.get<FeatureGate>();

  /// Transitional adapter retained only as the existing compression route seam.
  LegacyCompressorAdapter get legacyCompressor =>
      locator.get<LegacyCompressorAdapter>();

  /// Batch workflow controller wired to the real picker and engine.
  BatchCompressionController get batchCompression =>
      locator.get<BatchCompressionAdapter>().controller;

  @override
  void dispose() => locator.dispose();
}

final class _FixedAppConfiguration implements AppConfiguration {
  const _FixedAppConfiguration(this.value);

  @override
  final AppConfig value;
}
