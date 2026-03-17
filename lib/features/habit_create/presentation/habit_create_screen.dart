import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/router/app_providers.dart';
import '../../../core/router/app_router.dart';

class HabitCreateScreen extends ConsumerStatefulWidget {
  const HabitCreateScreen({super.key});

  @override
  ConsumerState<HabitCreateScreen> createState() => _HabitCreateScreenState();
}

class _HabitCreateScreenState extends ConsumerState<HabitCreateScreen> {
  final _nameController = TextEditingController();
  final _categoryController = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = '습관명을 입력하세요');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(habitRepositoryProvider).createHabit(
            name: name,
            category: _categoryController.text.trim().isEmpty
                ? null
                : _categoryController.text.trim(),
            startDate: DateTime.now(),
          );
      if (mounted) {
        ref.read(homeRefreshTriggerProvider.notifier).state++;
        context.pop();
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
            TextField(
              controller: _categoryController,
              decoration: const InputDecoration(
                hintText: '예: 건강',
              ),
              textInputAction: TextInputAction.done,
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
