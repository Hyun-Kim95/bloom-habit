import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bloom_habit/l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/router/app_providers.dart';
import '../../../data/legal/legal_repository.dart';

/// Displays terms or privacy policy fetched from API.
class LegalViewScreen extends ConsumerStatefulWidget {
  const LegalViewScreen({super.key, required this.type});

  /// 'terms' | 'privacy'
  final String type;

  @override
  ConsumerState<LegalViewScreen> createState() => _LegalViewScreenState();
}

class _LegalViewScreenState extends ConsumerState<LegalViewScreen> {
  LegalDocumentItem? _doc;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = ref.read(legalRepositoryProvider);
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final doc = widget.type == 'privacy' ? await repo.getPrivacy() : await repo.getTerms();
      if (mounted) {
        setState(() {
          _doc = doc;
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
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.foregroundDark : AppColors.foreground;
    final muted = AppColors.mutedFg(isDark);

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: AppBar(
        title: Text(
          widget.type == 'privacy' ? l10n.privacyPolicy : l10n.terms,
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
                  onRefresh: _load,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_doc != null) ...[
                          if (_doc!.content.isEmpty)
                            Text(
                              l10n.noContent,
                              style: GoogleFonts.dmSans(fontSize: 15, color: muted),
                            )
                          else
                            SelectableText(
                              _doc!.content,
                              style: GoogleFonts.dmSans(
                                fontSize: 15,
                                height: 1.5,
                                color: textColor,
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
                ),
    );
  }
}
