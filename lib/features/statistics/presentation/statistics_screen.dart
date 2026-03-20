import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/router/app_providers.dart';
import '../../../core/utils/habit_icon_color.dart';
import '../../../data/habit/habit_repository.dart';
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
  List<AiFeedbackItem> _aiFeedback = [];
  bool _loading = true;
  late TabController _tabController;
  int _sevenDayCompleted = 0;
  int _sevenDayPossible = 0;
  int _sevenDayPercent = 0;

  /// 주 탭: 선택된 주의 월요일 (로컬)
  DateTime _selectedWeekStart = _thisWeekMonday();
  /// 월 탭: 선택된 연·월
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
    final monthEnd = DateTime(_selectedYear, _selectedMonth + 1, 0); // 해당 달 마지막 날
    final monthCompleted = await repo.getCompletedCountByHabitForDateRange(monthStart, monthEnd);
    final streaks = <String, int>{};
    for (final h in habits) {
      if (h.serverId != null) {
        streaks[h.serverId!] = await repo.getStreakDays(h.serverId!);
      }
    }
    final aiFeedback = await repo.getAiFeedbackList(limit: 20);
    final sevenDay = await repo.getRolling7DaySuccessRate();
    if (mounted) {
      setState(() {
        _habits = habits;
        _todayCompleted = completed;
        _weekCompleted = weekCompleted;
        _monthCompleted = monthCompleted;
        _streaks = streaks;
        _aiFeedback = aiFeedback;
        _sevenDayCompleted = sevenDay.completed;
        _sevenDayPossible = sevenDay.possible;
        _sevenDayPercent = sevenDay.percent;
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

  String _monthLabel() => '$_selectedYear년 $_selectedMonth월';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final completedCount = _todayCompleted.values.where((v) => v).length;
    final weekTotal = _weekCompleted.values.fold<int>(0, (a, b) => a + b);
    final monthTotal = _monthCompleted.values.fold<int>(0, (a, b) => a + b);

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: AppBar(
        title: Text(
          '통계',
          style: GoogleFonts.dmSans(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.mutedForeground,
          tabs: const [
            Tab(text: '일'),
            Tab(text: '주'),
            Tab(text: '월'),
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
                  _buildWeekTab(isDark, weekTotal),
                  _buildMonthTab(isDark, monthTotal),
                ],
              ),
            ),
    );
  }

  Widget _buildDayTab(bool isDark, int completedCount) {
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
                  '오늘의 요약',
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.mutedForeground,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _SummaryChip(
                      label: '전체 습관',
                      value: '${_habits.length}개',
                    ),
                    const SizedBox(width: 16),
                    _SummaryChip(
                      label: '오늘 완료',
                      value: '$completedCount개',
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
                  '최근 7일 성공률',
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.mutedForeground,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '오늘을 포함한 7일 동안, 활성 습관의 시작일 이후「해야 할 날」대비 완료한 날의 비율입니다.',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    height: 1.4,
                    color: AppColors.mutedForeground,
                  ),
                ),
                const SizedBox(height: 16),
                if (_sevenDayPossible == 0)
                  Text(
                    '활성 습관이 없으면 표시되지 않습니다.',
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      color: AppColors.mutedForeground,
                    ),
                  )
                else ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '달성',
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
                    '$_sevenDayCompleted / $_sevenDayPossible (습관·날 단위)',
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      color: AppColors.mutedForeground,
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

  Widget _buildWeekTab(bool isDark, int totalCompleted) {
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
        _buildPeriodCard(isDark, '주간 요약', totalCompleted),
        const SizedBox(height: 24),
        _buildHabitCompletionList(isDark, _weekCompleted),
      ],
    );
  }

  Widget _buildMonthTab(bool isDark, int totalCompleted) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _PeriodSelector(
          label: _monthLabel(),
          onPrev: _prevMonth,
          onNext: _canGoNextMonth ? _nextMonth : null,
          isDark: isDark,
        ),
        const SizedBox(height: 16),
        _buildPeriodCard(isDark, '월간 요약', totalCompleted),
        const SizedBox(height: 24),
        _buildHabitCompletionList(isDark, _monthCompleted),
      ],
    );
  }

  Widget _buildPeriodCard(bool isDark, String periodLabel, int totalCompleted) {
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
                color: AppColors.mutedForeground,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _SummaryChip(
                  label: '전체 습관',
                  value: '${_habits.length}개',
                ),
                const SizedBox(width: 16),
                _SummaryChip(
                  label: '완료 횟수',
                  value: '$totalCompleted회',
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
    final textColor = isDark ? AppColors.foregroundDark : AppColors.foreground;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '습관별 완료',
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
                  '등록된 습관이 없어요.',
                  style: GoogleFonts.dmSans(fontSize: 15, color: AppColors.mutedForeground),
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
                  '$count회',
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
                  if (_aiFeedback.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text(
                      'AI 피드백',
                      style: GoogleFonts.dmSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.foregroundDark : AppColors.foreground,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._aiFeedback.take(20).map((f) {
                      final dateStr = f.recordDate.length >= 10
                          ? f.recordDate
                          : f.createdAt.length >= 10
                              ? f.createdAt.substring(0, 10)
                              : f.recordDate;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    f.habitName,
                                    style: GoogleFonts.dmSans(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    dateStr,
                                    style: GoogleFonts.dmSans(
                                      fontSize: 12,
                                      color: AppColors.mutedForeground,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                f.responseText,
                                style: GoogleFonts.dmSans(
                                  fontSize: 15,
                                  color: isDark ? AppColors.foregroundDark : AppColors.foreground,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                  const SizedBox(height: 24),
                  Text(
                    '습관별 연속일',
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
                            '등록된 습관이 없어요.',
                            style: GoogleFonts.dmSans(
                              fontSize: 15,
                              color: AppColors.mutedForeground,
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
                                    color: AppColors.mutedForeground,
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
                                '$streak일',
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
          color: AppColors.primary,
          style: IconButton.styleFrom(
            backgroundColor: AppColors.primary.withValues(alpha: 0.12),
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
          color: onNext != null ? AppColors.primary : AppColors.mutedForeground,
          style: IconButton.styleFrom(
            backgroundColor: AppColors.primary.withValues(alpha: 0.12),
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
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.muted.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(AppTheme.radius),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 12,
                color: AppColors.mutedForeground,
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
