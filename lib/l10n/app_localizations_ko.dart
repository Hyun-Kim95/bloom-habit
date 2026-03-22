// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => 'Bloom Habit';

  @override
  String get navHome => '홈';

  @override
  String get navHabits => '습관';

  @override
  String get navStats => '통계';

  @override
  String get navSettings => '설정';

  @override
  String get pressBackAgainToExit => '한 번 더 누르면 앱이 종료됩니다.';

  @override
  String get connectionErrorMessage =>
      '서버에 연결할 수 없습니다.\n서버(포트 3000)가 켜져 있는지 확인하세요.\nWindows 에뮬레이터: 방화벽이 10.0.2.2를 막는 경우가 많습니다. PC에서 adb reverse tcp:3000 tcp:3000 실행 후 앱을 flutter run --dart-define=API_USE_LOCALHOST=true 로 다시 띄워 보세요.\n실기기: 같은 Wi-Fi의 PC IP로 API_BASE_URL을 지정하세요.';

  @override
  String get retry => '다시 시도';

  @override
  String get todayHabitsTitle => '오늘의 습관';

  @override
  String get addNewHabit => '새 습관 추가';

  @override
  String get emptyHabitTitle => '아직 습관이 없어요.';

  @override
  String get emptyHabitDescription => '새 습관 추가로 첫 습관을 등록해 보세요.';

  @override
  String get completedHeatmapTitle => '완료 히트맵';

  @override
  String get heatmapLess => '적음';

  @override
  String get heatmapMore => '많음';

  @override
  String get todayProgressLabel => '오늘 달성률';

  @override
  String get todayProgressTitle => '오늘의 진행';

  @override
  String get todayProgressDescription => '오늘 목표 중 달성한 습관 비율이에요.';

  @override
  String completedHabitCount(int completed, int total) {
    return '$completed / $total 습관 완료';
  }

  @override
  String get completedTodayDialogTitle => '오늘 완료했어요!';

  @override
  String get confirm => '확인';

  @override
  String get habitTitle => '습관';

  @override
  String get addHabit => '습관 추가';

  @override
  String get noHabitsRegistered => '등록된 습관이 없어요';

  @override
  String get addHabitGuide => '우측 상단 + 버튼으로 습관을 추가해 보세요.';

  @override
  String get activeHabits => '진행 중 습관';

  @override
  String get hiddenHabits => '숨긴 습관';

  @override
  String get settingsTitle => '설정';

  @override
  String get accountManagement => '계정 관리';

  @override
  String get announcements => '공지사항';

  @override
  String get serviceAnnouncementList => '서비스 공지 목록';

  @override
  String get terms => '약관';

  @override
  String get privacyPolicy => '개인정보처리방침';

  @override
  String get inquiry => '문의하기';

  @override
  String get notificationSettings => '알림 설정';

  @override
  String get displaySettings => '표시 설정';

  @override
  String get language => '언어';

  @override
  String get theme => '화면 테마';

  @override
  String get systemTheme => '시스템 설정 따름';

  @override
  String get lightTheme => '라이트 모드';

  @override
  String get darkTheme => '다크 모드';

  @override
  String get weekdayMon => '월';

  @override
  String get weekdayTue => '화';

  @override
  String get weekdayWed => '수';

  @override
  String get weekdayThu => '목';

  @override
  String get weekdayFri => '금';

  @override
  String get weekdaySat => '토';

  @override
  String get weekdaySun => '일';

  @override
  String get ok => '확인';

  @override
  String get day => '일';

  @override
  String get week => '주';

  @override
  String get month => '월';

  @override
  String get skip => '건너뛰기';

  @override
  String get next => '다음';

  @override
  String get getStarted => '시작하기';

  @override
  String get onboardingSubtitle1 => '작은 습관이 인생을 바꿉니다';

  @override
  String get onboardingBody1 => '매일 조금씩 기록하고, 꾸준함을 키워 보세요.';

  @override
  String get onboardingTitle2 => '습관 기록';

  @override
  String get onboardingSubtitle2 => '오늘 한 일을 간단히 체크';

  @override
  String get onboardingBody2 => '완료할 때마다 기록하면 연속 달성일과 통계를 볼 수 있어요.';

  @override
  String get onboardingTitle3 => '시작하기';

  @override
  String get onboardingSubtitle3 => '지금 바로 첫 습관을 만들어 보세요';

  @override
  String get onboardingBody3 => '로그인 후 습관을 추가하고, 오늘부터 기록을 시작해요.';

  @override
  String get loginFailed => '로그인 실패';

  @override
  String get loginSubtitle => '소셜 계정으로 간편히 시작하세요';

  @override
  String get loginWithGoogle => 'Google로 로그인';

  @override
  String get loginWithKakao => '카카오로 로그인';

  @override
  String get loginWithNaver => '네이버로 로그인';

  @override
  String loginError(String message) {
    return '로그인 중 오류: $message';
  }

  @override
  String get hideHabit => '습관 숨기기';

  @override
  String get hideHabitDescription =>
      '이 습관을 숨길까요? 숨긴 습관은 홈 목록에서 보이지 않고, 습관 목록의 숨긴 습관에서 볼 수 있어요.';

  @override
  String get cancel => '취소';

  @override
  String get hide => '숨기기';

  @override
  String get hideFailed => '숨기기 처리에 실패했어요.';

  @override
  String get unhideHabit => '습관 숨김 해제';

  @override
  String get unhideHabitDescription =>
      '이 습관을 다시 표시할까요? 해제하면 진행 중 습관 목록으로 이동합니다.';

  @override
  String get unhide => '해제하기';

  @override
  String get unhideFailed => '숨김 해제 처리에 실패했어요.';

  @override
  String get edit => '수정';

  @override
  String get delete => '삭제';

  @override
  String get enterSubject => '제목을 입력해 주세요.';

  @override
  String get enterContent => '내용을 입력해 주세요.';

  @override
  String get inquirySubmitted => '문의가 등록되었습니다. 관리자 답변을 기다려 주세요.';

  @override
  String get newInquiry => '새 문의';

  @override
  String get subject => '제목';

  @override
  String get inquiryContent => '문의 내용';

  @override
  String get submitInquiry => '문의 등록';

  @override
  String get myInquiries => '내 문의 목록';

  @override
  String get noInquiries => '등록한 문의가 없습니다.';

  @override
  String get answered => '답변 완료';

  @override
  String get pending => '대기 중';

  @override
  String replyAt(String date) {
    return '답변 $date';
  }

  @override
  String get adminReply => '관리자 답변';

  @override
  String replyTime(String date) {
    return '답변 시간: $date';
  }

  @override
  String get noContent => '(내용 없음)';

  @override
  String get untitled => '(제목 없음)';

  @override
  String get noNotices => '등록된 공지가 없습니다.';

  @override
  String get korean => '한국어';

  @override
  String get profileAndLogout => '프로필 및 로그아웃';

  @override
  String get inquirySubtitle => '게시판으로 문의·답변 확인';

  @override
  String get notificationSettingsSubtitle => '습관 리마인더는 여기서 켜세요.';

  @override
  String get soundAndFeedback => '사운드·피드백';

  @override
  String get sound => '사운드';

  @override
  String get soundSubtitle => '기록 완료 시 효과음';

  @override
  String get haptic => '햅틱';

  @override
  String get hapticSubtitle => '진동 피드백';

  @override
  String get loading => '로딩…';

  @override
  String get onboarding => '온보딩';

  @override
  String get replayOnboarding => '온보딩 다시 보기';

  @override
  String get replayOnboardingSubtitle => '시작 화면을 다시 볼 수 있어요';

  @override
  String get showOnlyFirstLaunch => '첫 실행만 보기';

  @override
  String get showOnlyFirstLaunchSubtitle => '끄면 앱을 열 때마다 온보딩을 볼 수 있어요';

  @override
  String get logout => '로그아웃';

  @override
  String versionLabel(String version) {
    return '버전 $version';
  }

  @override
  String yearMonth(int year, int month) {
    return '$year년 $month월';
  }

  @override
  String get todaySummary => '오늘의 요약';

  @override
  String get totalHabits => '전체 습관';

  @override
  String countItems(int count) {
    return '$count개';
  }

  @override
  String get todayCompleted => '오늘 완료';

  @override
  String get last7DaysSuccessRate => '최근 7일 성공률';

  @override
  String get last7DaysSuccessRateDescription =>
      '오늘을 포함한 7일 동안, 활성 습관의 시작일 이후「해야 할 날」대비 완료한 날의 비율입니다.';

  @override
  String get noActiveHabitsForRate => '활성 습관이 없으면 표시되지 않습니다.';

  @override
  String get achieved => '달성';

  @override
  String successPairCount(int completed, int possible) {
    return '$completed / $possible (습관·날 단위)';
  }

  @override
  String get weeklySummary => '주간 요약';

  @override
  String get weeklySuccessRate => '주간 성공률';

  @override
  String get weeklySuccessRateDescription =>
      '선택한 주(월~일) 동안, 활성 습관의 시작일 이후「해야 할 날」대비 완료한 날의 비율입니다.';

  @override
  String get monthlySummary => '월간 요약';

  @override
  String get monthlySuccessRate => '월간 성공률';

  @override
  String get monthlySuccessRateDescription =>
      '선택한 달 동안, 활성 습관의 시작일 이후「해야 할 날」대비 완료한 날의 비율입니다.';

  @override
  String get completedCountLabel => '완료 횟수';

  @override
  String countTimes(int count) {
    return '$count회';
  }

  @override
  String get completedByHabit => '습관별 완료';

  @override
  String get noHabitsYet => '등록된 습관이 없어요.';

  @override
  String get aiFeedback => 'AI 피드백';

  @override
  String get streakByHabit => '습관별 연속일';

  @override
  String daysCount(int count) {
    return '$count일';
  }

  @override
  String get profileLoadFailed => '프로필을 불러오지 못했습니다. 네트워크를 확인해 주세요.';

  @override
  String get nickname => '닉네임';

  @override
  String get nicknameHint => '닉네임 (비워 두면 표시 안 함)';

  @override
  String get max20Chars => '최대 20자';

  @override
  String get save => '저장';

  @override
  String get saved => '저장했어요.';

  @override
  String saveFailed(String message) {
    return '저장 실패: $message';
  }

  @override
  String get profilePhotoManageTitle => '프로필 사진';

  @override
  String get profilePhotoManageSubtitle => '이미지 주소로 바꾸거나 기본 아이콘으로 되돌릴 수 있어요.';

  @override
  String get profilePhotoDialogTitle => '프로필 사진 변경';

  @override
  String get profilePhotoUrlHint => 'https:// 로 시작하는 이미지 주소';

  @override
  String get profilePhotoInvalidUrl => 'http 또는 https 로 시작하는 주소만 사용할 수 있어요.';

  @override
  String get profilePhotoUpdated => '프로필 사진을 반영했어요.';

  @override
  String get resetProfilePhotoButton => '기본 아이콘';

  @override
  String get removeProfilePhoto => '프로필 사진 제거';

  @override
  String get removeProfilePhotoDescription =>
      '저장된 프로필 사진을 지울까요? (Google로 다시 로그인하면 사진이 다시 동기화될 수 있어요.)';

  @override
  String get remove => '제거';

  @override
  String get profilePhotoRemoved => '프로필 사진을 지웠어요.';

  @override
  String processFailed(String message) {
    return '처리 실패: $message';
  }

  @override
  String get deleteAccount => '회원 탈퇴';

  @override
  String get deleteAccountDescription =>
      '탈퇴 즉시 계정이 비활성화되어 다시 로그인할 수 없습니다.\n서버의 습관·기록 등은 비활성화일 기준 최대 1년(365일) 후 자동 삭제되며, 그 전·후 모두 복구되지 않습니다.\n사유를 입력한 뒤 진행해 주세요.';

  @override
  String get withdrawReason => '탈퇴 사유';

  @override
  String get withdrawReasonHint => '탈퇴 사유를 입력해 주세요.';

  @override
  String get withdrawReasonRequired => '탈퇴 사유를 입력해 주세요.';

  @override
  String get withdraw => '탈퇴';

  @override
  String withdrawFailed(String message) {
    return '탈퇴 처리 중 오류가 났어요. $message';
  }

  @override
  String get noName => '이름 없음';

  @override
  String loginWithProvider(String provider) {
    return '$provider 로그인';
  }

  @override
  String get changeNickname => '닉네임 변경';

  @override
  String get nicknameSubtitle => '문의·앱에 보이는 이름입니다. (최대 20자)';

  @override
  String get revertToDefaultIcon => '기본 아이콘으로 돌아갑니다.';

  @override
  String get accountDataWarning =>
      '습관·기록 데이터는 이 계정에 연동됩니다. 회원 탈퇴 시 즉시 로그인이 제한되고, 서버 데이터는 최대 1년(365일) 보관 후 삭제됩니다. 삭제 후에는 복구할 수 없으며, 기기에 남은 데이터는 앱 설정 등으로 별도 삭제할 수 있습니다.';

  @override
  String get emailSectionTitle => '이메일';

  @override
  String get emailStatusNone => '미등록';

  @override
  String get emailStatusVerified => '등록됨';

  @override
  String get emailRegisteredLabel => '등록된 이메일';

  @override
  String get emailEnterHint => 'example@email.com';

  @override
  String get emailRequired => '이메일 주소를 입력해 주세요.';

  @override
  String get withdrawing => '탈퇴 처리 중…';

  @override
  String get enterHabitName => '습관명을 입력하세요';

  @override
  String get notificationPermissionRequired => '알림 권한이 필요합니다. 설정에서 허용해 주세요.';

  @override
  String get serverSlowResponse =>
      '서버 응답이 지연되고 있습니다. 서버와 PostgreSQL이 실행 중인지 확인해 주세요.';

  @override
  String get goalTypeCompletion => '완료 여부';

  @override
  String get goalTypeCount => '횟수';

  @override
  String get goalTypeDuration => '시간';

  @override
  String get goalTypeNumber => '수치';

  @override
  String get createNewHabit => '새 습관 만들기';

  @override
  String get habitName => '습관명';

  @override
  String get habitNameHint => '예: 아침 물 500ml';

  @override
  String get categoryOptional => '카테고리 (선택)';

  @override
  String get noneSelected => '선택 안 함';

  @override
  String get goalType => '목표 유형';

  @override
  String get habitTemplateOptional => '템플릿 (선택)';

  @override
  String get goalCountHint => '목표 횟수 (예: 3)';

  @override
  String get goalDurationHint => '목표 분 (예: 30)';

  @override
  String get goalNumberHint => '목표 수치';

  @override
  String get startDate => '시작일';

  @override
  String get colorOptional => '색상 (선택)';

  @override
  String get iconOptional => '아이콘 (선택)';

  @override
  String get reminderNotification => '리마인더 알림';

  @override
  String get reminderNotificationSubtitle => '매일 설정한 시간에 이 습관 알림';

  @override
  String get notificationTime => '알림 시간';

  @override
  String get editFailedTryAgain => '수정에 실패했어요. 다시 시도해 주세요.';

  @override
  String get deleteRecord => '기록 삭제';

  @override
  String deleteRecordForDate(String date) {
    return '$date 기록을 삭제할까요?';
  }

  @override
  String get processFailedTryAgain => '처리하지 못했어요. 다시 시도해 주세요.';

  @override
  String get completeToday => '오늘 완료하기';

  @override
  String get completionPraiseCategoryHealth => '건강 습관을 지켜냈어요. 몸이 고마워할 거예요!';

  @override
  String get completionPraiseCategoryExercise => '오늘도 움직임으로 몸을 깨우셨네요. 멋져요!';

  @override
  String get completionPraiseCategoryReading => '책과 함께한 오늘, 쌓이는 시간이에요.';

  @override
  String get completionPraiseCategoryLearning => '배움의 한 걸음, 잘하셨어요!';

  @override
  String get completionPraiseCategoryMeditation => '마음까지 챙기는 하루. 오늘도 균형 잡혔어요.';

  @override
  String get completionPraiseCategoryHobby => '좋아하는 일에 시간 쓴 하루, 빛나요.';

  @override
  String get completionPraiseCategoryWork => '업무 습관 하나 지켰어요. 생산적인 하루!';

  @override
  String get completionPraiseCategoryLife => '생활을 가지런히 하셨네요. 속이 시원할 거예요.';

  @override
  String get completionPraiseGoalCompletion => '오늘 목표를 완료했어요. 스스로 칭찬해 주세요!';

  @override
  String get completionPraiseGoalCount => '목표 횟수를 채웠어요. 꾸준함이 빛나요!';

  @override
  String get completionPraiseGoalDuration => '정한 시간만큼 해냈어요. 집중력이 대단해요!';

  @override
  String get completionPraiseGoalNumber => '수치 목표에 한 걸음 더 가까워졌어요!';

  @override
  String get recordHistory => '기록 히스토리';

  @override
  String get noRecent30DaysRecords => '최근 30일 기록이 없어요.';

  @override
  String get deleteHabit => '습관 삭제';

  @override
  String get deleteHabitDescription => '이 습관을 삭제할까요?';

  @override
  String get editHabit => '습관 수정';

  @override
  String get goalValue => '목표값';

  @override
  String get color => '색상';

  @override
  String get icon => '아이콘';

  @override
  String pageNotFound(String uri) {
    return '페이지를 찾을 수 없습니다: $uri';
  }
}
