import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_strings.dart';
import '../domain/compression_models.dart';
import '../domain/gateways/compressor_gateways.dart';

/// Performs image work in native codecs and stores outputs in the app cache.
class ImageCompressionService implements ImageCompressionGateway {
  /// Reads dimensions and file size without retaining decoded image memory.
  @override
  Future<PhotoAsset> inspect(String sourcePath) async {
    final File source = File(sourcePath);
    final int bytes = await source.length();
    final ui.ImmutableBuffer buffer = await ui.ImmutableBuffer.fromFilePath(
      source.path,
    );
    try {
      final ui.ImageDescriptor descriptor = await ui.ImageDescriptor.encoded(
        buffer,
      );
      try {
        return PhotoAsset(
          filePath: source.path,
          bytes: bytes,
          width: descriptor.width,
          height: descriptor.height,
        );
      } finally {
        descriptor.dispose();
      }
    } finally {
      buffer.dispose();
    }
  }

  /// Compresses a source file to a cache-only output at the requested options.
  ///
  /// When [targetBytes] is provided the engine binary-searches quality so the
  /// output lands at or under the target, then reports the achieved quality on
  /// the returned [CompressedAsset] so the UI slider can follow along.
  @override
  Future<CompressedAsset> compress(
    PhotoAsset source, {
    int quality = 72,
    CompressorFormat format = CompressorFormat.jpeg,
    double scale = 1,
    int? targetBytes,
    bool keepExif = false,
  }) async {
    final Directory cache = await _cacheDirectory();
    // Lossy encoders respond to quality; PNG does not, so target-size search
    // is skipped for it and the requested quality is used as-is.
    if (targetBytes != null && format != CompressorFormat.png) {
      return _compressToTarget(
        source,
        cache,
        format: format,
        scale: scale,
        targetBytes: targetBytes,
        keepExif: keepExif,
      );
    }
    return _encodeTo(
      source,
      p.join(cache.path, _filename(format)),
      format: format,
      quality: quality,
      scale: scale,
      keepExif: keepExif,
    );
  }

  /// Finds the highest quality whose output fits inside [targetBytes].
  ///
  /// The search converges in a handful of attempts (log2 of the quality
  /// range), which is fine because it only runs when the user picks a target
  /// size — never while a slider is being dragged.
  Future<CompressedAsset> _compressToTarget(
    PhotoAsset source,
    Directory cache, {
    required CompressorFormat format,
    required double scale,
    required int targetBytes,
    required bool keepExif,
  }) async {
    int low = _minQuality;
    int high = 100;
    CompressedAsset best = await _encodeTo(
      source,
      p.join(cache.path, _filename(format)),
      format: format,
      quality: low,
      scale: scale,
      keepExif: keepExif,
    );
    // Even the minimum quality exceeds the target: keep the smallest output.
    if (best.bytes > targetBytes) return best;
    while (low <= high) {
      final int mid = (low + high) ~/ 2;
      final CompressedAsset candidate = await _encodeTo(
        source,
        p.join(cache.path, _filename(format)),
        format: format,
        quality: mid,
        scale: scale,
        keepExif: keepExif,
      );
      if (candidate.bytes <= targetBytes) {
        await _deleteFile(best.filePath);
        best = candidate;
        low = mid + 1;
      } else {
        await _deleteFile(candidate.filePath);
        high = mid - 1;
      }
    }
    return best;
  }

  Future<CompressedAsset> _encodeTo(
    PhotoAsset source,
    String targetPath, {
    required CompressorFormat format,
    required int quality,
    required double scale,
    required bool keepExif,
  }) async {
    XFile? output;
    try {
      output = await FlutterImageCompress.compressAndGetFile(
        source.filePath,
        targetPath,
        quality: quality,
        format: _compressFormat(format),
        minWidth: _targetWidth(source, scale),
        minHeight: _targetHeight(source, scale),
        keepExif: keepExif,
      );
    } catch (_) {
      await _deleteFile(targetPath);
      rethrow;
    }
    if (output == null) {
      throw const FileSystemException(
        'The image encoder did not return an output file.',
      );
    }

    final File compressedFile = File(output.path);
    try {
      final PhotoAsset metadata = await inspect(compressedFile.path);
      return CompressedAsset(
        filePath: compressedFile.path,
        bytes: metadata.bytes,
        width: metadata.width,
        height: metadata.height,
        quality: quality,
        format: format,
      );
    } catch (_) {
      await _deleteFile(compressedFile.path);
      rethrow;
    }
  }

  /// Keeps large sources bounded at the max dimension unless a resize was
  /// explicitly requested, in which case the exact fraction is used.
  int _targetWidth(PhotoAsset source, double scale) =>
      scale < 1 ? math.max(1, (source.width * scale).round()) : _maxDimension;

  int _targetHeight(PhotoAsset source, double scale) =>
      scale < 1 ? math.max(1, (source.height * scale).round()) : _maxDimension;

  CompressFormat _compressFormat(CompressorFormat format) => switch (format) {
    CompressorFormat.jpeg => CompressFormat.jpeg,
    CompressorFormat.png => CompressFormat.png,
    CompressorFormat.webp => CompressFormat.webp,
  };

  String _filename(CompressorFormat format) {
    final String extension = switch (format) {
      CompressorFormat.jpeg => 'jpg',
      CompressorFormat.png => 'png',
      CompressorFormat.webp => 'webp',
    };
    return '${AppConstants.temporaryOutputPrefix}'
        '${DateTime.now().microsecondsSinceEpoch}_${_fileCounter++}.$extension';
  }

  Future<Directory> _cacheDirectory() async {
    final Directory cacheRoot = await getTemporaryDirectory();
    final Directory cache = Directory(
      p.join(cacheRoot.path, AppStrings.cacheDirectory),
    );
    await cache.create(recursive: true);
    return cache;
  }

  Future<void> _deleteFile(String filePath) async {
    try {
      final File file = File(filePath);
      if (await file.exists()) await file.delete();
    } on FileSystemException {
      // Cache cleanup is best effort.
    }
  }

  @override
  Future<void> deleteTemporaryOutput(String filePath) async {
    final Directory cacheRoot = await getTemporaryDirectory();
    final Directory managedCache = Directory(
      p.join(cacheRoot.path, AppStrings.cacheDirectory),
    );
    final File file = File(filePath);
    try {
      if (!await file.exists()) return;
      final String managedRoot = p.normalize(
        p.absolute(await managedCache.resolveSymbolicLinks()),
      );
      final String candidate = p.normalize(
        p.absolute(await file.resolveSymbolicLinks()),
      );
      final String relative = p.relative(candidate, from: managedRoot);
      final bool insideManagedCache =
          relative != '..' &&
          !relative.startsWith('..${p.separator}') &&
          !p.isAbsolute(relative);
      final bool isGeneratedOutput = p
          .basename(candidate)
          .startsWith(AppConstants.temporaryOutputPrefix);
      if (insideManagedCache && isGeneratedOutput) {
        await file.delete();
      }
    } on FileSystemException {
      // Temporary cleanup is best effort and must not interrupt the feature.
    }
  }

  static const int _maxDimension = 2400;

  static const int _minQuality = 10;

  static int _fileCounter = 0;
}
