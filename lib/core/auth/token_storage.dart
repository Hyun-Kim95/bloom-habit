import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// 액세스·리프레시 토큰 보안 저장
class TokenStorage {
  TokenStorage() : _storage = const FlutterSecureStorage(aOptions: AndroidOptions(encryptedSharedPreferences: true));

  final FlutterSecureStorage _storage;
  static const _keyAccess = 'bloom_habit_access_token';
  static const _keyRefresh = 'bloom_habit_refresh_token';

  Future<String?> getAccessToken() => _storage.read(key: _keyAccess);
  Future<String?> getRefreshToken() => _storage.read(key: _keyRefresh);

  Future<void> saveTokens({required String accessToken, String? refreshToken}) async {
    await _storage.write(key: _keyAccess, value: accessToken);
    if (refreshToken != null) {
      await _storage.write(key: _keyRefresh, value: refreshToken);
    }
  }

  Future<void> clear() async {
    await _storage.delete(key: _keyAccess);
    await _storage.delete(key: _keyRefresh);
  }
}
