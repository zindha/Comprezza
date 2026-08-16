import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:path/path.dart' as p;

import '../../../../../../core/errors/app_error.dart';
import '../../../../../../core/errors/error_mapper.dart';
import '../../../../../../core/errors/result_error_adapter.dart';
import '../../../../../../core/models/result.dart';
import '../../../../../../core/services/file_system_service.dart';
import '../interfaces/file_management_interfaces.dart';
import '../models/file_management_models.dart';

/// Persists history records as a replaceable local JSON document.
final class JsonHistoryStorage implements HistoryStorage {
  /// Creates history storage.
  JsonHistoryStorage({required this.storage, required this.fileSystem});

  /// App-managed storage resolver.
  final StorageManager storage;

  /// App-owned filesystem boundary.
  final FileSystemService fileSystem;

  static const String _fileName = 'compression_history.json';

  // Serializes history reads and read-modify-write mutations within one app
  // process, preventing readers from observing an in-progress replacement.
  Future<void> _operationTail = Future<void>.value();

  @override
  Future<Result<void>> save(CompressionHistoryRecord record) {
    return _serialize<Result<void>>(() async {
      try {
        final Result<Directory> directory = await storage.directory(
          StorageLocation.history,
        );
        if (directory case Failure<Directory>(error: final AppError error)) {
          return Result<void>.failure(error);
        }
        final File file = File(
          p.join((directory as Success<Directory>).value.path, _fileName),
        );
        final List<CompressionHistoryRecord> records = await _readFile(file);
        records.removeWhere(
          (CompressionHistoryRecord item) => item.id == record.id,
        );
        records.add(record);
        records.sort(
          (CompressionHistoryRecord a, CompressionHistoryRecord b) =>
              b.createdAt.compareTo(a.createdAt),
        );
        final Result<File> writeResult = await fileSystem.writeTextAtomic(
          file,
          jsonEncode(
            records
                .map((CompressionHistoryRecord item) => item.toJson())
                .toList(),
          ),
        );
        if (writeResult case Failure<File>(error: final AppError error)) {
          return Result<void>.failure(error);
        }
        return const Result<void>.success(null);
      } catch (error, stackTrace) {
        return _failure<void>(error, stackTrace);
      }
    });
  }

  @override
  Future<Result<List<CompressionHistoryRecord>>> readAll() {
    return _serialize<Result<List<CompressionHistoryRecord>>>(() async {
      try {
        final Result<Directory> directory = await storage.directory(
          StorageLocation.history,
        );
        if (directory case Failure<Directory>(error: final AppError error)) {
          return Result<List<CompressionHistoryRecord>>.failure(error);
        }
        final File file = File(
          p.join((directory as Success<Directory>).value.path, _fileName),
        );
        final List<CompressionHistoryRecord> records = await _readFile(file);
        records.sort(
          (CompressionHistoryRecord a, CompressionHistoryRecord b) =>
              b.createdAt.compareTo(a.createdAt),
        );
        return Result<List<CompressionHistoryRecord>>.success(
          List<CompressionHistoryRecord>.unmodifiable(records),
        );
      } catch (error, stackTrace) {
        return _failure<List<CompressionHistoryRecord>>(error, stackTrace);
      }
    });
  }

  @override
  Future<Result<void>> delete(String id) {
    return _serialize<Result<void>>(() async {
      try {
        final Result<Directory> directory = await storage.directory(
          StorageLocation.history,
        );
        if (directory case Failure<Directory>(error: final AppError error)) {
          return Result<void>.failure(error);
        }
        final File file = File(
          p.join((directory as Success<Directory>).value.path, _fileName),
        );
        final List<CompressionHistoryRecord> records = await _readFile(file);
        records.removeWhere((CompressionHistoryRecord item) => item.id == id);
        final Result<File> writeResult = await fileSystem.writeTextAtomic(
          file,
          jsonEncode(
            records
                .map((CompressionHistoryRecord item) => item.toJson())
                .toList(),
          ),
        );
        if (writeResult case Failure<File>(error: final AppError error)) {
          return Result<void>.failure(error);
        }
        return const Result<void>.success(null);
      } catch (error, stackTrace) {
        return _failure<void>(error, stackTrace);
      }
    });
  }

  Future<T> _serialize<T>(Future<T> Function() operation) async {
    final Future<void> previous = _operationTail;
    final Completer<void> completed = Completer<void>();
    _operationTail = completed.future;
    await previous;
    try {
      return await operation();
    } finally {
      completed.complete();
    }
  }

  Future<List<CompressionHistoryRecord>> _readFile(File file) async {
    if (!await file.exists()) return <CompressionHistoryRecord>[];
    final Result<String> readResult = await fileSystem.readText(file);
    if (readResult case Failure<String>(error: final AppError error)) {
      throw FileSystemException(error.message);
    }
    final String contents = (readResult as Success<String>).value;
    // Decoding and parsing the whole document is pure CPU work that would
    // otherwise block the UI isolate when the read completes (exactly when the
    // route transition is animating on first visit). Run it on a background
    // isolate; records are plain data so they cross the boundary safely.
    return _parseHistoryDocument(contents);
  }

  /// Decodes and parses a history document on a background isolate.
  ///
  /// Static so the isolate closure captures only the sendable [contents]
  /// string, never this storage instance or its filesystem dependencies.
  static Future<List<CompressionHistoryRecord>> _parseHistoryDocument(
    String contents,
  ) {
    return Isolate.run<List<CompressionHistoryRecord>>(() {
      final Object? decoded;
      try {
        decoded = jsonDecode(contents);
      } on FormatException catch (error, stackTrace) {
        throw FormatException(
          'History storage is corrupted: $error',
          stackTrace,
        );
      }
      if (decoded is! List<Object?>) {
        throw const FormatException('History storage has an invalid shape.');
      }
      final List<CompressionHistoryRecord> records =
          <CompressionHistoryRecord>[];
      for (final Object? entry in decoded) {
        if (entry is! Map<String, Object?>) {
          throw const FormatException('History record has an invalid shape.');
        }
        final CompressionHistoryRecord? record =
            CompressionHistoryRecord.fromJson(entry);
        if (record == null) {
          throw const FormatException('History record is invalid.');
        }
        records.add(record);
      }
      return records;
    });
  }

  Result<T> _failure<T>(Object error, StackTrace stackTrace) {
    final exception = ErrorMapper.map(error, stackTrace);
    return Result<T>.failure(ResultErrorAdapter.fromException(exception));
  }
}
