import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:isar/isar.dart';

import '../auth/auth_repository.dart';
import '../settings/app_settings.dart';
import '../auth/token_storage.dart';
import '../network/api_client.dart';
import '../network/api_endpoints.dart';
import '../network/api_config_stub.dart'
    if (dart.library.io) '../network/api_config_io.dart'
    as api_config;
import '../../data/local/isar_provider.dart';
import '../../data/sync/sync_repository.dart';
import '../../data/habit/habit_repository.dart';
import '../../data/inquiries/inquiry_repository.dart';
import '../../data/legal/legal_repository.dart';
import '../../data/notices/notice_repository.dart';

class UnreadSummary {
  const UnreadSummary({
    required this.noticeUnreadCount,
    required this.inquiryUnreadCount,
  });

  final int noticeUnreadCount;
  final int inquiryUnreadCount;

  bool get hasUnread => noticeUnreadCount > 0 || inquiryUnreadCount > 0;
}

final _tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(baseUrl: api_config.getApiBaseUrl());
});

/// OAuth client ID for a Google Cloud "Web application".
/// Without this, Android may return a null idToken.
const String kGoogleServerClientId =
    '330461831190-mc1srsr433vth1pintipo4v806v4f0c2.apps.googleusercontent.com';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final api = ref.watch(apiClientProvider);
  final storage = ref.watch(_tokenStorageProvider);
  return AuthRepository(
    apiClient: api,
    tokenStorage: storage,
    googleServerClientId: kGoogleServerClientId,
  );
});

/// Runs once at app start. true means session is restored.
final sessionRestoredProvider = FutureProvider<bool>((ref) async {
  return ref.read(authRepositoryProvider).restoreSession();
});

/// GET /me after [sessionRestoredProvider]. `null` = guest or failed fetch.
final meProfileProvider = FutureProvider<MeProfile?>((ref) async {
  final restored = await ref.watch(sessionRestoredProvider.future);
  if (!restored) return null;
  return ref.read(authRepositoryProvider).fetchProfile();
});

/// Isar local DB, initialized once for the app.
final isarProvider = FutureProvider<Isar>((ref) => openIsar());

/// Sync repository (server -> local pull).
final syncRepositoryProvider = Provider<SyncRepository>((ref) {
  final api = ref.watch(apiClientProvider);
  final isarFuture = ref.watch(isarProvider.future);
  return SyncRepository(dio: api.dio, isarFuture: isarFuture);
});

/// Habit and record repository (API + local).
final habitRepositoryProvider = Provider<HabitRepository>((ref) {
  final api = ref.watch(apiClientProvider);
  final isarFuture = ref.watch(isarProvider.future);
  return HabitRepository(dio: api.dio, isarFuture: isarFuture);
});

/// Trigger to refresh Home list after habit create/update.
final homeRefreshTriggerProvider = StateProvider<int>((ref) => 0);

/// Inquiry repository.
final inquiryRepositoryProvider = Provider<InquiryRepository>((ref) {
  return InquiryRepository(dio: ref.watch(apiClientProvider).dio);
});

/// Legal documents repository (public API).
final legalRepositoryProvider = Provider<LegalRepository>((ref) {
  return LegalRepository(dio: ref.watch(apiClientProvider).dio);
});

/// Notices repository (public API).
final noticeRepositoryProvider = Provider<NoticeRepository>((ref) {
  return NoticeRepository(dio: ref.watch(apiClientProvider).dio);
});

/// App-wide settings (notification/sound/haptic).
final appSettingsProvider = FutureProvider<AppSettings>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return AppSettings(prefs);
});

final unreadSummaryProvider = FutureProvider<UnreadSummary>((ref) async {
  final dio = ref.watch(apiClientProvider).dio;
  final res = await dio.get<Map<String, dynamic>>(ApiEndpoints.meUnreadSummary);
  final data = res.data ?? const <String, dynamic>{};
  return UnreadSummary(
    noticeUnreadCount: (data['noticeUnreadCount'] as num?)?.toInt() ?? 0,
    inquiryUnreadCount: (data['inquiryUnreadCount'] as num?)?.toInt() ?? 0,
  );
});
