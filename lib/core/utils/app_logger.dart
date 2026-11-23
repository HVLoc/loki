import 'package:flutter/foundation.dart';

/// Structured diagnostic logger that redacts sensitive fields.
final class AppLogger {
  AppLogger._();

  static void info(String tag, String message) {
    if (kDebugMode) {
      debugPrint('[INFO][$tag] ${_redact(message)}');
    }
  }

  static void warn(String tag, String message) {
    if (kDebugMode) {
      debugPrint('[WARN][$tag] ${_redact(message)}');
    }
  }

  static void error(
    String tag,
    String message, [
    Object? error,
    StackTrace? stackTrace,
  ]) {
    if (kDebugMode) {
      debugPrint('[ERROR][$tag] ${_redact(message)} | err=$error');
      if (stackTrace != null) {
        debugPrint(stackTrace.toString());
      }
    }
  }

  static String _redact(String input) {
    return input.replaceAll(
      RegExp(r'(token|password|secret|apiKey)=[^\s&]+', caseSensitive: false),
      r'$1=[REDACTED]',
    );
  }
}
