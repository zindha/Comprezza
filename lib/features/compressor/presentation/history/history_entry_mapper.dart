import 'package:path/path.dart' as p;

import '../../../../core/constants/app_constants.dart';
import '../../data/services/file_management/models/file_management_models.dart';
import '../../domain/entities/application_entities.dart';

/// Converts a persisted [CompressionHistoryRecord] into the presentation
/// [HistoryEntry] contract used by the history and insights screens.
///
/// The storage record deliberately keeps only stable identity data: paths,
/// timestamp, preset label, ratio, bytes saved, and the processed file count.
/// The derived input/output byte counts are recomputed from those two
/// invariants so the detail view and charts stay truthful to what was
/// persisted.
HistoryEntry historyEntryFromRecord(CompressionHistoryRecord record) {
  final double ratio = record.compressionRatio;
  final int savedBytes = record.savedBytes;
  // saved = input - output and ratio = input / output, so when the run
  // actually saved bytes the original size can be recovered exactly.
  int inputBytes = savedBytes;
  int outputBytes = 0;
  if (ratio > 1) {
    inputBytes = (savedBytes * ratio / (ratio - 1)).round();
    outputBytes = (inputBytes - savedBytes).clamp(0, inputBytes);
  }
  return HistoryEntry(
    id: record.id,
    sourceName: p.basename(record.originalPath),
    outputName: p.basename(record.compressedPath),
    createdAt: record.createdAt,
    statistics: CompressionStatistics(
      inputBytes: inputBytes,
      outputBytes: outputBytes,
      savedBytes: savedBytes,
      savingsRatio: outputBytes > 0 ? inputBytes / outputBytes : ratio,
      processedFiles: record.processedFiles,
      duration: Duration.zero,
    ),
    preset: CompressionPreset(
      id: record.preset,
      name: record.preset,
      quality: AppConstants.defaultQuality,
    ),
    outputPath: record.compressedPath,
  );
}
