import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_fable/l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/errors/error_logger.dart';
import '../../../core/errors/user_facing_error.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/router/app_providers.dart';
import '../../../data/notices/notice_repository.dart';

class NoticesScreen extends ConsumerStatefulWidget {
  const NoticesScreen({super.key});

  @override
  ConsumerState<NoticesScreen> createState() => _NoticesScreenState();
}

class _NoticesScreenState extends ConsumerState<NoticesScreen> {
  List<NoticeItem> _items = [];
  final Set<String> _readNoticeIds = <String>{};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  Future<void> _load() async {
    final repo = ref.read(noticeRepositoryProvider);
    final lang = Localizations.localeOf(context).languageCode;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await repo.listPublished(languageCode: lang);
      if (mounted) {
        setState(() {
          _items = list;
          _loading = false;
        });
      }
    } catch (e, st) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ErrorLogger.logError('NoticesScreen._load', e, st);
        setState(() {
          _error = UserFacingError.resolve(
            e,
            l10n: l10n,
            kind: UserFacingErrorKind.load,
          );
          _loading = false;
        });
      }
    }
  }

  String _shortDate(String iso) {
    if (iso.length >= 10) return iso.substring(0, 10);
    return iso;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    ref.listen(appSettingsProvider, (prev, next) {
      next.whenData((settings) {
        final prevLocale = prev?.valueOrNull?.localeCode;
        if (prevLocale != null && prevLocale != settings.localeCode) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _load();
          });
        }
      });
    });
    final repo = ref.read(noticeRepositoryProvider);
    final lang = Localizations.localeOf(context).languageCode;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.foregroundDark : AppColors.foreground;
    final muted = AppColors.mutedFg(isDark);

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: AppBar(
        title: Text(
          l10n.announcements,
          style: GoogleFonts.dmSans(fontSize: 18, fontWeight: FontWeight.w600, color: textColor),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _loading
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
                          style: GoogleFonts.dmSans(fontSize: 14, color: AppColors.destructive),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        FilledButton(onPressed: _load, child: Text(l10n.retry)),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: _load,
                  child: _items.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            SizedBox(
                              height: MediaQuery.sizeOf(context).height * 0.3,
                            ),
                            Center(
                              child: Text(
                                l10n.noNotices,
                                style: GoogleFonts.dmSans(fontSize: 15, color: muted),
                              ),
                            ),
                          ],
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                          itemCount: _items.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 12),
                          itemBuilder: (context, i) {
                            final n = _items[i];
                            final titleText = n.resolvedTitle(lang);
                            final bodyText = n.resolvedBody(lang);
                            return Card(
                              child: ExpansionTile(
                                onExpansionChanged: (expanded) {
                                  if (!expanded) return;
                                  if (_readNoticeIds.contains(n.id)) return;
                                  _readNoticeIds.add(n.id);
                                  repo
                                      .markNoticeRead(n.id)
                                      .whenComplete(() => ref.invalidate(unreadSummaryProvider));
                                },
                                tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                title: Text(
                                  titleText.isEmpty ? l10n.untitled : titleText,
                                  style: GoogleFonts.dmSans(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: textColor,
                                  ),
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(
                                    _shortDate(n.publishedAt),
                                    style: GoogleFonts.dmSans(fontSize: 12, color: muted),
                                  ),
                                ),
                                children: [
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: SelectableText(
                                      bodyText.isEmpty ? l10n.noContent : bodyText,
                                      style: GoogleFonts.dmSans(
                                        fontSize: 15,
                                        height: 1.45,
                                        color: textColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
    );
  }
}
