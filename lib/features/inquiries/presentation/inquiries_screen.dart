import 'package:flutter/material.dart';
import 'package:bloom_habit/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/router/app_providers.dart';
import '../../../data/inquiries/inquiry_repository.dart';

class InquiriesScreen extends ConsumerStatefulWidget {
  const InquiriesScreen({super.key});

  @override
  ConsumerState<InquiriesScreen> createState() => _InquiriesScreenState();
}

class _InquiriesScreenState extends ConsumerState<InquiriesScreen> {
  final _subjectController = TextEditingController();
  final _bodyController = TextEditingController();
  List<InquiryItem> _list = [];
  bool _loading = true;
  bool _submitting = false;
  String? _error;
  final Set<String> _readInquiryIds = <String>{};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = ref.read(inquiryRepositoryProvider);
      final list = await repo.getMyInquiries();
      if (mounted) setState(() {
        _list = list;
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() {
        _loading = false;
        _error = e.toString().split('\n').first;
      });
    }
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    final subject = _subjectController.text.trim();
    final body = _bodyController.text.trim();
    if (subject.isEmpty) {
      setState(() => _error = l10n.enterSubject);
      return;
    }
    if (body.isEmpty) {
      setState(() => _error = l10n.enterContent);
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final repo = ref.read(inquiryRepositoryProvider);
      await repo.createInquiry(subject: subject, body: body);
      if (mounted) {
        _subjectController.clear();
        _bodyController.clear();
        setState(() => _submitting = false);
        _load();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.inquirySubmitted)),
        );
      }
    } catch (e) {
      if (mounted) setState(() {
        _submitting = false;
        _error = e.toString().split('\n').first;
      });
    }
  }

  DateTime? _tryParseIso(String? value) {
    if (value == null || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }

  bool _isUnreadReply(InquiryItem item) {
    if (item.status != 'answered') return false;
    if ((item.adminReply ?? '').trim().isEmpty) return false;
    final repliedAt = _tryParseIso(item.repliedAt);
    final userReadAt = _tryParseIso(item.userReadAt);
    if (repliedAt == null) return userReadAt == null;
    if (userReadAt == null) return true;
    return userReadAt.isBefore(repliedAt);
  }

  Future<void> _markInquiryReadIfNeeded(InquiryItem item) async {
    if (!_isUnreadReply(item)) return;
    if (_readInquiryIds.contains(item.id)) return;
    _readInquiryIds.add(item.id);
    final repo = ref.read(inquiryRepositoryProvider);
    try {
      await repo.markInquiryRead(item.id);
    } catch (_) {
      _readInquiryIds.remove(item.id);
      return;
    }
    ref.invalidate(unreadSummaryProvider);
    await _load();
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
          l10n.inquiry,
          style: GoogleFonts.dmSans(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.newInquiry,
              style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w600, color: fg),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _subjectController,
              decoration: InputDecoration(
                hintText: l10n.subject,
                filled: true,
                fillColor: isDark ? AppColors.cardDark : AppColors.card,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.radius)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              style: GoogleFonts.dmSans(fontSize: 15, color: fg),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _bodyController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: l10n.inquiryContent,
                alignLabelWithHint: true,
                filled: true,
                fillColor: isDark ? AppColors.cardDark : AppColors.card,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.radius)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              style: GoogleFonts.dmSans(fontSize: 15, color: fg),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.destructive)),
            ],
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _submitting ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.primaryForeground,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radius)),
              ),
              child: _submitting
                  ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(l10n.submitInquiry, style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 32),
            Text(
              l10n.myInquiries,
              style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w600, color: fg),
            ),
            const SizedBox(height: 12),
            if (_loading)
              const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator(strokeWidth: 2)))
            else if (_list.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    l10n.noInquiries,
                    style: GoogleFonts.dmSans(fontSize: 14, color: muted),
                  ),
                ),
              )
            else
              ..._list.map(
                (item) => _InquiryCard(
                  item: item,
                  isDark: isDark,
                  l10n: l10n,
                  isUnreadReply: _isUnreadReply(item),
                  onOpenReply: () => _markInquiryReadIfNeeded(item),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _InquiryCard extends StatelessWidget {
  const _InquiryCard({
    required this.item,
    required this.isDark,
    required this.l10n,
    required this.isUnreadReply,
    required this.onOpenReply,
  });

  final InquiryItem item;
  final bool isDark;
  final AppLocalizations l10n;
  final bool isUnreadReply;
  final VoidCallback onOpenReply;

  @override
  Widget build(BuildContext context) {
    final fg = isDark ? AppColors.foregroundDark : AppColors.foreground;
    final muted = AppColors.mutedFg(isDark);
    final primary = isDark ? AppColors.primaryDark : AppColors.primary;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        onExpansionChanged: (expanded) {
          if (expanded) onOpenReply();
        },
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          item.subject,
          style: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w600, color: fg),
        ),
        subtitle: Wrap(
          spacing: 8,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              _formatDate(item.createdAt),
              style: GoogleFonts.dmSans(fontSize: 12, color: muted),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: item.status == 'answered'
                    ? primary.withValues(alpha: 0.2)
                    : muted.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                item.status == 'answered' ? l10n.answered : l10n.pending,
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: item.status == 'answered' ? primary : muted,
                ),
              ),
            ),
            if (isUnreadReply)
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.destructive,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            if (item.status == 'answered' && item.repliedAt != null && item.repliedAt!.isNotEmpty)
              Text(
                l10n.replyAt(_formatDate(item.repliedAt!)),
                style: GoogleFonts.dmSans(fontSize: 12, color: muted),
              ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.body,
                  style: GoogleFonts.dmSans(fontSize: 14, color: fg, height: 1.4),
                ),
                if (item.adminReply != null && item.adminReply!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radius),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.adminReply,
                          style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w600, color: primary),
                        ),
                        const SizedBox(height: 6),
                        if (item.repliedAt != null && item.repliedAt!.isNotEmpty)
                          Text(
                            l10n.replyTime(_formatDate(item.repliedAt!)),
                            style: GoogleFonts.dmSans(fontSize: 11, color: muted),
                          ),
                        if (item.repliedAt != null && item.repliedAt!.isNotEmpty)
                          const SizedBox(height: 6),
                        Text(
                          item.adminReply!,
                          style: GoogleFonts.dmSans(fontSize: 14, color: fg, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String iso) {
    try {
      // Server returns toISOString(); parse and render in local time.
      final dt = DateTime.parse(iso).toLocal();
      final yyyy = dt.year.toString().padLeft(4, '0');
      final mm = dt.month.toString().padLeft(2, '0');
      final dd = dt.day.toString().padLeft(2, '0');
      final hh = dt.hour.toString().padLeft(2, '0');
      final mi = dt.minute.toString().padLeft(2, '0');
      return '$yyyy.$mm.$dd $hh:$mi';
    } catch (_) {
      // Fallback: show leading part of ISO string.
      if (iso.length >= 16) return iso.substring(0, 16).replaceFirst('T', ' ');
      if (iso.length >= 10) return iso.substring(0, 10);
      return iso;
    }
  }
}
