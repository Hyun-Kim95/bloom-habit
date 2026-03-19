import 'package:app_settings/app_settings.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

import '../settings/app_settings.dart' as app_prefs;
import '../../data/local/entity/local_habit.dart';

/// 습관별 리마인더 알림 (로컬)
class NotificationService {
  NotificationService._();
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;

  static const _channelId = 'bloom_habit_reminder';
  static const _channelName = '습관 리마인더';
  static const _fcmChannelId = 'bloom_habit_inquiry_reply';
  static const _fcmChannelName = '문의 답변 알림';

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  bool _rescheduling = false;

  FlutterLocalNotificationsPlugin get plugin => _plugin;

  Future<void> init() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();
    // 기기 로컬 타임존 설정 (에뮬레이터가 UTC를 반환하면 로컬 시간이 어긋남)
    try {
      final tzInfo = await FlutterTimezone.getLocalTimezone();
      final id = tzInfo.identifier;
      if (id == 'UTC' || id.startsWith('Etc/') || id == 'GMT' || id.isEmpty) {
        tz.setLocalLocation(tz.getLocation('Asia/Seoul'));
      } else {
        tz.setLocalLocation(tz.getLocation(id));
      }
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('Asia/Seoul'));
    }
    debugPrint('[NotificationService] 타임존: ${tz.local.name}');
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

    const fcmChannel = AndroidNotificationChannel(
      _fcmChannelId,
      _fcmChannelName,
      description: '문의 답변이 등록되었을 때 알림을 받습니다.',
      importance: Importance.max,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(fcmChannel);
    await ensurePermission();
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

  /// 시스템 앱 알림 설정 화면으로 이동 (권한이 아닌 '알림' 메뉴에서 켜야 함)
  Future<void> openNotificationSettings() async {
    await AppSettings.openAppSettings(type: AppSettingsType.notification);
  }

  /// 앱 시작/스케줄 시점마다 권한 상태 확인 후 필요하면 재요청
  Future<bool> ensurePermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return true;
    final enabled = await android.areNotificationsEnabled();
    if (enabled == true) return true;
    final granted = await android.requestNotificationsPermission();
    return granted ?? false;
  }

  /// 습관별 알림 ID (양수, habit serverId 기반)
  static int _notificationId(String? serverId) {
    if (serverId == null || serverId.isEmpty) return 0;
    return serverId.hashCode.abs() % 0x7FFFFFFF;
  }

  /// 사용자가 설정한 시각(기기 로컬)의 다음 발생 시점. DateTime은 항상 기기 로컬이므로 정확함.
  tz.TZDateTime _nextOccurrence(int hour, int minute) {
    final now = DateTime.now();
    var scheduled = DateTime(now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) scheduled = scheduled.add(const Duration(days: 1));
    final instant = scheduled.millisecondsSinceEpoch;
    return tz.TZDateTime.fromMillisecondsSinceEpoch(tz.UTC, instant);
  }

  /// 알림 켜진 습관들 기준으로 전체 스케줄 갱신 (전역 알림 off면 스케줄 안 함).
  /// 동시 호출 시 한 번만 실행되며, 같은 습관(serverId)은 한 번만 스케줄됩니다.
  Future<void> rescheduleFromHabits(List<LocalHabit> habits) async {
    if (_rescheduling) return;
    _rescheduling = true;
    try {
      await init();
      if (!await ensurePermission()) {
        await _plugin.cancelAll();
        return;
      }
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(app_prefs.keyNotificationsEnabled) == false) {
        await _plugin.cancelAll();
        return;
      }
      await _plugin.cancelAll();
      final toSchedule = habits.where((h) =>
          h.reminderEnabled == true &&
          h.reminderHour != null &&
          h.reminderMinute != null &&
          h.serverId != null).toList();
      debugPrint('[NotificationService] 리마인더 스케줄 대상 습관 수: ${toSchedule.length}');
      const androidDetails = AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: '습관별 설정한 시간에 리마인더가 울립니다.',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      );
      const details = NotificationDetails(android: androidDetails);
      final scheduledIds = <int>{};
      for (final h in toSchedule) {
        if (h.serverId == null) continue;
        final id = _notificationId(h.serverId);
        if (scheduledIds.contains(id)) continue;
        scheduledIds.add(id);
        final title = h.name?.isNotEmpty == true ? h.name! : '습관';
        final body = '오늘의 "$title" 확인해 보세요 🌱';
        final scheduledAt = _nextOccurrence(h.reminderHour!, h.reminderMinute!);
        debugPrint('[NotificationService] 스케줄: id=$id "$title" ${h.reminderHour}:${h.reminderMinute} -> $scheduledAt');
        try {
          await _plugin.zonedSchedule(
            id,
            title,
            body,
            scheduledAt,
            details,
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
            matchDateTimeComponents: DateTimeComponents.time,
          );
        } catch (e, st) {
          debugPrint('[NotificationService] 스케줄 실패: $e\n$st');
        }
      }
    } finally {
      _rescheduling = false;
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

  /// FCM 수신을 전면(포그라운드)에서도 화면에 표시하기 위한 로컬 알림.
  /// 현재 `remoteMessage.notification`이 있는 경우를 기준으로 사용합니다.
  Future<void> showFcmNotification({
    required String title,
    required String body,
  }) async {
    await init();
    final id = DateTime.now().millisecondsSinceEpoch.remainder(1 << 31);

    const androidDetails = AndroidNotificationDetails(
      _fcmChannelId,
      _fcmChannelName,
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    );
    const details = NotificationDetails(android: androidDetails);
    await _plugin.show(id, title, body, details);
  }
}
