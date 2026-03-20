import 'package:flutter/material.dart';
import 'package:bloom_habit/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/router/app_providers.dart';
import '../../../core/router/app_router.dart';

/// Figma-style onboarding with framed layout, illustration, typography, and CTA.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;
  static const _pages = 3;

  Future<void> _completeOnboarding() async {
    final settings = await ref.read(appSettingsProvider.future);
    await settings.setOnboardingSeen(true);
    if (!mounted) return;
    final restored = await ref.read(sessionRestoredProvider.future);
    if (!mounted) return;
    context.go(restored ? AppRoutes.home : AppRoutes.login);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.backgroundDark : AppColors.background;
    final fg = isDark ? AppColors.foregroundDark : AppColors.foreground;
    final muted = AppColors.mutedForeground;
    final primary = isDark ? AppColors.primaryDark : AppColors.primary;
    final dotInactive = isDark ? AppColors.borderDark : AppColors.border;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            // Top: skip action
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _completeOnboarding,
                  style: TextButton.styleFrom(
                    foregroundColor: muted,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  child: Text(
                    l10n.skip,
                    style: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ),
            // Framed content area: PageView
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _currentPage = i),
                children: [
                  _OnboardingFrame(
                    illustration: _OnboardingIllustration(
                      icon: Icons.eco_rounded,
                      color: primary,
                      backgroundColor: primary.withValues(alpha: 0.12),
                    ),
                    title: 'Bloom Habit',
                    subtitle: l10n.onboardingSubtitle1,
                    body: l10n.onboardingBody1,
                    isDark: isDark,
                  ),
                  _OnboardingFrame(
                    illustration: _OnboardingIllustration(
                      icon: Icons.check_circle_outline_rounded,
                      color: primary,
                      backgroundColor: primary.withValues(alpha: 0.12),
                    ),
                    title: l10n.onboardingTitle2,
                    subtitle: l10n.onboardingSubtitle2,
                    body: l10n.onboardingBody2,
                    isDark: isDark,
                  ),
                  _OnboardingFrame(
                    illustration: _OnboardingIllustration(
                      icon: Icons.rocket_launch_rounded,
                      color: primary,
                      backgroundColor: primary.withValues(alpha: 0.12),
                    ),
                    title: l10n.onboardingTitle3,
                    subtitle: l10n.onboardingSubtitle3,
                    body: l10n.onboardingBody3,
                    isDark: isDark,
                  ),
                ],
              ),
            ),
            // Bottom: page indicator + action button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              child: Row(
                children: [
                  ...List.generate(
                    _pages,
                    (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: i == _currentPage ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: i == _currentPage ? primary : dotInactive,
                      ),
                    ),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: () {
                      if (_currentPage < _pages - 1) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      } else {
                        _completeOnboarding();
                      }
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: isDark ? AppColors.primaryForegroundDark : AppColors.primaryForeground,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radius),
                      ),
                    ),
                    child: Text(
                      _currentPage >= _pages - 1 ? l10n.getStarted : l10n.next,
                      style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One onboarding frame: illustration area + typography.
class _OnboardingFrame extends StatelessWidget {
  const _OnboardingFrame({
    required this.illustration,
    required this.title,
    required this.subtitle,
    required this.body,
    required this.isDark,
  });

  final Widget illustration;
  final String title;
  final String subtitle;
  final String body;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final fg = isDark ? AppColors.foregroundDark : AppColors.foreground;
    final muted = AppColors.mutedForeground;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 24),
          illustration,
          const SizedBox(height: 40),
          Text(
            title,
            style: GoogleFonts.lora(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: fg,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            style: GoogleFonts.dmSans(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            body,
            style: GoogleFonts.dmSans(
              fontSize: 15,
              height: 1.5,
              color: muted,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

/// Illustration area: circular background with icon.
class _OnboardingIllustration extends StatelessWidget {
  const _OnboardingIllustration({
    required this.icon,
    required this.color,
    required this.backgroundColor,
  });

  final IconData icon;
  final Color color;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 160,
        height: 160,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.15),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 72, color: color),
      ),
    );
  }
}
