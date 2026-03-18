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

/// 목표 유형 (서버 goalType)
const _goalTypes = [
  ('completion', '완료 여부'),
  ('count', '횟수'),
  ('duration', '시간'),
  ('number', '수치'),
];

/// 색상 프리셋 (hex without #)
const _colorPresets = [
  '22C55E', // primary green
  '3B82F6', // blue
  'F59E0B', // amber
  'EF4444', // red
  '8B5CF6', // violet
  'EC4899', // pink
  '14B8A6', // teal
  '6B7280', // gray
];

/// 아이콘 이름 (Material Icons)
const _iconNames = [
  'fitness_center',
  'menu_book',
  'local_drink',
  'self_improvement',
  'bedtime',
  'eco',
  'psychology',
  'work',
  'volunteer_activism',
  'star',
  'check_circle',
  'flag',
];

IconData _iconDataFromName(String name) {
  switch (name) {
    case 'fitness_center': return Icons.fitness_center;
    case 'menu_book': return Icons.menu_book;
    case 'local_drink': return Icons.local_drink;
    case 'self_improvement': return Icons.self_improvement;
    case 'bedtime': return Icons.bedtime;
    case 'eco': return Icons.eco;
    case 'psychology': return Icons.psychology;
    case 'work': return Icons.work;
    case 'volunteer_activism': return Icons.volunteer_activism;
    case 'star': return Icons.star;
    case 'check_circle': return Icons.check_circle;
    case 'flag': return Icons.flag;
    default: return Icons.star;
  }
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
  String _goalType = 'completion';
  double? _goalValue;
  DateTime _startDate = DateTime.now();
  String? _colorHex;
  String? _iconName;

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
            goalType: _goalType,
            goalValue: _goalValue,
            startDate: _startDate,
            colorHex: _colorHex,
            iconName: _iconName,
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
            const SizedBox(height: 20),
            Text(
              '목표 유형',
              style: GoogleFonts.dmSans(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDark ? AppColors.foregroundDark : AppColors.foreground,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _goalType,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.radius)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radius),
                  borderSide: BorderSide(color: AppColors.input),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              items: _goalTypes
                  .map((e) => DropdownMenuItem(value: e.$1, child: Text(e.$2, style: GoogleFonts.dmSans())))
                  .toList(),
              onChanged: (v) => setState(() => _goalType = v ?? 'completion'),
            ),
            if (_goalType != 'completion') ...[
              const SizedBox(height: 12),
              TextFormField(
                initialValue: _goalValue?.toInt().toString(),
                decoration: InputDecoration(
                  labelText: _goalType == 'count' ? '목표 횟수 (예: 3)' : _goalType == 'duration' ? '목표 분 (예: 30)' : '목표 수치',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.radius)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                keyboardType: TextInputType.number,
                onChanged: (v) {
                  final n = double.tryParse(v.trim());
                  setState(() => _goalValue = n);
                },
              ),
            ],
            const SizedBox(height: 20),
            Text(
              '시작일',
              style: GoogleFonts.dmSans(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDark ? AppColors.foregroundDark : AppColors.foreground,
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                '${_startDate.year}.${_startDate.month.toString().padLeft(2, '0')}.${_startDate.day.toString().padLeft(2, '0')}',
                style: GoogleFonts.dmSans(fontSize: 16),
              ),
              trailing: const Icon(Icons.calendar_today, color: AppColors.primary),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _startDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null && mounted) setState(() => _startDate = picked);
              },
            ),
            const SizedBox(height: 20),
            Text(
              '색상 (선택)',
              style: GoogleFonts.dmSans(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDark ? AppColors.foregroundDark : AppColors.foreground,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                ..._colorPresets.map((hex) {
                  final selected = _colorHex == hex;
                  return GestureDetector(
                    onTap: () => setState(() => _colorHex = _colorHex == hex ? null : hex),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Color(int.parse('FF$hex', radix: 16)),
                        shape: BoxShape.circle,
                        border: selected ? Border.all(color: isDark ? Colors.white : Colors.black, width: 2) : null,
                      ),
                    ),
                  );
                }),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              '아이콘 (선택)',
              style: GoogleFonts.dmSans(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDark ? AppColors.foregroundDark : AppColors.foreground,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _iconNames.map((name) {
                final iconData = _iconDataFromName(name);
                final selected = _iconName == name;
                return GestureDetector(
                  onTap: () => setState(() => _iconName = _iconName == name ? null : name),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: selected ? AppColors.primary.withValues(alpha: 0.2) : AppColors.muted.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(AppTheme.radius),
                    ),
                    child: Icon(iconData, color: selected ? AppColors.primary : AppColors.mutedForeground, size: 24),
                  ),
                );
              }).toList(),
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
