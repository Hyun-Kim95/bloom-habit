import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/local/entity/local_habit.dart';
import '../../features/account/presentation/account_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/habit_create/presentation/habit_create_screen.dart';
import '../../features/habit_detail/presentation/habit_detail_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/statistics/presentation/statistics_screen.dart';
import '../../features/inquiries/presentation/inquiries_screen.dart';
import '../../features/habit_list/presentation/habit_list_screen.dart';
import '../../features/legal/presentation/legal_view_screen.dart';
import '../../features/notices/presentation/notices_screen.dart';
import '../errors/error_logger.dart';
import '../../l10n/app_localizations.dart';
import 'app_providers.dart';
import 'main_shell.dart';

/// Route paths.
class AppRoutes {
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String home = '/home';
  static const String habits = '/habits';
  static const String habitCreate = '/habit/create';
  static const String habitDetail = '/habit';
  static const String settings = '/settings';
  static const String account = '/account';
  static const String statistics = '/statistics';
  static const String inquiries = '/inquiries';
  static const String legalTerms = '/legal/terms';
  static const String legalPrivacy = '/legal/privacy';
  static const String notices = '/notices';
}

GoRouter createAppRouter(WidgetRef ref) {
  return GoRouter(
    initialLocation: AppRoutes.onboarding,
    debugLogDiagnostics: true,
    redirect: (BuildContext context, GoRouterState state) async {
      final restored = await ref.read(sessionRestoredProvider.future);
      final path = state.uri.path;
      final replayOnboarding = state.uri.queryParameters['replay'] == '1';
      // If already authenticated, keep login/onboarding unreachable.
      if (restored &&
          (path == AppRoutes.login ||
              (path == AppRoutes.onboarding && !replayOnboarding))) {
        return AppRoutes.home;
      }
      if (!restored &&
          path != AppRoutes.onboarding &&
          path != AppRoutes.login &&
          !path.startsWith('/legal/')) {
        return AppRoutes.login;
      }
      // If onboarding was already seen and one-time mode is enabled, go to login.
      if (path == AppRoutes.onboarding && !restored) {
        final settings = await ref.read(appSettingsProvider.future);
        if (settings.hasSeenOnboarding &&
            settings.showOnboardingOnlyFirstLaunch) {
          return AppRoutes.login;
        }
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (_, _) => const OnboardingScreen(),
      ),
      GoRoute(path: AppRoutes.login, builder: (_, _) => const LoginScreen()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            initialLocation: AppRoutes.home,
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (_, _) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            initialLocation: AppRoutes.habits,
            routes: [
              GoRoute(
                path: AppRoutes.habits,
                builder: (_, _) => const HabitListScreen(),
              ),
              GoRoute(
                path: AppRoutes.habitCreate,
                builder: (_, _) => const HabitCreateScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            initialLocation: AppRoutes.statistics,
            routes: [
              GoRoute(
                path: AppRoutes.statistics,
                builder: (_, _) => const StatisticsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            initialLocation: AppRoutes.settings,
            routes: [
              GoRoute(
                path: AppRoutes.settings,
                builder: (_, _) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '${AppRoutes.habitDetail}/:id',
        builder: (_, state) {
          final extra = state.extra as LocalHabit?;
          if (extra == null) return const SizedBox();
          return HabitDetailScreen(habit: extra);
        },
      ),
      GoRoute(
        path: AppRoutes.account,
        builder: (_, _) => const AccountScreen(),
      ),
      GoRoute(
        path: AppRoutes.inquiries,
        builder: (_, _) => const InquiriesScreen(),
      ),
      GoRoute(
        path: AppRoutes.legalTerms,
        builder: (_, _) => const LegalViewScreen(type: 'terms'),
      ),
      GoRoute(
        path: AppRoutes.legalPrivacy,
        builder: (_, _) => const LegalViewScreen(type: 'privacy'),
      ),
      GoRoute(
        path: AppRoutes.notices,
        builder: (_, _) => const NoticesScreen(),
      ),
    ],
    errorBuilder: (context, state) {
      ErrorLogger.logError('AppRouter.pageNotFound', state.uri.toString());
      return Scaffold(
        body: Center(
          child: Text(AppLocalizations.of(context)!.pageNotFound),
        ),
      );
    },
  );
}
