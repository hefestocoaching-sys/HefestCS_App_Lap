import 'package:flutter/foundation.dart';

enum LogLevel { debug, info, warning, error }

class AppLogger {
  static final AppLogger instance = AppLogger._();
  AppLogger._();

  // In release, only error. In debug, all.
  final LogLevel _minLevel = kReleaseMode ? LogLevel.error : LogLevel.debug;

  void debug(String message, [Object? data]) {
    _log(LogLevel.debug, message, data: data);
  }

  void info(String message, [Object? data]) {
    _log(LogLevel.info, message, data: data);
  }

  void warning(String message, [Object? data]) {
    _log(LogLevel.warning, message, data: data);
  }

  void error(String message, [Object? error, StackTrace? stackTrace]) {
    _log(LogLevel.error, message, data: error, stackTrace: stackTrace);
  }

  void _log(
    LogLevel level,
    String message, {
    Object? data,
    StackTrace? stackTrace,
  }) {
    if (level.index < _minLevel.index) return;

    final timestamp = DateTime.now().toIso8601String();
    final prefix = '[${level.name.toUpperCase()}]';

    if (kDebugMode) {
      debugPrint('$timestamp $prefix $message');
      if (data != null) debugPrint('  Data: ${_sanitize(data)}');
      if (stackTrace != null) debugPrint('  Stack: $stackTrace');
    }
  }

  // Redact common sensitive patterns before logging.
  String _sanitize(Object data) {
    final str = data.toString();
    return str
        .replaceAll(
          RegExp(r'[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}'),
          '[REDACTED_EMAIL]',
        )
        .replaceAll(
          RegExp(
            r'\b[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-'
            r'[0-9a-fA-F]{4}-[0-9a-fA-F]{12}\b',
          ),
          '[REDACTED_UUID]',
        )
        .replaceAll(RegExp(r'\b\d{4,}\b'), '[REDACTED_NUMBER]');
  }
}

final logger = AppLogger.instance;
