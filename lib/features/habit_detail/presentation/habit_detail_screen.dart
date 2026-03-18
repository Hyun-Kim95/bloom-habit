import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/router/app_providers.dart';
import '../../../core/router/app_router.dart';
import '../../../core/notifications/notification_service.dart';
import '../../../data/local/entity/local_habit.dart';

class HabitDetailScreen extends ConsumerStatefulWidget {
  const HabitDetailScreen({super.key, required this.habit});

  final LocalHabit habit;

  @override
  ConsumerState<HabitDetailScreen> createState() => _HabitDetailScreenState();
}

class _HabitDetailScreenState extends ConsumerState<HabitDetailScreen> {
  int _streak = 0;
  bool _todayCompleted = false;
  bool _recording = false;
  bool _reminderEnabled = false;
  int _reminderHour = 9;
  int _reminderMinute = 0;
  bool _reminderSaving = false;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final repo = ref.read(habitRepositoryProvider);
    final completed = await repo.getTodayCompletedByHabit();
    final streak = await repo.getStreakDays(widget.habit.serverId ?? '');
    final habit = await repo.getHabitByServerId(widget.habit.serverId ?? '');
    if (mounted) {
      setState(() {
        _todayCompleted = completed[widget.habit.serverId] ?? false;
        _streak = streak;
        if (habit != null) {
          _reminderEnabled = habit.reminderEnabled ?? false;
          _reminderHour = habit.reminderHour ?? 9;
          _reminderMinute = habit.reminderMinute ?? 0;
        }
      });
    }
  }

  Future<void> _recordToday() async {
    if (_todayCompleted || _recording) return;
    setState(() => _recording = true);
    try {
      final repo = ref.read(habitRepositoryProvider);
      final record = await repo.recordToday(
        widget.habit.serverId!,
        completed: true,
      );
      if (!mounted) return;
      setState(() => _todayCompleted = true);
      final comment = await repo.requestAiFeedback(
        widget.habit.serverId!,
        record.serverId ?? '',
      );
      if (!mounted) return;
      await _showAiCommentDialog(context, comment);
    } catch (_) {
      if (mounted) setState(() => _recording = false);
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
        content: Text(comment),
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
    final h = widget.habit;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: AppBar(
        title: Text(
          h.name ?? '습관',
          style: GoogleFonts.dmSans(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('습관 삭제'),
                  content: const Text('이 습관을 삭제할까요?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('취소'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: FilledButton.styleFrom(backgroundColor: AppColors.destructive),
                      child: const Text('삭제'),
                    ),
                  ],
                ),
              );
              if (ok == true && mounted) {
                await ref.read(habitRepositoryProvider).deleteHabit(h.serverId!);
                if (mounted) {
                  ref.read(homeRefreshTriggerProvider.notifier).state++;
                  context.go(AppRoutes.home);
                }
              }
            },
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
            Text(
              '$_streak일 연속',
              style: GoogleFonts.lora(
                fontSize: 28,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.foregroundDark : AppColors.foreground,
              ),
            ),
            const SizedBox(height: 32),
            if (_todayCompleted)
              Card(
                child: ListTile(
                  leading: Icon(Icons.check_circle, color: AppColors.primary, size: 28),
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
          ],
        ),
      ),
    );
  }

  Future<void> _saveReminder({required bool enabled, required int hour, required int minute}) async {
    final sid = widget.habit.serverId;
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
