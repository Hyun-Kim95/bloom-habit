import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

import '../settings/app_settings.dart';
import '../../data/local/entity/local_habit.dart';

/// 습관별 리마인더 알림 (로컬)
class NotificationService {
  NotificationService._() {}
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;

  static const _channelId = 'bloom_habit_reminder';
  static const _channelName = '습관 리마인더';

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
      description: '습관별 설정한 시간에 리마인더가 울립니다.',
      importance: Importance.defaultImportance,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
    _initialized = true;
  }

  void _onTap(NotificationResponse response) {}

  /// Android 13+ 알림 권한 요청
  Future<bool> requestPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      return granted ?? false;
    }
    return true;
  }

  /// 습관별 알림 ID (양수, habit serverId 기반)
  static int _notificationId(String? serverId) {
    if (serverId == null || serverId.isEmpty) return 0;
    return serverId.hashCode.abs() % 0x7FFFFFFF;
  }

  tz.TZDateTime _nextOccurrence(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var d = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (d.isBefore(now)) d = d.add(const Duration(days: 1));
    return d;
  }

  /// 알림 켜진 습관들 기준으로 전체 스케줄 갱신 (전역 알림 off면 스케줄 안 함)
  Future<void> rescheduleFromHabits(List<LocalHabit> habits) async {
    await init();
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(keyNotificationsEnabled) == false) {
      await _plugin.cancelAll();
      return;
    }
    await _plugin.cancelAll();
    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: '습관별 설정한 시간에 리마인더가 울립니다.',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    const details = NotificationDetails(android: androidDetails);
    for (final h in habits) {
      if (h.reminderEnabled != true || h.reminderHour == null || h.reminderMinute == null) continue;
      if (h.serverId == null) continue;
      final id = _notificationId(h.serverId);
      final title = h.name?.isNotEmpty == true ? h.name! : '습관';
      final body = '오늘의 "${title}" 확인해 보세요 🌱';
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        _nextOccurrence(h.reminderHour!, h.reminderMinute!),
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }

  /// 특정 습관 알림만 취소
  Future<void> cancelHabit(String? serverId) async {
    if (serverId == null) return;
    await _plugin.cancel(_notificationId(serverId));
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
