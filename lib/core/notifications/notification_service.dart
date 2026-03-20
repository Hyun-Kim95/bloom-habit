import 'package:app_settings/app_settings.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

import '../settings/app_settings.dart' as app_prefs;
import '../../data/local/entity/local_habit.dart';
import '../../l10n/app_strings.dart';

/// Per-habit local reminder notifications.
class NotificationService {
  NotificationService._();
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;

  static const _channelId = 'bloom_habit_reminder';
  static String get _channelName => AppStrings.notifChannelHabit;
  static const _fcmChannelId = 'bloom_habit_inquiry_reply';
  static String get _fcmChannelName => AppStrings.notifChannelInquiry;

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  bool _rescheduling = false;

  FlutterLocalNotificationsPlugin get plugin => _plugin;

  Future<void> init() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();
    // Use device timezone. Emulator may return UTC unexpectedly.
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
    debugPrint('[NotificationService] timezone: ${tz.local.name}');
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: android);
    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onTap,
    );
    final androidChannel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: AppStrings.notifDescHabit,
      importance: Importance.defaultImportance,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    final fcmChannel = AndroidNotificationChannel(
      _fcmChannelId,
      _fcmChannelName,
      description: AppStrings.notifDescInquiry,
      importance: Importance.max,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(fcmChannel);
    await ensurePermission();
    _initialized = true;
  }

  void _onTap(NotificationResponse response) {}

  /// Request notification permission on Android 13+.
  Future<bool> requestPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      return granted ?? false;
    }
    return true;
  }

  /// Open OS app notification settings screen.
  Future<void> openNotificationSettings() async {
    await AppSettings.openAppSettings(type: AppSettingsType.notification);
  }

  /// Check current permission state and re-request if needed.
  Future<bool> ensurePermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return true;
    final enabled = await android.areNotificationsEnabled();
    if (enabled == true) return true;
    final granted = await android.requestNotificationsPermission();
    return granted ?? false;
  }

  /// Positive notification ID derived from habit serverId.
  static int _notificationId(String? serverId) {
    if (serverId == null || serverId.isEmpty) return 0;
    return serverId.hashCode.abs() % 0x7FFFFFFF;
  }

  /// Next occurrence at user-selected local time.
  tz.TZDateTime _nextOccurrence(int hour, int minute) {
    final now = DateTime.now();
    var scheduled = DateTime(now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) scheduled = scheduled.add(const Duration(days: 1));
    final instant = scheduled.millisecondsSinceEpoch;
    return tz.TZDateTime.fromMillisecondsSinceEpoch(tz.UTC, instant);
  }

  /// Rebuild full schedule from enabled habits.
  /// Concurrent calls are coalesced, and each habit is scheduled once.
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
      debugPrint('[NotificationService] reminder target habits: ${toSchedule.length}');
      final androidDetails = AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: AppStrings.notifDescHabit,
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      );
      final details = NotificationDetails(android: androidDetails);
      final scheduledIds = <int>{};
      for (final h in toSchedule) {
        if (h.serverId == null) continue;
        final id = _notificationId(h.serverId);
        if (scheduledIds.contains(id)) continue;
        scheduledIds.add(id);
        final title = h.name?.isNotEmpty == true ? h.name! : AppStrings.notifFallbackTitle;
        final body = AppStrings.notifFallbackBody(title);
        final scheduledAt = _nextOccurrence(h.reminderHour!, h.reminderMinute!);
        debugPrint('[NotificationService] schedule: id=$id "$title" ${h.reminderHour}:${h.reminderMinute} -> $scheduledAt');
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
          debugPrint('[NotificationService] schedule failed: $e\n$st');
        }
      }
    } finally {
      _rescheduling = false;
    }
  }

  /// Cancel one habit notification only.
  Future<void> cancelHabit(String? serverId) async {
    if (serverId == null) return;
    await _plugin.cancel(_notificationId(serverId));
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  /// Show local notification for foreground FCM message handling.
  Future<void> showFcmNotification({
    required String title,
    required String body,
  }) async {
    await init();
    final id = DateTime.now().millisecondsSinceEpoch.remainder(1 << 31);

    final androidDetails = AndroidNotificationDetails(
      _fcmChannelId,
      _fcmChannelName,
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    );
    final details = NotificationDetails(android: androidDetails);
    await _plugin.show(id, title, body, details);
  }
}
