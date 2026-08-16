import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;

import '../../core/constants/app_strings.dart';
import '../../core/errors/app_error.dart';
import '../../core/errors/error_code.dart';
import '../../core/models/result.dart';
import '../../core/utils/zip_writer.dart';
import '../../features/compressor/data/services/file_management/interfaces/file_management_interfaces.dart';
import '../../features/compressor/data/services/file_management/models/file_management_models.dart';
import '../../features/compressor/domain/compression_models.dart';
import '../../features/compressor/domain/gateways/compressor_gateways.dart';
import '../../features/compressor/domain/share_export/share_export_interfaces.dart';
import '../../features/compressor/domain/share_export/share_export_models.dart';
import '../../features/compressor/presentation/batch_compression_controller.dart';
import 'service_locator.dart';

/// Bridges the device gallery/Downloads persistence used by batch actions.
const MethodChannel _deviceChannel = MethodChannel(
  AppStrings.deviceExportChannel,
);

/// Wires the presentation batch controller to the platform picker, engine,
/// gallery/Downloads persistence, share sheet, and ZIP archive builder.
///
/// The controller itself stays presentation-owned (injected seams) so its
/// screen remains testable; this adapter is the one place that connects those
/// seams to the real application services.
final class BatchCompressionAdapter implements Disposable {
  /// Creates the adapter and the controller it owns.
  ///
  /// [exportGateway], [shareService], and [storage] are optional so the
  /// adapter keeps working in tests that only exercise picking/processing.
  /// When omitted, the corresponding batch actions remain no-ops.
  BatchCompressionAdapter({
    required ImagePickerService picker,
    required ImageCompressionGateway compression,
    HistoryStorage? history,
    ImageExportGateway? exportGateway,
    ShareExportService? shareService,
    StorageManager? storage,
  }) : controller = BatchCompressionController(
         picker: () => _pickImages(picker, compression),
         processor: (BatchImageItem image, BatchCompressionSettings settings) =>
             _process(compression, image, settings),
         history: history,
         saveAllHandler: exportGateway == null
             ? null
             : (List<String> paths) => _saveAll(exportGateway, paths),
         shareHandler: shareService == null
             ? null
             : (List<String> paths) => _share(shareService, compression, paths),
         zipBuilder: storage == null
             ? null
             : (List<String> paths) => _buildZip(storage, paths),
         zipSaver: storage == null ? null : _saveZipToDownloads,
       );

  /// The batch workflow controller this adapter wires.
  final BatchCompressionController controller;

  /// Note: the batch picker seam has no error channel, so a failed pick
  /// (e.g. permission denial) is surfaced as an empty selection and the
  /// screen falls back to its empty state.
  static Future<List<BatchImageItem>> _pickImages(
    ImagePickerService picker,
    ImageCompressionGateway compression,
  ) async {
    final Result<List<SelectedFile>> result = await picker.pick(
      const ImageSelectionRequest(multiple: true),
    );
    return result.fold(
      onSuccess: (List<SelectedFile> files) =>
          _inspectSelection(files, compression),
      onFailure: (_) =>
          Future<List<BatchImageItem>>.value(const <BatchImageItem>[]),
    );
  }

  static Future<List<BatchImageItem>> _inspectSelection(
    List<SelectedFile> files,
    ImageCompressionGateway compression,
  ) async {
    final List<BatchImageItem> items = <BatchImageItem>[];
    for (final SelectedFile file in files) {
      try {
        final PhotoAsset asset = await compression.inspect(file.path);
        items.add(
          BatchImageItem(
            id: file.path,
            path: file.path,
            name: file.name,
            bytes: asset.bytes,
            width: asset.width,
            height: asset.height,
            format: _formatOf(file.path),
          ),
        );
      } catch (_) {
        // Unreadable files are skipped instead of failing the whole batch.
      }
    }
    return items;
  }

  static Future<BatchImageResult> _process(
    ImageCompressionGateway compression,
    BatchImageItem image,
    BatchCompressionSettings settings,
  ) async {
    final CompressedAsset output = await compression.compress(
      PhotoAsset(
        filePath: image.path,
        bytes: image.bytes,
        width: image.width,
        height: image.height,
      ),
      quality: settings.quality,
      format: _format(settings.format),
      scale: _scale(settings.resize),
      targetBytes: settings.targetBytes,
      keepExif: settings.keepMetadata,
    );
    return BatchImageResult(
      outputPath: output.filePath,
      outputBytes: output.bytes,
    );
  }

  /// Saves every generated output to the gallery using the approved gateway.
  static Future<void> _saveAll(
    ImageExportGateway gateway,
    List<String> outputPaths,
  ) async {
    for (final String path in outputPaths) {
      await gateway.saveToDevice(path);
    }
  }

  /// Dispatches generated files (images or a ZIP) through the share sheet.
  static Future<void> _share(
    ShareExportService service,
    ImageCompressionGateway inspector,
    List<String> filePaths,
  ) async {
    final List<ShareAsset> assets = <ShareAsset>[];
    for (final String path in filePaths) {
      assets.add(ShareAsset(compressed: await _assetOf(inspector, path)));
    }
    final Result<ShareOutcome> result = await service.share(
      ShareRequest(
        assets: assets,
        scope: filePaths.length > 1 ? ShareScope.selected : ShareScope.single,
      ),
    );
    if (result case Failure<ShareOutcome>(error: final AppError error)) {
      throw error;
    }
  }

  /// Builds a STORE-method ZIP archive of the completed outputs.
  static Future<BatchZipResult> _buildZip(
    StorageManager storage,
    List<String> outputPaths,
  ) async {
    final Result<Directory> directoryResult = await storage.directory(
      StorageLocation.exports,
    );
    if (directoryResult case Failure<Directory>(error: final AppError error)) {
      throw error;
    }
    final Directory directory = (directoryResult as Success<Directory>).value;
    final String stamp = DateTime.now().toUtc().toIso8601String().replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );
    final String name = 'Comprezza_$stamp.zip';
    final File output = File(p.join(directory.path, name));
    final Map<String, int> nameCounts = <String, int>{};
    try {
      await ZipWriter.write(
        outputPath: output.path,
        entries: <ZipEntry>[
          for (final String path in outputPaths)
            ZipEntry(
              sourcePath: path,
              name: _uniqueZipName(p.basename(path), nameCounts),
            ),
        ],
      );
    } on Object {
      // Never leave a partially written archive behind on failure.
      await _deleteBestEffort(output.path);
      rethrow;
    }
    return BatchZipResult(
      path: output.path,
      name: name,
      bytes: await output.length(),
      fileCount: outputPaths.length,
    );
  }

  static Future<void> _deleteBestEffort(String path) async {
    try {
      final File file = File(path);
      if (await file.exists()) await file.delete();
    } on Object {
      // Preserve the primary archive error.
    }
  }

  /// Persists a ZIP archive to the device Downloads folder via the platform
  /// bridge (Android MediaStore Downloads collection).
  static Future<void> _saveZipToDownloads(String zipPath) async {
    final File file = File(zipPath);
    if (!await file.exists()) {
      throw const AppError(
        code: ErrorCode.notFound,
        message: 'The ZIP archive is no longer available.',
      );
    }
    await _deviceChannel.invokeMethod<void>('saveToDownloads', <String, Object>{
      'path': file.path,
    });
  }

  /// Builds an export asset for a generated file. ZIP archives carry no
  /// image dimensions and skip inspection entirely.
  static Future<ExportAsset> _assetOf(
    ImageCompressionGateway inspector,
    String path,
  ) async {
    if (p.extension(path).toLowerCase() == '.zip') {
      return _zipAsset(path);
    }
    final File file = File(path);
    final PhotoAsset inspected = await inspector.inspect(path);
    return ExportAsset(
      id: path,
      filePath: path,
      displayName: p.basename(path),
      bytes: inspected.bytes > 0 ? inspected.bytes : await file.length(),
      originalBytes: inspected.bytes,
      width: inspected.width,
      height: inspected.height,
      format: _exportFormat(path),
      preset: 'Batch',
      metadataStatus: ExportMetadataStatus.unknown,
    );
  }

  static Future<ExportAsset> _zipAsset(String path) async {
    final File file = File(path);
    return ExportAsset(
      id: path,
      filePath: path,
      displayName: p.basename(path),
      bytes: await file.length(),
      width: 0,
      height: 0,
      format: ExportImageFormat.unknown,
      preset: 'Batch',
      metadataStatus: ExportMetadataStatus.notPresent,
    );
  }

  /// Ensures duplicate archive names (same source basename) stay readable.
  static String _uniqueZipName(String base, Map<String, int> seen) {
    final int count = seen.update(
      base,
      (int value) => value + 1,
      ifAbsent: () => 0,
    );
    if (count == 0) return base;
    return '${p.basenameWithoutExtension(base)}_$count${p.extension(base)}';
  }

  static CompressorFormat _format(BatchOutputFormat format) => switch (format) {
    BatchOutputFormat.jpeg => CompressorFormat.jpeg,
    BatchOutputFormat.png => CompressorFormat.png,
    BatchOutputFormat.webp => CompressorFormat.webp,
  };

  static double _scale(BatchResizeChoice resize) => switch (resize) {
    BatchResizeChoice.original => 1,
    BatchResizeChoice.percent75 => .75,
    BatchResizeChoice.percent50 => .5,
    BatchResizeChoice.percent25 => .25,
  };

  static String _formatOf(String path) {
    final String extension = p.extension(path).toLowerCase();
    return switch (extension) {
      '.png' => 'png',
      '.webp' => 'webp',
      _ => 'jpg',
    };
  }

  static ExportImageFormat _exportFormat(String path) =>
      switch (p.extension(path).toLowerCase()) {
        '.jpg' || '.jpeg' => ExportImageFormat.jpeg,
        '.png' => ExportImageFormat.png,
        '.webp' => ExportImageFormat.webp,
        _ => ExportImageFormat.unknown,
      };

  /// Releases the owned batch controller.
  @override
  void dispose() => controller.dispose();
}
