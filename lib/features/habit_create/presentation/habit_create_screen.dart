import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/router/app_providers.dart';
import '../../../core/router/app_router.dart';
import '../../../core/notifications/notification_service.dart';

class HabitCreateScreen extends ConsumerStatefulWidget {
  const HabitCreateScreen({super.key});

  @override
  ConsumerState<HabitCreateScreen> createState() => _HabitCreateScreenState();
}

class _HabitCreateScreenState extends ConsumerState<HabitCreateScreen> {
  final _nameController = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _reminderEnabled = false;
  int _reminderHour = 9;
  int _reminderMinute = 0;
  List<String> _categories = [];
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final list = await ref.read(habitRepositoryProvider).getHabitCategories();
      if (mounted) setState(() => _categories = list);
    } catch (_) {}
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = '습관명을 입력하세요');
      return;
    }
    if (_reminderEnabled) {
      final granted = await NotificationService().requestPermission();
      if (!granted && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('알림 권한이 필요합니다. 설정에서 허용해 주세요.')),
        );
        return;
      }
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final created = await ref.read(habitRepositoryProvider).createHabit(
            name: name,
            category: _selectedCategory?.trim().isEmpty == true ? null : _selectedCategory,
            startDate: DateTime.now(),
          );
      if (mounted && created.serverId != null) {
        if (_reminderEnabled) {
          await ref.read(habitRepositoryProvider).updateLocalReminder(
                serverId: created.serverId!,
                enabled: true,
                hour: _reminderHour,
                minute: _reminderMinute,
              );
          final habits = await ref.read(habitRepositoryProvider).getActiveHabits();
          await NotificationService().rescheduleFromHabits(habits);
        }
        ref.read(homeRefreshTriggerProvider.notifier).state++;
        context.go(AppRoutes.home);
      }
    } catch (e) {
      if (mounted) {
        final msg = e.toString();
        final isTimeout = msg.contains('receive timeout') ||
            msg.contains('connection timeout') ||
            msg.contains('connection error');
        setState(() {
          _loading = false;
          _error = isTimeout
              ? '서버 응답이 지연되고 있습니다. 서버와 PostgreSQL이 실행 중인지 확인해 주세요.'
              : msg;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: AppBar(
        title: Text(
          '새 습관 만들기',
          style: GoogleFonts.dmSans(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            Text(
              '습관명',
              style: GoogleFonts.dmSans(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDark ? AppColors.foregroundDark : AppColors.foreground,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                hintText: '예: 아침 물 500ml',
              ),
              textInputAction: TextInputAction.next,
              onChanged: (_) => setState(() => _error = null),
            ),
            const SizedBox(height: 20),
            Text(
              '카테고리 (선택)',
              style: GoogleFonts.dmSans(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDark ? AppColors.foregroundDark : AppColors.foreground,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String?>(
              value: _selectedCategory,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.radius)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radius),
                  borderSide: BorderSide(color: AppColors.input),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              hint: Text(
                '선택 안 함',
                style: GoogleFonts.dmSans(color: AppColors.mutedForeground),
              ),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('선택 안 함'),
                ),
                ..._categories.map(
                  (c) => DropdownMenuItem<String?>(
                    value: c,
                    child: Text(c, style: GoogleFonts.dmSans()),
                  ),
                ),
              ],
              onChanged: (v) => setState(() => _selectedCategory = v),
            ),
            const SizedBox(height: 24),
            Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SwitchListTile(
                    value: _reminderEnabled,
                    onChanged: _loading
                        ? null
                        : (v) => setState(() => _reminderEnabled = v),
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
                    trailing: Text(
                      '${_reminderHour.toString().padLeft(2, '0')}:${_reminderMinute.toString().padLeft(2, '0')}',
                      style: GoogleFonts.dmSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                    onTap: _reminderEnabled
                        ? () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay(hour: _reminderHour, minute: _reminderMinute),
                            );
                            if (picked != null && mounted) {
                              setState(() {
                                _reminderHour = picked.hour;
                                _reminderMinute = picked.minute;
                              });
                            }
                          }
                        : null,
                  ),
                ],
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.destructive.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radius),
                ),
                child: Text(
                  _error!,
                  style: GoogleFonts.dmSans(fontSize: 14, color: AppColors.destructive),
                ),
              ),
            ],
            const SizedBox(height: 32),
            SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        '저장',
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
