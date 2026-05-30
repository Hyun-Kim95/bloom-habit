/// Product analytics abstraction (PostHog or no-op).
abstract class AnalyticsService {
  Future<void> init();

  Future<void> identify({
    required String userId,
    Map<String, Object?> userProperties = const {},
  });

  Future<void> reset();

  Future<void> capture(
    String eventName, {
    Map<String, Object?> properties = const {},
  });

  bool get isActive;
}
