import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bloom_habit/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/notifications/notification_service.dart';
import '../../../core/router/app_providers.dart';
import '../../../core/router/app_router.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String _versionText = '';

  String _themeModeLabel(String mode) {
    final l10n = AppLocalizations.of(context)!;
    switch (mode) {
      case 'light':
        return l10n.lightTheme;
      case 'dark':
        return l10n.darkTheme;
      default:
        return l10n.systemTheme;
    }
  }

  String _localeLabel(String code) {
    switch (code) {
      case 'en':
        return 'English';
      default:
        return '한국어';
    }
  }

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (mounted) setState(() => _versionText = '${info.version}+${info.buildNumber}');
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settingsAsync = ref.watch(appSettingsProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: AppBar(
        title: Text(
          l10n.settingsTitle,
          style: GoogleFonts.dmSans(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        children: [
          _SettingsTile(
            icon: Icons.person_outline,
            title: l10n.accountManagement,
            subtitle: l10n.profileAndLogout,
            onTap: () => context.push(AppRoutes.account),
          ),
          const SizedBox(height: 8),
          _SettingsTile(
            icon: Icons.campaign_outlined,
            title: l10n.announcements,
            subtitle: l10n.serviceAnnouncementList,
            onTap: () => context.push(AppRoutes.notices),
          ),
          _SettingsTile(
            icon: Icons.menu_book_outlined,
            title: l10n.terms,
            subtitle: l10n.terms,
            onTap: () => context.push(AppRoutes.legalTerms),
          ),
          _SettingsTile(
            icon: Icons.privacy_tip_outlined,
            title: l10n.privacyPolicy,
            subtitle: l10n.privacyPolicy,
            onTap: () => context.push(AppRoutes.legalPrivacy),
          ),
          _SettingsTile(
            icon: Icons.mail_outline,
            title: l10n.inquiry,
            subtitle: l10n.inquirySubtitle,
            onTap: () => context.push(AppRoutes.inquiries),
          ),
          _SettingsTile(
            icon: Icons.notifications_outlined,
            title: l10n.notificationSettings,
            subtitle: l10n.notificationSettingsSubtitle,
            onTap: () => NotificationService().openNotificationSettings(),
          ),
          const Divider(height: 24),
          Text(
            l10n.displaySettings,
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
                    leading: const Icon(Icons.language_outlined, color: AppColors.primary, size: 24),
                    title: Text(
                      l10n.language,
                      style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text(
                      _localeLabel(settings.localeCode),
                      style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.mutedForeground),
                    ),
                    trailing: const Icon(Icons.chevron_right, color: AppColors.mutedForeground),
                    onTap: () async {
                      final selected = await showModalBottomSheet<String>(
                        context: context,
                        showDragHandle: true,
                        builder: (ctx) => SafeArea(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ListTile(
                                title: const Text('한국어'),
                                onTap: () => Navigator.pop(ctx, 'ko'),
                              ),
                              ListTile(
                                title: const Text('English'),
                                onTap: () => Navigator.pop(ctx, 'en'),
                              ),
                            ],
                          ),
                        ),
                      );
                      if (selected == null) return;
                      await settings.setLocaleCode(selected);
                      ref.invalidate(appSettingsProvider);
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.dark_mode_outlined, color: AppColors.primary, size: 24),
                    title: Text(
                      l10n.theme,
                      style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text(
                      _themeModeLabel(settings.themeMode),
                      style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.mutedForeground),
                    ),
                    trailing: const Icon(Icons.chevron_right, color: AppColors.mutedForeground),
                    onTap: () async {
                      final selected = await showModalBottomSheet<String>(
                        context: context,
                        showDragHandle: true,
                        builder: (ctx) => SafeArea(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ListTile(
                                title: Text(l10n.systemTheme),
                                onTap: () => Navigator.pop(ctx, 'system'),
                              ),
                              ListTile(
                                title: Text(l10n.lightTheme),
                                onTap: () => Navigator.pop(ctx, 'light'),
                              ),
                              ListTile(
                                title: Text(l10n.darkTheme),
                                onTap: () => Navigator.pop(ctx, 'dark'),
                              ),
                            ],
                          ),
                        ),
                      );
                      if (selected == null) return;
                      await settings.setThemeMode(selected);
                      ref.invalidate(appSettingsProvider);
                    },
                  ),
                ],
              ),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const Divider(height: 24),
          Text(
            l10n.soundAndFeedback,
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
                    value: settings.soundEnabled,
                    onChanged: (v) async {
                      await settings.setSoundEnabled(v);
                      ref.invalidate(appSettingsProvider);
                    },
                    title: Text(
                      l10n.sound,
                      style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text(
                      l10n.soundSubtitle,
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
                      l10n.haptic,
                      style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text(
                      l10n.hapticSubtitle,
                      style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.mutedForeground),
                    ),
                    activeColor: AppColors.primary,
                  ),
                ],
              ),
            ),
            loading: () => Card(child: ListTile(title: Text(l10n.loading))),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.onboarding,
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
                      l10n.replayOnboarding,
                      style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text(
                      l10n.replayOnboardingSubtitle,
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
                      l10n.showOnlyFirstLaunch,
                      style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text(
                      l10n.showOnlyFirstLaunchSubtitle,
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
                l10n.versionLabel(_versionText),
                style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.mutedForeground),
              ),
            ),
          ],
          const Divider(height: 24),
          _SettingsTile(
            icon: Icons.logout,
            title: l10n.logout,
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
