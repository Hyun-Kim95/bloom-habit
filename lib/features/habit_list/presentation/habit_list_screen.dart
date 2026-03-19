import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/router/app_providers.dart';
import '../../../core/router/app_router.dart';
import '../../../core/utils/habit_icon_color.dart';
import '../../../data/local/entity/local_habit.dart';

/// 하단 Habits 탭에서 보여주는 습관 목록 화면.
class HabitListScreen extends ConsumerStatefulWidget {
  const HabitListScreen({super.key});

  @override
  ConsumerState<HabitListScreen> createState() => _HabitListScreenState();
}

class _HabitListScreenState extends ConsumerState<HabitListScreen> {
  List<LocalHabit> _habits = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = ref.read(habitRepositoryProvider);
      await repo.syncFromServer();
      if (!mounted) return;
      final habits = await repo.getActiveHabits();
      if (mounted) {
        setState(() {
          _habits = habits;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.cardDark : AppColors.card;
    final border = isDark ? AppColors.borderDark : AppColors.border;
    final text = isDark ? AppColors.foregroundDark : AppColors.foreground;
    final textMuted = AppColors.mutedForeground;
    final primary = AppColors.primary;
    const iconBg = Color(0xFFDCE9DE);

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: AppBar(
        title: Text(
          '습관',
          style: GoogleFonts.dmSans(fontSize: 18, fontWeight: FontWeight.w600, color: text),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => context.push(AppRoutes.habitCreate),
            icon: const Icon(Icons.add),
            tooltip: '습관 추가',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_error!, style: GoogleFonts.dmSans(fontSize: 14, color: AppColors.destructive)),
                        const SizedBox(height: 16),
                        FilledButton(onPressed: _load, child: const Text('다시 시도')),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: _habits.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            const SizedBox(height: 48),
                            Icon(Icons.list_rounded, size: 64, color: textMuted),
                            const SizedBox(height: 16),
                            Text(
                              '등록된 습관이 없어요',
                              style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w600, color: text),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '우측 상단 + 버튼으로 습관을 추가해 보세요.',
                              style: GoogleFonts.dmSans(fontSize: 14, color: textMuted),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          itemCount: _habits.length,
                          itemBuilder: (context, index) {
                            final h = _habits[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Material(
                                color: cardColor,
                                borderRadius: BorderRadius.circular(AppTheme.radius),
                                child: InkWell(
                                  onTap: () {
                                    if (h.serverId != null) {
                                      context.push('${AppRoutes.habitDetail}/${h.serverId}', extra: h);
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(AppTheme.radius),
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: border),
                                      borderRadius: BorderRadius.circular(AppTheme.radius),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: habitColorFromHex(h.colorHex, fallback: iconBg).withValues(alpha: 0.25),
                                            borderRadius: BorderRadius.circular(AppTheme.radius),
                                          ),
                                          alignment: Alignment.center,
                                          child: Icon(
                                            habitIconFromName(h.iconName),
                                            size: 20,
                                            color: habitColorFromHex(h.colorHex, fallback: primary),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                h.name ?? '',
                                                style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w700, color: text),
                                              ),
                                              if (h.category != null && h.category!.isNotEmpty) ...[
                                                const SizedBox(height: 4),
                                                Text(
                                                  h.category!,
                                                  style: GoogleFonts.dmSans(fontSize: 12, color: textMuted),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                        Icon(Icons.chevron_right, color: textMuted),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
    );
  }
}
