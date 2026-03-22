import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:bloom_habit/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/router/app_router.dart';
import '../../../core/router/app_providers.dart';
import 'sns_login_buttons.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  /// Which provider is currently signing in: google | kakao | naver
  String? _loadingFor;
  String? _error;

  Future<void> _signInWithGoogle() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _loadingFor = 'google';
      _error = null;
    });
    try {
      final repo = ref.read(authRepositoryProvider);
      final result = await repo.signInWithGoogle();
      if (!mounted) return;
      if (result.cancelled) return;
      if (result.isSuccess) {
        await repo.registerFcmToken();
        ref.invalidate(sessionRestoredProvider);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          context.go(AppRoutes.home);
        });
      } else {
        setState(() => _error = result.error ?? l10n.loginFailed);
      }
    } catch (e, st) {
      if (!mounted) return;
      setState(() {
        _error = l10n.loginError(e.toString().split('\n').first);
      });
      debugPrintStack(stackTrace: st, label: e.toString());
    } finally {
      if (mounted) setState(() => _loadingFor = null);
    }
  }

  Future<void> _signInWithKakao() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _loadingFor = 'kakao';
      _error = null;
    });
    try {
      final repo = ref.read(authRepositoryProvider);
      final result = await repo.signInWithKakao();
      if (!mounted) return;
      if (result.cancelled) return;
      if (result.isSuccess) {
        await repo.registerFcmToken();
        ref.invalidate(sessionRestoredProvider);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          context.go(AppRoutes.home);
        });
      } else {
        setState(() => _error = result.error ?? l10n.loginFailed);
      }
    } catch (e, st) {
      if (!mounted) return;
      setState(() {
        _error = l10n.loginError(e.toString().split('\n').first);
      });
      debugPrintStack(stackTrace: st, label: e.toString());
    } finally {
      if (mounted) setState(() => _loadingFor = null);
    }
  }

  Future<void> _signInWithNaver() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _loadingFor = 'naver';
      _error = null;
    });
    try {
      final repo = ref.read(authRepositoryProvider);
      final result = await repo.signInWithNaver();
      if (!mounted) return;
      if (result.cancelled) return;
      if (result.isSuccess) {
        await repo.registerFcmToken();
        ref.invalidate(sessionRestoredProvider);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          context.go(AppRoutes.home);
        });
      } else {
        setState(() => _error = result.error ?? l10n.loginFailed);
      }
    } catch (e, st) {
      if (!mounted) return;
      setState(() {
        _error = l10n.loginError(e.toString().split('\n').first);
      });
      debugPrintStack(stackTrace: st, label: e.toString());
    } finally {
      if (mounted) setState(() => _loadingFor = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAndroid = !kIsWeb && Platform.isAndroid;
    final busy = _loadingFor != null;
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
                  Icon(Icons.eco, size: 56, color: isDark ? AppColors.primaryDark : AppColors.primary),
                  const SizedBox(height: 16),
                  Text(
                    'Bloom Habit',
                    style: GoogleFonts.lora(
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.foregroundDark
                          : AppColors.foreground,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.loginSubtitle,
                    style: GoogleFonts.dmSans(
                      fontSize: 15,
                      color: AppColors.mutedFg(isDark),
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
                  GoogleSignInButton(
                    label: l10n.loginWithGoogle,
                    loading: _loadingFor == 'google',
                    onPressed: busy ? null : _signInWithGoogle,
                  ),
                  if (isAndroid) ...[
                    const SizedBox(height: 12),
                    KakaoSignInButton(
                      label: l10n.loginWithKakao,
                      loading: _loadingFor == 'kakao',
                      onPressed: busy ? null : _signInWithKakao,
                    ),
                    const SizedBox(height: 12),
                    NaverSignInButton(
                      label: l10n.loginWithNaver,
                      loading: _loadingFor == 'naver',
                      onPressed: busy ? null : _signInWithNaver,
                    ),
                  ],
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
