import 'package:shared_preferences/shared_preferences.dart';

/// NotificationService에서도 사용
const String keyNotificationsEnabled = 'settings_notifications_enabled';
const _keySoundEnabled = 'settings_sound_enabled';
const _keyHapticEnabled = 'settings_haptic_enabled';
const _keyOnboardingSeen = 'settings_onboarding_seen';
const _keyOnboardingOnlyFirstLaunch = 'settings_onboarding_only_first_launch';

/// 앱 전역 설정 (알림/사운드/햅틱/온보딩) - SharedPreferences
class AppSettings {
  AppSettings(this._prefs);

  final SharedPreferences _prefs;

  bool get notificationsEnabled => _prefs.getBool(keyNotificationsEnabled) ?? true;
  bool get soundEnabled => _prefs.getBool(_keySoundEnabled) ?? true;
  bool get hapticEnabled => _prefs.getBool(_keyHapticEnabled) ?? true;
  bool get hasSeenOnboarding => _prefs.getBool(_keyOnboardingSeen) ?? false;
  bool get showOnboardingOnlyFirstLaunch => _prefs.getBool(_keyOnboardingOnlyFirstLaunch) ?? true;

  Future<void> setNotificationsEnabled(bool value) async {
    await _prefs.setBool(keyNotificationsEnabled, value);
  }

  Future<void> setSoundEnabled(bool value) async {
    await _prefs.setBool(_keySoundEnabled, value);
  }

  Future<void> setHapticEnabled(bool value) async {
    await _prefs.setBool(_keyHapticEnabled, value);
  }

  Future<void> setOnboardingSeen(bool value) async {
    await _prefs.setBool(_keyOnboardingSeen, value);
  }

  Future<void> setShowOnboardingOnlyFirstLaunch(bool value) async {
    await _prefs.setBool(_keyOnboardingOnlyFirstLaunch, value);
  }
}

/// 약관/개인정보 URL (정책 확정 후 값 설정)
abstract class LegalUrls {
  static const String terms = '';
  static const String privacy = '';
}

