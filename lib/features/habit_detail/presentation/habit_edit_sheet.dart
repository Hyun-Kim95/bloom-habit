import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/local/entity/local_habit.dart';

const kGoalTypes = [
  ('completion', '완료 여부'),
  ('count', '횟수'),
  ('duration', '시간'),
  ('number', '수치'),
];

const kColorPresets = [
  '22C55E', '3B82F6', 'F59E0B', 'EF4444', '8B5CF6', 'EC4899', '14B8A6', '6B7280',
];

const kIconNames = [
  'fitness_center', 'menu_book', 'local_drink', 'self_improvement', 'bedtime',
  'eco', 'psychology', 'work', 'volunteer_activism', 'star', 'check_circle', 'flag',
];

IconData iconDataFromName(String name) {
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

/// 습관 수정용 데이터 (시트에서 편집 후 반환)
class HabitEditResult {
  const HabitEditResult({
    required this.name,
    required this.goalType,
    this.goalValue,
    this.colorHex,
    this.iconName,
  });
  final String name;
  final String goalType;
  final double? goalValue;
  final String? colorHex;
  final String? iconName;
}

Future<HabitEditResult?> showHabitEditSheet(
  BuildContext context, {
  required LocalHabit habit,
  required bool isDark,
}) async {
  final nameController = TextEditingController(text: habit.name ?? '');
  String goalType = habit.goalType ?? 'completion';
  double? goalValue = habit.goalValue;
  String? colorHex = habit.colorHex;
  String? iconName = habit.iconName;

  return showModalBottomSheet<HabitEditResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setModalState) {
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '습관 수정',
                    style: GoogleFonts.dmSans(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: '습관명',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => setModalState(() {}),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: goalType,
                    decoration: const InputDecoration(
                      labelText: '목표 유형',
                      border: OutlineInputBorder(),
                    ),
                    items: kGoalTypes
                        .map((e) => DropdownMenuItem(value: e.$1, child: Text(e.$2)))
                        .toList(),
                    onChanged: (v) => setModalState(() => goalType = v ?? 'completion'),
                  ),
                  if (goalType != 'completion') ...[
                    const SizedBox(height: 12),
                    TextFormField(
                      initialValue: goalValue?.toInt().toString(),
                      decoration: const InputDecoration(
                        labelText: '목표값',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (v) {
                        final n = double.tryParse(v.trim());
                        setModalState(() => goalValue = n);
                      },
                    ),
                  ],
                  const SizedBox(height: 16),
                  const Text('색상', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: kColorPresets.map((hex) {
                      final selected = colorHex == hex;
                      return GestureDetector(
                        onTap: () => setModalState(() => colorHex = selected ? null : hex),
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
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  const Text('아이콘', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: kIconNames.map((name) {
                      final selected = iconName == name;
                      return GestureDetector(
                        onTap: () => setModalState(() => iconName = selected ? null : name),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: selected ? AppColors.primary.withValues(alpha: 0.2) : AppColors.muted.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(AppTheme.radius),
                          ),
                          child: Icon(iconDataFromName(name), color: selected ? AppColors.primary : AppColors.mutedForeground, size: 24),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () {
                      final name = nameController.text.trim();
                      if (name.isEmpty) return;
                      Navigator.pop(ctx, HabitEditResult(
                        name: name,
                        goalType: goalType,
                        goalValue: goalValue,
                        colorHex: colorHex,
                        iconName: iconName,
                      ));
                    },
                    child: const Text('저장'),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
