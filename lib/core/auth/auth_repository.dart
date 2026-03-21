import 'dart:io' show Platform;

import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
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
    required this.authProvider,
    required this.createdAt,
  });

  final String id;
  final String? email;
  final String? displayName;
  final String? avatarUrl;

  /// `google` | `kakao` | `naver` | `unknown` (legacy `apple` possible)
  final String authProvider;
  final String createdAt;

  static MeProfile? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    final id = json['id'] as String?;
    if (id == null) return null;
    return MeProfile(
      id: id,
      email: json['email'] as String?,
      displayName: json['displayName'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      authProvider: json['authProvider'] as String? ?? 'unknown',
      createdAt: json['createdAt'] as String? ?? '',
    );
  }
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

  /// Google login: fetch ID token and exchange for app token.
  Future<AuthResult> signInWithGoogle() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) return AuthResult.cancelled();

      final auth = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null)
        return AuthResult.fail(AppStrings.authIdTokenMissing);

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
    }
    if (data.isEmpty) return;
    await _api.dio.patch<Map<String, dynamic>>(ApiEndpoints.me, data: data);
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

  /// Register FCM token for push notifications.
  Future<void> registerFcmToken() async {
    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(alert: true, badge: true, sound: true);
      final token = await messaging.getToken();
      if (token == null || token.isEmpty) return;
      await _api.dio.patch<Map<String, dynamic>>(
        ApiEndpoints.me,
        data: {'fcmToken': token},
      );
      debugPrint(
        'FCM token registered: ${token.length >= 6 ? token.substring(0, 6) : token}',
      );
    } catch (_) {
      // Ignore when Firebase is not configured or permission is denied.
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
