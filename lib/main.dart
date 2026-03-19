import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/notifications/notification_service.dart';
import 'core/notifications/fcm_notification_listener.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (_) {
    // Firebase 미설정(google-services.json 등 없음) 시 무시
  }
  final notif = NotificationService();
  await notif.init();
  await FcmNotificationListener.init(notif);
  runApp(
    const ProviderScope(
      child: BloomHabitApp(),
    ),
  );
}

class BloomHabitApp extends ConsumerWidget {
  const BloomHabitApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Bloom Habit',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: createAppRouter(ref),
    );
  }
}
