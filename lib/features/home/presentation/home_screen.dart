import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/router/app_providers.dart';
import '../../../core/router/app_router.dart';
import '../../../data/local/entity/local_habit.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  List<LocalHabit> _habits = [];
  Map<String, bool> _todayCompleted = {};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    // 첫 프레임 그린 뒤 sync 시작 (로딩 UI가 보이도록, ANR 방지)
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
      await repo.syncFromServer();
      if (!mounted) return;
      final habits = await repo.getActiveHabits();
      final completed = await repo.getTodayCompletedByHabit();
      if (mounted) {
        setState(() {
          _habits = habits;
          _todayCompleted = completed;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        final msg = e.toString();
        final isConnectionError = msg.contains('connection timeout') ||
            msg.contains('connection error') ||
            msg.contains('Connection refused') ||
            msg.contains('ConnectionTimeout');
        setState(() {
          _loading = false;
          _error = isConnectionError
              ? '서버에 연결할 수 없습니다.\n서버가 실행 중인지 확인하고, 실기기라면 같은 Wi-Fi의 PC IP로 연결해 보세요.'
              : msg.split('\n').first;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 습관 추가/수정 후 돌아왔을 때 목록 다시 불러오기
    ref.listen<int>(homeRefreshTriggerProvider, (prev, next) {
      if (prev != null && next != prev && mounted) _load();
    });

    final dateStr = _formatDate(DateTime.now());
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: AppBar(
        title: Text(
          '오늘의 습관',
          style: GoogleFonts.dmSans(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push(AppRoutes.settings),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        color: AppColors.primary,
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _error!,
                            style: GoogleFonts.dmSans(
                              fontSize: 14,
                              color: AppColors.destructive,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: _load,
                            child: const Text('다시 시도'),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                    children: [
                      Text(
                        dateStr,
                        style: GoogleFonts.dmSans(
                          fontSize: 15,
                          color: AppColors.mutedForeground,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (_habits.isEmpty)
                        _EmptyHabitsCard()
                      else
                        ..._habits.map((h) => _HabitCard(
                              habit: h,
                              completed: _todayCompleted[h.serverId] ?? false,
                              onTap: () => context.push(
                                '${AppRoutes.habitDetail}/${h.serverId}',
                                extra: h,
                              ),
                              onRecord: () async {
                                try {
                                  final repo = ref.read(habitRepositoryProvider);
                                  final record = await repo.recordToday(h.serverId!);
                                  final comment = await repo.requestAiFeedback(
                                    h.serverId!,
                                    record.serverId ?? '',
                                  );
                                  if (!context.mounted) return;
                                  _load();
                                  await _showAiCommentDialog(context, comment);
                                } catch (_) {}
                              },
                            )),
                    ],
                  ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(AppRoutes.habitCreate),
        child: const Icon(Icons.add),
      ),
    );
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

  String _formatDate(DateTime d) {
    const months = [
      '1월', '2월', '3월', '4월', '5월', '6월',
      '7월', '8월', '9월', '10월', '11월', '12월'
    ];
    return '${d.year}년 ${months[d.month - 1]} ${d.day}일';
  }
}

class _EmptyHabitsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.add_circle_outline, size: 48, color: AppColors.mutedForeground),
            const SizedBox(height: 16),
            Text(
              '아직 습관이 없어요.',
              style: GoogleFonts.dmSans(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.foregroundDark
                    : AppColors.foreground,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '우측 하단 + 버튼으로\n첫 습관을 추가해 보세요.',
              style: GoogleFonts.dmSans(
                fontSize: 14,
                color: AppColors.mutedForeground,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _HabitCard extends StatelessWidget {
  const _HabitCard({
    required this.habit,
    required this.completed,
    required this.onTap,
    required this.onRecord,
  });

  final LocalHabit habit;
  final bool completed;
  final VoidCallback onTap;
  final VoidCallback onRecord;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      habit.name ?? '',
                      style: GoogleFonts.dmSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.foregroundDark : AppColors.foreground,
                      ),
                    ),
                    if (habit.category != null && habit.category!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        habit.category!,
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          color: AppColors.mutedForeground,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (completed)
                Icon(Icons.check_circle, color: AppColors.primary, size: 28)
              else
                FilledButton(
                  onPressed: onRecord,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    minimumSize: Size.zero,
                  ),
                  child: Text(
                    '완료',
                    style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
