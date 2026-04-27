import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'monetization_ad_config.dart';
import 'monetization_notifier.dart';
import 'monetization_platform.dart';

/// 메인 셸 하단에 붙는 배너. 광고 제거 구매 시 숨깁니다.
class AdaptiveBannerAdSlot extends ConsumerStatefulWidget {
  const AdaptiveBannerAdSlot({super.key});

  @override
  ConsumerState<AdaptiveBannerAdSlot> createState() =>
      _AdaptiveBannerAdSlotState();
}

class _AdaptiveBannerAdSlotState extends ConsumerState<AdaptiveBannerAdSlot> {
  BannerAd? _banner;
  bool _loading = false;

  @override
  void dispose() {
    _banner?.dispose();
    super.dispose();
  }

  Future<void> _mountBanner() async {
    if (!monetizationSupported) return;
    final adFree = ref.read(monetizationProvider).adFree;
    if (adFree) return;
    if (_loading || _banner != null) return;
    _loading = true;
    final width = MediaQuery.sizeOf(context).width.truncate();
    final size =
        await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(
      width,
    );
    if (!mounted) return;
    if (size == null) {
      _loading = false;
      return;
    }
    final unitId = MonetizationAdConfig.bannerAdUnitId();
    final banner = BannerAd(
      adUnitId: unitId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          if (mounted) {
            setState(() {
              _banner = null;
              _loading = false;
            });
          }
        },
        onAdLoaded: (_) {
          if (mounted) {
            setState(() => _loading = false);
          }
        },
      ),
    );
    await banner.load();
    if (!mounted) {
      banner.dispose();
      return;
    }
    setState(() {
      _banner = banner;
      _loading = false;
    });
  }

  void _disposeBanner() {
    _banner?.dispose();
    _banner = null;
    _loading = false;
  }

  @override
  Widget build(BuildContext context) {
    if (!monetizationSupported) {
      return const SizedBox.shrink();
    }

    final adFree = ref.watch(monetizationProvider.select((s) => s.adFree));

    ref.listen(monetizationProvider, (prev, next) {
      if (prev?.adFree != true && next.adFree) {
        _disposeBanner();
        setState(() {});
      }
      if (prev?.adFree == true && !next.adFree) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _mountBanner());
      }
    });

    if (adFree) {
      return const SizedBox.shrink();
    }

    if (_banner == null && !_loading) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _mountBanner());
    }

    final b = _banner;
    if (b == null) {
      return const SizedBox(height: 0);
    }

    return SizedBox(
      height: b.size.height.toDouble(),
      width: b.size.width.toDouble(),
      child: AdWidget(ad: b),
    );
  }
}
