import 'package:shared_preferences/shared_preferences.dart';

const _kUpdateSnoozeUntilKey = 'update_snooze_until';

class AppUpdateSnooze {
  AppUpdateSnooze(this._prefs);

  final SharedPreferences _prefs;

  bool get isSnoozedToday {
    final raw = _prefs.getString(_kUpdateSnoozeUntilKey);
    if (raw == null || raw.isEmpty) return false;
    final today = _todayKey();
    return raw == today;
  }

  Future<void> snoozeForToday() async {
    await _prefs.setString(_kUpdateSnoozeUntilKey, _todayKey());
  }

  String _todayKey() {
    final now = DateTime.now();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    return '${now.year}-$month-$day';
  }
}
