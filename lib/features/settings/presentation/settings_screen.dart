import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/router/app_providers.dart';
import '../../../core/router/app_router.dart';
import '../../../core/notifications/notification_service.dart';
import '../../../core/settings/app_settings.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String _versionText = '';

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (mounted) setState(() => _versionText = '${info.version}+${info.buildNumber}');
    });
  }

  Future<void> _openUrl(BuildContext context, String url, String name) async {
    if (url.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$name은(는) 준비 중입니다.')),
        );
      }
      return;
    }
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('링크를 열 수 없습니다.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settingsAsync = ref.watch(appSettingsProvider);

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
          const SizedBox(height: 8),
          _SettingsTile(
            icon: Icons.menu_book_outlined,
            title: '약관',
            subtitle: '이용약관',
            onTap: () => _openUrl(context, LegalUrls.terms, '약관'),
          ),
          _SettingsTile(
            icon: Icons.privacy_tip_outlined,
            title: '개인정보처리방침',
            subtitle: '개인정보 처리 방침',
            onTap: () => _openUrl(context, LegalUrls.privacy, '개인정보처리방침'),
          ),
          _SettingsTile(
            icon: Icons.mail_outline,
            title: '문의하기',
            subtitle: '게시판으로 문의·답변 확인',
            onTap: () => context.push(AppRoutes.inquiries),
          ),
          const Divider(height: 24),
          Text(
            '알림·피드백',
            style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.mutedForeground,
            ),
          ),
          const SizedBox(height: 8),
          settingsAsync.when(
            data: (settings) => Card(
              child: Column(
                children: [
                  SwitchListTile(
                    value: settings.notificationsEnabled,
                    onChanged: (v) async {
                      await settings.setNotificationsEnabled(v);
                      if (!v) await NotificationService().cancelAll();
                      ref.invalidate(appSettingsProvider);
                    },
                    title: Text(
                      '알림',
                      style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text(
                      '습관 리마인더 알림 사용',
                      style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.mutedForeground),
                    ),
                    activeColor: AppColors.primary,
                  ),
                  SwitchListTile(
                    value: settings.soundEnabled,
                    onChanged: (v) async {
                      await settings.setSoundEnabled(v);
                      ref.invalidate(appSettingsProvider);
                    },
                    title: Text(
                      '사운드',
                      style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text(
                      '기록 완료 시 효과음',
                      style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.mutedForeground),
                    ),
                    activeColor: AppColors.primary,
                  ),
                  SwitchListTile(
                    value: settings.hapticEnabled,
                    onChanged: (v) async {
                      await settings.setHapticEnabled(v);
                      ref.invalidate(appSettingsProvider);
                    },
                    title: Text(
                      '햅틱',
                      style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text(
                      '진동 피드백',
                      style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.mutedForeground),
                    ),
                    activeColor: AppColors.primary,
                  ),
                ],
              ),
            ),
            loading: () => const Card(child: ListTile(title: Text('로딩…'))),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 24),
          Text(
            '온보딩',
            style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.mutedForeground,
            ),
          ),
          const SizedBox(height: 8),
          settingsAsync.when(
            data: (settings) => Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.replay, color: AppColors.primary, size: 24),
                    title: Text(
                      '온보딩 다시 보기',
                      style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text(
                      '시작 화면을 다시 볼 수 있어요',
                      style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.mutedForeground),
                    ),
                    trailing: const Icon(Icons.chevron_right, color: AppColors.mutedForeground),
                    onTap: () => context.go(AppRoutes.onboarding),
                  ),
                  SwitchListTile(
                    value: settings.showOnboardingOnlyFirstLaunch,
                    onChanged: (v) async {
                      await settings.setShowOnboardingOnlyFirstLaunch(v);
                      ref.invalidate(appSettingsProvider);
                    },
                    title: Text(
                      '첫 실행만 보기',
                      style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text(
                      '끄면 앱을 열 때마다 온보딩을 볼 수 있어요',
                      style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.mutedForeground),
                    ),
                    activeColor: AppColors.primary,
                  ),
                ],
              ),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          if (_versionText.isNotEmpty) ...[
            const SizedBox(height: 24),
            Center(
              child: Text(
                '버전 $_versionText',
                style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.mutedForeground),
              ),
            ),
          ],
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
