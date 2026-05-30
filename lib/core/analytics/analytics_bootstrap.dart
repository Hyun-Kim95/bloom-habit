import 'package:flutter/foundation.dart';

import '../config/app_flags.dart';
import 'analytics_events.dart';
import 'analytics_service.dart';
import 'no_op_analytics_service.dart';
import 'posthog_analytics_service.dart';

AnalyticsService _analyticsInstance = const NoOpAnalyticsService();

/// Global analytics instance (set during [initAnalytics]).
AnalyticsService get analyticsService => _analyticsInstance;

bool get isAnalyticsConfigured =>
    kAnalyticsEnabled && kPostHogApiKey.trim().isNotEmpty;

AnalyticsService _createAnalyticsService() {
  if (!isAnalyticsConfigured) {
    return const NoOpAnalyticsService();
  }
  return PosthogAnalyticsService(
    apiKey: kPostHogApiKey.trim(),
    host: kPostHogHost.trim(),
    environment: kAnalyticsEnvironment.trim(),
  );
}

/// Initializes analytics after Firebase bootstrap. Failures are non-fatal.
Future<AnalyticsService> initAnalytics() async {
  final service = _createAnalyticsService();
  if (service is NoOpAnalyticsService) {
    _analyticsInstance = service;
    return service;
  }

  try {
    await service.init();
    _analyticsInstance = service;
    await service.capture(AnalyticsEvents.appOpened);
  } catch (e, st) {
    debugPrint('[analytics] init failed: $e\n$st');
    _analyticsInstance = const NoOpAnalyticsService();
  }
  return _analyticsInstance;
}
