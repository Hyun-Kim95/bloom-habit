import 'package:flutter/material.dart';
import 'package:bloom_habit/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/router/app_providers.dart';
import '../../../core/router/app_router.dart';
import '../../../core/utils/habit_icon_color.dart';
import '../../../data/local/entity/local_habit.dart';

/// Habit list screen shown on bottom Habits tab.
class HabitListScreen extends ConsumerStatefulWidget {
  const HabitListScreen({super.key});

  @override
  ConsumerState<HabitListScreen> createState() => _HabitListScreenState();
}

class _HabitListScreenState extends ConsumerState<HabitListScreen> {
  List<LocalHabit> _habits = [];
  List<LocalHabit> _hiddenHabits = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = ref.read(habitRepositoryProvider);
      await repo.syncFromServer();
      if (!mounted) return;
      final habits = await repo.getActiveHabits();
      final hiddenHabits = await repo.getHiddenHabits();
      if (mounted) {
        setState(() {
          _habits = habits;
          _hiddenHabits = hiddenHabits;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    ref.listen<int>(homeRefreshTriggerProvider, (prev, next) {
      if (prev != null && next != prev && mounted) _load();
    });
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.cardDark : AppColors.card;
    final border = isDark ? AppColors.borderDark : AppColors.border;
    final text = isDark ? AppColors.foregroundDark : AppColors.foreground;
    final textMuted = AppColors.mutedFg(isDark);
    final primary = AppColors.primary;
    const iconBg = Color(0xFFDCE9DE);

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: AppBar(
        title: Text(
          l10n.habitTitle,
          style: GoogleFonts.dmSans(fontSize: 18, fontWeight: FontWeight.w600, color: text),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => context.push(AppRoutes.habitCreate),
            icon: const Icon(Icons.add),
            tooltip: l10n.addHabit,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_error!, style: GoogleFonts.dmSans(fontSize: 14, color: AppColors.destructive)),
                        const SizedBox(height: 16),
                        FilledButton(onPressed: _load, child: Text(l10n.retry)),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: _habits.isEmpty && _hiddenHabits.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            const SizedBox(height: 48),
                            Icon(Icons.list_rounded, size: 64, color: textMuted),
                            const SizedBox(height: 16),
                            Text(
                              l10n.noHabitsRegistered,
                              style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w600, color: text),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              l10n.addHabitGuide,
                              style: GoogleFonts.dmSans(fontSize: 14, color: textMuted),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        )
                      : ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          children: [
                            if (_habits.isNotEmpty) ...[
                              Text(
                                l10n.activeHabits,
                                style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w700, color: textMuted),
                              ),
                              const SizedBox(height: 10),
                              ..._habits.map(
                                (h) => _HabitListItem(
                                  habit: h,
                                  cardColor: cardColor,
                                  border: border,
                                  primary: primary,
                                  text: text,
                                  textMuted: textMuted,
                                  iconBg: iconBg,
                                ),
                              ),
                            ],
                            if (_hiddenHabits.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Text(
                                l10n.hiddenHabits,
                                style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w700, color: textMuted),
                              ),
                              const SizedBox(height: 10),
                              ..._hiddenHabits.map(
                                (h) => _HabitListItem(
                                  habit: h,
                                  cardColor: cardColor,
                                  border: border,
                                  primary: primary,
                                  text: text,
                                  textMuted: textMuted,
                                  iconBg: iconBg,
                                  hidden: true,
                                ),
                              ),
                            ],
                          ],
                        ),
                ),
    );
  }
}

class _HabitListItem extends StatelessWidget {
  const _HabitListItem({
    required this.habit,
    required this.cardColor,
    required this.border,
    required this.primary,
    required this.text,
    required this.textMuted,
    required this.iconBg,
    this.hidden = false,
  });

  final LocalHabit habit;
  final Color cardColor;
  final Color border;
  final Color primary;
  final Color text;
  final Color textMuted;
  final Color iconBg;
  final bool hidden;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: cardColor,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        child: InkWell(
          onTap: () {
            if (habit.serverId != null) {
              context.push('${AppRoutes.habitDetail}/${habit.serverId}', extra: habit);
            }
          },
          borderRadius: BorderRadius.circular(AppTheme.radius),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: border),
              borderRadius: BorderRadius.circular(AppTheme.radius),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: habitColorFromHex(habit.colorHex, fallback: iconBg).withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(AppTheme.radius),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    hidden ? Icons.visibility_off_outlined : habitIconFromName(habit.iconName),
                    size: 20,
                    color: habitColorFromHex(habit.colorHex, fallback: primary),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        habit.name ?? '',
                        style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w700, color: text),
                      ),
                      if (habit.category != null && habit.category!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          habit.category!,
                          style: GoogleFonts.dmSans(fontSize: 12, color: textMuted),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
