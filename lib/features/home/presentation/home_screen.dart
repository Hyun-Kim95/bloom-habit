import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

import 'package:lottie/lottie.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/router/app_providers.dart';
import '../../../core/router/app_router.dart';
import '../../../core/notifications/notification_service.dart';
import '../../../core/settings/app_settings.dart';
import '../../../core/utils/habit_icon_color.dart';
import '../../../core/widget/home_widget_update.dart';
import '../../../data/local/entity/local_habit.dart';

/// Figma Home Dashboard (New Style) 색상
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
  bool _loading = true;
  String? _error;

  String _buildShareText() {
    final links = <String>[
      if (StoreUrls.android.trim().isNotEmpty) 'Google Play: ${StoreUrls.android}',
      if (StoreUrls.ios.trim().isNotEmpty) 'App Store: ${StoreUrls.ios}',
    ];
    final linkText = links.isNotEmpty
        ? '\n\n${links.join('\n')}'
        : '\n\n스토어에서 "Bloom Habit"을 검색해 다운로드해 주세요!';
    return '습관 만들기, Bloom Habit과 함께 시작해 보세요.\n지금 바로 다운로드하세요!$linkText';
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
      final heatmapCounts = await repo.getLast28DaysCompletionCounts();
      if (mounted) {
        setState(() {
          _habits = habits;
          _todayCompleted = completed;
          _heatmapCounts = heatmapCounts;
          _loading = false;
        });
        _rescheduleRemindersOnce(habits);
        final completedCount = completed.values.where((v) => v).length;
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
              ? '서버에 연결할 수 없습니다.\n서버가 실행 중인지 확인하고, 에뮬레이터는 10.0.2.2:3000, 실기기는 같은 Wi-Fi의 PC IP로 연결해 보세요.'
              : msg.split('\n').first;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(
              onShare: () => Share.share(
                _buildShareText(),
                subject: 'Bloom Habit',
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _load,
                color: primary,
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(color: AppColors.primary),
                      )
                    : _error != null
                        ? _ErrorBody(error: _error!, onRetry: _load)
                        : ListView(
                            padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                            children: [
                              _TodayProgressCard(
                                completedToday: _todayCompleted.values.where((v) => v).length,
                                totalHabits: _habits.length,
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
                                onAddNew: () => context.go(AppRoutes.habitCreate),
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
                                completedCounts: _heatmapCounts,
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
      // 즉시 완료 상태 반영 (낙관적 업데이트)
      setState(() {
        _todayCompleted = Map<String, bool>.from(_todayCompleted)..[sid] = true;
      });
      final repo = ref.read(habitRepositoryProvider);
      final record = await repo.recordToday(sid);
      final settings = ref.read(appSettingsProvider).value;
      if (settings?.hapticEnabled ?? true) HapticFeedback.mediumImpact();
      if (settings?.soundEnabled ?? true) SystemSound.play(SystemSoundType.click);
      final comment = await repo.requestAiFeedback(sid, record.serverId ?? '');
      if (!context.mounted) return;
      // 서버/로컬 반영 후 목록·히트맵 다시 불러와서 화면 갱신
      await _load();
      if (!context.mounted) return;
      await _showAiCommentDialog(context, comment);
    } catch (_) {
      // 실패 시 방금 넣은 완료 표시 롤백
      if (mounted) {
        setState(() {
          _todayCompleted = Map<String, bool>.from(_todayCompleted)..remove(sid);
        });
      }
    }
  }

  Future<void> _showAiCommentDialog(BuildContext context, String comment) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.eco, color: AppColors.primary, size: 24),
            const SizedBox(width: 8),
            const Text('오늘 완료했어요!'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 100,
                width: 100,
                child: Lottie.network(
                  'https://assets2.lottiefiles.com/packages/lf20_yqcyqv2y.json',
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Icon(Icons.check_circle, size: 64, color: AppColors.primary),
                ),
              ),
              const SizedBox(height: 16),
              Text(comment),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onShare});

  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.cardDark : Colors.white;
    final textColor = isDark ? AppColors.foregroundDark : _DashboardColors.text;
    final border = isDark ? AppColors.borderDark : _DashboardColors.border;
    final muted = isDark ? AppColors.mutedForeground : _DashboardColors.textMuted;
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: cardColor,
            child: Icon(Icons.person_outline, color: muted, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Bloom Habit',
              style: GoogleFonts.lora(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                fontStyle: FontStyle.italic,
                color: textColor,
                letterSpacing: -0.45,
              ),
            ),
          ),
          Material(
            color: cardColor,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              onTap: onShare,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  border: Border.all(color: border),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Icon(Icons.share_outlined, size: 20, color: textColor),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TodayProgressCard extends StatelessWidget {
  const _TodayProgressCard({
    required this.completedToday,
    required this.totalHabits,
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
                      '오늘의 진행',
                      style: GoogleFonts.lora(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        fontStyle: FontStyle.italic,
                        color: text,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '오늘 목표 중 달성한 습관 비율이에요.',
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
                '오늘 달성률',
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
            '$completedToday / $totalHabits 습관 완료',
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
              "Today's Habits",
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
                'Add New',
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
            cardColor: cardColor,
            border: border,
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
    required this.cardColor,
    required this.border,
    required this.text,
    required this.textMuted,
  });

  final Color cardColor;
  final Color border;
  final Color text;
  final Color textMuted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: cardColor,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(AppTheme.radius),
      ),
      child: Column(
        children: [
          Icon(Icons.add_circle_outline, size: 48, color: textMuted),
          const SizedBox(height: 16),
          Text(
            '아직 습관이 없어요.',
            style: GoogleFonts.dmSans(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: text,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Add New로 첫 습관을 추가해 보세요.',
            style: GoogleFonts.dmSans(
              fontSize: 14,
              color: textMuted,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _HeatmapSection extends StatelessWidget {
  const _HeatmapSection({
    required this.completedCounts,
    required this.cardColor,
    required this.border,
    required this.primary,
    required this.text,
    required this.textMuted,
    required this.progressTrack,
  });

  final Map<String, int> completedCounts;
  final Color cardColor;
  final Color border;
  final Color primary;
  final Color text;
  final Color textMuted;
  final Color progressTrack;

  static String _dateKey(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  /// 완료 개수 0 = 배경색, 1이상 = 연한 초록(적을수록) ~ 진한 초록(많을수록)
  Color _colorForCount(int count, int maxCount) {
    if (count <= 0) return progressTrack;
    if (maxCount <= 1) return primary;
    final lightGreen = Color.lerp(progressTrack, primary, 0.35)!;
    final t = (count - 1) / (maxCount - 1);
    return Color.lerp(lightGreen, primary, t.clamp(0.0, 1.0))!;
  }

  @override
  Widget build(BuildContext context) {
    const cols = 7;
    const rows = 4;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = today.subtract(const Duration(days: 27));
    final dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final maxCount = completedCounts.values.isEmpty
        ? 0
        : completedCounts.values.reduce((a, b) => a > b ? a : b);

    // 열 = 요일(Mon=0 .. Sun=6), 행 = 해당 요일의 28일 내 순서(과거→최근)
    final grid = List.generate(rows, (_) => List.filled(cols, 0));
    for (int c = 0; c < cols; c++) {
      final weekday = c + 1; // Dart: Mon=1, Sun=7
      int row = 0;
      for (int i = 0; i < 28 && row < rows; i++) {
        final d = start.add(Duration(days: i));
        if (d.weekday == weekday) {
          grid[row][c] = completedCounts[_dateKey(d)] ?? 0;
          row++;
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Consistency Heatmap',
          style: GoogleFonts.lora(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            fontStyle: FontStyle.italic,
            color: text,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cardColor,
            border: Border.all(color: border),
            borderRadius: BorderRadius.circular(AppTheme.radius),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(
                  cols,
                  (c) => SizedBox(
                    width: 36,
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
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final cellSize = 36.0;
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(rows, (r) {
                      return Padding(
                        padding: EdgeInsets.only(bottom: r < rows - 1 ? 6 : 0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: List.generate(cols, (c) {
                            final count = grid[r][c];
                            final cellColor = _colorForCount(count, maxCount);
                            return Container(
                              width: cellSize - 2,
                              height: cellSize - 2,
                              decoration: BoxDecoration(
                                color: cellColor,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            );
                          }),
                        ),
                      );
                    }),
                  );
                },
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Less',
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
                      color: primary.withOpacity(0.5),
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
                    'More',
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
      ],
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.error, required this.onRetry});

  final String error;
  final VoidCallback onRetry;

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
              child: const Text('다시 시도'),
            ),
          ],
        ),
      ),
    );
  }
}
