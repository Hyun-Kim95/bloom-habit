import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/router/app_router.dart';
import '../../../core/router/app_providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _loading = false;
  String? _error;

  Future<void> _signInWithGoogle() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = ref.read(authRepositoryProvider);
      final result = await repo.signInWithGoogle();
      if (!mounted) return;
      setState(() => _loading = false);
      if (result.cancelled) return;
      if (result.isSuccess) {
        ref.invalidate(sessionRestoredProvider);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          context.go(AppRoutes.home);
        });
      } else {
        setState(() => _error = result.error ?? '로그인 실패');
      }
    } catch (e, st) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = '로그인 중 오류: ${e.toString().split('\n').first}';
      });
      debugPrintStack(stackTrace: st, label: e.toString());
    }
  }

  Future<void> _signInWithApple() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = ref.read(authRepositoryProvider);
      final result = await repo.signInWithApple();
      if (!mounted) return;
      setState(() => _loading = false);
      if (result.cancelled) return;
      if (result.isSuccess) {
        ref.invalidate(sessionRestoredProvider);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          context.go(AppRoutes.home);
        });
      } else {
        setState(() => _error = result.error ?? '로그인 실패');
      }
    } catch (e, st) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = '로그인 중 오류: ${e.toString().split('\n').first}';
      });
      debugPrintStack(stackTrace: st, label: e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 24),
                  Icon(
                    Icons.eco,
                    size: 56,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Bloom Habit',
                    style: GoogleFonts.lora(
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.foregroundDark : AppColors.foreground,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '소셜 계정으로 간편히 시작하세요',
                    style: GoogleFonts.dmSans(
                      fontSize: 15,
                      color: AppColors.mutedForeground,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  if (_error != null) ...[
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
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  SizedBox(
                    height: 52,
                    child: FilledButton(
                      onPressed: _loading ? null : _signInWithGoogle,
                      child: _loading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              'Google로 로그인',
                              style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 52,
                    child: OutlinedButton(
                      onPressed: _loading ? null : _signInWithApple,
                      child: Text(
                        'Apple로 로그인',
                        style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
