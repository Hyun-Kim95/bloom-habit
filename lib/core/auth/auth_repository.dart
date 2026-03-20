import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../network/api_client.dart';
import '../network/api_endpoints.dart';
import 'token_storage.dart';

/// GET /me 프로필
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
  /// `google` | `apple` | `unknown`
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

/// 소셜 로그인 + 서버 토큰 발급
class AuthRepository {
  AuthRepository({
    required ApiClient apiClient,
    required TokenStorage tokenStorage,
    String? googleServerClientId,
  })  : _api = apiClient,
        _storage = tokenStorage,
        _googleSignIn = GoogleSignIn(
          scopes: ['email', 'profile'],
          serverClientId: (googleServerClientId != null &&
                  googleServerClientId.isNotEmpty &&
                  googleServerClientId.contains('.apps.googleusercontent.com'))
              ? googleServerClientId
              : null,
        );

  final ApiClient _api;
  final TokenStorage _storage;
  final GoogleSignIn _googleSignIn;

  /// 구글 로그인: ID 토큰 획득 후 서버에 전달해 앱 토큰 발급
  Future<AuthResult> signInWithGoogle() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) return AuthResult.cancelled();

      final auth = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null) return AuthResult.fail('ID token 없음');

      final email = account.email;
      final displayName = account.displayName;
      final res = await _api.dio.post<Map<String, dynamic>>(
        ApiEndpoints.authGoogle,
        data: {
          'idToken': idToken,
          if (email.isNotEmpty) 'email': email,
          if (displayName != null && displayName.isNotEmpty) 'displayName': displayName,
          'avatarUrl': account.photoUrl,
        },
      );
      return await _handleAuthResponse(res);
    } on PlatformException catch (e) {
      // ApiException: 10 = DEVELOPER_ERROR → Google Cloud에 SHA-1·패키지명 미등록
      if (e.code == 'sign_in_failed' &&
          e.message != null &&
          e.message!.contains('ApiException: 10')) {
        return AuthResult.fail(
          'Google 로그인 설정이 필요합니다. '
          '개발 PC에서 docs/google-signin-setup.md를 참고해 Google Cloud에 SHA-1을 등록해 주세요.',
        );
      }
      return AuthResult.fail(e.message ?? e.code);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        return AuthResult.fail(
          '서버 연결 시간이 초과되었습니다. '
          'PC에서 서버(포트 3000)가 실행 중인지 확인해 주세요.',
        );
      }
      if (e.type == DioExceptionType.connectionError) {
        return AuthResult.fail(
          '서버에 연결할 수 없습니다. 서버가 실행 중인지, 에뮬레이터라면 10.0.2.2:3000으로 연결되는지 확인해 주세요.',
        );
      }
      final msg = e.response?.data is Map
          ? (e.response!.data as Map)['message']?.toString()
          : null;
      return AuthResult.fail(msg ?? e.message ?? '네트워크 오류');
    } catch (e) {
      return AuthResult.fail(e.toString().split('\n').first);
    }
  }

  /// 애플 로그인: identityToken 획득 후 서버에 전달
  Future<AuthResult> signInWithApple() async {
    final cred = await SignInWithApple.getAppleIDCredential(
      scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
    );
    final idToken = cred.identityToken;
    if (idToken == null) return AuthResult.fail('Apple identity token 없음');

    final res = await _api.dio.post<Map<String, dynamic>>(
      ApiEndpoints.authApple,
      data: {
        'identityToken': idToken,
        'email': cred.email,
        'displayName': cred.givenName != null
            ? '${cred.givenName ?? ''} ${cred.familyName ?? ''}'.trim()
            : null,
      },
    );
    return _handleAuthResponse(res);
  }

  Future<AuthResult> _handleAuthResponse(
    Response<Map<String, dynamic>> res,
  ) async {
    if (res.data == null) return AuthResult.fail('응답 없음');
    final access = res.data!['accessToken'] as String?;
    final refresh = res.data!['refreshToken'] as String?;
    final user = res.data!['user'] as Map<String, dynamic>?;
    if (access == null) return AuthResult.fail('토큰 없음');

    try {
      await _storage
          .saveTokens(accessToken: access, refreshToken: refresh)
          .timeout(const Duration(seconds: 5));
    } catch (_) {
      return AuthResult.fail('토큰 저장 실패');
    }
    _api.setAccessToken(access);
    return AuthResult.success(user: user);
  }

  Future<void> logout() async {
    await _googleSignIn.signOut();
    await _api.dio.post(ApiEndpoints.authLogout);
    await _storage.clear();
    _api.setAccessToken(null);
  }

  /// 내 프로필 (GET /me)
  Future<MeProfile?> fetchProfile() async {
    try {
      final res = await _api.dio.get<Map<String, dynamic>>(ApiEndpoints.me);
      return MeProfile.fromJson(res.data);
    } catch (_) {
      return null;
    }
  }

  /// 표시 이름·프로필 사진 URL 갱신 (PATCH /me). 전달한 필드만 서버에 반영됩니다.
  Future<void> updateMeProfile({
    String? displayName,
    bool clearAvatar = false,
  }) async {
    final data = <String, dynamic>{};
    if (displayName != null) {
      data['displayName'] = displayName.trim();
    }
    if (clearAvatar) {
      data['avatarUrl'] = null;
    }
    if (data.isEmpty) return;
    await _api.dio.patch<Map<String, dynamic>>(ApiEndpoints.me, data: data);
  }

  /// 회원 탈퇴: 서버에서 계정·데이터 삭제 후 로컬 토큰 제거
  Future<void> deleteAccount() async {
    await _api.dio.delete(ApiEndpoints.me);
    await _storage.clear();
    _api.setAccessToken(null);
  }

  /// 저장된 토큰으로 로그인 상태 복원
  Future<bool> restoreSession() async {
    final access = await _storage.getAccessToken();
    if (access == null) return false;
    _api.setAccessToken(access);
    return true;
  }

  /// FCM 토큰을 서버에 등록 (문의 답변 등 푸시 수신용). Firebase 미설정 시 무시.
  Future<void> registerFcmToken() async {
    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      final token = await messaging.getToken();
      if (token == null || token.isEmpty) return;
      await _api.dio.patch<Map<String, dynamic>>(
        ApiEndpoints.me,
        data: {'fcmToken': token},
      );
      debugPrint('FCM token 등록됨: ${token.length >= 6 ? token.substring(0, 6) : token}');
    } catch (_) {
      // Firebase 미설정 또는 권한 거부 시 무시
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
