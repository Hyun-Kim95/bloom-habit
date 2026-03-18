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
import 'app_providers.dart';
import 'main_shell.dart';

/// 라우트 경로
class AppRoutes {
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String home = '/home';
  static const String habitCreate = '/habit/create';
  static const String habitDetail = '/habit';
  static const String settings = '/settings';
  static const String account = '/account';
  static const String statistics = '/statistics';
}

GoRouter createAppRouter(WidgetRef ref) {
  return GoRouter(
    initialLocation: AppRoutes.onboarding,
    debugLogDiagnostics: true,
    redirect: (BuildContext context, GoRouterState state) async {
      final restored = await ref.read(sessionRestoredProvider.future);
      final path = state.uri.path;
      final isPublic = path == AppRoutes.onboarding || path == AppRoutes.login;
      if (restored && isPublic) {
        return AppRoutes.home;
      }
      if (!restored && !isPublic) {
        return AppRoutes.login;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (_, __) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (_, __) => const LoginScreen(),
      ),
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
                builder: (_, __) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            initialLocation: AppRoutes.habitCreate,
            routes: [
              GoRoute(
                path: AppRoutes.habitCreate,
                builder: (_, __) => const HabitCreateScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            initialLocation: AppRoutes.statistics,
            routes: [
              GoRoute(
                path: AppRoutes.statistics,
                builder: (_, __) => const StatisticsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            initialLocation: AppRoutes.settings,
            routes: [
              GoRoute(
                path: AppRoutes.settings,
                builder: (_, __) => const SettingsScreen(),
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
        builder: (_, __) => const AccountScreen(),
      ),
    ],
    errorBuilder: (_, state) => Scaffold(
      body: Center(
        child: Text('Not found: ${state.uri}'),
      ),
    ),
  );
}
