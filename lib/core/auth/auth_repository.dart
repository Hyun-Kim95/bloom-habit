import 'dart:async';
import 'dart:io' show Platform;

import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart' as kakao;
import 'package:flutter_naver_login/flutter_naver_login.dart';
import 'package:flutter_naver_login/interface/types/naver_login_status.dart';

import '../network/api_client.dart';
import '../network/api_endpoints.dart';
import '../social/android_social_sdk_init.dart';
import 'token_storage.dart';
import '../../l10n/app_strings.dart';

/// GET /me profile.
class MeProfile {
  const MeProfile({
    required this.id,
    this.email,
    this.displayName,
    this.avatarUrl,
    this.ianaTimeZone,
    this.missedHabitPushLocalHour,
    this.missedHabitPushLocalMinute,
    required this.authProvider,
    required this.createdAt,
  });

  final String id;
  final String? email;
  final String? displayName;
  final String? avatarUrl;
  final String? ianaTimeZone;
  final int? missedHabitPushLocalHour;
  final int? missedHabitPushLocalMinute;

  /// `google` | `kakao` | `naver` | `unknown` (legacy `apple` possible)
  final String authProvider;
  final String createdAt;

  static int? _intField(Object? v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return null;
  }

  static MeProfile? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    final id = json['id'] as String?;
    if (id == null) return null;
    return MeProfile(
      id: id,
      email: json['email'] as String?,
      displayName: json['displayName'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      ianaTimeZone: json['ianaTimeZone'] as String?,
      missedHabitPushLocalHour: _intField(json['missedHabitPushLocalHour']),
      missedHabitPushLocalMinute: _intField(json['missedHabitPushLocalMinute']),
      authProvider: json['authProvider'] as String? ?? 'unknown',
      createdAt: json['createdAt'] as String? ?? '',
    );
  }
}

class AvatarUploadPresign {
  const AvatarUploadPresign({required this.uploadUrl, required this.publicUrl});

  final String uploadUrl;
  final String publicUrl;
}

/// Social login + server token issuance.
class AuthRepository {
  AuthRepository({
    required ApiClient apiClient,
    required TokenStorage tokenStorage,
    String? googleServerClientId,
  }) : _api = apiClient,
       _storage = tokenStorage,
       _googleSignIn = GoogleSignIn(
         scopes: ['email', 'profile'],
         serverClientId:
             (googleServerClientId != null &&
                 googleServerClientId.isNotEmpty &&
                 googleServerClientId.contains('.apps.googleusercontent.com'))
             ? googleServerClientId
             : null,
       );

  final ApiClient _api;
  final TokenStorage _storage;
  final GoogleSignIn _googleSignIn;
  StreamSubscription<String>? _fcmTokenRefreshSub;

  /// Google login: fetch ID token and exchange for app token.
  Future<AuthResult> signInWithGoogle() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) return AuthResult.cancelled();

      final auth = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null) {
        return AuthResult.fail(AppStrings.authIdTokenMissing);
      }

      final email = account.email;
      final displayName = account.displayName;
      final res = await _api.dio.post<Map<String, dynamic>>(
        ApiEndpoints.authGoogle,
        data: {
          'idToken': idToken,
          if (email.isNotEmpty) 'email': email,
          if (displayName != null && displayName.isNotEmpty)
            'displayName': displayName,
          'avatarUrl': account.photoUrl,
        },
      );
      return await _handleAuthResponse(res);
    } on PlatformException catch (e) {
      // ApiException: 10 = DEVELOPER_ERROR (SHA-1/package not registered).
      if (e.code == 'sign_in_failed' &&
          e.message != null &&
          e.message!.contains('ApiException: 10')) {
        return AuthResult.fail(AppStrings.authGoogleSetupNeeded);
      }
      return AuthResult.fail(e.message ?? e.code);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        return AuthResult.fail(AppStrings.authServerTimeout);
      }
      if (e.type == DioExceptionType.connectionError) {
        return AuthResult.fail(AppStrings.authServerUnreachable);
      }
      final msg = e.response?.data is Map
          ? (e.response!.data as Map)['message']?.toString()
          : null;
      return AuthResult.fail(msg ?? e.message ?? AppStrings.authNetworkError);
    } catch (e) {
      return AuthResult.fail(e.toString().split('\n').first);
    }
  }

  String _kakaoLoginErrorMessage(Object e) {
    final s = e.toString();
    if (s.contains('keyHash') || s.contains('key hash')) {
      return AppStrings.authKakaoKeyHashFailed;
    }
    return s.split('\n').first;
  }

  bool _isUserCancelledSocialLogin(Object e) {
    final message = e.toString().toLowerCase();
    return message.contains('access_denied') ||
        message.contains('canceled by user') ||
        message.contains('cancelled by user') ||
        message.contains('user canceled') ||
        message.contains('user cancelled') ||
        message.contains('login canceled') ||
        message.contains('login cancelled') ||
        message.contains('취소');
  }

  Future<AuthResult> signInWithKakao() async {
    if (!kIsWeb && Platform.isAndroid) {
      await initAndroidSocialSdks();
      if (!isKakaoSdkReady) {
        return AuthResult.fail(AppStrings.authKakaoNotConfigured);
      }
    }
    try {
      kakao.OAuthToken token;
      if (await kakao.isKakaoTalkInstalled()) {
        try {
          token = await kakao.UserApi.instance.loginWithKakaoTalk();
        } catch (_) {
          token = await kakao.UserApi.instance.loginWithKakaoAccount();
        }
      } else {
        token = await kakao.UserApi.instance.loginWithKakaoAccount();
      }
      final accessToken = token.accessToken;
      if (accessToken.trim().isEmpty) {
        return AuthResult.fail('Kakao access token missing');
      }
      final res = await _api.dio.post<Map<String, dynamic>>(
        ApiEndpoints.authKakao,
        data: {'accessToken': accessToken},
      );
      return _handleAuthResponse(res);
    } on DioException catch (e) {
      final msg = e.response?.data is Map
          ? (e.response!.data as Map)['message']?.toString()
          : null;
      return AuthResult.fail(msg ?? e.message ?? AppStrings.authNetworkError);
    } catch (e) {
      if (_isUserCancelledSocialLogin(e)) {
        return AuthResult.cancelled();
      }
      return AuthResult.fail(_kakaoLoginErrorMessage(e));
    }
  }

  Future<AuthResult> signInWithNaver() async {
    if (!kIsWeb && Platform.isAndroid) {
      await initAndroidSocialSdks();
    }
    try {
      final result = await FlutterNaverLogin.logIn();
      if (result.status != NaverLoginStatus.loggedIn) {
        if (result.status == NaverLoginStatus.loggedOut) {
          return AuthResult.cancelled();
        }
        final msg = result.errorMessage?.trim();
        return AuthResult.fail(
          msg != null && msg.isNotEmpty ? msg : 'Naver login failed',
        );
      }
      // Android plugin often returns loggedIn without accessToken in the map;
      // token is still in NaverIdLoginSDK — fetch explicitly.
      var accessToken = result.accessToken?.accessToken.trim() ?? '';
      if (accessToken.isEmpty) {
        final t = await FlutterNaverLogin.getCurrentAccessToken();
        accessToken = t.accessToken.trim();
      }
      if (accessToken.isEmpty) {
        return AuthResult.fail(AppStrings.authNaverAccessTokenMissing);
      }
      final res = await _api.dio.post<Map<String, dynamic>>(
        ApiEndpoints.authNaver,
        data: {'accessToken': accessToken},
      );
      return _handleAuthResponse(res);
    } on DioException catch (e) {
      final msg = e.response?.data is Map
          ? (e.response!.data as Map)['message']?.toString()
          : null;
      return AuthResult.fail(msg ?? e.message ?? AppStrings.authNetworkError);
    } catch (e) {
      return AuthResult.fail(e.toString().split('\n').first);
    }
  }

  Future<AuthResult> _handleAuthResponse(
    Response<Map<String, dynamic>> res,
  ) async {
    if (res.data == null) return AuthResult.fail(AppStrings.authEmptyResponse);
    final access = res.data!['accessToken'] as String?;
    final refresh = res.data!['refreshToken'] as String?;
    final user = res.data!['user'] as Map<String, dynamic>?;
    if (access == null) return AuthResult.fail(AppStrings.authTokenMissing);

    try {
      await _storage
          .saveTokens(accessToken: access, refreshToken: refresh)
          .timeout(const Duration(seconds: 5));
    } catch (_) {
      return AuthResult.fail(AppStrings.authTokenSaveFailed);
    }
    _api.setAccessToken(access);
    return AuthResult.success(user: user);
  }

  Future<void> logout() async {
    await _googleSignIn.signOut();
    try {
      await FlutterNaverLogin.logOutAndDeleteToken();
    } catch (_) {}
    await _api.dio.post(ApiEndpoints.authLogout);
    await _storage.clear();
    _api.setAccessToken(null);
  }

  /// Fetch my profile (GET /me).
  Future<MeProfile?> fetchProfile() async {
    try {
      final res = await _api.dio.get<Map<String, dynamic>>(ApiEndpoints.me);
      return MeProfile.fromJson(res.data);
    } catch (_) {
      return null;
    }
  }

  /// Update profile (PATCH /me), partial fields only.
  Future<void> updateMeProfile({
    String? displayName,
    String? email,
    String? avatarUrl,
    bool clearAvatar = false,
  }) async {
    final data = <String, dynamic>{};
    if (displayName != null) {
      data['displayName'] = displayName.trim();
    }
    if (email != null) {
      data['email'] = email.trim();
    }
    if (clearAvatar) {
      data['avatarUrl'] = null;
    } else if (avatarUrl != null) {
      final t = avatarUrl.trim();
      data['avatarUrl'] = t.isEmpty ? null : t;
    }
    if (data.isEmpty) return;
    await _api.dio.patch<Map<String, dynamic>>(ApiEndpoints.me, data: data);
  }

  /// 미달성 요약 FCM 로컬 시각 (PATCH /me).
  Future<void> updateMissedHabitPushLocalTime({
    required int hour,
    required int minute,
  }) async {
    await _api.dio.patch<Map<String, dynamic>>(
      ApiEndpoints.me,
      data: {
        'missedHabitPushLocalHour': hour,
        'missedHabitPushLocalMinute': minute,
      },
    );
  }

  /// 미달성 요약 시각을 서버 env 기본으로 되돌림.
  Future<void> clearMissedHabitPushLocalTime() async {
    await _api.dio.patch<Map<String, dynamic>>(
      ApiEndpoints.me,
      data: {
        'missedHabitPushLocalHour': null,
        'missedHabitPushLocalMinute': null,
      },
    );
  }

  Future<AvatarUploadPresign> createAvatarUploadPresign({
    required String fileName,
    required int fileSize,
    String? contentType,
  }) async {
    final presignBody = <String, dynamic>{
      'fileName': fileName,
      'fileSize': fileSize,
    };
    if (contentType != null) {
      presignBody['contentType'] = contentType;
    }
    final res = await _api.dio.post<Map<String, dynamic>>(
      ApiEndpoints.meAvatarPresign,
      data: presignBody,
    );
    final data = res.data ?? const <String, dynamic>{};
    final uploadUrl = _resolveApiUrl(data['uploadUrl']?.toString() ?? '');
    final publicUrl = _resolveApiUrl(data['publicUrl']?.toString() ?? '');
    if (uploadUrl.isEmpty || publicUrl.isEmpty) {
      throw Exception('Invalid avatar upload presign response');
    }
    return AvatarUploadPresign(uploadUrl: uploadUrl, publicUrl: publicUrl);
  }

  Future<void> uploadAvatarFile({
    required String uploadUrl,
    required Uint8List bytes,
    required String fileName,
    String? mimeType,
  }) async {
    final normalizedMime = _normalizeImageMimeType(mimeType, fileName);
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(
        bytes,
        filename: fileName,
        contentType: DioMediaType.parse(normalizedMime),
      ),
    });
    try {
      await _api.dio.put(
        uploadUrl,
        data: formData,
        options: Options(
          headers: <String, String>{'Content-Type': 'multipart/form-data'},
          followRedirects: false,
          validateStatus: (status) =>
              status != null && status >= 200 && status < 400,
        ),
      );
    } on DioException catch (e) {
      final location = e.response?.headers.value('location');
      debugPrint(
        'AuthRepository: avatar upload failed status=${e.response?.statusCode} location=$location',
      );
      rethrow;
    }
  }

  String _normalizeImageMimeType(String? mimeType, String fileName) {
    final normalized = (mimeType ?? '').toLowerCase().trim();
    if (normalized.startsWith('image/')) return normalized;
    final lowerName = fileName.toLowerCase();
    if (lowerName.endsWith('.png')) return 'image/png';
    if (lowerName.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  String _resolveApiUrl(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return '';
    final parsed = Uri.tryParse(trimmed);
    if (parsed != null && parsed.hasScheme) return trimmed;
    final base = Uri.parse(_api.dio.options.baseUrl);
    final resolved = base.resolveUri(
      Uri.parse(trimmed.startsWith('/') ? trimmed.substring(1) : trimmed),
    );
    return resolved.toString();
  }

  /// Deactivate account on server with reason and clear local tokens.
  Future<void> deleteAccount(String reason) async {
    await _api.dio.delete(ApiEndpoints.me, data: {'reason': reason.trim()});
    await _storage.clear();
    _api.setAccessToken(null);
  }

  /// Restore session from saved token.
  Future<bool> restoreSession() async {
    final access = await _storage.getAccessToken();
    if (access == null) return false;
    _api.setAccessToken(access);
    try {
      await _api.dio.get<Map<String, dynamic>>(ApiEndpoints.me);
      return true;
    } on DioException catch (e) {
      final status = e.response?.statusCode ?? 0;
      final msg = e.response?.data is Map
          ? ((e.response!.data as Map)['message']?.toString() ?? '')
          : (e.message ?? '');
      final inactive =
          msg.contains('Inactive user') ||
          msg.contains('비활성화') ||
          msg.contains('deactivat');
      // Inactive/invalid token: force logout and block auto-login.
      if (status == 401 || status == 403 || inactive) {
        await _storage.clear();
        _api.setAccessToken(null);
        return false;
      }
      // Keep existing behavior for transient network/server errors.
      return true;
    } catch (_) {
      return true;
    }
  }

  Future<String?> _deviceIanaTimeZone() async {
    try {
      final tzInfo = await FlutterTimezone.getLocalTimezone();
      final id = tzInfo.identifier.trim();
      return id.isEmpty ? null : id;
    } catch (_) {
      return null;
    }
  }

  /// Subscribe to FCM token rotation and PATCH `/me` when logged in.
  void attachFcmTokenRefreshListener() {
    _fcmTokenRefreshSub?.cancel();
    _fcmTokenRefreshSub = FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      final t = newToken.trim();
      if (t.isEmpty) return;
      try {
        final iana = await _deviceIanaTimeZone();
        await _api.dio.patch<Map<String, dynamic>>(
          ApiEndpoints.me,
          data: {
            'fcmToken': t,
            'ianaTimeZone': ?iana,
          },
        );
        debugPrint(
          'FCM token refreshed on server: ${t.length >= 6 ? t.substring(0, 6) : t}',
        );
      } on DioException catch (e) {
        final code = e.response?.statusCode ?? 0;
        if (code == 401 || code == 403) return;
        debugPrint('[AuthRepository] FCM token refresh PATCH failed: $e');
      } catch (e) {
        debugPrint('[AuthRepository] FCM token refresh failed: $e');
      }
    });
  }

  /// Register FCM token for push notifications.
  Future<void> registerFcmToken() async {
    try {
      final messaging = FirebaseMessaging.instance;
      const stepTimeout = Duration(seconds: 20);
      await messaging
          .requestPermission(alert: true, badge: true, sound: true)
          .timeout(stepTimeout);
      final token = await messaging.getToken().timeout(stepTimeout);
      if (token == null || token.isEmpty) return;
      final iana = await _deviceIanaTimeZone();
      await _api.dio.patch<Map<String, dynamic>>(
        ApiEndpoints.me,
        data: {
          'fcmToken': token,
          'ianaTimeZone': ?iana,
        },
      );
      debugPrint(
        'FCM token registered: ${token.length >= 6 ? token.substring(0, 6) : token}',
      );
    } catch (_) {
      // Ignore when Firebase is not configured, permission denied, or timeout.
    }
  }
}

class AuthResult {
  const AuthResult._({this.user, this.cancelled = false, this.error});

  final Map<String, dynamic>? user;
  final bool cancelled;
  final String? error;

  factory AuthResult.success({Map<String, dynamic>? user}) =>
      AuthResult._(user: user);
  factory AuthResult.cancelled() => const AuthResult._(cancelled: true);
  factory AuthResult.fail(String message) => AuthResult._(error: message);

  bool get isSuccess => user != null && !cancelled && error == null;
}
