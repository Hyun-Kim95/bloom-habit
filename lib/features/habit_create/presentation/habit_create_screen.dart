import 'package:flutter/material.dart';
import 'package:bloom_habit/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/router/app_providers.dart';
import '../../../core/router/app_router.dart';
import '../../../core/notifications/notification_service.dart';
import '../../../data/habit/habit_repository.dart';

class HabitCreateScreen extends ConsumerStatefulWidget {
  const HabitCreateScreen({super.key});

  @override
  ConsumerState<HabitCreateScreen> createState() => _HabitCreateScreenState();
}

/// Goal types (server `goalType`).
const _goalTypes = ['completion', 'count', 'duration', 'number'];

/// Color presets (hex without #).
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

/// Icon names (Material Icons).
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
    case 'fitness_center':
      return Icons.fitness_center;
    case 'menu_book':
      return Icons.menu_book;
    case 'local_drink':
      return Icons.local_drink;
    case 'self_improvement':
      return Icons.self_improvement;
    case 'bedtime':
      return Icons.bedtime;
    case 'eco':
      return Icons.eco;
    case 'psychology':
      return Icons.psychology;
    case 'work':
      return Icons.work;
    case 'volunteer_activism':
      return Icons.volunteer_activism;
    case 'star':
      return Icons.star;
    case 'check_circle':
      return Icons.check_circle;
    case 'flag':
      return Icons.flag;
    default:
      return Icons.star;
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
  List<HabitTemplateItem> _templates = [];
  String? _selectedTemplateId;
  String? _selectedCategory;
  String _goalType = 'completion';
  double? _goalValue;
  DateTime _startDate = DateTime.now();
  String? _colorHex;
  String? _iconName;

  @override
  void initState() {
    super.initState();
    _loadInitialOptions();
  }

  Future<void> _loadInitialOptions() async {
    try {
      final repo = ref.read(habitRepositoryProvider);
      final categoriesFuture = repo.getHabitCategories();
      final templatesFuture = repo.getHabitTemplates();
      final categories = await categoriesFuture;
      final templates = await templatesFuture;
      if (mounted) {
        setState(() {
          _categories = categories;
          _templates = templates;
        });
      }
    } catch (_) {}
  }

  void _applyTemplate(String? templateId) {
    setState(() {
      _selectedTemplateId = templateId;
      if (templateId == null) return;
      HabitTemplateItem? t;
      for (final item in _templates) {
        if (item.id == templateId) {
          t = item;
          break;
        }
      }
      if (t == null) return;
      _nameController.text = t.name;
      _selectedCategory = t.category;
      _goalType = _goalTypes.contains(t.goalType) ? t.goalType : 'completion';
      _goalValue = _goalType == 'completion' ? null : t.goalValue;
      _colorHex = t.colorHex;
      _iconName = t.iconName;
      _error = null;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = l10n.enterHabitName);
      return;
    }
    if (_reminderEnabled) {
      final granted = await NotificationService().requestPermission();
      if (!granted && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.notificationPermissionRequired)),
        );
        return;
      }
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final created = await ref
          .read(habitRepositoryProvider)
          .createHabit(
            name: name,
            category: _selectedCategory?.trim().isEmpty == true
                ? null
                : _selectedCategory,
            goalType: _goalType,
            goalValue: _goalValue,
            startDate: _startDate,
            colorHex: _colorHex,
            iconName: _iconName,
          );
      if (mounted && created.serverId != null) {
        if (_reminderEnabled) {
          await ref
              .read(habitRepositoryProvider)
              .updateLocalReminder(
                serverId: created.serverId!,
                enabled: true,
                hour: _reminderHour,
                minute: _reminderMinute,
              );
          final habits = await ref
              .read(habitRepositoryProvider)
              .getActiveHabits();
          await NotificationService().rescheduleFromHabits(habits);
        }
        ref.read(homeRefreshTriggerProvider.notifier).state++;
        context.go(AppRoutes.home);
      }
    } catch (e) {
      if (mounted) {
        final msg = e.toString();
        final isTimeout =
            msg.contains('receive timeout') ||
            msg.contains('connection timeout') ||
            msg.contains('connection error');
        setState(() {
          _loading = false;
          _error = isTimeout ? l10n.serverSlowResponse : msg;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    String goalTypeLabel(String type) {
      switch (type) {
        case 'count':
          return l10n.goalTypeCount;
        case 'duration':
          return l10n.goalTypeDuration;
        case 'number':
          return l10n.goalTypeNumber;
        default:
          return l10n.goalTypeCompletion;
      }
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = AppColors.mutedFg(isDark);
    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: AppBar(
        title: Text(
          l10n.createNewHabit,
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
              l10n.habitTemplateOptional,
              style: GoogleFonts.dmSans(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDark ? AppColors.foregroundDark : AppColors.foreground,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String?>(
              value: _selectedTemplateId,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radius),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radius),
                  borderSide: BorderSide(color: AppColors.input),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
              hint: Text(
                l10n.noneSelected,
                style: GoogleFonts.dmSans(color: muted),
              ),
              items: [
                DropdownMenuItem<String?>(
                  value: null,
                  child: Text(l10n.noneSelected),
                ),
                ..._templates.map(
                  (t) => DropdownMenuItem<String?>(
                    value: t.id,
                    child: Text(t.name, style: GoogleFonts.dmSans()),
                  ),
                ),
              ],
              onChanged: _applyTemplate,
            ),
            const SizedBox(height: 20),
            Text(
              l10n.habitName,
              style: GoogleFonts.dmSans(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDark ? AppColors.foregroundDark : AppColors.foreground,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(hintText: l10n.habitNameHint),
              textInputAction: TextInputAction.next,
              onChanged: (_) => setState(() => _error = null),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.categoryOptional,
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
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radius),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radius),
                  borderSide: BorderSide(color: AppColors.input),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
              hint: Text(
                l10n.noneSelected,
                style: GoogleFonts.dmSans(color: muted),
              ),
              items: [
                DropdownMenuItem<String?>(
                  value: null,
                  child: Text(l10n.noneSelected),
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
              l10n.goalType,
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
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radius),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radius),
                  borderSide: BorderSide(color: AppColors.input),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
              items: _goalTypes
                  .map(
                    (e) => DropdownMenuItem(
                      value: e,
                      child: Text(
                        goalTypeLabel(e),
                        style: GoogleFonts.dmSans(),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _goalType = v ?? 'completion'),
            ),
            if (_goalType != 'completion') ...[
              const SizedBox(height: 12),
              TextFormField(
                initialValue: _goalValue?.toInt().toString(),
                decoration: InputDecoration(
                  labelText: _goalType == 'count'
                      ? l10n.goalCountHint
                      : _goalType == 'duration'
                      ? l10n.goalDurationHint
                      : l10n.goalNumberHint,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radius),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
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
              l10n.startDate,
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
              trailing: const Icon(
                Icons.calendar_today,
                color: AppColors.primary,
              ),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _startDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null && mounted)
                  setState(() => _startDate = picked);
              },
            ),
            const SizedBox(height: 20),
            Text(
              l10n.colorOptional,
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
                    onTap: () => setState(
                      () => _colorHex = _colorHex == hex ? null : hex,
                    ),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Color(int.parse('FF$hex', radix: 16)),
                        shape: BoxShape.circle,
                        border: selected
                            ? Border.all(
                                color: isDark ? Colors.white : Colors.black,
                                width: 2,
                              )
                            : null,
                      ),
                    ),
                  );
                }),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              l10n.iconOptional,
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
                  onTap: () => setState(
                    () => _iconName = _iconName == name ? null : name,
                  ),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.primary.withValues(alpha: 0.2)
                          : AppColors.muted.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(AppTheme.radius),
                    ),
                    child: Icon(
                      iconData,
                      color: selected
                          ? (isDark ? AppColors.primaryDark : AppColors.primary)
                          : muted,
                      size: 24,
                    ),
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
                      l10n.reminderNotification,
                      style: GoogleFonts.dmSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? AppColors.foregroundDark
                            : AppColors.foreground,
                      ),
                    ),
                    subtitle: Text(
                      l10n.reminderNotificationSubtitle,
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        color: muted,
                      ),
                    ),
                    activeThumbColor: isDark ? AppColors.primaryDark : AppColors.primary,
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
                        color: isDark
                            ? AppColors.foregroundDark
                            : AppColors.foreground,
                      ),
                    ),
                    trailing: Text(
                      '${_reminderHour.toString().padLeft(2, '0')}:${_reminderMinute.toString().padLeft(2, '0')}',
                      style: GoogleFonts.dmSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.primaryDark : AppColors.primary,
                      ),
                    ),
                    onTap: _reminderEnabled
                        ? () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay(
                                hour: _reminderHour,
                                minute: _reminderMinute,
                              ),
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
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    color: AppColors.destructive,
                  ),
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
                        l10n.save,
                        style: GoogleFonts.dmSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
