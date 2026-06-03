import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:kakao_flutter_sdk_common/kakao_flutter_sdk_common.dart';

const MethodChannel _configChannel = MethodChannel('habit_fable/native_config');
const MethodChannel _naverChannel = MethodChannel('flutter_naver_login');

/// Loads keys from `android/local.properties` (via [BuildConfig] + MethodChannel)
/// so Kakao/Naver work without `--dart-define`. Still supports dart-define overrides.
///
/// Retries a few times: [main] can run before [MainActivity.configureFlutterEngine]
/// has registered the channel, so the first call may return empty.
Future<void> initAndroidSocialSdks() async {
  if (kIsWeb || !Platform.isAndroid) return;

  var kakaoKey = const String.fromEnvironment('KAKAO_NATIVE_APP_KEY');
  Map<String, String> keys = {};

  for (var attempt = 0; attempt < 10; attempt++) {
    try {
      final raw = await _configChannel.invokeMethod<Map<dynamic, dynamic>>(
        'getSocialKeys',
      );
      if (raw != null) {
        keys = {
          for (final e in raw.entries)
            e.key.toString(): e.value?.toString() ?? '',
        };
      }
    } catch (e, st) {
      debugPrint('[initAndroidSocialSdks] getSocialKeys attempt $attempt: $e\n$st');
    }

    if (kakaoKey.isEmpty) {
      kakaoKey = keys['kakaoNativeAppKey'] ?? '';
    }

    final naverReady = _naverKeysPresent(keys);
    if (kakaoKey.isNotEmpty && naverReady) break;
    await Future<void>.delayed(Duration(milliseconds: 50 * (attempt + 1)));
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

  await _initNaverSdkFromKeys(keys);
}

bool _naverKeysPresent(Map<String, String> keys) {
  final nid = keys['naverClientId'] ?? '';
  final nsec = keys['naverClientSecret'] ?? '';
  final nname = keys['naverClientName'] ?? '';
  return nid.isNotEmpty && nsec.isNotEmpty && nname.isNotEmpty;
}

Future<void> _initNaverSdkFromKeys(Map<String, String> keys) async {
  _naverSdkInitialized = false;
  _naverKeysConfigured = false;
  final nid = keys['naverClientId'] ?? '';
  final nsec = keys['naverClientSecret'] ?? '';
  final nname = keys['naverClientName'] ?? '';
  if (nid.isEmpty || nsec.isEmpty || nname.isEmpty) {
    if (kDebugMode) {
      debugPrint(
        '[initAndroidSocialSdks] Naver keys missing in native config '
        '(clientId/secret/name).',
      );
    }
    return;
  }

  _naverKeysConfigured = true;

  try {
    await _naverChannel.invokeMethod<void>(
      'initSdk',
      <String, String>{
        'clientId': nid,
        'clientSecret': nsec,
        'clientName': nname,
      },
    );
    _naverSdkInitialized = true;
  } on PlatformException catch (e, st) {
    debugPrint(
      '[initAndroidSocialSdks] Naver initSdk failed: ${e.code} ${e.message}\n$st',
    );
  } catch (e, st) {
    debugPrint('[initAndroidSocialSdks] Naver initSdk failed: $e\n$st');
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

bool _naverSdkInitialized = false;
bool _naverKeysConfigured = false;

/// Naver [initSdk] succeeded, or keys exist (AndroidManifest·플러그인 자동 초기화).
bool get isNaverSdkReady {
  if (kIsWeb) return true;
  if (!Platform.isAndroid) return true;
  return _naverSdkInitialized || _naverKeysConfigured;
}
