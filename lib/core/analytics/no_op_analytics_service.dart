import 'analytics_service.dart';

/// Default when analytics is disabled or API key is missing.
class NoOpAnalyticsService implements AnalyticsService {
  const NoOpAnalyticsService();

  @override
  bool get isActive => false;

  @override
  Future<void> init() async {}

  @override
  Future<void> identify({
    required String userId,
    Map<String, Object?> userProperties = const {},
  }) async {}

  @override
  Future<void> reset() async {}

  @override
  Future<void> capture(
    String eventName, {
    Map<String, Object?> properties = const {},
  }) async {}
}
