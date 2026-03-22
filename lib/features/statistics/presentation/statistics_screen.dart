import 'package:flutter/material.dart';
import 'package:bloom_habit/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/router/app_providers.dart';
import '../../../core/utils/habit_icon_color.dart';
import '../../../data/local/entity/local_habit.dart';

class StatisticsScreen extends ConsumerStatefulWidget {
  const StatisticsScreen({super.key});

  @override
  ConsumerState<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends ConsumerState<StatisticsScreen> with SingleTickerProviderStateMixin {
  List<LocalHabit> _habits = [];
  Map<String, int> _streaks = {};
  Map<String, bool> _todayCompleted = {};
  Map<String, int> _weekCompleted = {};
  Map<String, int> _monthCompleted = {};
  bool _loading = true;
  late TabController _tabController;
  int _sevenDayCompleted = 0;
  int _sevenDayPossible = 0;
  int _sevenDayPercent = 0;
  int _weekSuccessCompleted = 0;
  int _weekSuccessPossible = 0;
  int _weekSuccessPercent = 0;
  int _monthSuccessCompleted = 0;
  int _monthSuccessPossible = 0;
  int _monthSuccessPercent = 0;

  /// Week tab: selected week's Monday (local).
  DateTime _selectedWeekStart = _thisWeekMonday();
  /// Month tab: selected year/month.
  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;

  static DateTime _thisWeekMonday() {
    final now = DateTime.now();
    final weekday = now.weekday; // 1=Mon .. 7=Sun
    return DateTime(now.year, now.month, now.day - (weekday - 1));
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final repo = ref.read(habitRepositoryProvider);
    final habits = await repo.getActiveHabits();
    final completed = await repo.getTodayCompletedByHabit();
    final weekEnd = _selectedWeekStart.add(const Duration(days: 6));
    final weekCompleted = await repo.getCompletedCountByHabitForDateRange(_selectedWeekStart, weekEnd);
    final monthStart = DateTime(_selectedYear, _selectedMonth, 1);
    final monthEnd = DateTime(_selectedYear, _selectedMonth + 1, 0); // last day of selected month
    final monthCompleted = await repo.getCompletedCountByHabitForDateRange(monthStart, monthEnd);
    final weekSuccess = await repo.getSuccessRateForDateRange(_selectedWeekStart, weekEnd);
    final monthSuccess = await repo.getSuccessRateForDateRange(monthStart, monthEnd);
    final streaks = <String, int>{};
    for (final h in habits) {
      if (h.serverId != null) {
        streaks[h.serverId!] = await repo.getStreakDays(h.serverId!);
      }
    }
    final sevenDay = await repo.getRolling7DaySuccessRate();
    if (mounted) {
      setState(() {
        _habits = habits;
        _todayCompleted = completed;
        _weekCompleted = weekCompleted;
        _monthCompleted = monthCompleted;
        _streaks = streaks;
        _sevenDayCompleted = sevenDay.completed;
        _sevenDayPossible = sevenDay.possible;
        _sevenDayPercent = sevenDay.percent;
        _weekSuccessCompleted = weekSuccess.completed;
        _weekSuccessPossible = weekSuccess.possible;
        _weekSuccessPercent = weekSuccess.percent;
        _monthSuccessCompleted = monthSuccess.completed;
        _monthSuccessPossible = monthSuccess.possible;
        _monthSuccessPercent = monthSuccess.percent;
        _loading = false;
      });
    }
  }

  void _prevWeek() {
    setState(() => _selectedWeekStart = _selectedWeekStart.subtract(const Duration(days: 7)));
    _load();
  }

  void _nextWeek() {
    setState(() => _selectedWeekStart = _selectedWeekStart.add(const Duration(days: 7)));
    _load();
  }

  void _prevMonth() {
    setState(() {
      if (_selectedMonth == 1) {
        _selectedYear--;
        _selectedMonth = 12;
      } else {
        _selectedMonth--;
      }
    });
    _load();
  }

  void _nextMonth() {
    setState(() {
      if (_selectedMonth == 12) {
        _selectedYear++;
        _selectedMonth = 1;
      } else {
        _selectedMonth++;
      }
    });
    _load();
  }

  String _weekRangeLabel() {
    final end = _selectedWeekStart.add(const Duration(days: 6));
    return '${_selectedWeekStart.month.toString().padLeft(2, '0')}.${_selectedWeekStart.day.toString().padLeft(2, '0')} ~ '
        '${end.month.toString().padLeft(2, '0')}.${end.day.toString().padLeft(2, '0')}';
  }

  String _monthLabel(AppLocalizations l10n) => l10n.yearMonth(_selectedYear, _selectedMonth);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final completedCount = _todayCompleted.values.where((v) => v).length;
    final weekTotal = _weekCompleted.values.fold<int>(0, (a, b) => a + b);
    final monthTotal = _monthCompleted.values.fold<int>(0, (a, b) => a + b);

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: AppBar(
        title: Text(
          l10n.navStats,
          style: GoogleFonts.dmSans(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: isDark ? AppColors.primaryDark : AppColors.primary,
          unselectedLabelColor: AppColors.mutedFg(isDark),
          tabs: [
            Tab(text: l10n.day),
            Tab(text: l10n.week),
            Tab(text: l10n.month),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _load,
              color: AppColors.primary,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildDayTab(isDark, completedCount),
                  _buildWeekTab(isDark, weekTotal, l10n),
                  _buildMonthTab(isDark, monthTotal, l10n),
                ],
              ),
            ),
    );
  }

  Widget _buildDayTab(bool isDark, int completedCount) {
    final l10n = AppLocalizations.of(context)!;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.todaySummary,
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.mutedFg(isDark),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _SummaryChip(
                      label: l10n.totalHabits,
                      value: l10n.countItems(_habits.length),
                    ),
                    const SizedBox(width: 16),
                    _SummaryChip(
                      label: l10n.todayCompleted,
                      value: l10n.countItems(completedCount),
                      valueColor: AppColors.primary,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.last7DaysSuccessRate,
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.mutedFg(isDark),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.last7DaysSuccessRateDescription,
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    height: 1.4,
                    color: AppColors.mutedFg(isDark),
                  ),
                ),
                const SizedBox(height: 16),
                if (_sevenDayPossible == 0)
                  Text(
                    l10n.noActiveHabitsForRate,
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      color: AppColors.mutedFg(isDark),
                    ),
                  )
                else ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.achieved,
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.foregroundDark : AppColors.foreground,
                        ),
                      ),
                      Text(
                        '$_sevenDayPercent%',
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: _sevenDayPercent / 100,
                      minHeight: 10,
                      backgroundColor: isDark ? AppColors.mutedDark : AppColors.muted,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.successPairCount(_sevenDayCompleted, _sevenDayPossible),
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      color: AppColors.mutedFg(isDark),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        _buildRestOfStatistics(isDark),
      ],
    );
  }

  bool get _canGoNextWeek {
    return _selectedWeekStart.isBefore(_thisWeekMonday());
  }

  bool get _canGoNextMonth {
    final now = DateTime.now();
    return _selectedYear < now.year ||
        (_selectedYear == now.year && _selectedMonth < now.month);
  }

  Widget _buildWeekTab(bool isDark, int totalCompleted, AppLocalizations l10n) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _PeriodSelector(
          label: _weekRangeLabel(),
          onPrev: _prevWeek,
          onNext: _canGoNextWeek ? _nextWeek : null,
          isDark: isDark,
        ),
        const SizedBox(height: 16),
        _buildPeriodCard(isDark, l10n.weeklySummary, totalCompleted, l10n),
        const SizedBox(height: 16),
        _buildSuccessRateBlock(
          isDark,
          title: l10n.weeklySuccessRate,
          description: l10n.weeklySuccessRateDescription,
          completed: _weekSuccessCompleted,
          possible: _weekSuccessPossible,
          percent: _weekSuccessPercent,
        ),
        const SizedBox(height: 24),
        _buildHabitCompletionList(isDark, _weekCompleted),
      ],
    );
  }

  Widget _buildMonthTab(bool isDark, int totalCompleted, AppLocalizations l10n) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _PeriodSelector(
          label: _monthLabel(l10n),
          onPrev: _prevMonth,
          onNext: _canGoNextMonth ? _nextMonth : null,
          isDark: isDark,
        ),
        const SizedBox(height: 16),
        _buildPeriodCard(isDark, l10n.monthlySummary, totalCompleted, l10n),
        const SizedBox(height: 16),
        _buildSuccessRateBlock(
          isDark,
          title: l10n.monthlySuccessRate,
          description: l10n.monthlySuccessRateDescription,
          completed: _monthSuccessCompleted,
          possible: _monthSuccessPossible,
          percent: _monthSuccessPercent,
        ),
        const SizedBox(height: 24),
        _buildHabitCompletionList(isDark, _monthCompleted),
      ],
    );
  }

  Widget _buildSuccessRateBlock(
    bool isDark, {
    required String title,
    required String description,
    required int completed,
    required int possible,
    required int percent,
  }) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.dmSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.mutedFg(isDark),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: GoogleFonts.dmSans(
                fontSize: 12,
                height: 1.4,
                color: AppColors.mutedFg(isDark),
              ),
            ),
            const SizedBox(height: 16),
            if (possible == 0)
              Text(
                l10n.noActiveHabitsForRate,
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  color: AppColors.mutedFg(isDark),
                ),
              )
            else ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.achieved,
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.foregroundDark : AppColors.foreground,
                    ),
                  ),
                  Text(
                    '$percent%',
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: percent / 100,
                  minHeight: 10,
                  backgroundColor: isDark ? AppColors.mutedDark : AppColors.muted,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.successPairCount(completed, possible),
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  color: AppColors.mutedFg(isDark),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodCard(bool isDark, String periodLabel, int totalCompleted, AppLocalizations l10n) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              periodLabel,
              style: GoogleFonts.dmSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.mutedFg(isDark),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _SummaryChip(
                  label: l10n.totalHabits,
                  value: l10n.countItems(_habits.length),
                ),
                const SizedBox(width: 16),
                _SummaryChip(
                  label: l10n.completedCountLabel,
                  value: l10n.countTimes(totalCompleted),
                  valueColor: AppColors.primary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHabitCompletionList(bool isDark, Map<String, int> byHabit) {
    final l10n = AppLocalizations.of(context)!;
    final textColor = isDark ? AppColors.foregroundDark : AppColors.foreground;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.completedByHabit,
          style: GoogleFonts.dmSans(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        const SizedBox(height: 12),
        if (_habits.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text(
                  l10n.noHabitsYet,
                  style: GoogleFonts.dmSans(fontSize: 15, color: AppColors.mutedFg(isDark)),
                ),
              ),
            ),
          )
        else
          ..._habits.map((h) {
            final count = byHabit[h.serverId] ?? 0;
            final habitColor = habitColorFromHex(h.colorHex);
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: habitColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    habitIconFromName(h.iconName),
                    size: 18,
                    color: habitColor,
                  ),
                ),
                title: Text(
                  h.name ?? '',
                  style: GoogleFonts.dmSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                ),
                trailing: Text(
                  l10n.countTimes(count),
                  style: GoogleFonts.dmSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: habitColor,
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildRestOfStatistics(bool isDark) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
                  const SizedBox(height: 24),
                  Text(
                    l10n.streakByHabit,
                    style: GoogleFonts.dmSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.foregroundDark : AppColors.foreground,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_habits.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Center(
                          child: Text(
                            l10n.noHabitsYet,
                            style: GoogleFonts.dmSans(
                              fontSize: 15,
                              color: AppColors.mutedFg(isDark),
                            ),
                          ),
                        ),
                      ),
                    )
                  else
                    ..._habits.map((h) {
                      final streak = _streaks[h.serverId] ?? 0;
                      final done = _todayCompleted[h.serverId] ?? false;
                      final habitColor = habitColorFromHex(h.colorHex);
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: habitColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              habitIconFromName(h.iconName),
                              size: 18,
                              color: habitColor,
                            ),
                          ),
                          title: Text(
                            h.name ?? '',
                            style: GoogleFonts.dmSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: isDark ? AppColors.foregroundDark : AppColors.foreground,
                            ),
                          ),
                          subtitle: h.category != null && h.category!.isNotEmpty
                              ? Text(
                                  h.category!,
                                  style: GoogleFonts.dmSans(
                                    fontSize: 13,
                                    color: AppColors.mutedFg(isDark),
                                  ),
                                )
                              : null,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (done)
                                Icon(Icons.check_circle, size: 20, color: habitColor),
                              const SizedBox(width: 8),
                              Text(
                                l10n.daysCount(streak),
                                style: GoogleFonts.dmSans(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: habitColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
      ],
    );
  }
}

class _PeriodSelector extends StatelessWidget {
  const _PeriodSelector({
    required this.label,
    required this.onPrev,
    required this.onNext,
    required this.isDark,
  });

  final String label;
  final VoidCallback onPrev;
  final VoidCallback? onNext;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? AppColors.foregroundDark : AppColors.foreground;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: onPrev,
          icon: const Icon(Icons.chevron_left),
          color: isDark ? AppColors.primaryDark : AppColors.primary,
          style: IconButton.styleFrom(
            backgroundColor: (isDark ? AppColors.primaryDark : AppColors.primary).withValues(alpha: 0.12),
          ),
        ),
        Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        IconButton(
          onPressed: onNext,
          icon: const Icon(Icons.chevron_right),
          color: onNext != null
              ? (isDark ? AppColors.primaryDark : AppColors.primary)
              : AppColors.mutedFg(isDark),
          style: IconButton.styleFrom(
            backgroundColor: (isDark ? AppColors.primaryDark : AppColors.primary).withValues(alpha: 0.12),
          ),
        ),
      ],
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.backgroundDark.withValues(alpha: 0.72)
              : AppColors.muted.withValues(alpha: 0.5),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.border,
          ),
          borderRadius: BorderRadius.circular(AppTheme.radius),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 12,
                color: AppColors.mutedFg(isDark),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.dmSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: valueColor ?? (Theme.of(context).brightness == Brightness.dark
                    ? AppColors.foregroundDark
                    : AppColors.foreground),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
