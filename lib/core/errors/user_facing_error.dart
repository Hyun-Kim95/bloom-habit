import 'package:dio/dio.dart';
import 'package:flutter/services.dart';

import '../../l10n/app_localizations.dart';
import '../../l10n/app_strings.dart';
import 'user_facing_exception.dart';

/// Maps technical errors to short user-safe messages.
class UserFacingError {
  UserFacingError._();

  static String resolve(
    Object error, {
    AppLocalizations? l10n,
    UserFacingErrorKind? kind,
  }) {
    if (error is UserFacingException) {
      return _sanitizeBusinessMessage(error.message) ??
          _messages(l10n).unexpected;
    }

    if (error is DioException) {
      return _fromDio(error, l10n: l10n, kind: kind);
    }

    if (error is PlatformException) {
      return _messages(l10n).unexpected;
    }

    final fromString = _fromString(error.toString(), l10n: l10n, kind: kind);
    if (fromString != null) return fromString;

    return _messageForKind(kind, l10n) ?? _messages(l10n).unexpected;
  }

  static String resolveAuth(Object error) {
    return resolve(error, kind: UserFacingErrorKind.auth);
  }

  static String? _fromString(
    String raw, {
    AppLocalizations? l10n,
    UserFacingErrorKind? kind,
  }) {
    final first = raw.split('\n').first.trim();
    if (first.isEmpty) return null;

    if (_isUserCancelled(first)) return null;

    if (_looksLikeConnectionIssue(first)) {
      return _messages(l10n).connection;
    }

    if (_looksLikeTimeout(first)) {
      return _messages(l10n).timeout;
    }

    if (_looksLikeAuthIssue(first)) {
      return _messages(l10n).auth;
    }

    final business = _extractBusinessMessage(first);
    if (business != null) return business;

    if (first.startsWith('Exception: ')) {
      final inner = first.substring('Exception: '.length).trim();
      final innerBusiness = _extractBusinessMessage(inner);
      if (innerBusiness != null) return innerBusiness;
      if (AppStrings.inquiryCreateFailed == inner ||
          inner.contains('문의 등록') ||
          inner.contains('Failed to submit inquiry')) {
        return inner;
      }
    }

    if (_isTechnicalNoise(first)) {
      return _messageForKind(kind, l10n) ?? _messages(l10n).unexpected;
    }

    return null;
  }

  static String _fromDio(
    DioException e, {
    AppLocalizations? l10n,
    UserFacingErrorKind? kind,
  }) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return _messages(l10n).timeout;
    }
    if (e.type == DioExceptionType.connectionError) {
      return _messages(l10n).connection;
    }

    final status = e.response?.statusCode;
    if (status == 401 || status == 403) {
      return _messages(l10n).auth;
    }

    final apiMessage = _apiMessageFromResponse(e.response?.data);
    if (apiMessage != null) return apiMessage;

    final fromMsg = e.message;
    if (fromMsg != null) {
      final parsed = _fromString(fromMsg, l10n: l10n, kind: kind);
      if (parsed != null) return parsed;
    }

    if (status != null && status >= 400 && status < 500) {
      return _messages(l10n).server;
    }

    return _messageForKind(kind, l10n) ?? _messages(l10n).unexpected;
  }

  static String? _apiMessageFromResponse(Object? data) {
    if (data is! Map) return null;
    final raw = data['message'];
    if (raw is String) {
      return _sanitizeBusinessMessage(raw);
    }
    if (raw is List && raw.isNotEmpty) {
      final first = raw.first;
      if (first is String) {
        return _sanitizeBusinessMessage(first);
      }
    }
    return null;
  }

  static String? _sanitizeBusinessMessage(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return null;
    if (_isTechnicalNoise(t)) return null;
    if (t.length > 200) return null;
    if (_isAllowedBusinessMessage(t)) return t;
    return null;
  }

  static bool _isAllowedBusinessMessage(String t) {
    if (_containsHangul(t)) return true;
    final lower = t.toLowerCase();
    if (lower.contains('invalid email') ||
        lower.contains('invalid password') ||
        lower.contains('inactive user') ||
        lower.contains('deactivated')) {
      return true;
    }
    return false;
  }

  static bool _containsHangul(String s) {
    for (final c in s.runes) {
      if (c >= 0xAC00 && c <= 0xD7A3) return true;
    }
    return false;
  }

  static bool _isTechnicalNoise(String s) {
    final lower = s.toLowerCase();
    return lower.contains('dioexception') ||
        lower.contains('platformexception') ||
        lower.contains('apiexception') ||
        lower.contains('statuscode') ||
        lower.contains('socketexception') ||
        lower.startsWith('{') ||
        lower.contains('stacktrace') ||
        RegExp(r'\b[A-Z][a-z]+Exception\b').hasMatch(s) ||
        RegExp(r':\s*\d+\s*(:|$)').hasMatch(s);
  }

  static bool _looksLikeConnectionIssue(String s) {
    final lower = s.toLowerCase();
    return lower.contains('connection timeout') ||
        lower.contains('connection error') ||
        lower.contains('connection refused') ||
        lower.contains('failed host lookup') ||
        lower.contains('network is unreachable') ||
        (lower.contains('dioexception') &&
            (lower.contains('connection') || lower.contains('unknown]')));
  }

  static bool _looksLikeTimeout(String s) {
    final lower = s.toLowerCase();
    return lower.contains('receive timeout') ||
        lower.contains('send timeout') ||
        lower.contains('connectiontimeout');
  }

  static bool _looksLikeAuthIssue(String s) {
    final lower = s.toLowerCase();
    return lower.contains('unauthorized') ||
        lower.contains('invalid token') ||
        lower.contains('missing or invalid authorization') ||
        lower.contains('401');
  }

  static bool _isUserCancelled(String s) {
    final lower = s.toLowerCase();
    return lower.contains('access_denied') ||
        lower.contains('canceled by user') ||
        lower.contains('cancelled by user') ||
        lower.contains('user canceled') ||
        lower.contains('user cancelled') ||
        lower.contains('login canceled') ||
        lower.contains('login cancelled') ||
        lower.contains('취소');
  }

  static String? _extractBusinessMessage(String s) {
    return _sanitizeBusinessMessage(s);
  }

  static String? _messageForKind(
    UserFacingErrorKind? kind,
    AppLocalizations? l10n,
  ) {
    final m = _messages(l10n);
    switch (kind) {
      case UserFacingErrorKind.load:
        return m.loadFailed;
      case UserFacingErrorKind.save:
        return m.saveFailed;
      case UserFacingErrorKind.submit:
        return m.submitFailed;
      case UserFacingErrorKind.auth:
        return m.auth;
      case UserFacingErrorKind.withdraw:
        return m.withdrawFailed;
      case UserFacingErrorKind.process:
        return m.processFailed;
      case null:
        return null;
    }
  }

  static _MessageBundle _messages(AppLocalizations? l10n) {
    if (l10n != null) {
      return _MessageBundle(
        connection: l10n.connectionErrorUserMessage,
        timeout: l10n.serverSlowResponse,
        auth: l10n.authSessionExpired,
        server: l10n.serverRequestFailed,
        unexpected: l10n.unexpectedErrorTryAgain,
        loadFailed: l10n.loadFailedTryAgain,
        saveFailed: l10n.saveFailedTryAgain,
        submitFailed: l10n.submitFailedTryAgain,
        processFailed: l10n.processFailedTryAgain,
        withdrawFailed: l10n.withdrawFailedTryAgain,
      );
    }
    return _MessageBundle(
      connection: AppStrings.connectionErrorUser,
      timeout: AppStrings.serverSlowResponse,
      auth: AppStrings.authSessionExpired,
      server: AppStrings.serverRequestFailed,
      unexpected: AppStrings.unexpectedErrorTryAgain,
      loadFailed: AppStrings.loadFailedTryAgain,
      saveFailed: AppStrings.saveFailedTryAgain,
      submitFailed: AppStrings.submitFailedTryAgain,
      processFailed: AppStrings.processFailedTryAgain,
      withdrawFailed: AppStrings.withdrawFailedTryAgain,
    );
  }
}

enum UserFacingErrorKind {
  load,
  save,
  submit,
  auth,
  withdraw,
  process,
}

class _MessageBundle {
  const _MessageBundle({
    required this.connection,
    required this.timeout,
    required this.auth,
    required this.server,
    required this.unexpected,
    required this.loadFailed,
    required this.saveFailed,
    required this.submitFailed,
    required this.processFailed,
    required this.withdrawFailed,
  });

  final String connection;
  final String timeout;
  final String auth;
  final String server;
  final String unexpected;
  final String loadFailed;
  final String saveFailed;
  final String submitFailed;
  final String processFailed;
  final String withdrawFailed;
}
