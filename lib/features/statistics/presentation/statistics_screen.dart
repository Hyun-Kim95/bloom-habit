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
    final weekCompleted = await repo.getCompletedCountByHabitForDays(7);
    final monthCompleted = await repo.getCompletedCountByHabitForDays(30);
    final streaks = <String, int>{};
    for (final h in habits) {
      if (h.serverId != null) {
        streaks[h.serverId!] = await repo.getStreakDays(h.serverId!);
      }
    }
    final aiFeedback = await repo.getAiFeedbackList(limit: 20);
    if (mounted) {
      setState(() {
        _habits = habits;
        _todayCompleted = completed;
        _weekCompleted = weekCompleted;
        _monthCompleted = monthCompleted;
        _streaks = streaks;
        _aiFeedback = aiFeedback;
        _loading = false;
      });
    }
  }

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
                  _buildPeriodTab(isDark, '이번 주', weekTotal, _weekCompleted),
                  _buildPeriodTab(isDark, '이번 달', monthTotal, _monthCompleted),
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
        _buildRestOfStatistics(isDark),
      ],
    );
  }

  Widget _buildPeriodTab(bool isDark, String periodLabel, int totalCompleted, Map<String, int> byHabit) {
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
                  '$periodLabel 요약',
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
        ),
        const SizedBox(height: 24),
        Text(
          '습관별 완료',
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
                    color: isDark ? AppColors.foregroundDark : AppColors.foreground,
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
