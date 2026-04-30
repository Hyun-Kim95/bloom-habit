import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:habit_fable/l10n/app_localizations.dart';

import '../config/app_flags.dart';
import '../monetization/adaptive_banner_ad_slot.dart';
import '../theme/app_theme.dart';
import 'app_providers.dart';
import 'app_router.dart';

/// Main tab root paths: double-back to exit here.
bool _isShellRootPath(String path) {
  return path == AppRoutes.home ||
      path == AppRoutes.habits ||
      path == AppRoutes.statistics ||
      path == AppRoutes.settings;
}

/// Main shell with shared bottom navigation.
class MainShell extends ConsumerStatefulWidget {
  const MainShell({
    super.key,
    required this.navigationShell,
  });

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  DateTime? _lastBackPress;

  static int _selectedIndexFromPath(String path) {
    if (path.startsWith(AppRoutes.habits) || path.startsWith(AppRoutes.habitCreate)) return 1;
    if (path.startsWith(AppRoutes.statistics)) return 2;
    if (path.startsWith(AppRoutes.settings)) return 3;
    return 0; // home
  }

  void _onTap(BuildContext context, int index) {
    final path = index == 0
        ? AppRoutes.home
        : index == 1
            ? AppRoutes.habits
            : index == 2
                ? AppRoutes.statistics
                : AppRoutes.settings;
    context.go(path);
  }

  bool _onPopInvoked(bool didPop) {
    if (didPop) return true;
    final path = GoRouterState.of(context).uri.path;
    final l10n = AppLocalizations.of(context)!;
    if (!_isShellRootPath(path)) return true;
    final now = DateTime.now();
    if (_lastBackPress != null && now.difference(_lastBackPress!).inMilliseconds < 2000) {
      SystemNavigator.pop();
      return true;
    }
    setState(() => _lastBackPress = now);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.pressBackAgainToExit),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;
    final l10n = AppLocalizations.of(context)!;
    final currentIndex = _selectedIndexFromPath(path);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.backgroundDark : _shellBackground;
    final border = isDark ? AppColors.borderDark : _shellBorder;
    final atRoot = _isShellRootPath(path);
    final unreadSummary = ref.watch(unreadSummaryProvider).valueOrNull;
    final hasSettingsUnread = unreadSummary?.hasUnread ?? false;

    return PopScope(
      canPop: !atRoot,
      onPopInvokedWithResult: (didPop, result) {
        if (atRoot && !didPop) _onPopInvoked(false);
      },
      child: Scaffold(
      body: Column(
        children: [
          Expanded(child: widget.navigationShell),
          if (!kScreenshotMode) const AdaptiveBannerAdSlot(),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: bg,
          border: Border(top: BorderSide(color: border)),
        ),
        child: Row(
          children: [
            Expanded(
              child: _NavItem(
                label: l10n.navHome,
                icon: Icons.home_rounded,
                selected: currentIndex == 0,
                onTap: () => _onTap(context, 0),
              ),
            ),
            Expanded(
              child: _NavItem(
                label: l10n.navHabits,
                icon: Icons.list_rounded,
                selected: currentIndex == 1,
                onTap: () => _onTap(context, 1),
              ),
            ),
            Expanded(
              child: _NavItem(
                label: l10n.navStats,
                icon: Icons.bar_chart_rounded,
                selected: currentIndex == 2,
                onTap: () => _onTap(context, 2),
              ),
            ),
            Expanded(
              child: _NavItem(
                label: l10n.navSettings,
                icon: Icons.settings_rounded,
                selected: currentIndex == 3,
                showBadge: hasSettingsUnread,
                onTap: () => _onTap(context, 3),
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }
}

const Color _shellBackground = Color(0xFFF0F8FF);
const Color _shellBorder = Color(0xFFD9DFE4);

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.selected,
    this.showBadge = false,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final bool showBadge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = selected
        ? (isDark ? AppColors.primaryDark : AppColors.primary)
        : AppColors.mutedFg(isDark);
    const double tapHeight = 56;
    const double rippleRadius = 30;
    return SizedBox(
      height: tapHeight,
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        child: InkResponse(
          onTap: onTap,
          containedInkWell: true,
          highlightShape: BoxShape.circle,
          radius: rippleRadius,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(icon, size: 22, color: color),
                    if (showBadge)
                      const Positioned(
                        right: -4,
                        top: -2,
                        child: _NavDotBadge(),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: GoogleFonts.dmSans(
                    fontSize: 10,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavDotBadge extends StatelessWidget {
  const _NavDotBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: AppColors.destructive,
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}
