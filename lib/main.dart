import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bloom_habit/l10n/app_localizations.dart';

import 'core/notifications/notification_service.dart';
import 'core/notifications/fcm_notification_listener.dart';
import 'core/router/app_providers.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/social/android_social_sdk_init.dart';
import 'l10n/app_strings.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initAndroidSocialSdks();
  scheduleAndroidSocialSdkWarmup();
  try {
    await Firebase.initializeApp();
  } catch (_) {
    // Firebase 미설정(google-services.json 등 없음) 시 무시
  }
  final notif = NotificationService();
  await notif.init();
  await FcmNotificationListener.init(notif);
  runApp(const ProviderScope(child: BloomHabitApp()));
}

class BloomHabitApp extends ConsumerWidget {
  const BloomHabitApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(appSettingsProvider);
    final settings = settingsAsync.valueOrNull;
    final themeMode = switch (settings?.themeMode) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    final localeCode = settings?.localeCode ?? 'ko';
    AppStrings.localeCode = localeCode;
    return MaterialApp.router(
      title: 'Bloom Habit',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      locale: Locale(localeCode),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      routerConfig: createAppRouter(ref),
    );
  }
}
