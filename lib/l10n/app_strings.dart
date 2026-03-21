class AppStrings {
  AppStrings._();

  static String localeCode = 'ko';
  static bool get isKo => localeCode.startsWith('ko');

  static String get authIdTokenMissing => isKo ? 'ID token 없음' : 'ID token missing';
  static String get authGoogleSetupNeeded => isKo
      ? 'Google 로그인 설정이 필요합니다. 개발 PC에서 docs/google-signin-setup.md를 참고해 Google Cloud에 SHA-1을 등록해 주세요.'
      : 'Google sign-in setup is required. Please register SHA-1 in Google Cloud (see docs/google-signin-setup.md).';
  static String get authServerTimeout => isKo
      ? '서버 연결 시간이 초과되었습니다. PC에서 서버(포트 3000)가 실행 중인지 확인해 주세요.'
      : 'Server connection timed out. Check if server (port 3000) is running on your PC.';
  static String get authServerUnreachable => isKo
      ? '서버에 연결할 수 없습니다. Windows 에뮬레이터는 adb reverse tcp:3000 tcp:3000 후 --dart-define=API_USE_LOCALHOST=true 를 써 보세요.'
      : 'Cannot reach server. On Windows emulator try adb reverse tcp:3000 tcp:3000 and --dart-define=API_USE_LOCALHOST=true.';
  static String get authNetworkError => isKo ? '네트워크 오류' : 'Network error';
  static String get authEmptyResponse => isKo ? '응답 없음' : 'Empty response';
  static String get authTokenMissing => isKo ? '토큰 없음' : 'Token missing';
  static String get authTokenSaveFailed => isKo ? '토큰 저장 실패' : 'Failed to save token';
  static String get authKakaoNotConfigured => isKo
      ? '카카오 SDK가 초기화되지 않았습니다. android/local.properties에 KAKAO_NATIVE_APP_KEY를 넣고 앱을 다시 빌드해 주세요.'
      : 'Kakao SDK is not initialized. Add KAKAO_NATIVE_APP_KEY to android/local.properties and rebuild.';
  static String get authKakaoKeyHashFailed => isKo
      ? '카카오 Android 키 해시가 콘솔에 등록되지 않았습니다. 카카오 개발자 콘솔 → 앱 → 플랫폼(Android) → 키 해시에 등록하세요. 방법: docs/kakao-android-keyhash.md'
      : 'Kakao Android key hash is not registered. Add it in Kakao Developers → App → Android platform. See docs/kakao-android-keyhash.md';
  static String get authNaverNotConfigured => isKo
      ? '네이버 SDK가 초기화되지 않았습니다. android/local.properties에 NAVER_* 값을 넣고 앱을 다시 빌드해 주세요.'
      : 'Naver SDK is not initialized. Add NAVER_* keys to android/local.properties and rebuild.';
  static String get authNaverAccessTokenMissing => isKo
      ? '네이버 액세스 토큰을 가져오지 못했습니다. 잠시 후 다시 시도해 주세요.'
      : 'Could not obtain Naver access token. Please try again.';

  static String get notifChannelHabit => isKo ? '습관 리마인더' : 'Habit Reminder';
  static String get notifChannelInquiry => isKo ? '문의 답변 알림' : 'Inquiry Reply';
  static String get notifDescHabit => isKo
      ? '습관별 설정한 시간에 리마인더가 울립니다.'
      : 'Sends reminders at configured habit times.';
  static String get notifDescInquiry => isKo
      ? '문의 답변이 등록되었을 때 알림을 받습니다.'
      : 'Notifies when an inquiry reply is posted.';
  static String get notifFallbackTitle => isKo ? '습관' : 'Habit';
  static String notifFallbackBody(String title) =>
      isKo ? '오늘의 "$title" 확인해 보세요 🌱' : 'Check your "$title" for today 🌱';

  static String get inquiryCreateFailed =>
      isKo ? '문의 등록에 실패했습니다.' : 'Failed to submit inquiry.';
}
