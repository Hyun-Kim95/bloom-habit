import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/monetization/monetization_notifier.dart';
import '../../../core/monetization/monetization_platform.dart';
import '../../../core/monetization/monetization_product_ids.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';

class SupportMonetizationScreen extends ConsumerStatefulWidget {
  const SupportMonetizationScreen({super.key});

  @override
  ConsumerState<SupportMonetizationScreen> createState() =>
      _SupportMonetizationScreenState();
}

class _SupportMonetizationScreenState
    extends ConsumerState<SupportMonetizationScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(monetizationProvider.notifier).refreshProducts();
    });
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = AppColors.mutedFg(isDark);
    final m = ref.watch(monetizationProvider);

    ref.listen(monetizationProvider, (prev, next) {
      if (next.snack == MonetizationSnack.none) return;
      final msg = switch (next.snack) {
        MonetizationSnack.removeAdsThanks => l10n.removeAdsThanks,
        MonetizationSnack.donationThanks => l10n.donationThanks,
        MonetizationSnack.restoreRequested => l10n.restorePurchasesRequested,
        MonetizationSnack.productsMissing => l10n.productsNotConfigured,
        MonetizationSnack.purchaseError => l10n.purchaseFailed,
        MonetizationSnack.none => '',
      };
      if (msg.isNotEmpty) {
        _showSnack(msg);
      }
      ref.read(monetizationProvider.notifier).clearSnack();
    });

    final removeProduct =
        m.product(MonetizationProductIds.removeAds);
    final smallProduct =
        m.product(MonetizationProductIds.donationSmall);
    final mediumProduct =
        m.product(MonetizationProductIds.donationMedium);

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: AppBar(
        title: Text(
          l10n.supportMonetizationTitle,
          style: GoogleFonts.dmSans(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            l10n.monetizationIntro,
            style: GoogleFonts.dmSans(fontSize: 15, height: 1.45, color: muted),
          ),
          const SizedBox(height: 20),
          if (!monetizationSupported)
            Text(
              l10n.monetizationUnsupported,
              style: GoogleFonts.dmSans(
                fontSize: 14,
                color: AppColors.destructive,
              ),
            )
          else ...[
            if (!m.storeAvailable)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  l10n.storeBillingUnavailable,
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    color: AppColors.destructive,
                  ),
                ),
              ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.removeAdsTitle,
                      style: GoogleFonts.dmSans(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.removeAdsDescription,
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        height: 1.4,
                        color: muted,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (m.adFree)
                      Text(
                        l10n.removeAdsPurchased,
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.primaryDark : AppColors.primary,
                        ),
                      )
                    else if (m.productsLoading)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(
                            l10n.loading,
                            style: GoogleFonts.dmSans(fontSize: 14, color: muted),
                          ),
                        ),
                      )
                    else
                      FilledButton(
                        onPressed: m.purchasePending || removeProduct == null
                            ? null
                            : () => ref
                                .read(monetizationProvider.notifier)
                                .buyRemoveAds(),
                        child: Text(
                          removeProduct != null
                              ? '${l10n.removeAdsTitle} · ${removeProduct.price}'
                              : l10n.removeAdsTitle,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.donationSectionTitle,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: muted,
              ),
            ),
            const SizedBox(height: 8),
            if (m.productsLoading)
              const SizedBox.shrink()
            else ...[
              if (smallProduct != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: OutlinedButton(
                    onPressed: m.purchasePending
                        ? null
                        : () => ref
                            .read(monetizationProvider.notifier)
                            .buyDonation(MonetizationProductIds.donationSmall),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${l10n.donationSmallTitle} · ${smallProduct.price}',
                            style: GoogleFonts.dmSans(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.donationSmallSubtitle,
                            style: GoogleFonts.dmSans(
                              fontSize: 13,
                              color: muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              if (mediumProduct != null)
                OutlinedButton(
                  onPressed: m.purchasePending
                      ? null
                      : () => ref
                          .read(monetizationProvider.notifier)
                          .buyDonation(MonetizationProductIds.donationMedium),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${l10n.donationMediumTitle} · ${mediumProduct.price}',
                          style: GoogleFonts.dmSans(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.donationMediumSubtitle,
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            color: muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (smallProduct == null && mediumProduct == null && !m.productsLoading)
                Text(
                  l10n.productsNotConfigured,
                  style: GoogleFonts.dmSans(fontSize: 13, color: muted),
                ),
            ],
            const SizedBox(height: 24),
            TextButton.icon(
              onPressed: m.purchasePending || !m.storeAvailable
                  ? null
                  : () => ref
                      .read(monetizationProvider.notifier)
                      .requestRestore(),
              icon: const Icon(Icons.restore),
              label: Text(l10n.restorePurchases),
            ),
          ],
        ],
      ),
    );
  }
}
