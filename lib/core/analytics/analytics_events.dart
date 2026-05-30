/// PostHog event names (stable contract for dashboards).
abstract final class AnalyticsEvents {
  static const appOpened = 'app_opened';
  static const onboardingCompleted = 'onboarding_completed';
  static const loginSuccess = 'login_success';
  static const habitCreated = 'habit_created';
  static const habitCompleted = 'habit_completed';
  static const notificationPermissionResult = 'notification_permission_result';
}
