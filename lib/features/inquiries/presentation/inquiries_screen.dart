import 'package:flutter/material.dart';
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
    final subject = _subjectController.text.trim();
    final body = _bodyController.text.trim();
    if (subject.isEmpty) {
      setState(() => _error = '제목을 입력해 주세요.');
      return;
    }
    if (body.isEmpty) {
      setState(() => _error = '내용을 입력해 주세요.');
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
          const SnackBar(content: Text('문의가 등록되었습니다. 관리자 답변을 기다려 주세요.')),
        );
      }
    } catch (e) {
      if (mounted) setState(() {
        _submitting = false;
        _error = e.toString().split('\n').first;
      });
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
          '문의하기',
          style: GoogleFonts.dmSans(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '새 문의',
              style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w600, color: fg),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _subjectController,
              decoration: InputDecoration(
                hintText: '제목',
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
                hintText: '문의 내용',
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
                  : Text('문의 등록', style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 32),
            Text(
              '내 문의 목록',
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
                    '등록한 문의가 없습니다.',
                    style: GoogleFonts.dmSans(fontSize: 14, color: muted),
                  ),
                ),
              )
            else
              ..._list.map((item) => _InquiryCard(item: item, isDark: isDark)),
          ],
        ),
      ),
    );
  }
}

class _InquiryCard extends StatelessWidget {
  const _InquiryCard({required this.item, required this.isDark});

  final InquiryItem item;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final fg = isDark ? AppColors.foregroundDark : AppColors.foreground;
    final muted = AppColors.mutedForeground;
    final primary = isDark ? AppColors.primaryDark : AppColors.primary;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
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
                item.status == 'answered' ? '답변 완료' : '대기 중',
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: item.status == 'answered' ? primary : muted,
                ),
              ),
            ),
            if (item.status == 'answered' && item.repliedAt != null && item.repliedAt!.isNotEmpty)
              Text(
                '답변 ${_formatDate(item.repliedAt!)}',
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
                          '관리자 답변',
                          style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w600, color: primary),
                        ),
                        const SizedBox(height: 6),
                        if (item.repliedAt != null && item.repliedAt!.isNotEmpty)
                          Text(
                            '답변 시간: ${_formatDate(item.repliedAt!)}',
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
      // 서버가 toISOString()을 주므로, 파싱 후 로컬 시간 기준으로 포맷합니다.
      final dt = DateTime.parse(iso).toLocal();
      final yyyy = dt.year.toString().padLeft(4, '0');
      final mm = dt.month.toString().padLeft(2, '0');
      final dd = dt.day.toString().padLeft(2, '0');
      final hh = dt.hour.toString().padLeft(2, '0');
      final mi = dt.minute.toString().padLeft(2, '0');
      return '$yyyy.$mm.$dd $hh:$mi';
    } catch (_) {
      // fallback: ISO 중 앞부분만 보여줌
      if (iso.length >= 16) return iso.substring(0, 16).replaceFirst('T', ' ');
      if (iso.length >= 10) return iso.substring(0, 10);
      return iso;
    }
  }
}
