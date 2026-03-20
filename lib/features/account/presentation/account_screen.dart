import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/auth/auth_repository.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/router/app_providers.dart';
import '../../../core/router/app_router.dart';

String _maskEmail(String? email) {
  if (email == null || email.isEmpty) return '연동된 이메일 없음';
  final at = email.indexOf('@');
  if (at < 0) return '***';
  if (at <= 1) return '***${email.substring(at)}';
  final local = email.substring(0, at);
  final domain = email.substring(at + 1);
  final visible = local.length <= 2 ? local[0] : local.substring(0, 2);
  return '$visible***@$domain';
}

String _providerLabel(String authProvider) {
  switch (authProvider) {
    case 'google':
      return 'Google';
    case 'apple':
      return 'Apple';
    default:
      return '소셜';
  }
}

class AccountScreen extends ConsumerStatefulWidget {
  const AccountScreen({super.key});

  @override
  ConsumerState<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends ConsumerState<AccountScreen> {
  bool _withdrawing = false;
  bool _loadingProfile = true;
  MeProfile? _profile;
  String? _profileError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadProfile());
  }

  Future<void> _loadProfile() async {
    setState(() {
      _loadingProfile = true;
      _profileError = null;
    });
    final auth = ref.read(authRepositoryProvider);
    final p = await auth.fetchProfile();
    if (!mounted) return;
    setState(() {
      _profile = p;
      _loadingProfile = false;
      _profileError = p == null ? '프로필을 불러오지 못했습니다. 네트워크를 확인해 주세요.' : null;
    });
  }

  Future<void> _editDisplayName() async {
    final auth = ref.read(authRepositoryProvider);
    final initial = _profile?.displayName ?? '';
    final controller = TextEditingController(text: initial);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('표시 이름'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: '앱에서 보여 줄 이름',
            counterText: '최대 80자',
          ),
          maxLength: 80,
          autofocus: true,
          textInputAction: TextInputAction.done,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('저장')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final name = controller.text.trim();
    try {
      await auth.updateMeProfile(displayName: name);
      await _loadProfile();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('저장했어요.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('저장 실패: ${e.toString().split('\n').first}')),
        );
      }
    }
  }

  Future<void> _clearAvatar() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('프로필 사진 제거'),
        content: const Text('저장된 프로필 사진을 지울까요? (Google로 다시 로그인하면 사진이 다시 동기화될 수 있어요.)'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('제거')),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    try {
      await ref.read(authRepositoryProvider).updateMeProfile(clearAvatar: true);
      await _loadProfile();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('프로필 사진을 지웠어요.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('처리 실패: ${e.toString().split('\n').first}')),
        );
      }
    }
  }

  Future<void> _withdraw() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('회원 탈퇴'),
        content: const Text(
          '탈퇴하면 모든 습관·기록 데이터가 삭제되며 복구할 수 없습니다.\n정말 탈퇴할까요?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.destructive),
            child: const Text('탈퇴'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _withdrawing = true);
    try {
      final auth = ref.read(authRepositoryProvider);
      final habitRepo = ref.read(habitRepositoryProvider);
      await auth.deleteAccount();
      await habitRepo.clearAllLocalData();
      if (!mounted) return;
      ref.invalidate(sessionRestoredProvider);
      context.go(AppRoutes.login);
    } catch (e) {
      if (mounted) {
        setState(() => _withdrawing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('탈퇴 처리 중 오류가 났어요. ${e.toString().split('\n').first}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = isDark ? AppColors.foregroundDark : AppColors.foreground;
    final muted = AppColors.mutedForeground;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: AppBar(
        title: Text(
          '계정 관리',
          style: GoogleFonts.dmSans(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _loadProfile,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: [
            if (_loadingProfile)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
              )
            else if (_profileError != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: [
                    Text(_profileError!, style: GoogleFonts.dmSans(fontSize: 14, color: muted)),
                    const SizedBox(height: 12),
                    FilledButton(onPressed: _loadProfile, child: const Text('다시 시도')),
                  ],
                ),
              )
            else ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ProfileAvatar(url: _profile?.avatarUrl),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _profile?.displayName?.trim().isNotEmpty == true
                                  ? _profile!.displayName!.trim()
                                  : '이름 없음',
                              style: GoogleFonts.dmSans(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: fg,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _maskEmail(_profile?.email),
                              style: GoogleFonts.dmSans(fontSize: 13, color: muted),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_providerLabel(_profile?.authProvider ?? '')} 로그인',
                              style: GoogleFonts.dmSans(fontSize: 12, color: muted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.badge_outlined),
                      title: Text('표시 이름 변경', style: GoogleFonts.dmSans(fontWeight: FontWeight.w600)),
                      subtitle: Text(
                        '문의·앱 내에 보이는 이름입니다.',
                        style: GoogleFonts.dmSans(fontSize: 12, color: muted),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _editDisplayName,
                    ),
                    if (_profile?.avatarUrl != null && _profile!.avatarUrl!.isNotEmpty)
                      ListTile(
                        leading: const Icon(Icons.hide_image_outlined),
                        title: Text('프로필 사진 제거', style: GoogleFonts.dmSans(fontWeight: FontWeight.w600)),
                        subtitle: Text(
                          '기본 아이콘으로 돌아갑니다.',
                          style: GoogleFonts.dmSans(fontSize: 12, color: muted),
                        ),
                        onTap: _clearAvatar,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Card(
                color: isDark ? AppColors.cardDark : AppColors.muted,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline, size: 20, color: muted),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '습관·기록 데이터는 이 계정에 연동됩니다. 회원 탈퇴 시 서버와 기기에 저장된 데이터가 삭제되며 복구할 수 없습니다.',
                          style: GoogleFonts.dmSans(fontSize: 13, height: 1.45, color: fg),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              height: 52,
              child: OutlinedButton.icon(
                onPressed: _withdrawing
                    ? null
                    : () async {
                        await ref.read(authRepositoryProvider).logout();
                        if (!context.mounted) return;
                        ref.invalidate(sessionRestoredProvider);
                        context.go(AppRoutes.login);
                      },
                icon: const Icon(Icons.logout, size: 20),
                label: const Text('로그아웃'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.destructive,
                  side: const BorderSide(color: AppColors.destructive),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 52,
              child: OutlinedButton.icon(
                onPressed: _withdrawing ? null : _withdraw,
                icon: _withdrawing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.person_off_outlined, size: 20),
                label: Text(_withdrawing ? '탈퇴 처리 중…' : '회원 탈퇴'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.destructive,
                  side: const BorderSide(color: AppColors.destructive),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    final size = 56.0;
    if (url != null && url!.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          url!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _fallback(size),
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return SizedBox(
              width: size,
              height: size,
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                ),
              ),
            );
          },
        ),
      );
    }
    return _fallback(size);
  }

  Widget _fallback(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.accent,
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.person, size: size * 0.5, color: AppColors.primary),
    );
  }
}
