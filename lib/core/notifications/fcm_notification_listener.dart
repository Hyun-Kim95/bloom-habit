import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'notification_service.dart';

/// Parses FCM `data` (title/body/type) and shows one local tray entry on all
/// platforms. Legacy Android-only: if OS filled [RemoteMessage.notification]
/// without `data` text, skip local to avoid doubling with the system shade.
Future<void> deliverFcmMessageToTray(
  RemoteMessage message,
  NotificationService notificationService,
) async {
  final data = message.data;
  final type = data['type']?.toString();
  final hasDataPayloadText = (data['title'] ?? '').toString().trim().isNotEmpty ||
      (data['body'] ?? '').toString().trim().isNotEmpty;
  var title = (data['title'] ?? '').toString().trim();
  var body = (data['body'] ?? '').toString().trim();
  final n = message.notification;
  if (title.isEmpty && body.isEmpty) {
    title = (n?.title ?? '').trim();
    body = (n?.body ?? '').trim();
  }
  if (title.isEmpty && body.isEmpty) return;

  final hasPlatformNotification = (n?.title?.trim().isNotEmpty ?? false) ||
      (n?.body?.trim().isNotEmpty ?? false);

  if (hasPlatformNotification &&
      defaultTargetPlatform == TargetPlatform.android &&
      !hasDataPayloadText) {
    return;
  }

  if (kDebugMode) {
    debugPrint(
      '[FCM deliver] type=$type hasDataText=$hasDataPayloadText '
      'hasPlatformN=$hasPlatformNotification -> showLocal',
    );
  }

  final imageUrl = data['imageUrl']?.toString();
  final tag = data['tag']?.toString();

  await notificationService.showFcmNotification(
    title: title,
    body: body,
    fcmDataType: type,
    imageUrl: (imageUrl != null && imageUrl.isNotEmpty) ? imageUrl : null,
    androidTag: (tag != null && tag.isNotEmpty) ? tag : null,
  );
}

/// Shows FCM notifications even while app is in foreground.
class FcmNotificationListener {
  FcmNotificationListener._();

  static final StreamController<String> _messageTypeController =
      StreamController<String>.broadcast();

  static Stream<String> get messageTypes => _messageTypeController.stream;

  static Future<void> init(NotificationService notificationService) async {
    if (Firebase.apps.isEmpty) {
      debugPrint('[FCM] Skipping listener setup: Firebase not initialized');
      return;
    }
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      final type = message.data['type']?.toString();
      if (type != null && type.isNotEmpty) {
        _messageTypeController.add(type);
      }
      await deliverFcmMessageToTray(message, notificationService);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('FCM opened: ${message.messageId}');
    });
  }
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (_) {}
  final service = NotificationService();
  await service.init();
  await deliverFcmMessageToTray(message, service);
}
