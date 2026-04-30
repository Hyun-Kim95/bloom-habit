import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:habit_fable/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/feedback/habit_completion_feedback.dart';
import '../../../core/timer/duration_timer_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/completion_praise.dart';
import '../../../core/router/app_providers.dart';
import '../../../core/router/app_router.dart';
import '../../../core/notifications/notification_service.dart';
import '../../../core/utils/habit_icon_color.dart';
import '../../../core/utils/habit_display_localization.dart';
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
  double? _todayValue;
  bool _recording = false;
  bool _durationRunning = false;
  int _runningElapsedMs = 0;
  Timer? _durationTicker;
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

  @override
  void dispose() {
    _durationTicker?.cancel();
    super.dispose();
  }

  void _setRunningTimerState(DurationTimerState timerState) {
    if (!(timerState.running && timerState.habitId == _habit.serverId)) {
      _durationTicker?.cancel();
      _durationTicker = null;
      _durationRunning = false;
      _runningElapsedMs = 0;
      return;
    }
    final baseElapsed = timerState.elapsedMs ?? 0;
    final startedAtMs = timerState.startedAtMs;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final derived = startedAtMs != null ? (nowMs - startedAtMs).clamp(0, 1 << 31) : 0;
    _durationRunning = true;
    _runningElapsedMs = baseElapsed > 0 ? baseElapsed : derived;
    _durationTicker?.cancel();
    _durationTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || !_durationRunning) return;
      setState(() {
        _runningElapsedMs += 1000;
      });
    });
  }

  String _formatRunningDuration(int elapsedMs) {
    final totalSec = (elapsedMs ~/ 1000).clamp(0, 359999);
    final mm = (totalSec ~/ 60).toString().padLeft(2, '0');
    final ss = (totalSec % 60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  Future<void> _loadStats() async {
    final repo = ref.read(habitRepositoryProvider);
    final completed = await repo.getTodayCompletedByHabit();
    final values = await repo.getTodayValueByHabit();
    final streak = await repo.getStreakDays(_habit.serverId ?? '');
    final habit = await repo.getHabitByServerId(_habit.serverId ?? '');
    final timerState = await DurationTimerService.getState();
    if (mounted) {
      setState(() {
        _todayCompleted = completed[_habit.serverId] ?? false;
        _todayValue = values[_habit.serverId];
        _streak = streak;
        if (habit != null) {
          _habit = habit;
          _reminderEnabled = habit.reminderEnabled ?? false;
          _reminderHour = habit.reminderHour ?? 9;
          _reminderMinute = habit.reminderMinute ?? 0;
        }
        _durationRunning =
            timerState.running &&
            timerState.habitId != null &&
            timerState.habitId == _habit.serverId;
        _setRunningTimerState(timerState);
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
    list.sort((a, b) => b.recordDate.compareTo(a.recordDate));
    if (mounted) {
      setState(() {
        _recordHistory = list;
        _historyLoading = false;
      });
    }
  }

  Future<void> _recordToday() async {
    if (_recording) return;
    final goalType = (_habit.goalType ?? 'completion').toLowerCase().trim();
    if (goalType == 'completion' && _todayCompleted) return;
    if (goalType == 'duration' && _durationRunning) {
      setState(() {
        _durationRunning = false;
        _runningElapsedMs = 0;
      });
      _durationTicker?.cancel();
      _durationTicker = null;
      try {
        final repo = ref.read(habitRepositoryProvider);
        final elapsedMs = await DurationTimerService.stop();
        final minutes = (((elapsedMs ?? 0).clamp(0, 2147483647)) ~/ 60000)
            .toDouble();
        if (minutes >= 1) {
          await repo.recordToday(_habit.serverId!, value: minutes);
          if (mounted) {
            final settings = ref.read(appSettingsProvider).value;
            debugPrint(
              'CompletionFeedbackProbe: detail request(duration-stop) {completionSoundEnabled: ${settings?.soundEnabled ?? true}, goalType: duration, habitId: ${_habit.serverId}}',
            );
            final feedbackPlayed = await HabitCompletionFeedback.trigger(
              soundEnabled: settings?.soundEnabled ?? true,
            );
            if (!feedbackPlayed && kDebugMode && mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('피드백 재생 실패(디버그). 로그를 확인해 주세요.'),
                  behavior: SnackBarBehavior.floating,
                  duration: Duration(seconds: 2),
                ),
              );
            }
          }
        } else if (mounted) {
          final isEn = Localizations.localeOf(context).languageCode == 'en';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isEn
                    ? 'Less than one minute is not saved, so completion feedback is skipped.'
                    : '1분 미만은 저장되지 않아 완료 피드백이 재생되지 않습니다.',
              ),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 3),
            ),
          );
        }
        if (!mounted) return;
        ref.read(homeRefreshTriggerProvider.notifier).state++;
        _loadStats();
        _loadRecordHistory();
      } catch (_) {
        if (mounted) {
          setState(() => _durationRunning = true);
        }
      }
      return;
    }
    setState(() => _recording = true);
    try {
      final repo = ref.read(habitRepositoryProvider);
      var shouldPlayFeedback = false;
      if (goalType == 'completion') {
        await repo.recordToday(_habit.serverId!, completed: true);
        shouldPlayFeedback = true;
      } else if (goalType == 'duration') {
        if (mounted) {
          setState(() {
            _durationRunning = true;
            _runningElapsedMs = 0;
            _recording = false;
          });
        }
        _durationTicker?.cancel();
        _durationTicker = Timer.periodic(const Duration(seconds: 1), (_) {
          if (!mounted || !_durationRunning) return;
          setState(() {
            _runningElapsedMs += 1000;
          });
        });
        try {
          await DurationTimerService.start(
            habitName: _habit.name ?? 'Habit',
            habitId: _habit.serverId,
          );
        } catch (_) {
          if (mounted) {
            setState(() {
              _durationRunning = false;
              _runningElapsedMs = 0;
            });
          }
          _durationTicker?.cancel();
          _durationTicker = null;
        }
        return;
      } else {
        final inputValue = await _askRecordValue(goalType, _habit.unit);
        if (inputValue == null) {
          if (mounted) setState(() => _recording = false);
          return;
        }
        await repo.recordToday(_habit.serverId!, value: inputValue);
        shouldPlayFeedback = true;
      }
      if (!mounted) return;
      if (shouldPlayFeedback) {
        final settings = ref.read(appSettingsProvider).value;
        debugPrint(
          'CompletionFeedbackProbe: detail request {completionSoundEnabled: ${settings?.soundEnabled ?? true}, goalType: $goalType, habitId: ${_habit.serverId}}',
        );
        final feedbackPlayed = await HabitCompletionFeedback.trigger(
          soundEnabled: settings?.soundEnabled ?? true,
        );
        if (!feedbackPlayed) {
          debugPrint(
            'CompletionFeedbackProbe: detail no-feedback-after-save {goalType: $goalType, habitId: ${_habit.serverId}}',
          );
          if (kDebugMode && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('피드백 재생 실패(디버그). 로그를 확인해 주세요.'),
                behavior: SnackBarBehavior.floating,
                duration: Duration(seconds: 2),
              ),
            );
          }
        }
      }
      setState(() {
        _recording = false;
      });
      ref.read(homeRefreshTriggerProvider.notifier).state++;
      _loadStats();
      _loadRecordHistory();
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(completionPraiseMessage(l10n, _habit)),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (_) {
      debugPrint('HabitDetailScreen: record today failed goalType=$goalType');
      if (mounted) setState(() => _recording = false);
    }
  }

  Future<double?> _askRecordValue(String goalType, String? unit) async {
    final l10n = AppLocalizations.of(context)!;
    final languageCode = Localizations.localeOf(context).languageCode;
    final controller = TextEditingController(text: '1');
    final normalizedUnit = (unit ?? '').trim();
    final unitHint = normalizedUnit.isEmpty
        ? null
        : localizeHabitUnit(normalizedUnit, languageCode);
    return showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          goalType == 'count'
              ? (languageCode == 'en' ? 'Count value' : '완료 횟수')
              : (languageCode == 'en' ? 'Completed value' : '완료값'),
        ),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            hintText: goalType == 'count'
                ? (languageCode == 'en' ? 'Default 1' : '기본 1')
                : goalType == 'duration'
                ? l10n.goalDurationHint
                : l10n.goalNumberHint,
            suffixText: goalType == 'count' ? null : unitHint,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              final raw = controller.text.trim();
              final n = double.tryParse(raw.isEmpty ? '1' : raw);
              if (n == null || n <= 0) return;
              Navigator.pop(ctx, n);
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }

  Future<void> _openEdit() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final result = await showHabitEditSheet(
      context,
      habit: _habit,
      isDark: isDark,
    );
    if (result == null || !mounted) return;
    try {
      final repo = ref.read(habitRepositoryProvider);
      await repo.updateHabit(
        _habit.serverId!,
        name: result.name,
        goalType: result.goalType,
        numberDirection: result.numberDirection,
        unit: result.unit,
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
          SnackBar(
            content: Text(AppLocalizations.of(context)!.editFailedTryAgain),
          ),
        );
      }
    }
  }

  Future<void> _archive() async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.hideHabit),
        content: Text(l10n.hideHabitDescription),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.hide),
          ),
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.hideFailed)));
      }
    }
  }

  Future<void> _unarchive() async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.unhideHabit),
        content: Text(l10n.unhideHabitDescription),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.unhide),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await ref.read(habitRepositoryProvider).archiveHabit(_habit.serverId!);
      if (!mounted) return;
      ref.read(homeRefreshTriggerProvider.notifier).state++;
      context.go(AppRoutes.habits);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.unhideFailed)));
      }
    }
  }

  Future<void> _onRecordAction(RecordSummary r, String action) async {
    final l10n = AppLocalizations.of(context)!;
    if (action != 'delete') return;
    final recordId = r.recordId;
    final habitId = _habit.serverId;
    if (recordId == null || habitId == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteRecord),
        content: Text(l10n.deleteRecordForDate(r.recordDate)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.destructive,
            ),
            child: Text(l10n.delete),
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.processFailedTryAgain)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final h = _habit;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = AppColors.mutedFg(isDark);
    final isHidden = h.archivedAt != null;
    final goalType = (h.goalType ?? 'completion').toLowerCase().trim();
    final languageCode = Localizations.localeOf(context).languageCode;
    final goalValue = h.goalValue;
    String? progressText;
    if (goalType != 'completion' && goalValue != null) {
      final runningMinutes = _durationRunning ? (_runningElapsedMs ~/ 60000).toDouble() : null;
      final current = runningMinutes ?? (_todayValue ?? 0);
      final unitSuffix = goalType == 'count'
          ? (languageCode == 'en' ? ' times' : '회')
          : (h.unit != null
                ? ' ${localizeHabitUnit(h.unit!, languageCode)}'
                : '');
      if (goalType == 'number' && h.numberDirection == 'lte') {
        progressText =
            '${current.toStringAsFixed(0)}$unitSuffix / <= ${goalValue.toStringAsFixed(0)}$unitSuffix';
      } else {
        progressText =
            '${current.toStringAsFixed(0)}$unitSuffix / ${goalValue.toStringAsFixed(0)}$unitSuffix';
      }
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: AppBar(
        title: Text(
          h.name ?? l10n.habitTitle,
          style: GoogleFonts.dmSans(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'edit') {
                await _openEdit();
              } else if (value == 'archive') {
                if (isHidden) {
                  await _unarchive();
                } else {
                  await _archive();
                }
              } else if (value == 'delete') {
                await _confirmDelete();
              }
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(value: 'edit', child: Text(l10n.edit)),
              PopupMenuItem(
                value: 'archive',
                child: Text(isHidden ? l10n.unhide : l10n.hide),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Text(
                  l10n.delete,
                  style: const TextStyle(color: AppColors.destructive),
                ),
              ),
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
                localizeHabitCategory(h.category!, languageCode),
                style: GoogleFonts.dmSans(fontSize: 14, color: muted),
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
                    l10n.daysCount(_streak),
                    style: GoogleFonts.lora(
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.foregroundDark
                          : AppColors.foreground,
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
                    l10n.completedTodayDialogTitle,
                    style: GoogleFonts.dmSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.foregroundDark
                          : AppColors.foreground,
                    ),
                  ),
                  subtitle: progressText != null ? Text(progressText) : null,
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
                          goalType == 'completion'
                              ? l10n.completeToday
                              : goalType == 'duration'
                              ? (_durationRunning ? '중지' : '시작')
                              : l10n.save,
                          style: GoogleFonts.dmSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            if (goalType == 'duration' && _durationRunning) ...[
              const SizedBox(height: 8),
              Text(
                languageCode == 'en'
                    ? 'Running ${_formatRunningDuration(_runningElapsedMs)}'
                    : '진행중 ${_formatRunningDuration(_runningElapsedMs)}',
                style: GoogleFonts.dmSans(fontSize: 13, color: muted),
              ),
            ],
            const SizedBox(height: 32),
            _buildReminderSection(isDark),
            const SizedBox(height: 24),
            Text(
              l10n.recordHistory,
              style: GoogleFonts.dmSans(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.foregroundDark : AppColors.foreground,
              ),
            ),
            const SizedBox(height: 12),
            if (_historyLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else if (_recordHistory.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    l10n.noRecent30DaysRecords,
                    style: GoogleFonts.dmSans(fontSize: 14, color: muted),
                  ),
                ),
              )
            else
              Card(
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _recordHistory.length,
                  separatorBuilder: (_, unused) => const Divider(height: 1),
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
                            Icon(
                              Icons.check_circle,
                              color: habitColorFromHex(_habit.colorHex),
                              size: 22,
                            )
                          else
                            Icon(Icons.cancel_outlined, color: muted, size: 22),
                          if (r.recordId != null) ...[
                            const SizedBox(width: 8),
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert, size: 22),
                              onSelected: (value) => _onRecordAction(r, value),
                              itemBuilder: (ctx) => [
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Text(
                                    AppLocalizations.of(context)!.delete,
                                    style: const TextStyle(
                                      color: AppColors.destructive,
                                    ),
                                  ),
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
    final l10n = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteHabit),
        content: Text(l10n.deleteHabitDescription),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.destructive,
            ),
            child: Text(l10n.delete),
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

  Future<void> _saveReminder({
    required bool enabled,
    required int hour,
    required int minute,
  }) async {
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
      final completedByHabit = await repo.getTodayCompletedByHabit();
      final excludeIds = completedByHabit.entries
          .where((e) => e.value)
          .map((e) => e.key)
          .toSet();
      await NotificationService().rescheduleFromHabits(
        habits,
        excludeCompletedHabitIds: excludeIds,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.saved),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _reminderSaving = false);
    }
  }

  Future<void> _toggleReminder(bool value) async {
    final l10n = AppLocalizations.of(context)!;
    if (value) {
      final granted = await NotificationService().requestPermission();
      if (!granted && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.notificationPermissionRequired)),
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
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SwitchListTile(
            value: _reminderEnabled,
            onChanged: _reminderSaving ? null : _toggleReminder,
            title: Text(
              l10n.reminderNotification,
              style: GoogleFonts.dmSans(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isDark ? AppColors.foregroundDark : AppColors.foreground,
              ),
            ),
            subtitle: Text(
              l10n.reminderNotificationSubtitle,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                color: AppColors.mutedFg(isDark),
              ),
            ),
            activeThumbColor: isDark
                ? AppColors.primaryDark
                : AppColors.primary,
          ),
          ListTile(
            leading: Icon(
              Icons.schedule,
              color: isDark ? AppColors.primaryDark : AppColors.primary,
            ),
            title: Text(
              l10n.notificationTime,
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
                      color: isDark ? AppColors.primaryDark : AppColors.primary,
                    ),
                  ),
            onTap: _reminderEnabled && !_reminderSaving
                ? _pickReminderTime
                : null,
          ),
        ],
      ),
    );
  }
}
