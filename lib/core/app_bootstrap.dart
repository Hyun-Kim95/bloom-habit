import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

import 'analytics/analytics_bootstrap.dart';
import 'notifications/fcm_notification_listener.dart';
import 'notifications/notification_service.dart';
import 'social/android_social_sdk_init.dart';

/// Heavy SDK init after [runApp] so release builds show UI before permission/FCM.
Future<void> bootstrapAppServices() async {
  try {
    await initAndroidSocialSdks();
    scheduleAndroidSocialSdkWarmup();

    try {
      await Firebase.initializeApp();
    } catch (e, st) {
      debugPrint('[bootstrap] Firebase.initializeApp failed: $e\n$st');
    }

    final notif = NotificationService();
    await notif.init(requestPermission: false);

    if (Firebase.apps.isNotEmpty) {
      await FcmNotificationListener.init(notif);
    }

    await initAnalytics();

    SchedulerBinding.instance.addPostFrameCallback((_) {
      unawaited(notif.ensurePermission());
    });
  } catch (e, st) {
    debugPrint('[bootstrap] bootstrapAppServices failed: $e\n$st');
  }
}
