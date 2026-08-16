import 'package:flutter/foundation.dart';

import '../errors/app_error.dart';

/// Structured logging abstraction for diagnostics and development support.
abstract interface class AppLogger {
  /// Logs a debug message.
  void debug(
    String message, {
    Map<String, Object?> context = const <String, Object?>{},
  });

  /// Logs an informational message.
  void info(
    String message, {
    Map<String, Object?> context = const <String, Object?>{},
  });

  /// Logs a warning.
  void warning(
    String message, {
    Map<String, Object?> context = const <String, Object?>{},
  });

  /// Logs an error and optional cause.
  void error(
    String message, {
    Object? cause,
    StackTrace? stackTrace,
    Map<String, Object?> context = const <String, Object?>{},
  });
}

/// Console logger enabled only when diagnostics are enabled.
final class ConsoleAppLogger implements AppLogger {
  /// Creates a logger.
  const ConsoleAppLogger({required this.enabled});

  /// Whether diagnostic output is enabled.
  final bool enabled;

  @override
  void debug(
    String message, {
    Map<String, Object?> context = const <String, Object?>{},
  }) {
    _write('DEBUG', message, context);
  }

  @override
  void info(
    String message, {
    Map<String, Object?> context = const <String, Object?>{},
  }) {
    _write('INFO', message, context);
  }

  @override
  void warning(
    String message, {
    Map<String, Object?> context = const <String, Object?>{},
  }) {
    _write('WARNING', message, context);
  }

  @override
  void error(
    String message, {
    Object? cause,
    StackTrace? stackTrace,
    Map<String, Object?> context = const <String, Object?>{},
  }) {
    if (!enabled || kReleaseMode) return;
    final String details = cause == null
        ? ''
        : ' cause_type=${cause.runtimeType}';
    // Stack traces remain attached to AppError for tests/debuggers but are not
    // printed by this privacy-safe console sink because they can contain paths.
    // ignore: avoid_print
    print(
      '[ERROR] ${_safeMessage(message)}$details context=${_safeContext(context)}',
    );
  }

  /// Logs a structured [AppError].
  void appError(AppError error) {
    this.error(
      error.message,
      cause: error.cause,
      stackTrace: error.stackTrace,
      context: <String, Object?>{'code': error.code},
    );
  }

  void _write(String level, String message, Map<String, Object?> context) {
    if (!enabled || kReleaseMode) return;
    // ignore: avoid_print
    print('[$level] ${_safeMessage(message)} context=${_safeContext(context)}');
  }

  String _safeMessage(String message) {
    return message.replaceAll(
      RegExp(r'(?:[A-Za-z]:[\\/]|/)[^\\s]+'),
      '<redacted-path>',
    );
  }

  Map<String, Object?> _safeContext(Map<String, Object?> context) {
    return <String, Object?>{
      for (final MapEntry<String, Object?> entry in context.entries)
        entry.key: _safeValue(entry.key, entry.value),
    };
  }

  Object? _safeValue(String key, Object? value) {
    final String normalizedKey = key.toLowerCase();
    if (normalizedKey.contains('path') ||
        normalizedKey.contains('uri') ||
        normalizedKey.contains('file')) {
      return '<redacted>';
    }
    return value is String || value is num || value is bool || value == null
        ? value
        : value.runtimeType;
  }
}
