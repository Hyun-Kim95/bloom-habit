import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/router/app_providers.dart';
import '../../../core/router/app_router.dart';
import '../../../core/notifications/notification_service.dart';
import '../../../core/utils/habit_icon_color.dart';
import '../../../data/habit/habit_repository.dart';
import '../../../data/local/entity/local_habit.dart';
import 'habit_edit_sheet.dart';

class HabitDetailScreen extends ConsumerStatefulWidget {
  const HabitDetailScreen({super.key, required this.habit});

  final LocalHabit habit;

  @override
  ConsumerState<HabitDetailScreen> createState() => _HabitDetailScreenState();
}

class _HabitDetailScreenState extends ConsumerState<HabitDetailScreen> {
  late LocalHabit _habit;
  int _streak = 0;
  bool _todayCompleted = false;
  bool _recording = false;
  bool _reminderEnabled = false;
  int _reminderHour = 9;
  int _reminderMinute = 0;
  bool _reminderSaving = false;
  List<RecordSummary> _recordHistory = [];
  bool _historyLoading = false;

  @override
  void initState() {
    super.initState();
    _habit = widget.habit;
    _loadStats();
    _loadRecordHistory();
  }

  Future<void> _loadStats() async {
    final repo = ref.read(habitRepositoryProvider);
    final completed = await repo.getTodayCompletedByHabit();
    final streak = await repo.getStreakDays(_habit.serverId ?? '');
    final habit = await repo.getHabitByServerId(_habit.serverId ?? '');
    if (mounted) {
      setState(() {
        _todayCompleted = completed[_habit.serverId] ?? false;
        _streak = streak;
        if (habit != null) {
          _habit = habit;
          _reminderEnabled = habit.reminderEnabled ?? false;
          _reminderHour = habit.reminderHour ?? 9;
          _reminderMinute = habit.reminderMinute ?? 0;
        }
      });
    }
  }

  Future<void> _loadRecordHistory() async {
    final sid = _habit.serverId;
    if (sid == null) return;
    setState(() => _historyLoading = true);
    final repo = ref.read(habitRepositoryProvider);
    final now = DateTime.now();
    final from = now.subtract(const Duration(days: 30));
    final list = await repo.getRecordHistory(sid, from: from, to: now);
    if (mounted) setState(() {
      _recordHistory = list;
      _historyLoading = false;
    });
  }

  Future<void> _recordToday() async {
    if (_todayCompleted || _recording) return;
    setState(() => _recording = true);
    try {
      final repo = ref.read(habitRepositoryProvider);
      final record = await repo.recordToday(
        _habit.serverId!,
        completed: true,
      );
      if (!mounted) return;
      setState(() => _todayCompleted = true);
      _loadRecordHistory();
      final settings = ref.read(appSettingsProvider).value;
      if (settings?.hapticEnabled ?? true) HapticFeedback.mediumImpact();
      if (settings?.soundEnabled ?? true) SystemSound.play(SystemSoundType.click);
      final comment = await repo.requestAiFeedback(
        _habit.serverId!,
        record.serverId ?? '',
      );
      if (!mounted) return;
      await _showAiCommentDialog(context, comment);
    } catch (_) {
      if (mounted) setState(() => _recording = false);
    }
  }

  Future<void> _openEdit() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final result = await showHabitEditSheet(context, habit: _habit, isDark: isDark);
    if (result == null || !mounted) return;
    try {
      final repo = ref.read(habitRepositoryProvider);
      await repo.updateHabit(
        _habit.serverId!,
        name: result.name,
        goalType: result.goalType,
        goalValue: result.goalValue,
        colorHex: result.colorHex,
        iconName: result.iconName,
      );
      final updated = await repo.getHabitByServerId(_habit.serverId!);
      if (mounted && updated != null) {
        setState(() => _habit = updated);
        ref.read(homeRefreshTriggerProvider.notifier).state++;
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('수정에 실패했어요. 다시 시도해 주세요.')),
        );
      }
    }
  }

  Future<void> _archive() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('습관 보관'),
        content: const Text('이 습관을 보관할까요? 보관한 습관은 홈 목록에서 숨겨지며, 보관함에서 다시 볼 수 있어요.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('보관하기')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await ref.read(habitRepositoryProvider).archiveHabit(_habit.serverId!);
      if (!mounted) return;
      ref.read(homeRefreshTriggerProvider.notifier).state++;
      context.go(AppRoutes.home);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('보관 처리에 실패했어요.')),
        );
      }
    }
  }

  Future<void> _onRecordAction(RecordSummary r, String action) async {
    if (action != 'delete') return;
    final recordId = r.recordId;
    final habitId = _habit.serverId;
    if (recordId == null || habitId == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('기록 삭제'),
        content: Text('${r.recordDate} 기록을 삭제할까요?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.destructive),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final repo = ref.read(habitRepositoryProvider);
    try {
      await repo.deleteRecord(habitId, recordId);
      if (!mounted) return;
      ref.read(homeRefreshTriggerProvider.notifier).state++;
      _loadRecordHistory();
      _loadStats();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('처리하지 못했어요. 다시 시도해 주세요.')),
        );
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

  @override
  Widget build(BuildContext context) {
    final h = _habit;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: AppBar(
        title: Text(
          h.name ?? '습관',
          style: GoogleFonts.dmSans(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'edit') await _openEdit();
              else if (value == 'archive') await _archive();
              else if (value == 'delete') await _confirmDelete();
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(value: 'edit', child: Text('수정')),
              const PopupMenuItem(value: 'archive', child: Text('보관하기')),
              const PopupMenuItem(value: 'delete', child: Text('삭제', style: TextStyle(color: AppColors.destructive))),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (h.category != null && h.category!.isNotEmpty) ...[
              Text(
                h.category!,
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  color: AppColors.mutedForeground,
                ),
              ),
              const SizedBox(height: 8),
            ],
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: habitColorFromHex(h.colorHex).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(AppTheme.radius),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    habitIconFromName(h.iconName),
                    size: 22,
                    color: habitColorFromHex(h.colorHex),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '$_streak일 연속',
                    style: GoogleFonts.lora(
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.foregroundDark : AppColors.foreground,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            if (_todayCompleted)
              Card(
                child: ListTile(
                  leading: Icon(
                    habitIconFromName(h.iconName),
                    color: habitColorFromHex(h.colorHex),
                    size: 28,
                  ),
                  title: Text(
                    '오늘 완료했어요!',
                    style: GoogleFonts.dmSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.foregroundDark : AppColors.foreground,
                    ),
                  ),
                ),
              )
            else
              SizedBox(
                height: 52,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: habitColorFromHex(h.colorHex),
                  ),
                  onPressed: _recording ? null : _recordToday,
                  child: _recording
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          '오늘 완료하기',
                          style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                ),
              ),
            const SizedBox(height: 32),
            _buildReminderSection(isDark),
            const SizedBox(height: 24),
            Text(
              '기록 히스토리',
              style: GoogleFonts.dmSans(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.foregroundDark : AppColors.foreground,
              ),
            ),
            const SizedBox(height: 12),
            if (_historyLoading)
              const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator(strokeWidth: 2)))
            else if (_recordHistory.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    '최근 30일 기록이 없어요.',
                    style: GoogleFonts.dmSans(fontSize: 14, color: AppColors.mutedForeground),
                  ),
                ),
              )
            else
              Card(
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _recordHistory.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final r = _recordHistory[i];
                    return ListTile(
                      title: Text(
                        r.recordDate,
                        style: GoogleFonts.dmSans(fontSize: 15),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (r.completed)
                            Icon(Icons.check_circle, color: habitColorFromHex(_habit.colorHex), size: 22)
                          else
                            Icon(Icons.cancel_outlined, color: AppColors.mutedForeground, size: 22),
                          if (r.recordId != null) ...[
                            const SizedBox(width: 8),
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert, size: 22),
                              onSelected: (value) => _onRecordAction(r, value),
                              itemBuilder: (ctx) => [
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Text('삭제', style: TextStyle(color: AppColors.destructive)),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('습관 삭제'),
        content: const Text('이 습관을 삭제할까요?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.destructive),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      await ref.read(habitRepositoryProvider).deleteHabit(_habit.serverId!);
      if (mounted) {
        ref.read(homeRefreshTriggerProvider.notifier).state++;
        context.go(AppRoutes.home);
      }
    }
  }

  Future<void> _saveReminder({required bool enabled, required int hour, required int minute}) async {
    final sid = _habit.serverId;
    if (sid == null) return;
    setState(() => _reminderSaving = true);
    try {
      final repo = ref.read(habitRepositoryProvider);
      await repo.updateLocalReminder(
        serverId: sid,
        enabled: enabled,
        hour: hour,
        minute: minute,
      );
      final habits = await repo.getActiveHabits();
      await NotificationService().rescheduleFromHabits(habits);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('저장됨'), duration: Duration(seconds: 2)),
        );
      }
    } finally {
      if (mounted) setState(() => _reminderSaving = false);
    }
  }

  Future<void> _toggleReminder(bool value) async {
    if (value) {
      final granted = await NotificationService().requestPermission();
      if (!granted && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('알림 권한이 필요합니다. 설정에서 허용해 주세요.')),
        );
        return;
      }
    }
    setState(() => _reminderEnabled = value);
    await _saveReminder(
      enabled: value,
      hour: _reminderHour,
      minute: _reminderMinute,
    );
  }

  Future<void> _pickReminderTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _reminderHour, minute: _reminderMinute),
    );
    if (picked != null && mounted) {
      setState(() {
        _reminderHour = picked.hour;
        _reminderMinute = picked.minute;
      });
      await _saveReminder(
        enabled: _reminderEnabled,
        hour: picked.hour,
        minute: picked.minute,
      );
    }
  }

  Widget _buildReminderSection(bool isDark) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SwitchListTile(
            value: _reminderEnabled,
            onChanged: _reminderSaving ? null : _toggleReminder,
            title: Text(
              '리마인더 알림',
              style: GoogleFonts.dmSans(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isDark ? AppColors.foregroundDark : AppColors.foreground,
              ),
            ),
            subtitle: Text(
              '매일 설정한 시간에 이 습관 알림',
              style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.mutedForeground),
            ),
            activeColor: AppColors.primary,
          ),
          ListTile(
            leading: const Icon(Icons.schedule, color: AppColors.primary),
            title: Text(
              '알림 시간',
              style: GoogleFonts.dmSans(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isDark ? AppColors.foregroundDark : AppColors.foreground,
              ),
            ),
            trailing: _reminderSaving
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    '${_reminderHour.toString().padLeft(2, '0')}:${_reminderMinute.toString().padLeft(2, '0')}',
                    style: GoogleFonts.dmSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
            onTap: _reminderEnabled && !_reminderSaving ? _pickReminderTime : null,
          ),
        ],
      ),
    );
  }
}
