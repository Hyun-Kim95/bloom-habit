import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:kakao_flutter_sdk_common/kakao_flutter_sdk_common.dart';

/// Loads keys from `android/local.properties` (via [BuildConfig] + MethodChannel)
/// so Kakao/Naver work without `--dart-define`. Still supports dart-define overrides.
Future<void> initAndroidSocialSdks() async {
  if (kIsWeb || !Platform.isAndroid) return;

  const configChannel = MethodChannel('bloom_habit/native_config');
  Map<String, String> keys = {};
  try {
    final raw = await configChannel.invokeMethod<Map<dynamic, dynamic>>('getSocialKeys');
    if (raw != null) {
      keys = {
        for (final e in raw.entries)
          e.key.toString(): e.value?.toString() ?? '',
      };
    }
  } catch (_) {}

  var kakaoKey = const String.fromEnvironment('KAKAO_NATIVE_APP_KEY');
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
