import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'notification_service.dart';

/// FCM 알림을 앱이 전면(포그라운드)에 있을 때도 화면에 표시하기 위한 리스너.
class FcmNotificationListener {
  FcmNotificationListener._();

  static Future<void> init(NotificationService notificationService) async {
    // 백그라운드에서도 메시지를 받는 경우를 대비(이 프로젝트는 notification payload 위주).
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      final notification = message.notification;
      if (notification == null) return;

      final title = notification.title ?? '';
      final body = notification.body ?? '';
      if (title.isEmpty && body.isEmpty) return;

      await notificationService.showFcmNotification(title: title, body: body);
    });

    // 사용자가 알림을 눌러 앱을 여는 경우(현재는 로그만)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('FCM opened: ${message.messageId}');
    });
  }
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // 백그라운드/종료 상태에서 notification payload은 OS가 표시해주는 경우가 많습니다.
  // 그래도 데이터 기반 메시지에 대비해서 최소 로컬 표시를 시도합니다.
  final notification = message.notification;
  final title = notification?.title ?? '';
  final body = notification?.body ?? '';
  if (title.isEmpty && body.isEmpty) return;

  final service = NotificationService();
  await service.init();
  await service.showFcmNotification(title: title, body: body);
}

