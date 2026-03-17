import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/router/app_providers.dart';
import '../../../core/router/app_router.dart';
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

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final repo = ref.read(habitRepositoryProvider);
    final completed = await repo.getTodayCompletedByHabit();
    final streak = await repo.getStreakDays(widget.habit.serverId ?? '');
    if (mounted) {
      setState(() {
        _todayCompleted = completed[widget.habit.serverId] ?? false;
        _streak = streak;
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
                if (mounted) context.go(AppRoutes.home);
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
          ],
        ),
      ),
    );
  }
}
