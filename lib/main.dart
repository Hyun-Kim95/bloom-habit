import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/notifications/notification_service.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final notif = NotificationService();
  await notif.init();
  final enabled = await notif.isEnabled();
  if (enabled) {
    final time = await notif.getScheduledTime();
    await notif.scheduleDaily(time.hour, time.minute);
  }
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
