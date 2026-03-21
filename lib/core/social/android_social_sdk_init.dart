import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:kakao_flutter_sdk_common/kakao_flutter_sdk_common.dart';

const MethodChannel _configChannel = MethodChannel('bloom_habit/native_config');

/// Loads keys from `android/local.properties` (via [BuildConfig] + MethodChannel)
/// so Kakao/Naver work without `--dart-define`. Still supports dart-define overrides.
///
/// Retries a few times: [main] can run before [MainActivity.configureFlutterEngine]
/// has registered the channel, so the first call may return empty.
Future<void> initAndroidSocialSdks() async {
  if (kIsWeb || !Platform.isAndroid) return;

  var kakaoKey = const String.fromEnvironment('KAKAO_NATIVE_APP_KEY');
  Map<String, String> keys = {};

  for (var attempt = 0; attempt < 6; attempt++) {
    try {
      final raw = await _configChannel.invokeMethod<Map<dynamic, dynamic>>('getSocialKeys');
      if (raw != null) {
        keys = {
          for (final e in raw.entries)
            e.key.toString(): e.value?.toString() ?? '',
        };
      }
    } catch (_) {}

    if (kakaoKey.isEmpty) {
      kakaoKey = keys['kakaoNativeAppKey'] ?? '';
    }

    if (kakaoKey.isNotEmpty) break;
    await Future<void>.delayed(Duration(milliseconds: 40 * (attempt + 1)));
  }

  if (kakaoKey.isEmpty) {
    kakaoKey = keys['kakaoNativeAppKey'] ?? '';
  }

  if (kakaoKey.isNotEmpty) {
    const customScheme = String.fromEnvironment('KAKAO_CUSTOM_SCHEME');
    KakaoSdk.init(
      nativeAppKey: kakaoKey,
      customScheme: customScheme.isNotEmpty ? customScheme : 'kakao$kakaoKey',
    );
  }

  final nid = keys['naverClientId'] ?? '';
  final nsec = keys['naverClientSecret'] ?? '';
  final nname = keys['naverClientName'] ?? '';
  if (nid.isNotEmpty && nsec.isNotEmpty && nname.isNotEmpty) {
    try {
      await const MethodChannel('flutter_naver_login').invokeMethod<void>(
        'initSdk',
        <String, String>{
          'clientId': nid,
          'clientSecret': nsec,
          'clientName': nname,
        },
      );
    } catch (_) {}
  }
}

/// Schedule a follow-up init after the first frame (channel registration race on cold start).
void scheduleAndroidSocialSdkWarmup() {
  if (kIsWeb) return;
  WidgetsBinding.instance.addPostFrameCallback((_) {
    initAndroidSocialSdks();
  });
}

/// Whether Kakao SDK [KakaoSdk.init] has run with a non-empty native key.
bool get isKakaoSdkReady {
  if (kIsWeb) return false;
  try {
    return KakaoSdk.appKey.isNotEmpty;
  } catch (_) {
    return false;
  }
}
