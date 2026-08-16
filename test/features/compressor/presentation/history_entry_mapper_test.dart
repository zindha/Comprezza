import 'package:comprezza/core/constants/app_constants.dart';
import 'package:comprezza/features/compressor/data/services/file_management/models/file_management_models.dart';
import 'package:comprezza/features/compressor/presentation/history/history_entry_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('historyEntryFromRecord', () {
    final DateTime createdAt = DateTime(2026, 8, 8, 12, 30);

    CompressionHistoryRecord record({
      double ratio = 4,
      int savedBytes = 3000,
      int processedFiles = 1,
    }) => CompressionHistoryRecord(
      id: 'entry-1',
      originalPath: '/photos/vacation.jpg',
      compressedPath: '/cache/comprezza_out.webp',
      createdAt: createdAt,
      preset: 'web',
      compressionRatio: ratio,
      savedBytes: savedBytes,
      checksum: 'abc123',
      processedFiles: processedFiles,
    );

    test('maps identity fields from the record', () {
      final entry = historyEntryFromRecord(record());

      expect(entry.id, 'entry-1');
      expect(entry.sourceName, 'vacation.jpg');
      expect(entry.outputName, 'comprezza_out.webp');
      expect(entry.createdAt, createdAt);
      expect(entry.outputPath, '/cache/comprezza_out.webp');
      expect(entry.preset.id, 'web');
      expect(entry.preset.name, 'web');
      expect(entry.preset.quality, AppConstants.defaultQuality);
      expect(entry.statistics.processedFiles, 1);
    });

    test('derives input and output bytes from ratio and saved bytes', () {
      // ratio = input / output and saved = input - output with ratio = 4 and
      // saved = 3000 -> input = 4000, output = 1000.
      final entry = historyEntryFromRecord(record());

      expect(entry.statistics.inputBytes, 4000);
      expect(entry.statistics.outputBytes, 1000);
      expect(entry.statistics.savedBytes, 3000);
      expect(entry.statistics.savingsRatio, closeTo(4, .001));
    });

    test('falls back gracefully when the record reports no savings', () {
      final entry = historyEntryFromRecord(record(ratio: 1, savedBytes: 500));

      expect(entry.statistics.inputBytes, 500);
      expect(entry.statistics.outputBytes, 0);
      expect(entry.statistics.savedBytes, 500);
      expect(entry.statistics.savingsRatio, 1);
    });

    test('maps the processed file count from batch records', () {
      final entry = historyEntryFromRecord(record(processedFiles: 3));

      expect(entry.statistics.processedFiles, 3);
    });

    test('legacy JSON without processedFiles defaults to one file', () {
      final parsedRecord = CompressionHistoryRecord.fromJson(<String, Object?>{
        'id': 'entry-1',
        'originalPath': '/photos/vacation.jpg',
        'compressedPath': '/cache/comprezza_out.webp',
        'createdAt': createdAt.toIso8601String(),
        'preset': 'web',
        'compressionRatio': 4,
        'savedBytes': 3000,
        'checksum': 'abc123',
      });

      expect(parsedRecord, isNotNull);
      expect(parsedRecord!.processedFiles, 1);
    });

    test('JSON with a processedFiles count round-trips', () {
      final CompressionHistoryRecord? parsedRecord =
          CompressionHistoryRecord.fromJson(record(processedFiles: 5).toJson());

      expect(parsedRecord, isNotNull);
      expect(parsedRecord!.processedFiles, 5);
    });
  });
}
