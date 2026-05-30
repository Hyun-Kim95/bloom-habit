import 'package:flutter/foundation.dart';

/// Logs technical error details for developers only (never shown in UI).
class ErrorLogger {
  ErrorLogger._();

  static void logError(
    String context,
    Object error, [
    StackTrace? stackTrace,
  ]) {
    debugPrint('[Error][$context] $error');
    if (stackTrace != null) {
      debugPrint(stackTrace.toString());
    }
    if (kDebugMode) {
      _logDebugHints(context, error);
    }
  }

  static void _logDebugHints(String context, Object error) {
    final s = error.toString();
    if (_looksLikeConnectionIssue(s)) {
      debugPrint(
        '[Error][$context] dev hint: check API server, API_BASE_URL, '
        'adb reverse (emulator). See connectionErrorDevHint in l10n.',
      );
    }
  }

  static bool _looksLikeConnectionIssue(String s) {
    final lower = s.toLowerCase();
    return lower.contains('connection timeout') ||
        lower.contains('connection error') ||
        lower.contains('connection refused') ||
        lower.contains('failed host lookup') ||
        lower.contains('socketexception') ||
        lower.contains('network is unreachable');
  }
}
