import 'package:shared_preferences/shared_preferences.dart';

/// Also used by NotificationService.
const String keyNotificationsEnabled = 'settings_notifications_enabled';
const _keySoundEnabled = 'settings_sound_enabled';
const _keyHapticEnabled = 'settings_haptic_enabled';
const _keyOnboardingSeen = 'settings_onboarding_seen';
const _keyOnboardingOnlyFirstLaunch = 'settings_onboarding_only_first_launch';
const _keyThemeMode = 'settings_theme_mode';
const _keyLocale = 'settings_locale';

/// App-wide settings (notification/sound/haptic/onboarding) in SharedPreferences.
class AppSettings {
  AppSettings(this._prefs);

  final SharedPreferences _prefs;

  bool get notificationsEnabled => _prefs.getBool(keyNotificationsEnabled) ?? true;
  bool get soundEnabled => _prefs.getBool(_keySoundEnabled) ?? true;
  bool get hapticEnabled => _prefs.getBool(_keyHapticEnabled) ?? true;
  bool get hasSeenOnboarding => _prefs.getBool(_keyOnboardingSeen) ?? false;
  bool get showOnboardingOnlyFirstLaunch => _prefs.getBool(_keyOnboardingOnlyFirstLaunch) ?? true;
  String get themeMode => _prefs.getString(_keyThemeMode) ?? 'system';
  String get localeCode => _prefs.getString(_keyLocale) ?? 'ko';

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

  Future<void> setThemeMode(String value) async {
    await _prefs.setString(_keyThemeMode, value);
  }

  Future<void> setLocaleCode(String value) async {
    await _prefs.setString(_keyLocale, value);
  }
}

/// Terms/privacy URLs (set real values after policy is finalized).
abstract class LegalUrls {
  static const String terms = '';
  static const String privacy = '';
}

/// Store links for app sharing (replace with production URLs).
abstract class StoreUrls {
  static const String android = '';
  static const String ios = '';
}

