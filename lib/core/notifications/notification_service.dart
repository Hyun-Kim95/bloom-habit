import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

/// 일일 습관 리마인더 알림 (로컬)
class NotificationService {
  NotificationService._() {
    _prefs = SharedPreferences.getInstance();
  }
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;

  static const _channelId = 'bloom_habit_reminder';
  static const _channelName = '습관 리마인더';
  static const _keyEnabled = 'notification_enabled';
  static const _keyHour = 'notification_hour';
  static const _keyMinute = 'notification_minute';

  late final Future<SharedPreferences> _prefs;
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  FlutterLocalNotificationsPlugin get plugin => _plugin;

  Future<void> init() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: android);
    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onTap,
    );
    const androidChannel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: '매일 설정한 시간에 습관을 확인하세요.',
      importance: Importance.defaultImportance,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
    _initialized = true;
  }

  void _onTap(NotificationResponse response) {
    // 알림 탭 시 앱 열기 등 (payload 활용 가능)
  }

  /// Android 13+ 알림 권한 요청
  Future<bool> requestPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      return granted ?? false;
    }
    return true;
  }

  Future<bool> isEnabled() async {
    final prefs = await _prefs;
    return prefs.getBool(_keyEnabled) ?? false;
  }

  Future<ScheduledTime> getScheduledTime() async {
    final prefs = await _prefs;
    final hour = prefs.getInt(_keyHour) ?? 9;
    final minute = prefs.getInt(_keyMinute) ?? 0;
    return ScheduledTime(hour: hour, minute: minute);
  }

  Future<void> setEnabled(bool enabled) async {
    final prefs = await _prefs;
    await prefs.setBool(_keyEnabled, enabled);
    if (!enabled) await cancelAll();
  }

  Future<void> setScheduledTime(int hour, int minute) async {
    final prefs = await _prefs;
    await prefs.setInt(_keyHour, hour);
    await prefs.setInt(_keyMinute, minute);
  }

  /// 일일 알림 스케줄 (매일 hour:minute에 울림)
  Future<void> scheduleDaily(int hour, int minute) async {
    await init();
    await cancelAll();
    final now = DateTime.now();
    var scheduled = DateTime(now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now) || scheduled.isAtSameMomentAs(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: '매일 설정한 시간에 습관을 확인하세요.',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    const details = NotificationDetails(android: androidDetails);
    await _plugin.zonedSchedule(
      0,
      '오늘의 습관',
      '오늘도 작은 습관을 확인해 보세요 🌱',
      _nextOccurrence(hour, minute),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  tz.TZDateTime _nextOccurrence(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var d = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (d.isBefore(now)) d = d.add(const Duration(days: 1));
    return d;
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  /// 설정 저장 후 스케줄 갱신 (enabled면 scheduleDaily, 아니면 cancel)
  Future<void> saveAndReschedule({required bool enabled, required int hour, required int minute}) async {
    final prefs = await _prefs;
    await prefs.setBool(_keyEnabled, enabled);
    await prefs.setInt(_keyHour, hour);
    await prefs.setInt(_keyMinute, minute);
    if (enabled) {
      await scheduleDaily(hour, minute);
    } else {
      await cancelAll();
    }
  }
}

/// 저장된 알림 시간 (material TimeOfDay와 구분)
class ScheduledTime {
  const ScheduledTime({required this.hour, required this.minute});
  final int hour;
  final int minute;
}
