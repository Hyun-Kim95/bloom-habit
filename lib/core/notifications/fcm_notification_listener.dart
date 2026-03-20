import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'notification_service.dart';

/// Shows FCM notifications even while app is in foreground.
class FcmNotificationListener {
  FcmNotificationListener._();

  static Future<void> init(NotificationService notificationService) async {
    // Register background handler for data/notification delivery.
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      final notification = message.notification;
      if (notification == null) return;

      final title = notification.title ?? '';
      final body = notification.body ?? '';
      if (title.isEmpty && body.isEmpty) return;

      await notificationService.showFcmNotification(title: title, body: body);
    });

    // User opened app from notification tap (currently log only).
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('FCM opened: ${message.messageId}');
    });
  }
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // OS usually displays notification payload in background/terminated states.
  // Still try a minimal local display for data-driven messages.
  final notification = message.notification;
  final title = notification?.title ?? '';
  final body = notification?.body ?? '';
  if (title.isEmpty && body.isEmpty) return;

  final service = NotificationService();
  await service.init();
  await service.showFcmNotification(title: title, body: body);
}

