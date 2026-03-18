import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/router/app_providers.dart';
import '../../../core/router/app_router.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: AppBar(
        title: Text(
          '설정',
          style: GoogleFonts.dmSans(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        children: [
          _SettingsTile(
            icon: Icons.person_outline,
            title: '계정 관리',
            subtitle: '프로필 및 로그아웃',
            onTap: () => context.push(AppRoutes.account),
          ),
          _SettingsTile(
            icon: Icons.bar_chart_outlined,
            title: '통계',
            subtitle: '습관 통계 보기',
            onTap: () => context.push(AppRoutes.statistics),
          ),
          const Divider(height: 24),
          _SettingsTile(
            icon: Icons.logout,
            title: '로그아웃',
            subtitle: null,
            titleColor: AppColors.destructive,
            onTap: () async {
              await ref.read(authRepositoryProvider).logout();
              if (!context.mounted) return;
              ref.invalidate(sessionRestoredProvider);
              context.go(AppRoutes.login);
            },
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.titleColor,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Color? titleColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = titleColor ?? (isDark ? AppColors.foregroundDark : AppColors.foreground);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: titleColor ?? AppColors.primary, size: 24),
        title: Text(
          title,
          style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w500, color: fg),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle!,
                style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.mutedForeground),
              )
            : null,
        trailing: const Icon(Icons.chevron_right, color: AppColors.mutedForeground),
        onTap: onTap,
      ),
    );
  }
}
