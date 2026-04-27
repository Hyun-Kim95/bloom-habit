import 'package:flutter/foundation.dart';

/// AdMob / Play Billing / StoreKit은 모바일 스토어 빌드에서만 사용합니다.
bool get monetizationSupported =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS);
