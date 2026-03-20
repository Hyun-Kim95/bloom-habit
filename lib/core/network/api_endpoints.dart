/// API path constants (based on docs/05-erd-api-spec).
abstract class ApiEndpoints {
  static const String authGoogle = '/auth/google';
  static const String authKakao = '/auth/kakao';
  static const String authNaver = '/auth/naver';
  static const String authRefresh = '/auth/refresh';
  static const String authLogout = '/auth/logout';

  static const String me = '/me';
  static const String habitCategories = '/habits/categories';
  static const String habitTemplates = '/habits/templates';
  static String habits([String? id]) => id == null ? '/habits' : '/habits/$id';
  static String habitArchive(String habitId) => '/habits/$habitId/archive';
  static String habitRecords(String habitId, [String? recordId]) =>
      recordId == null
          ? '/habits/$habitId/records'
          : '/habits/$habitId/records/$recordId';
  static String habitStats(String habitId) => '/habits/$habitId/stats';
  static const String notificationSettings = '/notification-settings';
  static const String sync = '/sync';
  static const String syncPush = '/sync/push';
  static const String inquiries = '/inquiries';
  static const String legalTerms = '/legal/terms';
  static const String legalPrivacy = '/legal/privacy';
  static const String notices = '/notices';
}
