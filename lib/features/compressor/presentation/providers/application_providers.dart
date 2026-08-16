import 'package:flutter/foundation.dart';

import '../../../../core/errors/app_error.dart';
import '../../../../core/errors/error_code.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/errors/result_error_adapter.dart';
import '../../../../core/models/result.dart';
import '../../domain/entities/entities.dart';
import '../../domain/usecases/usecases.dart';
import '../viewmodels/application_states.dart';

String _friendlyError(AppError error) => error.message;

AppError _providerError(Object error, StackTrace stackTrace) {
  final exception = ErrorMapper.map(error, stackTrace);
  return ResultErrorAdapter.fromException(exception);
}

/// Shared lifecycle and notification behavior for feature providers.
abstract base class ApplicationProvider extends ChangeNotifier {
  bool _disposed = false;

  bool get isDisposed => _disposed;

  void notifyStateChanged() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

/// Manages image selection state and recovery.
final class HomeProvider extends ApplicationProvider {
  HomeProvider({
    required SelectImagesUseCase selectImages,
    required RecoverSelectionUseCase recoverSelection,
  }) : _selectImages = selectImages,
       _recoverSelection = recoverSelection;

  final SelectImagesUseCase _selectImages;
  final RecoverSelectionUseCase _recoverSelection;
  HomeState _state = HomeState();
  bool _running = false;
  bool _lastMultiple = true;

  HomeState get state => _state;

  Future<void> selectImages({bool multiple = true}) async {
    if (_running || isDisposed) return;
    _running = true;
    _lastMultiple = multiple;
    _set(
      _state.copyWith(
        status: OperationStatus.loading,
        clearMessage: true,
        canRetry: false,
      ),
    );
    try {
      final Result<List<SelectedImage>> result = await _selectImages.execute(
        multiple: multiple,
      );
      if (isDisposed) return;
      result.fold(
        onSuccess: (List<SelectedImage> images) => _set(
          _state.copyWith(
            status: images.isEmpty
                ? OperationStatus.empty
                : OperationStatus.success,
            images: List<SelectedImage>.unmodifiable(images),
            clearMessage: true,
          ),
        ),
        onFailure: (AppError error) => _set(
          _state.copyWith(
            status: OperationStatus.error,
            message: _friendlyError(error),
            canRetry: error.isRecoverable,
          ),
        ),
      );
    } catch (error, stackTrace) {
      if (!isDisposed) _setError(_providerError(error, stackTrace));
    } finally {
      _running = false;
    }
  }

  Future<void> recover() async {
    if (_running || isDisposed) return;
    _running = true;
    _set(_state.copyWith(status: OperationStatus.loading, clearMessage: true));
    try {
      final Result<List<SelectedImage>> result = await _recoverSelection
          .execute();
      if (isDisposed) return;
      result.fold(
        onSuccess: (List<SelectedImage> images) => _set(
          _state.copyWith(
            status: images.isEmpty
                ? OperationStatus.empty
                : OperationStatus.success,
            images: List<SelectedImage>.unmodifiable(images),
            clearMessage: true,
          ),
        ),
        onFailure: (AppError error) => _setError(error),
      );
    } catch (error, stackTrace) {
      if (!isDisposed) _setError(_providerError(error, stackTrace));
    } finally {
      _running = false;
    }
  }

  Future<void> retry() => selectImages(multiple: _lastMultiple);

  void _setError(AppError error) => _set(
    _state.copyWith(
      status: OperationStatus.error,
      message: _friendlyError(error),
      canRetry: error.isRecoverable,
    ),
  );

  void _set(HomeState next) {
    if (_state == next || isDisposed) return;
    _state = next;
    notifyStateChanged();
  }
}

/// Coordinates compression actions and exposes immutable progress state.
final class CompressionProvider extends ApplicationProvider {
  CompressionProvider({required CompressImagesUseCase compressImages})
    : _compressImages = compressImages;

  final CompressImagesUseCase _compressImages;
  CompressionState _state = CompressionState();
  CompressionRequest? _lastRequest;
  OperationControl? _control;
  bool _running = false;

  CompressionState get state => _state;
  bool get isProcessing => _running;

  Future<void> compress(CompressionRequest request) async {
    if (isDisposed || _running) return;
    _running = true;
    _lastRequest = request;
    final OperationControl control = OperationControl();
    _control = control;
    _set(
      _state.copyWith(
        status: OperationStatus.loading,
        progress: ProcessingProgress(
          completedFiles: 0,
          totalFiles: request.images.length,
          currentFileProgress: 0,
          overallProgress: 0,
          speedBytesPerSecond: 0,
          estimatedTimeRemaining: null,
          queuePosition: 0,
        ),
        clearResult: true,
        clearMessage: true,
        canRetry: false,
      ),
    );
    try {
      final Result<CompressionResult> result = await _compressImages.execute(
        request,
        control: control,
        onProgress: (ProcessingProgress progress) {
          if (isDisposed || control.isCancelled) return;
          _set(
            _state.copyWith(
              status: control.isPaused
                  ? OperationStatus.paused
                  : OperationStatus.loading,
              progress: progress,
            ),
          );
        },
      );
      if (isDisposed) return;
      if (control.isCancelled) {
        _set(_state.copyWith(status: OperationStatus.cancelled));
        return;
      }
      result.fold(
        onSuccess: (CompressionResult value) => _set(
          _state.copyWith(
            status: OperationStatus.completed,
            result: value,
            clearMessage: true,
            progress: _completedProgress(value),
          ),
        ),
        onFailure: (AppError error) => _set(
          _state.copyWith(
            status: error.code == ErrorCode.cancelled
                ? OperationStatus.cancelled
                : OperationStatus.error,
            message: _friendlyError(error),
            canRetry: error.isRecoverable,
          ),
        ),
      );
    } catch (error, stackTrace) {
      if (!isDisposed) {
        if (control.isCancelled) {
          _set(_state.copyWith(status: OperationStatus.cancelled));
        } else {
          _set(
            _state.copyWith(
              status: OperationStatus.error,
              message: _friendlyError(_providerError(error, stackTrace)),
              canRetry: true,
            ),
          );
        }
      }
    } finally {
      _control = null;
      _running = false;
    }
  }

  @override
  void dispose() {
    _control?.cancel();
    _control = null;
    super.dispose();
  }

  void cancel() {
    final OperationControl? control = _control;
    control?.cancel();
    if (control != null && !isDisposed) {
      _set(_state.copyWith(status: OperationStatus.cancelled));
    }
  }

  void pause() {
    final OperationControl? control = _control;
    if (control == null || control.isCancelled) return;
    control.pause();
    if (!isDisposed) _set(_state.copyWith(status: OperationStatus.paused));
  }

  void resume() {
    final OperationControl? control = _control;
    if (control == null || control.isCancelled) return;
    control.resume();
    if (!isDisposed) _set(_state.copyWith(status: OperationStatus.loading));
  }

  Future<void> retry() {
    final CompressionRequest? request = _lastRequest;
    return request == null ? Future<void>.value() : compress(request);
  }

  ProcessingProgress _completedProgress(CompressionResult result) =>
      ProcessingProgress(
        currentFile: result.images.isEmpty ? null : result.images.last.name,
        completedFiles: result.statistics.processedFiles,
        totalFiles: result.statistics.processedFiles,
        currentFileProgress: 1,
        overallProgress: 1,
        speedBytesPerSecond: result.benchmark?.bytesPerSecond ?? 0,
        estimatedTimeRemaining: Duration.zero,
        queuePosition: 0,
      );

  void _set(CompressionState next) {
    if (_state == next || isDisposed) return;
    _state = next;
    notifyStateChanged();
  }
}

/// Coordinates a batch request independently from single-image state.
final class BatchCompressionProvider extends ApplicationProvider {
  BatchCompressionProvider({required CompressImagesUseCase compressImages})
    : _compressImages = compressImages;

  final CompressImagesUseCase _compressImages;
  BatchCompressionState _state = BatchCompressionState();
  CompressionRequest? _lastRequest;
  OperationControl? _control;
  bool _running = false;

  BatchCompressionState get state => _state;

  Future<void> compress(CompressionRequest request) async {
    if (isDisposed || _running) return;
    _running = true;
    _lastRequest = request;
    final OperationControl control = OperationControl();
    _control = control;
    _set(
      _state.copyWith(
        status: OperationStatus.loading,
        results: const <CompressedImage>[],
        progress: ProcessingProgress(
          completedFiles: 0,
          totalFiles: request.images.length,
          currentFileProgress: 0,
          overallProgress: 0,
          speedBytesPerSecond: 0,
          estimatedTimeRemaining: null,
          queuePosition: 0,
        ),
        clearMessage: true,
        canRetry: false,
      ),
    );
    try {
      final Result<CompressionResult> result = await _compressImages.execute(
        request,
        control: control,
        onProgress: (ProcessingProgress progress) {
          if (isDisposed || control.isCancelled) return;
          _set(
            _state.copyWith(
              status: control.isPaused
                  ? OperationStatus.paused
                  : OperationStatus.loading,
              progress: progress,
            ),
          );
        },
      );
      if (isDisposed) return;
      if (control.isCancelled) {
        _set(_state.copyWith(status: OperationStatus.cancelled));
        return;
      }
      result.fold(
        onSuccess: (CompressionResult value) => _set(
          _state.copyWith(
            status: OperationStatus.completed,
            results: List<CompressedImage>.unmodifiable(value.images),
            progress: ProcessingProgress(
              currentFile: value.images.isEmpty ? null : value.images.last.name,
              completedFiles: value.statistics.processedFiles,
              totalFiles: value.statistics.processedFiles,
              currentFileProgress: 1,
              overallProgress: 1,
              speedBytesPerSecond: value.benchmark?.bytesPerSecond ?? 0,
              estimatedTimeRemaining: Duration.zero,
              queuePosition: 0,
            ),
          ),
        ),
        onFailure: (AppError error) => _set(
          _state.copyWith(
            status: error.code == ErrorCode.cancelled
                ? OperationStatus.cancelled
                : OperationStatus.error,
            message: _friendlyError(error),
            canRetry: error.isRecoverable,
          ),
        ),
      );
    } catch (error, stackTrace) {
      if (!isDisposed) {
        if (control.isCancelled) {
          _set(_state.copyWith(status: OperationStatus.cancelled));
        } else {
          _set(
            _state.copyWith(
              status: OperationStatus.error,
              message: _friendlyError(_providerError(error, stackTrace)),
              canRetry: true,
            ),
          );
        }
      }
    } finally {
      _control = null;
      _running = false;
    }
  }

  @override
  void dispose() {
    _control?.cancel();
    _control = null;
    super.dispose();
  }

  void cancel() {
    final OperationControl? control = _control;
    control?.cancel();
    if (control != null && !isDisposed) {
      _set(_state.copyWith(status: OperationStatus.cancelled));
    }
  }

  void pause() {
    final OperationControl? control = _control;
    if (control == null || control.isCancelled) return;
    control.pause();
    if (!isDisposed) _set(_state.copyWith(status: OperationStatus.paused));
  }

  void resume() {
    final OperationControl? control = _control;
    if (control == null || control.isCancelled) return;
    control.resume();
    if (!isDisposed) _set(_state.copyWith(status: OperationStatus.loading));
  }

  Future<void> retry() {
    final CompressionRequest? request = _lastRequest;
    return request == null ? Future<void>.value() : compress(request);
  }

  void _set(BatchCompressionState next) {
    if (_state == next || isDisposed) return;
    _state = next;
    notifyStateChanged();
  }
}

/// Loads and mutates local history.
final class HistoryProvider extends ApplicationProvider {
  HistoryProvider({
    required LoadHistoryUseCase loadHistory,
    required DeleteHistoryUseCase deleteHistory,
  }) : _loadHistory = loadHistory,
       _deleteHistory = deleteHistory;

  final LoadHistoryUseCase _loadHistory;
  final DeleteHistoryUseCase _deleteHistory;
  HistoryState _state = HistoryState();
  bool _running = false;

  HistoryState get state => _state;

  Future<void> load() async {
    if (_running || isDisposed) return;
    _running = true;
    _set(_state.copyWith(status: OperationStatus.loading, clearMessage: true));
    try {
      final Result<List<HistoryEntry>> result = await _loadHistory.execute();
      if (isDisposed) return;
      result.fold(
        onSuccess: (List<HistoryEntry> entries) => _set(
          _state.copyWith(
            status: entries.isEmpty
                ? OperationStatus.empty
                : OperationStatus.success,
            entries: List<HistoryEntry>.unmodifiable(entries),
          ),
        ),
        onFailure: (AppError error) => _setError(error),
      );
    } catch (error, stackTrace) {
      if (!isDisposed) _setError(_providerError(error, stackTrace));
    } finally {
      _running = false;
    }
  }

  Future<void> delete(String id) async {
    if (_running || isDisposed) return;
    _running = true;
    try {
      final Result<void> result = await _deleteHistory.execute(id);
      if (isDisposed) return;
      result.fold(
        onSuccess: (_) => _set(
          _state.copyWith(
            entries: List<HistoryEntry>.unmodifiable(
              _state.entries.where((HistoryEntry item) => item.id != id),
            ),
            status: _state.entries.length <= 1
                ? OperationStatus.empty
                : OperationStatus.success,
            clearMessage: true,
          ),
        ),
        onFailure: (AppError error) => _setError(error),
      );
    } catch (error, stackTrace) {
      if (!isDisposed) _setError(_providerError(error, stackTrace));
    } finally {
      _running = false;
    }
  }

  Future<void> retry() => load();

  void _setError(AppError error) => _set(
    _state.copyWith(
      status: OperationStatus.error,
      message: _friendlyError(error),
      canRetry: error.isRecoverable,
    ),
  );

  void _set(HistoryState next) {
    if (_state == next || isDisposed) return;
    _state = next;
    notifyStateChanged();
  }
}

/// Loads and updates persisted settings.
final class SettingsProvider extends ApplicationProvider {
  SettingsProvider({
    required LoadSettingsUseCase loadSettings,
    required UpdateSettingsUseCase updateSettings,
  }) : _loadSettings = loadSettings,
       _updateSettings = updateSettings;

  final LoadSettingsUseCase _loadSettings;
  final UpdateSettingsUseCase _updateSettings;
  SettingsState _state = const SettingsState();
  bool _running = false;

  SettingsState get state => _state;

  Future<void> load() async {
    if (_running || isDisposed) return;
    _running = true;
    _set(_state.copyWith(status: OperationStatus.loading, clearMessage: true));
    try {
      final Result<Settings> result = await _loadSettings.execute();
      if (isDisposed) return;
      result.fold(
        onSuccess: (Settings settings) => _set(
          _state.copyWith(status: OperationStatus.success, settings: settings),
        ),
        onFailure: (AppError error) => _setError(error),
      );
    } catch (error, stackTrace) {
      if (!isDisposed) _setError(_providerError(error, stackTrace));
    } finally {
      _running = false;
    }
  }

  Future<void> update(Settings settings) async {
    if (_running || isDisposed) return;
    _running = true;
    _set(_state.copyWith(status: OperationStatus.loading, clearMessage: true));
    try {
      final Result<void> result = await _updateSettings.execute(settings);
      if (isDisposed) return;
      result.fold(
        onSuccess: (_) => _set(
          _state.copyWith(status: OperationStatus.success, settings: settings),
        ),
        onFailure: (AppError error) => _setError(error),
      );
    } catch (error, stackTrace) {
      if (!isDisposed) _setError(_providerError(error, stackTrace));
    } finally {
      _running = false;
    }
  }

  void _setError(AppError error) => _set(
    _state.copyWith(
      status: OperationStatus.error,
      message: _friendlyError(error),
      canRetry: error.isRecoverable,
    ),
  );

  void _set(SettingsState next) {
    if (_state == next || isDisposed) return;
    _state = next;
    notifyStateChanged();
  }
}

/// Loads aggregate local statistics.
final class StatisticsProvider extends ApplicationProvider {
  StatisticsProvider({required LoadStatisticsUseCase loadStatistics})
    : _loadStatistics = loadStatistics;

  final LoadStatisticsUseCase _loadStatistics;
  StatisticsState _state = const StatisticsState();
  bool _running = false;

  StatisticsState get state => _state;

  Future<void> load() async {
    if (_running || isDisposed) return;
    _running = true;
    _set(_state.copyWith(status: OperationStatus.loading, clearMessage: true));
    try {
      final Result<CompressionStatistics> result = await _loadStatistics
          .execute();
      if (isDisposed) return;
      result.fold(
        onSuccess: (CompressionStatistics value) => _set(
          _state.copyWith(status: OperationStatus.success, statistics: value),
        ),
        onFailure: (AppError error) => _setError(error),
      );
    } catch (error, stackTrace) {
      if (!isDisposed) _setError(_providerError(error, stackTrace));
    } finally {
      _running = false;
    }
  }

  Future<void> retry() => load();

  void _setError(AppError error) => _set(
    _state.copyWith(
      status: OperationStatus.error,
      message: _friendlyError(error),
      canRetry: error.isRecoverable,
    ),
  );

  void _set(StatisticsState next) {
    if (_state == next || isDisposed) return;
    _state = next;
    notifyStateChanged();
  }
}

/// Runs a compression workflow and exposes its local benchmark result.
final class BenchmarkProvider extends ApplicationProvider {
  BenchmarkProvider({required CompressImagesUseCase compressImages})
    : _compressImages = compressImages;

  final CompressImagesUseCase _compressImages;
  BenchmarkState _state = const BenchmarkState();
  bool _running = false;

  BenchmarkState get state => _state;

  Future<void> run(CompressionRequest request) async {
    if (_running || isDisposed) return;
    _running = true;
    _set(_state.copyWith(status: OperationStatus.loading, clearMessage: true));
    try {
      final Result<CompressionResult> result = await _compressImages.execute(
        request,
      );
      if (isDisposed) return;
      result.fold(
        onSuccess: (CompressionResult value) => _set(
          _state.copyWith(
            status: OperationStatus.completed,
            result: value.benchmark,
          ),
        ),
        onFailure: (AppError error) => _set(
          _state.copyWith(
            status: OperationStatus.error,
            message: _friendlyError(error),
            canRetry: error.isRecoverable,
          ),
        ),
      );
    } catch (error, stackTrace) {
      if (!isDisposed) {
        _set(
          _state.copyWith(
            status: OperationStatus.error,
            message: _friendlyError(_providerError(error, stackTrace)),
            canRetry: true,
          ),
        );
      }
    } finally {
      _running = false;
    }
  }

  void _set(BenchmarkState next) {
    if (_state == next || isDisposed) return;
    _state = next;
    notifyStateChanged();
  }
}
