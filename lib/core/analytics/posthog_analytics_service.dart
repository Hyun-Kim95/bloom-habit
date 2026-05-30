import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:posthog_flutter/posthog_flutter.dart';

import 'analytics_service.dart';

class PosthogAnalyticsService implements AnalyticsService {
  PosthogAnalyticsService({
    required this.apiKey,
    required this.host,
    required this.environment,
  });

  final String apiKey;
  final String host;
  final String environment;

  bool _initialized = false;
  Map<String, Object?> _commonProperties = const {};

  @override
  bool get isActive => _initialized;

  @override
  Future<void> init() async {
    if (_initialized) return;

    final config = PostHogConfig(apiKey);
    config.host = host;
    config.debug = kDebugMode;
    config.captureApplicationLifecycleEvents = false;
    config.sessionReplay = false;

    await Posthog().setup(config);

    final packageInfo = await PackageInfo.fromPlatform();
    _commonProperties = {
      'environment': environment,
      'platform': _platformLabel(),
      'app_version': packageInfo.version,
      'build_number': packageInfo.buildNumber,
    };

    _initialized = true;
  }

  String _platformLabel() {
    if (kIsWeb) return 'web';
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    return 'other';
  }

  Map<String, Object?> _mergeProperties(Map<String, Object?> properties) {
    if (properties.isEmpty) return Map<String, Object?>.from(_commonProperties);
    return {..._commonProperties, ...properties};
  }

  @override
  Future<void> identify({
    required String userId,
    Map<String, Object?> userProperties = const {},
  }) async {
    if (!_initialized) return;
    await Posthog().identify(
      userId: userId,
      userProperties: userProperties.map(
        (key, value) => MapEntry(key, value ?? ''),
      ),
    );
  }

  @override
  Future<void> reset() async {
    if (!_initialized) return;
    await Posthog().reset();
  }

  @override
  Future<void> capture(
    String eventName, {
    Map<String, Object?> properties = const {},
  }) async {
    if (!_initialized) return;
    await Posthog().capture(
      eventName: eventName,
      properties: _mergeProperties(properties).map(
        (key, value) => MapEntry(key, value ?? ''),
      ),
    );
  }
}
