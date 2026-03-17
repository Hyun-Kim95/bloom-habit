import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/router/app_router.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;
  static const _pages = 3;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => context.go(AppRoutes.login),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.mutedForeground,
                  ),
                  child: Text(
                    '건너뛰기',
                    style: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _currentPage = i),
                children: const [
                  _OnboardingPage(
                    title: 'Bloom Habit',
                    subtitle: '작은 습관이 인생을 바꿉니다.',
                    body: '매일 조금씩 기록하고, 꾸준함을 키워 보세요.',
                    icon: Icons.eco,
                  ),
                  _OnboardingPage(
                    title: '습관 기록',
                    subtitle: '오늘 한 일을 간단히 체크',
                    body: '완료할 때마다 기록하면 연속 달성일과 통계를 볼 수 있어요.',
                    icon: Icons.check_circle_outline,
                  ),
                  _OnboardingPage(
                    title: '시작하기',
                    subtitle: '지금 바로 첫 습관을 만들어 보세요.',
                    body: '로그인 후 습관을 추가하고, 오늘부터 기록을 시작해요.',
                    icon: Icons.rocket_launch_outlined,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              child: Row(
                children: [
                  ...List.generate(
                    _pages,
                    (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: i == _currentPage ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: i == _currentPage
                            ? AppColors.primary
                            : (isDark ? AppColors.borderDark : AppColors.border),
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
                        context.go(AppRoutes.login);
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        _currentPage >= _pages - 1 ? '시작하기' : '다음',
                        style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
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

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({
    required this.title,
    required this.subtitle,
    required this.body,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final String body;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = isDark ? AppColors.foregroundDark : AppColors.foreground;
    final muted = AppColors.mutedForeground;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: isDark ? 0.3 : 1),
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            ),
            child: Icon(icon, size: 40, color: AppColors.primary),
          ),
          const SizedBox(height: 32),
          Text(
            title,
            style: GoogleFonts.lora(
              fontSize: 26,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            style: GoogleFonts.dmSans(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: muted,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Text(
            body,
            style: GoogleFonts.dmSans(
              fontSize: 15,
              height: 1.5,
              color: muted,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
