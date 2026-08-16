import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

import '../../../core/utils/file_size_formatter.dart';
import '../data/services/file_management/interfaces/file_management_interfaces.dart';
import '../data/services/file_management/models/file_management_models.dart';
import '../domain/compression_models.dart';
import '../domain/gateways/compressor_gateways.dart';

/// Coordinates compressor feature state through constructor-injected gateways.
class CompressorController extends ChangeNotifier {
  /// Creates a controller with domain-facing gateways for testing.
  CompressorController({
    required ImagePickerGateway pickerGateway,
    required ImageCompressionGateway compressionGateway,
    required ImageExportGateway exportGateway,
    HistoryStorage? history,
  }) : _pickerGateway = pickerGateway,
       _compressionGateway = compressionGateway,
       _exportGateway = exportGateway,
       _history = history {
    unawaited(recoverLostSelection());
  }

  final ImagePickerGateway _pickerGateway;
  final ImageCompressionGateway _compressionGateway;
  final ImageExportGateway _exportGateway;

  /// Optional persistent history sink. When present, completed exports are
  /// recorded so the History and Insights destinations reflect real sessions.
  final HistoryStorage? _history;
  Timer? _qualityDebounce;
  int _operationId = 0;
  bool _disposed = false;
  _ExportAction? _lastExportAction;
  bool _exportFailed = false;

  /// Current dashboard status.
  CompressorStatus status = CompressorStatus.empty;

  /// Selected source image metadata.
  PhotoAsset? original;

  /// Current compressed output metadata.
  CompressedAsset? compressed;

  /// Current compression quality.
  int quality = 72;

  /// Target output size in bytes, or null for quality-first mode.
  int? targetBytes;

  /// Output format used for the next compression.
  CompressorFormat format = CompressorFormat.jpeg;

  /// Output scale factor (1.0 keeps dimensions, 0.5 halves them).
  double scale = 1;

  /// Whether EXIF metadata is preserved in the compressed output.
  bool keepMetadata = false;

  final ValueNotifier<int> _qualityListenable = ValueNotifier<int>(72);

  /// Quality updates used by the slider and estimate-only UI.
  ValueListenable<int> get qualityListenable => _qualityListenable;

  /// User-safe error text for the current operation.
  String? errorMessage;

  /// Whether an export operation is active.
  bool isExporting = false;

  /// Whether the last export/share operation failed and can be retried.
  bool get exportFailed => _exportFailed;

  /// Whether the dashboard has an image loaded.
  bool get hasSelection => original != null;

  /// Selects a new image and begins its first compression.
  Future<void> pickImage() async {
    if (isExporting || _disposed) return;
    _qualityDebounce?.cancel();
    final int selectionOperation = ++_operationId;
    try {
      final String? selectedPath = await _pickerGateway.pickImagePath();
      if (selectedPath == null ||
          selectionOperation != _operationId ||
          _disposed) {
        return;
      }
      await _loadFile(selectedPath);
    } catch (error) {
      if (selectionOperation == _operationId && !_disposed) {
        _setError(_friendlyError(error));
      }
    }
  }

  /// Captures a new image with the system camera and compresses it.
  Future<void> pickCameraImage() async {
    if (isExporting || _disposed) return;
    _qualityDebounce?.cancel();
    final int selectionOperation = ++_operationId;
    try {
      final String? selectedPath = await _pickerGateway.pickCameraImagePath();
      if (selectedPath == null ||
          selectionOperation != _operationId ||
          _disposed) {
        return;
      }
      await _loadFile(selectedPath);
    } catch (error) {
      if (selectionOperation == _operationId && !_disposed) {
        _setError(_friendlyError(error));
      }
    }
  }

  /// Recovers a photo if Android recreated the activity during picking.
  Future<void> recoverLostSelection() async {
    final int recoveryOperation = _operationId;
    try {
      final String? recoveredPath = await _pickerGateway.recoverLostImagePath();
      if (!_disposed &&
          recoveryOperation == _operationId &&
          recoveredPath != null &&
          original == null) {
        await _loadFile(recoveredPath);
      }
    } catch (error) {
      if (!_disposed && recoveryOperation == _operationId) {
        _setError(_friendlyError(error));
      }
    }
  }

  /// Updates quality and debounces native work while the slider is moving.
  ///
  /// Dragging the slider opts back into manual quality mode, so any active
  /// target-size constraint is cleared and the chip selection follows.
  void setQuality(double value) {
    if (isExporting || original == null || _disposed) return;
    _operationId++;
    final CompressorStatus previousStatus = status;
    quality = value.round().clamp(1, 100).toInt();
    _qualityListenable.value = quality;
    targetBytes = null;
    // Keep the last valid output visible while the replacement is generated.
    // This prevents preview flicker and gives the user a stable comparison
    // during slider interaction.
    status = CompressorStatus.processing;
    errorMessage = null;
    if (previousStatus != CompressorStatus.processing) notifyListeners();
    _qualityDebounce?.cancel();
    _qualityDebounce = Timer(const Duration(milliseconds: 280), () {
      unawaited(_compressCurrent());
    });
  }

  /// Requests an output at or under [bytes]; the engine finds the best quality
  /// and the slider follows the achieved value. Pass null to return to
  /// quality-first mode.
  void setTargetSize(int? bytes) {
    if (isExporting || original == null || _disposed) return;
    _scheduleRecompress(const Duration(milliseconds: 120), () {
      targetBytes = bytes;
    });
  }

  /// Updates the output format and recompresses.
  void setFormat(CompressorFormat value) {
    if (isExporting || original == null || _disposed || format == value) return;
    format = value;
    _scheduleRecompress(const Duration(milliseconds: 120), () {});
  }

  /// Updates the output scale and recompresses.
  void setScale(double value) {
    if (isExporting || original == null || _disposed || scale == value) return;
    scale = value;
    _scheduleRecompress(const Duration(milliseconds: 120), () {});
  }

  /// Toggles EXIF metadata preservation and recompresses.
  void setMetadata(bool value) {
    if (isExporting || original == null || _disposed || keepMetadata == value) {
      return;
    }
    keepMetadata = value;
    _scheduleRecompress(const Duration(milliseconds: 120), () {});
  }

  void _scheduleRecompress(Duration debounce, VoidCallback mutate) {
    _operationId++;
    final CompressorStatus previousStatus = status;
    mutate();
    status = CompressorStatus.processing;
    errorMessage = null;
    if (previousStatus != CompressorStatus.processing) notifyListeners();
    _qualityDebounce?.cancel();
    _qualityDebounce = Timer(debounce, () {
      unawaited(_compressCurrent());
    });
  }

  /// Exports the current compressed file through the platform gateway.
  Future<bool> saveToDevice() async {
    final CompressedAsset? result = compressed;
    if (result == null ||
        status != CompressorStatus.ready ||
        isExporting ||
        _disposed) {
      return false;
    }
    _lastExportAction = _ExportAction.save;
    _exportFailed = false;
    isExporting = true;
    errorMessage = null;
    notifyListeners();
    try {
      await _exportGateway.saveToDevice(result.filePath);
      unawaited(_recordHistory());
      _exportFailed = false;
      return true;
    } catch (error) {
      _exportFailed = true;
      _setExportError(_friendlyError(error));
      return false;
    } finally {
      isExporting = false;
      if (!_disposed) notifyListeners();
    }
  }

  /// Opens the platform share sheet for the current compressed file.
  Future<bool> shareImage() async {
    final CompressedAsset? result = compressed;
    if (result == null ||
        status != CompressorStatus.ready ||
        isExporting ||
        _disposed) {
      return false;
    }
    _lastExportAction = _ExportAction.share;
    _exportFailed = false;
    isExporting = true;
    errorMessage = null;
    notifyListeners();
    try {
      await _exportGateway.share(result.filePath);
      unawaited(_recordHistory());
      _exportFailed = false;
      return true;
    } catch (error) {
      _exportFailed = true;
      _setExportError(_friendlyError(error));
      return false;
    } finally {
      isExporting = false;
      if (!_disposed) notifyListeners();
    }
  }

  /// Persists the completed session to local history.
  ///
  /// Best-effort and non-blocking: a failed history write must never fail an
  /// export, and the export UI should not wait on disk I/O. The record carries
  /// stable identity plus the two invariants (ratio and bytes saved) the
  /// history/insights screens derive their metrics from.
  Future<void> _recordHistory() async {
    final HistoryStorage? history = _history;
    final PhotoAsset? source = original;
    final CompressedAsset? output = compressed;
    if (history == null || source == null || output == null || _disposed) {
      return;
    }
    final int savedBytes = math.max(0, source.bytes - output.bytes);
    final double ratio = output.bytes > 0 && source.bytes > 0
        ? source.bytes / output.bytes
        : 1;
    // A cheap deterministic identity (not a content hash) keeps the record
    // stable across reads without reading the whole source file again.
    final String checksum = sha256
        .convert(
          utf8.encode(
            '${source.filePath}|${source.bytes}|'
            '${source.width}x${source.height}',
          ),
        )
        .toString();
    final String preset = targetBytes == null
        ? 'Quality $quality'
        : 'Target ${FileSizeFormatter.format(targetBytes!)}';
    final DateTime now = DateTime.now();
    try {
      await history.save(
        CompressionHistoryRecord(
          id: '${now.microsecondsSinceEpoch}',
          originalPath: source.filePath,
          compressedPath: output.filePath,
          createdAt: now,
          preset: preset,
          compressionRatio: ratio,
          savedBytes: savedBytes,
          checksum: checksum,
        ),
      );
    } catch (_) {
      // Best-effort recording: storage failures are intentionally ignored so
      // a completed export is never surfaced as an error.
    }
  }

  /// Retries the most recent failed save/share operation.
  Future<bool> retryLastExport() async {
    if (!_exportFailed || _lastExportAction == null || _disposed) return false;
    if (status == CompressorStatus.error) {
      status = CompressorStatus.ready;
      errorMessage = null;
      _exportFailed = false;
      notifyListeners();
    }
    return _lastExportAction == _ExportAction.save
        ? saveToDevice()
        : shareImage();
  }

  /// Requests cancellation of staging work when the gateway supports it.
  void cancelExport() {
    final ImageExportGateway gateway = _exportGateway;
    if (gateway case final CancellableImageExportGateway cancellable) {
      cancellable.cancelExport();
    }
  }

  /// Clears the current image and returns to the landing state.
  void reset() {
    if (isExporting || _disposed) return;
    _qualityDebounce?.cancel();
    _operationId++;
    final CompressedAsset? previous = compressed;
    original = null;
    compressed = null;
    quality = 72;
    _qualityListenable.value = quality;
    targetBytes = null;
    format = CompressorFormat.jpeg;
    scale = 1;
    keepMetadata = false;
    errorMessage = null;
    _exportFailed = false;
    status = CompressorStatus.empty;
    notifyListeners();
    if (previous != null) unawaited(_deleteTemporaryFile(previous.filePath));
  }

  Future<void> _loadFile(String filePath) async {
    _operationId++;
    final int operation = _operationId;
    final CompressedAsset? previous = compressed;
    status = CompressorStatus.processing;
    original = null;
    compressed = null;
    quality = 72;
    _qualityListenable.value = quality;
    targetBytes = null;
    format = CompressorFormat.jpeg;
    scale = 1;
    keepMetadata = false;
    if (previous != null) unawaited(_deleteTemporaryFile(previous.filePath));
    errorMessage = null;
    notifyListeners();
    try {
      final PhotoAsset asset = await _compressionGateway.inspect(filePath);
      if (operation != _operationId || _disposed) return;
      original = asset;
      notifyListeners();
      await _compressCurrent(operation: operation);
    } catch (error) {
      if (operation == _operationId && !_disposed) {
        _setError(_friendlyError(error));
      }
    }
  }

  Future<void> _compressCurrent({int? operation}) async {
    final PhotoAsset? asset = original;
    if (asset == null || _disposed) return;
    final int currentOperation = operation ?? ++_operationId;
    final CompressedAsset? previous = compressed;
    final CompressorStatus previousStatus = status;
    // Retain a previous valid output while native work is in flight. The
    // workflow renders it as the last result until the new output is ready.
    status = CompressorStatus.processing;
    errorMessage = null;
    if (previousStatus != CompressorStatus.processing) notifyListeners();
    try {
      final CompressedAsset result = await _compressionGateway.compress(
        asset,
        quality: quality,
        format: format,
        scale: scale,
        targetBytes: targetBytes,
        keepExif: keepMetadata,
      );
      if (currentOperation != _operationId || _disposed) {
        await _deleteTemporaryFile(result.filePath);
        return;
      }
      compressed = result;
      // In target-size mode the engine may settle on a different quality than
      // requested; reflect the achieved value in the slider.
      if (result.quality != quality) {
        quality = result.quality;
        _qualityListenable.value = quality;
      }
      if (previous != null && previous.filePath != result.filePath) {
        unawaited(_deleteTemporaryFile(previous.filePath));
      }
      status = CompressorStatus.ready;
      notifyListeners();
    } catch (error) {
      if (currentOperation == _operationId && !_disposed) {
        _setError(_friendlyError(error));
      }
    }
  }

  void _setError(String message) {
    if (_disposed) return;
    status = original == null ? CompressorStatus.empty : CompressorStatus.error;
    _exportFailed = false;
    errorMessage = message;
    notifyListeners();
  }

  void _setExportError(String message) {
    if (_disposed) return;
    status = original == null ? CompressorStatus.empty : CompressorStatus.error;
    errorMessage = message;
    notifyListeners();
  }

  String _friendlyError(Object error) {
    if (error is UnsupportedError) {
      return error.message?.toString() ??
          'This action is not supported on this device.';
    }
    final String message = error.toString();
    return message.startsWith('Exception:')
        ? message.substring('Exception:'.length).trim()
        : message;
  }

  Future<void> _deleteTemporaryFile(String filePath) =>
      _compressionGateway.deleteTemporaryOutput(filePath);

  @override
  void dispose() {
    _disposed = true;
    _qualityDebounce?.cancel();
    // Stop managed export staging before this controller's route scope goes
    // away. The system Sharesheet owns its own lifecycle, but local staging
    // already exposes cooperative cancellation through the existing gateway.
    cancelExport();
    final CompressedAsset? previous = compressed;
    if (previous != null) unawaited(_deleteTemporaryFile(previous.filePath));
    _qualityListenable.dispose();
    super.dispose();
  }
}

enum _ExportAction { save, share }
