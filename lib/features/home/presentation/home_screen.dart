import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bloom_habit/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';


import '../../../core/theme/app_theme.dart';
import '../../../core/router/app_providers.dart';
import '../../../core/router/app_router.dart';
import '../../../core/notifications/notification_service.dart';
import '../../../core/utils/habit_icon_color.dart';
import '../../../core/widget/home_widget_update.dart';
import '../../../data/local/entity/local_habit.dart';

/// Figma Home Dashboard (new style) color constants.
class _DashboardColors {
  static const Color background = Color(0xFFF0F8FF);
  static const Color primary = Color(0xFF22C55E);
  static const Color border = Color(0xFFD9DFE4);
  static const Color text = Color(0xFF374151);
  static const Color textMuted = Color(0xFF6B727E);
  static const Color progressTrack = Color(0xFFE6ECF2);
  static const Color iconBg = Color(0xFFDCE9DE);
  static const Color card = Color(0xFFFFFFFF);
}

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  static bool _remindersRescheduled = false;

  List<LocalHabit> _habits = [];
  Map<String, bool> _todayCompleted = {};
  Map<String, int> _heatmapCounts = {};
  /// Currently displayed heatmap month (based on day 1).
  DateTime _heatmapMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
  int _heatmapSlideDirection = 1; // 1: next month, -1: previous month
  bool _loading = true;
  String? _error;

  bool get _canGoNextHeatmap {
    final now = DateTime.now();
    final cur = DateTime(now.year, now.month, 1);
    return _heatmapMonth.isBefore(cur);
  }

  int _completedCountForActiveHabits(
    List<LocalHabit> habits,
    Map<String, bool> completedByHabit,
  ) {
    var count = 0;
    for (final h in habits) {
      final sid = h.serverId;
      if (sid == null) continue;
      if (completedByHabit[sid] == true) count++;
    }
    return count;
  }

  Future<void> _rescheduleRemindersOnce(List<LocalHabit> habits) async {
    if (_remindersRescheduled) return;
    _remindersRescheduled = true;
    await NotificationService().rescheduleFromHabits(habits);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = ref.read(habitRepositoryProvider);
      final authRepo = ref.read(authRepositoryProvider);
      await repo.syncFromServer();
      if (!mounted) return;
      final habits = await repo.getActiveHabits();
      final completed = await repo.getTodayCompletedByHabit();
      final heatmapStart = DateTime(_heatmapMonth.year, _heatmapMonth.month, 1);
      final heatmapEnd = DateTime(_heatmapMonth.year, _heatmapMonth.month + 1, 0);
      final heatmapCounts = await repo.getCompletionCountsForDateRange(heatmapStart, heatmapEnd);
      if (mounted) {
        setState(() {
          _habits = habits;
          _todayCompleted = completed;
          _heatmapCounts = heatmapCounts;
          _loading = false;
        });
        _rescheduleRemindersOnce(habits);
        final completedCount = _completedCountForActiveHabits(habits, completed);
        updateHomeWidget(todayCompleted: completedCount, totalHabits: habits.length);
        await authRepo.registerFcmToken();
      }
    } catch (e) {
      if (mounted) {
        final msg = e.toString();
        final isConnectionError = msg.contains('connection timeout') ||
            msg.contains('connection error') ||
            msg.contains('Connection refused') ||
            msg.contains('ConnectionTimeout') ||
            msg.contains('DioException [unknown]') ||
            (msg.contains('DioException') && msg.endsWith('null'));
        setState(() {
          _loading = false;
          _error = isConnectionError
              ? AppLocalizations.of(context)!.connectionErrorMessage
              : msg.split('\n').first;
        });
      }
    }
  }

  Future<Map<String, int>> _loadHeatmapCountsFor(DateTime month) async {
    final repo = ref.read(habitRepositoryProvider);
    final heatmapStart = DateTime(month.year, month.month, 1);
    final heatmapEnd = DateTime(month.year, month.month + 1, 0);
    return repo.getCompletionCountsForDateRange(heatmapStart, heatmapEnd);
  }

  Future<void> _prevHeatmapMonth() async {
    final targetMonth = DateTime(_heatmapMonth.year, _heatmapMonth.month - 1, 1);
    final nextCounts = await _loadHeatmapCountsFor(targetMonth);
    if (!mounted) return;
    setState(() {
      _heatmapSlideDirection = -1;
      _heatmapMonth = targetMonth;
      _heatmapCounts = nextCounts;
    });
  }

  Future<void> _nextHeatmapMonth() async {
    if (!_canGoNextHeatmap) return;
    final targetMonth = DateTime(_heatmapMonth.year, _heatmapMonth.month + 1, 1);
    final nextCounts = await _loadHeatmapCountsFor(targetMonth);
    if (!mounted) return;
    setState(() {
      _heatmapSlideDirection = 1;
      _heatmapMonth = targetMonth;
      _heatmapCounts = nextCounts;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    ref.listen<int>(homeRefreshTriggerProvider, (prev, next) {
      if (prev != null && next != prev && mounted) _load();
    });

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.backgroundDark : _DashboardColors.background;
    final primary = isDark ? AppColors.primaryDark : _DashboardColors.primary;
    final text = isDark ? AppColors.foregroundDark : _DashboardColors.text;
    final textMuted = isDark ? AppColors.mutedForeground : _DashboardColors.textMuted;
    final cardColor = isDark ? AppColors.cardDark : _DashboardColors.card;
    final border = isDark ? AppColors.borderDark : _DashboardColors.border;
    final progressTrack = isDark ? AppColors.mutedDark : _DashboardColors.progressTrack;
    final iconBg = isDark ? AppColors.accent : _DashboardColors.iconBg;
    final completedTodayCount = _completedCountForActiveHabits(_habits, _todayCompleted);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: _load,
                color: primary,
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(color: AppColors.primary),
                      )
                    : _error != null
                        ? _ErrorBody(error: _error!, onRetry: _load, l10n: l10n)
                        : ListView(
                            padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                            children: [
                              _TodayProgressCard(
                                completedToday: completedTodayCount,
                                totalHabits: _habits.length,
                                l10n: l10n,
                                cardColor: cardColor,
                                border: border,
                                primary: primary,
                                text: text,
                                textMuted: textMuted,
                                progressTrack: progressTrack,
                                iconBg: iconBg,
                              ),
                              const SizedBox(height: 24),
                              _TodaySection(
                                habits: _habits,
                                todayCompleted: _todayCompleted,
                                l10n: l10n,
                                onAddNew: () => context.push(AppRoutes.habitCreate),
                                onTapHabit: (h) => context.push(
                                  '${AppRoutes.habitDetail}/${h.serverId}',
                                  extra: h,
                                ),
                                onRecord: (h) => _recordHabit(h),
                                cardColor: cardColor,
                                border: border,
                                primary: primary,
                                text: text,
                                textMuted: textMuted,
                                iconBg: iconBg,
                              ),
                              const SizedBox(height: 24),
                              _HeatmapSection(
                                displayMonthStart: _heatmapMonth,
                                slideDirection: _heatmapSlideDirection,
                                l10n: l10n,
                                completedCounts: _heatmapCounts,
                                onPrevMonth: _prevHeatmapMonth,
                                onNextMonth: _canGoNextHeatmap ? _nextHeatmapMonth : null,
                                cardColor: cardColor,
                                border: border,
                                primary: primary,
                                text: text,
                                textMuted: textMuted,
                                progressTrack: progressTrack,
                              ),
                            ],
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _recordHabit(LocalHabit h) async {
    if (h.serverId == null) return;
    final sid = h.serverId!;
    try {
      // Reflect completion immediately (optimistic update).
      setState(() {
        _todayCompleted = Map<String, bool>.from(_todayCompleted)..[sid] = true;
      });
      final repo = ref.read(habitRepositoryProvider);
      await repo.recordToday(sid);
      final settings = ref.read(appSettingsProvider).value;
      if (settings?.hapticEnabled ?? true) HapticFeedback.mediumImpact();
      if (settings?.soundEnabled ?? true) SystemSound.play(SystemSoundType.click);
      if (!context.mounted) return;
      // Refresh list and heatmap after server/local persistence.
      await _load();
    } catch (_) {
      // Roll back optimistic completion on failure.
      if (mounted) {
        setState(() {
          _todayCompleted = Map<String, bool>.from(_todayCompleted)..remove(sid);
        });
      }
    }
  }

}

class _TodayProgressCard extends StatelessWidget {
  const _TodayProgressCard({
    required this.completedToday,
    required this.totalHabits,
    required this.l10n,
    required this.cardColor,
    required this.border,
    required this.primary,
    required this.text,
    required this.textMuted,
    required this.progressTrack,
    required this.iconBg,
  });

  final int completedToday;
  final int totalHabits;
  final AppLocalizations l10n;
  final Color cardColor;
  final Color border;
  final Color primary;
  final Color text;
  final Color textMuted;
  final Color progressTrack;
  final Color iconBg;

  @override
  Widget build(BuildContext context) {
    final total = totalHabits > 0 ? totalHabits : 1;
    final pct = (completedToday / total * 100).round().clamp(0, 100);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(AppTheme.radius),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 68,
                height: 68,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: iconBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.local_florist_outlined, size: 32, color: primary),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.todayProgressTitle,
                      style: GoogleFonts.lora(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        fontStyle: FontStyle.italic,
                        color: text,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.todayProgressDescription,
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        color: textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.todayProgressLabel,
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: text,
                ),
              ),
              Text(
                '$pct%',
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: pct / 100,
              minHeight: 10,
              backgroundColor: progressTrack,
              valueColor: AlwaysStoppedAnimation<Color>(primary),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.completedHabitCount(completedToday, totalHabits),
            style: GoogleFonts.dmSans(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _TodaySection extends StatelessWidget {
  const _TodaySection({
    required this.habits,
    required this.todayCompleted,
    required this.l10n,
    required this.onAddNew,
    required this.onTapHabit,
    required this.onRecord,
    required this.cardColor,
    required this.border,
    required this.primary,
    required this.text,
    required this.textMuted,
    required this.iconBg,
  });

  final List<LocalHabit> habits;
  final Map<String, bool> todayCompleted;
  final AppLocalizations l10n;
  final VoidCallback onAddNew;
  final void Function(LocalHabit) onTapHabit;
  final void Function(LocalHabit) onRecord;
  final Color cardColor;
  final Color border;
  final Color primary;
  final Color text;
  final Color textMuted;
  final Color iconBg;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.todayHabitsTitle,
              style: GoogleFonts.lora(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                fontStyle: FontStyle.italic,
                color: text,
              ),
            ),
            TextButton(
              onPressed: onAddNew,
              style: TextButton.styleFrom(
                foregroundColor: primary,
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                l10n.addNewHabit,
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (habits.isEmpty)
          _EmptyHabitsCard(
            l10n: l10n,
            onAddNew: onAddNew,
            cardColor: cardColor,
            border: border,
            primary: primary,
            text: text,
            textMuted: textMuted,
          )
        else
          ...habits.map(
            (h) => _DashboardHabitCard(
              habit: h,
              completed: todayCompleted[h.serverId] ?? false,
              onTap: () => onTapHabit(h),
              onRecord: () => onRecord(h),
              cardColor: cardColor,
              border: border,
              primary: primary,
              text: text,
              textMuted: textMuted,
              iconBg: iconBg,
            ),
          ),
      ],
    );
  }
}

class _DashboardHabitCard extends StatelessWidget {
  const _DashboardHabitCard({
    required this.habit,
    required this.completed,
    required this.onTap,
    required this.onRecord,
    required this.cardColor,
    required this.border,
    required this.primary,
    required this.text,
    required this.textMuted,
    required this.iconBg,
  });

  final LocalHabit habit;
  final bool completed;
  final VoidCallback onTap;
  final VoidCallback onRecord;
  final Color cardColor;
  final Color border;
  final Color primary;
  final Color text;
  final Color textMuted;
  final Color iconBg;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: cardColor,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radius),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(
                color: completed ? primary : border,
                width: completed ? 2 : 1,
              ),
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
                    habitIconFromName(habit.iconName),
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
                        style: GoogleFonts.dmSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: text,
                        ),
                      ),
                      if (habit.category != null && habit.category!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          habit.category!,
                          style: GoogleFonts.dmSans(
                            fontSize: 12,
                            color: textMuted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                InkWell(
                  onTap: completed ? null : onRecord,
                  customBorder: const CircleBorder(),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: completed
                        ? Icon(Icons.check_circle, size: 32, color: primary)
                        : Icon(Icons.check_circle_outline, size: 32, color: border),
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

class _EmptyHabitsCard extends StatelessWidget {
  const _EmptyHabitsCard({
    required this.l10n,
    required this.onAddNew,
    required this.cardColor,
    required this.border,
    required this.primary,
    required this.text,
    required this.textMuted,
  });

  final AppLocalizations l10n;
  final VoidCallback onAddNew;
  final Color cardColor;
  final Color border;
  final Color primary;
  final Color text;
  final Color textMuted;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppTheme.radius);
    return Semantics(
      button: true,
      label: l10n.addNewHabit,
      child: SizedBox(
        width: double.infinity,
        child: Material(
          color: cardColor,
          borderRadius: radius,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onAddNew,
            borderRadius: radius,
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                border: Border.all(color: border),
                borderRadius: radius,
              ),
              child: Column(
                children: [
                  Icon(Icons.add_circle_outline, size: 48, color: primary),
                  const SizedBox(height: 16),
                  Text(
                    l10n.emptyHabitTitle,
                    style: GoogleFonts.dmSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: text,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.emptyHabitDescription,
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      color: textMuted,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeatmapSection extends StatelessWidget {
  const _HeatmapSection({
    required this.displayMonthStart,
    required this.slideDirection,
    required this.l10n,
    required this.completedCounts,
    required this.onPrevMonth,
    required this.onNextMonth,
    required this.cardColor,
    required this.border,
    required this.primary,
    required this.text,
    required this.textMuted,
    required this.progressTrack,
  });

  final DateTime displayMonthStart;
  final int slideDirection;
  final AppLocalizations l10n;
  final Map<String, int> completedCounts;
  final VoidCallback onPrevMonth;
  final VoidCallback? onNextMonth;
  final Color cardColor;
  final Color border;
  final Color primary;
  final Color text;
  final Color textMuted;
  final Color progressTrack;

  static String _dateKey(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  static bool _isFutureCalendarDay(DateTime day, DateTime todayCal) {
    final d = DateTime(day.year, day.month, day.day);
    final t = DateTime(todayCal.year, todayCal.month, todayCal.day);
    return d.isAfter(t);
  }

  /// 0 completion uses track color, positive values scale light->strong green.
  Color _colorForCount(int count, int maxCount) {
    if (count <= 0) return progressTrack;
    if (maxCount <= 1) return primary;
    final lightGreen = Color.lerp(progressTrack, primary, 0.35)!;
    final t = (count - 1) / (maxCount - 1);
    return Color.lerp(lightGreen, primary, t.clamp(0.0, 1.0))!;
  }

  @override
  Widget build(BuildContext context) {
    final y = displayMonthStart.year;
    final m = displayMonthStart.month;
    final firstDay = DateTime(y, m, 1);
    final lastDay = DateTime(y, m + 1, 0);
    final daysInMonth = lastDay.day;
    final leading = firstDay.weekday - 1; // Monday-based week start
    final now = DateTime.now();
    final todayCal = DateTime(now.year, now.month, now.day);

    var maxCount = 0;
    for (var day = 1; day <= daysInMonth; day++) {
      final d = DateTime(y, m, day);
      if (_isFutureCalendarDay(d, todayCal)) continue;
      final c = completedCounts[_dateKey(d)] ?? 0;
      if (c > maxCount) maxCount = c;
    }

    final totalCells = leading + daysInMonth;
    final rowCount = (totalCells + 6) ~/ 7;
    final paddedCells = rowCount * 7;

    final dayLabels = [
      l10n.weekdayMon,
      l10n.weekdayTue,
      l10n.weekdayWed,
      l10n.weekdayThu,
      l10n.weekdayFri,
      l10n.weekdaySat,
      l10n.weekdaySun,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.completedHeatmapTitle,
          style: GoogleFonts.lora(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            fontStyle: FontStyle.italic,
            color: text,
          ),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onHorizontalDragEnd: (details) {
            final v = details.primaryVelocity ?? 0;
            if (v.abs() < 200) return;
            if (v < 0 && onNextMonth != null) {
              onNextMonth!.call();
              return;
            }
            if (v > 0) onPrevMonth();
          },
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cardColor,
              border: Border.all(color: border),
              borderRadius: BorderRadius.circular(AppTheme.radius),
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 360),
              switchInCurve: Curves.easeInOutCubic,
              switchOutCurve: Curves.easeInOutCubic,
              transitionBuilder: (child, animation) {
                final beginX = slideDirection > 0 ? 1.0 : -1.0;
                final offsetAnim = Tween<Offset>(
                  begin: Offset(beginX, 0),
                  end: Offset.zero,
                ).animate(animation);
                return ClipRect(
                  child: SlideTransition(
                    position: offsetAnim,
                    child: FadeTransition(opacity: animation, child: child),
                  ),
                );
              },
              child: Column(
                key: ValueKey<String>('heatmap-$y-$m'),
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: onPrevMonth,
                        icon: const Icon(Icons.chevron_left),
                        color: primary,
                        style: IconButton.styleFrom(
                          backgroundColor: primary.withValues(alpha: 0.12),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          l10n.yearMonth(y, m),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.dmSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: text,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: onNextMonth,
                        icon: const Icon(Icons.chevron_right),
                        color: onNextMonth != null ? primary : textMuted,
                        style: IconButton.styleFrom(
                          backgroundColor: primary.withValues(alpha: onNextMonth != null ? 0.12 : 0.04),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: List.generate(
                      7,
                      (c) => Expanded(
                        child: Text(
                          dayLabels[c],
                          style: GoogleFonts.dmSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: textMuted,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 7,
                      mainAxisSpacing: 6,
                      crossAxisSpacing: 6,
                      childAspectRatio: 1,
                    ),
                    itemCount: paddedCells,
                    itemBuilder: (context, i) {
                      if (i < leading || i >= leading + daysInMonth) {
                        return const SizedBox.shrink();
                      }
                      final dayNum = i - leading + 1;
                      final d = DateTime(y, m, dayNum);
                      final isFuture = _isFutureCalendarDay(d, todayCal);
                      final count = isFuture ? 0 : (completedCounts[_dateKey(d)] ?? 0);
                      final cellColor = isFuture
                          ? progressTrack.withValues(alpha: 0.45)
                          : _colorForCount(count, maxCount);
                      return Container(
                        decoration: BoxDecoration(
                          color: cellColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '$dayNum',
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isFuture ? textMuted : text,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        l10n.heatmapLess,
                        style: GoogleFonts.dmSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: textMuted,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: progressTrack,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: primary.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: primary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l10n.heatmapMore,
                        style: GoogleFonts.dmSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.error, required this.onRetry, required this.l10n});

  final String error;
  final VoidCallback onRetry;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              error,
              style: GoogleFonts.dmSans(
                fontSize: 14,
                color: AppColors.destructive,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onRetry,
              child: Text(l10n.retry),
            ),
          ],
        ),
      ),
    );
  }
}
