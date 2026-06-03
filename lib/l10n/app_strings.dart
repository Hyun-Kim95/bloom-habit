class AppStrings {
  AppStrings._();

  static String localeCode = 'ko';
  static bool get isKo => localeCode.startsWith('ko');

  // User-facing (auth layer without BuildContext)
  static String get connectionErrorUser => isKo
      ? '서버에 연결할 수 없습니다. 네트워크를 확인한 뒤 다시 시도해 주세요.'
      : 'Unable to connect to the server. Check your network and try again.';
  static String get serverSlowResponse => isKo
      ? '응답이 지연되고 있어요. 잠시 후 다시 시도해 주세요.'
      : 'The response is taking longer than usual. Please try again later.';
  static String get authSessionExpired => isKo
      ? '로그인이 만료되었어요. 다시 로그인해 주세요.'
      : 'Your session has expired. Please sign in again.';
  static String get serverRequestFailed => isKo
      ? '요청을 처리하지 못했어요. 잠시 후 다시 시도해 주세요.'
      : 'We could not complete your request. Please try again.';
  static String get unexpectedErrorTryAgain => isKo
      ? '문제가 발생했어요. 잠시 후 다시 시도해 주세요.'
      : 'Something went wrong. Please try again later.';
  static String get loadFailedTryAgain => isKo
      ? '불러오지 못했어요. 다시 시도해 주세요.'
      : 'Could not load data. Please try again.';
  static String get saveFailedTryAgain => isKo
      ? '저장하지 못했어요. 다시 시도해 주세요.'
      : 'Could not save. Please try again.';
  static String get submitFailedTryAgain => isKo
      ? '등록하지 못했어요. 다시 시도해 주세요.'
      : 'Could not submit. Please try again.';
  static String get processFailedTryAgain => isKo
      ? '처리하지 못했어요. 다시 시도해 주세요.'
      : 'Could not process. Please try again.';
  static String get withdrawFailedTryAgain => isKo
      ? '탈퇴 처리하지 못했어요. 다시 시도해 주세요.'
      : 'Could not complete account deletion. Please try again.';
  static String get loginFailedGeneric => isKo
      ? '로그인에 실패했어요. 잠시 후 다시 시도해 주세요.'
      : 'Sign-in failed. Please try again later.';

  static String get authIdTokenMissing => loginFailedGeneric;
  static String get authGoogleSetupNeeded => loginFailedGeneric;
  static String get authServerTimeout => serverSlowResponse;
  static String get authServerUnreachable => connectionErrorUser;
  static String get authNetworkError => unexpectedErrorTryAgain;
  static String get authEmptyResponse => unexpectedErrorTryAgain;
  static String get authTokenMissing => unexpectedErrorTryAgain;
  static String get authTokenSaveFailed => saveFailedTryAgain;
  static String get authKakaoNotConfigured => loginFailedGeneric;
  static String get authKakaoKeyHashFailed => loginFailedGeneric;
  static String get authKakaoAccessTokenMissing => loginFailedGeneric;
  static String get authNaverNotConfigured => isKo
      ? '네이버 로그인 설정을 불러오지 못했어요. 앱을 완전히 종료한 뒤 다시 시도해 주세요.'
      : 'Could not load Naver login settings. Fully close the app and try again.';
  static String get authNaverAccessTokenMissing => isKo
      ? '네이버 로그인 인증이 끝나지 않았어요. 다시 시도해 주세요.'
      : 'Naver sign-in did not finish. Please try again.';
  static String get authNaverSdkConfigNeeded => isKo
      ? '네이버 로그인 처리 중 오류가 났어요. 잠시 후 다시 시도해 주세요.'
      : 'Naver sign-in failed. Please try again later.';
  static String get authNaverReleaseR8Error => isKo
      ? '네이버 로그인에 실패했어요. 최신 APK를 다시 설치한 뒤 시도해 주세요. (no_catagorized)'
      : 'Naver sign-in failed. Reinstall the latest APK and try again.';
  static String get authNaverConsoleMismatch => isKo
      ? '네이버 개발자 센터 > 내 애플리케이션 > Android 환경에서 패키지명(com.khyun.bloom_habit)과 Client ID·Secret이 앱 빌드 값과 같은지 확인해 주세요.'
      : 'In Naver developer console, check Android package com.khyun.bloom_habit and that Client ID/Secret match your app build.';
  static String get authNaverCertificationError => isKo
      ? '네이버 로그인 통신(인증서) 오류예요. 기기 날짜·시간과 네트워크를 확인한 뒤 다시 시도해 주세요.'
      : 'Naver sign-in certificate error. Check device date/time and network, then try again.';
  static String get authNaverKeysMissingAtBuild => isKo
      ? '앱 빌드에 네이버 로그인 키가 포함되지 않았어요. (android/local.properties의 NAVER_CLIENT_ID 등)'
      : 'Naver login keys were missing at build time (NAVER_CLIENT_ID in android/local.properties).';
  static String get authNaverProfileFailed => isKo
      ? '네이버 프로필을 가져오지 못했어요. 잠시 후 다시 시도해 주세요.'
      : 'Could not load your Naver profile. Please try again later.';
  static String get authNaverLoginFailed => loginFailedGeneric;

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
