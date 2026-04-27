import 'package:flutter/foundation.dart';

/// 배너 광고 단위 ID. 디버그는 Google 테스트 단위, 릴리스는 dart-define 권장.
abstract class MonetizationAdConfig {
  MonetizationAdConfig._();

  static String bannerAdUnitId() {
    if (kDebugMode) {
      return defaultTargetPlatform == TargetPlatform.iOS
          ? 'ca-app-pub-3940256099942544/2934735716'
          : 'ca-app-pub-3940256099942544/6300978111';
    }
    const fromEnv = String.fromEnvironment('BANNER_AD_UNIT_ID');
    if (fromEnv.isNotEmpty) return fromEnv;
    return defaultTargetPlatform == TargetPlatform.iOS
        ? 'ca-app-pub-3940256099942544/2934735716'
        : 'ca-app-pub-3940256099942544/6300978111';
  }
}
