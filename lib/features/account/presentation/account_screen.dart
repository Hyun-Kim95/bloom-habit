import 'package:flutter/material.dart';
import 'package:bloom_habit/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/auth/auth_repository.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/router/app_providers.dart';
import '../../../core/router/app_router.dart';

bool _isValidHttpAvatarUrl(String url) {
  final t = url.trim();
  if (t.isEmpty) return false;
  return RegExp(r'^https?://', caseSensitive: false).hasMatch(t);
}

String _maskEmail(String? email) {
  if (email == null || email.isEmpty) return '';
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
    case 'kakao':
      return 'Kakao';
    case 'naver':
      return 'Naver';
    default:
      return 'Social';
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
    final l10n = AppLocalizations.of(context)!;
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
      _profileError = p == null ? l10n.profileLoadFailed : null;
    });
  }

  Future<void> _editNickname() async {
    final l10n = AppLocalizations.of(context)!;
    final auth = ref.read(authRepositoryProvider);
    final initial = _profile?.displayName ?? '';
    final controller = TextEditingController(text: initial);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.nickname),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: l10n.nicknameHint,
            counterText: l10n.max20Chars,
          ),
          maxLength: 20,
          autofocus: true,
          textInputAction: TextInputAction.done,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.save),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final name = controller.text.trim();
    try {
      await auth.updateMeProfile(displayName: name);
      await _loadProfile();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.saved)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.saveFailed(e.toString().split('\n').first)),
          ),
        );
      }
    }
  }

  Future<void> _clearAvatar() async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.removeProfilePhoto),
        content: Text(l10n.removeProfilePhotoDescription),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.remove),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    try {
      await ref.read(authRepositoryProvider).updateMeProfile(clearAvatar: true);
      await _loadProfile();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.profilePhotoRemoved)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.processFailed(e.toString().split('\n').first)),
          ),
        );
      }
    }
  }

  Future<void> _manageProfilePhoto() async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: (_profile?.avatarUrl ?? '').trim());
    final newUrl = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.profilePhotoDialogTitle),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: l10n.profilePhotoUrlHint),
          keyboardType: TextInputType.url,
          autocorrect: false,
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _clearAvatar();
            },
            child: Text(l10n.resetProfilePhotoButton),
          ),
          FilledButton(
            onPressed: () {
              final u = controller.text.trim();
              if (!_isValidHttpAvatarUrl(u)) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(content: Text(l10n.profilePhotoInvalidUrl)),
                );
                return;
              }
              Navigator.pop(ctx, u);
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
    if (!mounted || newUrl == null) return;
    try {
      await ref.read(authRepositoryProvider).updateMeProfile(avatarUrl: newUrl);
      await _loadProfile();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.profilePhotoUpdated)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.processFailed(e.toString().split('\n').first)),
          ),
        );
      }
    }
  }

  Future<void> _withdraw() async {
    final l10n = AppLocalizations.of(context)!;
    final reasonController = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteAccount),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.deleteAccountDescription),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              maxLength: 500,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: l10n.withdrawReason,
                hintText: l10n.withdrawReasonHint,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              final reason = reasonController.text.trim();
              if (reason.isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(content: Text(l10n.withdrawReasonRequired)),
                );
                return;
              }
              Navigator.pop(ctx, true);
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.destructive,
            ),
            child: Text(l10n.withdraw),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final reason = reasonController.text.trim();
    setState(() => _withdrawing = true);
    try {
      final auth = ref.read(authRepositoryProvider);
      final habitRepo = ref.read(habitRepositoryProvider);
      await auth.deleteAccount(reason);
      await habitRepo.clearAllLocalData();
      if (!mounted) return;
      ref.invalidate(sessionRestoredProvider);
      context.go(AppRoutes.login);
    } catch (e) {
      if (mounted) {
        setState(() => _withdrawing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.withdrawFailed(e.toString().split('\n').first)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = isDark ? AppColors.foregroundDark : AppColors.foreground;
    final muted = AppColors.mutedFg(isDark);

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: AppBar(
        title: Text(
          l10n.accountManagement,
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
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              )
            else if (_profileError != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: [
                    Text(
                      _profileError!,
                      style: GoogleFonts.dmSans(fontSize: 14, color: muted),
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _loadProfile,
                      child: Text(l10n.retry),
                    ),
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
                                  : l10n.noName,
                              style: GoogleFonts.dmSans(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: fg,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _maskEmail(_profile?.email),
                              style: GoogleFonts.dmSans(
                                fontSize: 13,
                                color: muted,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              l10n.loginWithProvider(
                                _providerLabel(_profile?.authProvider ?? ''),
                              ),
                              style: GoogleFonts.dmSans(
                                fontSize: 12,
                                color: muted,
                              ),
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
                      title: Text(
                        l10n.changeNickname,
                        style: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        l10n.nicknameSubtitle,
                        style: GoogleFonts.dmSans(fontSize: 12, color: muted),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _editNickname,
                    ),
                    ListTile(
                      leading: const Icon(Icons.account_circle_outlined),
                      title: Text(
                        l10n.profilePhotoManageTitle,
                        style: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        l10n.profilePhotoManageSubtitle,
                        style: GoogleFonts.dmSans(fontSize: 12, color: muted),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _manageProfilePhoto,
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
                          l10n.accountDataWarning,
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            height: 1.45,
                            color: fg,
                          ),
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
                label: Text(l10n.logout),
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
                label: Text(
                  _withdrawing ? l10n.withdrawing : l10n.deleteAccount,
                ),
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
