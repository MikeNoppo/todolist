import 'package:flutter/foundation.dart';

class AppLogger {
  const AppLogger._();

  static void debug(String tag, String message) {
    if (!kDebugMode) return;
    debugPrint(_format('DEBUG', tag, message));
  }

  static void info(String tag, String message) {
    if (!kDebugMode) return;
    debugPrint(_format('INFO', tag, message));
  }

  static void warn(String tag, String message) {
    if (!kDebugMode) return;
    debugPrint(_format('WARN', tag, message));
  }

  static void error(
    String tag,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    final StringBuffer buffer = StringBuffer(_format('ERROR', tag, message));
    if (error != null) {
      buffer.write(' | error: $error');
    }

    debugPrint(buffer.toString());

    if (stackTrace != null) {
      debugPrintStack(
        stackTrace: stackTrace,
        label: '[ERROR] [$tag] stack trace',
      );
    }
  }

  static String _format(String level, String tag, String message) {
    return '[$level] [$tag] $message';
  }
}
