/// API 경로 상수 (docs/05-erd-api-spec 기준)
abstract class ApiEndpoints {
  static const String authGoogle = '/auth/google';
  static const String authApple = '/auth/apple';
  static const String authRefresh = '/auth/refresh';
  static const String authLogout = '/auth/logout';

  static const String me = '/me';
  static const String habitCategories = '/habits/categories';
  static String habits([String? id]) => id == null ? '/habits' : '/habits/$id';
  static String habitArchive(String habitId) => '/habits/$habitId/archive';
  static String habitRecords(String habitId, [String? recordId]) =>
      recordId == null
          ? '/habits/$habitId/records'
          : '/habits/$habitId/records/$recordId';
  static String habitStats(String habitId) => '/habits/$habitId/stats';
  static const String meLevel = '/me/level';
  static String aiFeedback(String habitId, String recordId) =>
      '/habits/$habitId/records/$recordId/ai-feedback';
  static String aiFeedbackList([int? limit]) =>
      limit != null ? '/habits/ai-feedback?limit=$limit' : '/habits/ai-feedback';
  static const String notificationSettings = '/notification-settings';
  static const String sync = '/sync';
  static const String syncPush = '/sync/push';
  static const String inquiries = '/inquiries';
  static const String legalTerms = '/legal/terms';
  static const String legalPrivacy = '/legal/privacy';
}
