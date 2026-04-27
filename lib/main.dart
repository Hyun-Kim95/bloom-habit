import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bloom_habit/l10n/app_localizations.dart';

import 'core/notifications/notification_service.dart';
import 'core/notifications/fcm_notification_listener.dart';
import 'core/monetization/monetization_notifier.dart';
import 'core/router/app_providers.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/social/android_social_sdk_init.dart';
import 'core/settings/app_settings.dart';
import 'l10n/app_strings.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final initialLocaleCode = prefs.getString(kSettingsLocaleKey) ?? 'ko';
  AppStrings.localeCode = initialLocaleCode;
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
  runApp(
    ProviderScope(child: BloomHabitApp(initialLocaleCode: initialLocaleCode)),
  );
}

class BloomHabitApp extends ConsumerStatefulWidget {
  const BloomHabitApp({super.key, required this.initialLocaleCode});

  /// Locale from SharedPreferences before [appSettingsProvider] resolves (avoids a `ko` first frame).
  final String initialLocaleCode;

  @override
  ConsumerState<BloomHabitApp> createState() => _BloomHabitAppState();
}

class _BloomHabitAppState extends ConsumerState<BloomHabitApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = createAppRouter(ref);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(monetizationProvider.notifier).bootstrap();
    });
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(appSettingsProvider);
    final settings = settingsAsync.valueOrNull;
    final themeMode = switch (settings?.themeMode) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.light,
    };
    final localeCode = settings?.localeCode ?? widget.initialLocaleCode;
    AppStrings.localeCode = localeCode;
    return MaterialApp.router(
      title: 'Bloom Habit',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      locale: Locale(localeCode),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      routerConfig: _router,
    );
  }
}
