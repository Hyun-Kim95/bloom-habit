import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:isar/isar.dart';

import '../auth/auth_repository.dart';
import '../settings/app_settings.dart';
import '../auth/token_storage.dart';
import '../network/api_client.dart';
import '../network/api_config_stub.dart'
    if (dart.library.io) '../network/api_config_io.dart'
    as api_config;
import '../../data/local/isar_provider.dart';
import '../../data/sync/sync_repository.dart';
import '../../data/habit/habit_repository.dart';
import '../../data/inquiries/inquiry_repository.dart';
import '../../data/legal/legal_repository.dart';

final _tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(baseUrl: api_config.getApiBaseUrl());
});

/// Google Cloud Console에서 만든 "웹 애플리케이션" OAuth 클라이언트 ID (xxx.apps.googleusercontent.com).
/// 없으면 Android에서 idToken이 null로 올 수 있음. docs/google-signin-setup.md 참고.
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

/// 앱 시작 시 한 번만 실행. true면 로그인 상태 유지 중.
final sessionRestoredProvider = FutureProvider<bool>((ref) async {
  return ref.read(authRepositoryProvider).restoreSession();
});

/// Isar (로컬 DB) - 앱에서 한 번만 초기화
final isarProvider = FutureProvider<Isar>((ref) => openIsar());

/// 동기화 (서버 → 로컬 풀)
final syncRepositoryProvider = Provider<SyncRepository>((ref) {
  final api = ref.watch(apiClientProvider);
  final isarFuture = ref.watch(isarProvider.future);
  return SyncRepository(dio: api.dio, isarFuture: isarFuture);
});

/// 습관·기록 (API + 로컬)
final habitRepositoryProvider = Provider<HabitRepository>((ref) {
  final api = ref.watch(apiClientProvider);
  final isarFuture = ref.watch(isarProvider.future);
  return HabitRepository(dio: api.dio, isarFuture: isarFuture);
});

/// 습관 추가/수정 후 홈 목록 갱신용 (값이 바뀌면 HomeScreen이 _load 호출)
final homeRefreshTriggerProvider = StateProvider<int>((ref) => 0);

/// 문의 (게시판)
final inquiryRepositoryProvider = Provider<InquiryRepository>((ref) {
  return InquiryRepository(dio: ref.watch(apiClientProvider).dio);
});

/// 약관·개인정보 (공개 API)
final legalRepositoryProvider = Provider<LegalRepository>((ref) {
  return LegalRepository(dio: ref.watch(apiClientProvider).dio);
});

/// 앱 전역 설정 (알림/사운드/햅틱)
final appSettingsProvider = FutureProvider<AppSettings>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return AppSettings(prefs);
});
