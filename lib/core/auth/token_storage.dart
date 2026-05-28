import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';

/// Secure storage for access/refresh tokens.
class TokenStorage {
  TokenStorage() : _storage = const FlutterSecureStorage(aOptions: AndroidOptions(encryptedSharedPreferences: true));

  final FlutterSecureStorage _storage;
  static const _keyAccess = 'bloom_habit_access_token';
  static const _keyRefresh = 'bloom_habit_refresh_token';

  Future<String?> getAccessToken() async {
    try {
      return await _storage.read(key: _keyAccess);
    } catch (e, st) {
      debugPrint('[TokenStorage] getAccessToken failed: $e\n$st');
      return null;
    }
  }

  Future<String?> getRefreshToken() async {
    try {
      return await _storage.read(key: _keyRefresh);
    } catch (e, st) {
      debugPrint('[TokenStorage] getRefreshToken failed: $e\n$st');
      return null;
    }
  }

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
