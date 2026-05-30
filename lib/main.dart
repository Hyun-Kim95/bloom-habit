import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:habit_fable/l10n/app_localizations.dart';
import 'dart:async';

import 'core/app_bootstrap.dart';
import 'core/notifications/fcm_notification_listener.dart';
import 'core/monetization/monetization_notifier.dart';
import 'core/analytics/analytics_identity_listener.dart';
import 'core/router/app_providers.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/settings/app_settings.dart';
import 'core/config/app_flags.dart';
import 'core/version/app_update_listener.dart';
import 'l10n/app_strings.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final initialLocaleCode = prefs.getString(kSettingsLocaleKey) ?? 'ko';
  AppStrings.localeCode = initialLocaleCode;
  runApp(
    ProviderScope(child: HabitFableApp(initialLocaleCode: initialLocaleCode)),
  );
}

class HabitFableApp extends ConsumerStatefulWidget {
  const HabitFableApp({super.key, required this.initialLocaleCode});

  /// Locale from SharedPreferences before [appSettingsProvider] resolves (avoids a `ko` first frame).
  final String initialLocaleCode;

  @override
  ConsumerState<HabitFableApp> createState() => _HabitFableAppState();
}

class _HabitFableAppState extends ConsumerState<HabitFableApp> {
  late final GoRouter _router;
  StreamSubscription<String>? _fcmTypeSub;

  @override
  void initState() {
    super.initState();
    _router = createAppRouter(ref);
    unawaited(bootstrapAppServices());
    _fcmTypeSub = FcmNotificationListener.messageTypes.listen((type) {
      if (type == 'inquiry_reply' || type == 'notice' || type == 'announcement') {
        ref.invalidate(unreadSummaryProvider);
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(monetizationProvider.notifier).bootstrap();
      ref.read(authRepositoryProvider).attachFcmTokenRefreshListener();
    });
  }

  @override
  void dispose() {
    _fcmTypeSub?.cancel();
    super.dispose();
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
      debugShowCheckedModeBanner: !kScreenshotMode,
      title: 'HabitFable',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      locale: Locale(localeCode),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      routerConfig: _router,
      builder: (context, child) {
        return AnalyticsIdentityListener(
          child: AppUpdateListener(
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
    );
  }
}
