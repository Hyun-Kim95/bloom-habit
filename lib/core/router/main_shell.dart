import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';
import 'app_router.dart';

/// 하단 네비가 공통으로 보이는 메인 셸 (Home / Habits / Stats / Settings)
class MainShell extends StatelessWidget {
  const MainShell({
    super.key,
    required this.navigationShell,
  });

  final StatefulNavigationShell navigationShell;

  static int _selectedIndexFromPath(String path) {
    if (path.startsWith(AppRoutes.habitCreate)) return 1;
    if (path.startsWith(AppRoutes.statistics)) return 2;
    if (path.startsWith(AppRoutes.settings)) return 3;
    return 0; // home
  }

  void _onTap(BuildContext context, int index) {
    final path = index == 0
        ? AppRoutes.home
        : index == 1
            ? AppRoutes.habitCreate
            : index == 2
                ? AppRoutes.statistics
                : AppRoutes.settings;
    context.go(path);
  }

  @override
  Widget build(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;
    final currentIndex = _selectedIndexFromPath(path);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.backgroundDark : _shellBackground;
    final border = isDark ? AppColors.borderDark : _shellBorder;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: bg,
          border: Border(top: BorderSide(color: border)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _NavItem(label: 'Home', selected: currentIndex == 0, onTap: () => _onTap(context, 0)),
            _NavItem(label: 'Habits', selected: currentIndex == 1, onTap: () => _onTap(context, 1)),
            _NavItem(label: 'Stats', selected: currentIndex == 2, onTap: () => _onTap(context, 2)),
            _NavItem(label: 'Settings', selected: currentIndex == 3, onTap: () => _onTap(context, 3)),
          ],
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
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.mutedForeground;
    IconData icon;
    switch (label) {
      case 'Home':
        icon = Icons.home_rounded;
        break;
      case 'Habits':
        icon = Icons.list_rounded;
        break;
      case 'Stats':
        icon = Icons.bar_chart_rounded;
        break;
      case 'Settings':
        icon = Icons.settings_rounded;
        break;
      default:
        icon = Icons.circle;
    }
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 22, color: color),
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
    );
  }
}
