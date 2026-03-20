import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ko.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ko'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In ko, this message translates to:
  /// **'Bloom Habit'**
  String get appTitle;

  /// No description provided for @navHome.
  ///
  /// In ko, this message translates to:
  /// **'홈'**
  String get navHome;

  /// No description provided for @navHabits.
  ///
  /// In ko, this message translates to:
  /// **'습관'**
  String get navHabits;

  /// No description provided for @navStats.
  ///
  /// In ko, this message translates to:
  /// **'통계'**
  String get navStats;

  /// No description provided for @navSettings.
  ///
  /// In ko, this message translates to:
  /// **'설정'**
  String get navSettings;

  /// No description provided for @pressBackAgainToExit.
  ///
  /// In ko, this message translates to:
  /// **'한 번 더 누르면 앱이 종료됩니다.'**
  String get pressBackAgainToExit;

  /// No description provided for @connectionErrorMessage.
  ///
  /// In ko, this message translates to:
  /// **'서버에 연결할 수 없습니다.\n서버가 실행 중인지 확인하고, 에뮬레이터는 10.0.2.2:3000, 실기기는 같은 Wi-Fi의 PC IP로 연결해 보세요.'**
  String get connectionErrorMessage;

  /// No description provided for @retry.
  ///
  /// In ko, this message translates to:
  /// **'다시 시도'**
  String get retry;

  /// No description provided for @todayHabitsTitle.
  ///
  /// In ko, this message translates to:
  /// **'오늘의 습관'**
  String get todayHabitsTitle;

  /// No description provided for @addNewHabit.
  ///
  /// In ko, this message translates to:
  /// **'새 습관 추가'**
  String get addNewHabit;

  /// No description provided for @emptyHabitTitle.
  ///
  /// In ko, this message translates to:
  /// **'아직 습관이 없어요.'**
  String get emptyHabitTitle;

  /// No description provided for @emptyHabitDescription.
  ///
  /// In ko, this message translates to:
  /// **'새 습관 추가로 첫 습관을 등록해 보세요.'**
  String get emptyHabitDescription;

  /// No description provided for @completedHeatmapTitle.
  ///
  /// In ko, this message translates to:
  /// **'완료 히트맵'**
  String get completedHeatmapTitle;

  /// No description provided for @heatmapLess.
  ///
  /// In ko, this message translates to:
  /// **'적음'**
  String get heatmapLess;

  /// No description provided for @heatmapMore.
  ///
  /// In ko, this message translates to:
  /// **'많음'**
  String get heatmapMore;

  /// No description provided for @todayProgressLabel.
  ///
  /// In ko, this message translates to:
  /// **'오늘 달성률'**
  String get todayProgressLabel;

  /// No description provided for @todayProgressTitle.
  ///
  /// In ko, this message translates to:
  /// **'오늘의 진행'**
  String get todayProgressTitle;

  /// No description provided for @todayProgressDescription.
  ///
  /// In ko, this message translates to:
  /// **'오늘 목표 중 달성한 습관 비율이에요.'**
  String get todayProgressDescription;

  /// No description provided for @completedHabitCount.
  ///
  /// In ko, this message translates to:
  /// **'{completed} / {total} 습관 완료'**
  String completedHabitCount(int completed, int total);

  /// No description provided for @completedTodayDialogTitle.
  ///
  /// In ko, this message translates to:
  /// **'오늘 완료했어요!'**
  String get completedTodayDialogTitle;

  /// No description provided for @confirm.
  ///
  /// In ko, this message translates to:
  /// **'확인'**
  String get confirm;

  /// No description provided for @habitTitle.
  ///
  /// In ko, this message translates to:
  /// **'습관'**
  String get habitTitle;

  /// No description provided for @addHabit.
  ///
  /// In ko, this message translates to:
  /// **'습관 추가'**
  String get addHabit;

  /// No description provided for @noHabitsRegistered.
  ///
  /// In ko, this message translates to:
  /// **'등록된 습관이 없어요'**
  String get noHabitsRegistered;

  /// No description provided for @addHabitGuide.
  ///
  /// In ko, this message translates to:
  /// **'우측 상단 + 버튼으로 습관을 추가해 보세요.'**
  String get addHabitGuide;

  /// No description provided for @activeHabits.
  ///
  /// In ko, this message translates to:
  /// **'진행 중 습관'**
  String get activeHabits;

  /// No description provided for @hiddenHabits.
  ///
  /// In ko, this message translates to:
  /// **'숨긴 습관'**
  String get hiddenHabits;

  /// No description provided for @settingsTitle.
  ///
  /// In ko, this message translates to:
  /// **'설정'**
  String get settingsTitle;

  /// No description provided for @accountManagement.
  ///
  /// In ko, this message translates to:
  /// **'계정 관리'**
  String get accountManagement;

  /// No description provided for @announcements.
  ///
  /// In ko, this message translates to:
  /// **'공지사항'**
  String get announcements;

  /// No description provided for @serviceAnnouncementList.
  ///
  /// In ko, this message translates to:
  /// **'서비스 공지 목록'**
  String get serviceAnnouncementList;

  /// No description provided for @terms.
  ///
  /// In ko, this message translates to:
  /// **'약관'**
  String get terms;

  /// No description provided for @privacyPolicy.
  ///
  /// In ko, this message translates to:
  /// **'개인정보처리방침'**
  String get privacyPolicy;

  /// No description provided for @inquiry.
  ///
  /// In ko, this message translates to:
  /// **'문의하기'**
  String get inquiry;

  /// No description provided for @notificationSettings.
  ///
  /// In ko, this message translates to:
  /// **'알림 설정'**
  String get notificationSettings;

  /// No description provided for @displaySettings.
  ///
  /// In ko, this message translates to:
  /// **'표시 설정'**
  String get displaySettings;

  /// No description provided for @language.
  ///
  /// In ko, this message translates to:
  /// **'언어'**
  String get language;

  /// No description provided for @theme.
  ///
  /// In ko, this message translates to:
  /// **'화면 테마'**
  String get theme;

  /// No description provided for @systemTheme.
  ///
  /// In ko, this message translates to:
  /// **'시스템 설정 따름'**
  String get systemTheme;

  /// No description provided for @lightTheme.
  ///
  /// In ko, this message translates to:
  /// **'라이트 모드'**
  String get lightTheme;

  /// No description provided for @darkTheme.
  ///
  /// In ko, this message translates to:
  /// **'다크 모드'**
  String get darkTheme;

  /// No description provided for @weekdayMon.
  ///
  /// In ko, this message translates to:
  /// **'월'**
  String get weekdayMon;

  /// No description provided for @weekdayTue.
  ///
  /// In ko, this message translates to:
  /// **'화'**
  String get weekdayTue;

  /// No description provided for @weekdayWed.
  ///
  /// In ko, this message translates to:
  /// **'수'**
  String get weekdayWed;

  /// No description provided for @weekdayThu.
  ///
  /// In ko, this message translates to:
  /// **'목'**
  String get weekdayThu;

  /// No description provided for @weekdayFri.
  ///
  /// In ko, this message translates to:
  /// **'금'**
  String get weekdayFri;

  /// No description provided for @weekdaySat.
  ///
  /// In ko, this message translates to:
  /// **'토'**
  String get weekdaySat;

  /// No description provided for @weekdaySun.
  ///
  /// In ko, this message translates to:
  /// **'일'**
  String get weekdaySun;

  /// No description provided for @ok.
  ///
  /// In ko, this message translates to:
  /// **'확인'**
  String get ok;

  /// No description provided for @day.
  ///
  /// In ko, this message translates to:
  /// **'일'**
  String get day;

  /// No description provided for @week.
  ///
  /// In ko, this message translates to:
  /// **'주'**
  String get week;

  /// No description provided for @month.
  ///
  /// In ko, this message translates to:
  /// **'월'**
  String get month;

  /// No description provided for @skip.
  ///
  /// In ko, this message translates to:
  /// **'건너뛰기'**
  String get skip;

  /// No description provided for @next.
  ///
  /// In ko, this message translates to:
  /// **'다음'**
  String get next;

  /// No description provided for @getStarted.
  ///
  /// In ko, this message translates to:
  /// **'시작하기'**
  String get getStarted;

  /// No description provided for @onboardingSubtitle1.
  ///
  /// In ko, this message translates to:
  /// **'작은 습관이 인생을 바꿉니다'**
  String get onboardingSubtitle1;

  /// No description provided for @onboardingBody1.
  ///
  /// In ko, this message translates to:
  /// **'매일 조금씩 기록하고, 꾸준함을 키워 보세요.'**
  String get onboardingBody1;

  /// No description provided for @onboardingTitle2.
  ///
  /// In ko, this message translates to:
  /// **'습관 기록'**
  String get onboardingTitle2;

  /// No description provided for @onboardingSubtitle2.
  ///
  /// In ko, this message translates to:
  /// **'오늘 한 일을 간단히 체크'**
  String get onboardingSubtitle2;

  /// No description provided for @onboardingBody2.
  ///
  /// In ko, this message translates to:
  /// **'완료할 때마다 기록하면 연속 달성일과 통계를 볼 수 있어요.'**
  String get onboardingBody2;

  /// No description provided for @onboardingTitle3.
  ///
  /// In ko, this message translates to:
  /// **'시작하기'**
  String get onboardingTitle3;

  /// No description provided for @onboardingSubtitle3.
  ///
  /// In ko, this message translates to:
  /// **'지금 바로 첫 습관을 만들어 보세요'**
  String get onboardingSubtitle3;

  /// No description provided for @onboardingBody3.
  ///
  /// In ko, this message translates to:
  /// **'로그인 후 습관을 추가하고, 오늘부터 기록을 시작해요.'**
  String get onboardingBody3;

  /// No description provided for @loginFailed.
  ///
  /// In ko, this message translates to:
  /// **'로그인 실패'**
  String get loginFailed;

  /// No description provided for @loginSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'소셜 계정으로 간편히 시작하세요'**
  String get loginSubtitle;

  /// No description provided for @loginWithGoogle.
  ///
  /// In ko, this message translates to:
  /// **'Google로 로그인'**
  String get loginWithGoogle;

  /// No description provided for @loginWithKakao.
  ///
  /// In ko, this message translates to:
  /// **'카카오로 로그인'**
  String get loginWithKakao;

  /// No description provided for @loginWithNaver.
  ///
  /// In ko, this message translates to:
  /// **'네이버로 로그인'**
  String get loginWithNaver;

  /// No description provided for @loginError.
  ///
  /// In ko, this message translates to:
  /// **'로그인 중 오류: {message}'**
  String loginError(String message);

  /// No description provided for @hideHabit.
  ///
  /// In ko, this message translates to:
  /// **'습관 숨기기'**
  String get hideHabit;

  /// No description provided for @hideHabitDescription.
  ///
  /// In ko, this message translates to:
  /// **'이 습관을 숨길까요? 숨긴 습관은 홈 목록에서 보이지 않고, 습관 목록의 숨긴 습관에서 볼 수 있어요.'**
  String get hideHabitDescription;

  /// No description provided for @cancel.
  ///
  /// In ko, this message translates to:
  /// **'취소'**
  String get cancel;

  /// No description provided for @hide.
  ///
  /// In ko, this message translates to:
  /// **'숨기기'**
  String get hide;

  /// No description provided for @hideFailed.
  ///
  /// In ko, this message translates to:
  /// **'숨기기 처리에 실패했어요.'**
  String get hideFailed;

  /// No description provided for @unhideHabit.
  ///
  /// In ko, this message translates to:
  /// **'습관 숨김 해제'**
  String get unhideHabit;

  /// No description provided for @unhideHabitDescription.
  ///
  /// In ko, this message translates to:
  /// **'이 습관을 다시 표시할까요? 해제하면 진행 중 습관 목록으로 이동합니다.'**
  String get unhideHabitDescription;

  /// No description provided for @unhide.
  ///
  /// In ko, this message translates to:
  /// **'해제하기'**
  String get unhide;

  /// No description provided for @unhideFailed.
  ///
  /// In ko, this message translates to:
  /// **'숨김 해제 처리에 실패했어요.'**
  String get unhideFailed;

  /// No description provided for @edit.
  ///
  /// In ko, this message translates to:
  /// **'수정'**
  String get edit;

  /// No description provided for @delete.
  ///
  /// In ko, this message translates to:
  /// **'삭제'**
  String get delete;

  /// No description provided for @enterSubject.
  ///
  /// In ko, this message translates to:
  /// **'제목을 입력해 주세요.'**
  String get enterSubject;

  /// No description provided for @enterContent.
  ///
  /// In ko, this message translates to:
  /// **'내용을 입력해 주세요.'**
  String get enterContent;

  /// No description provided for @inquirySubmitted.
  ///
  /// In ko, this message translates to:
  /// **'문의가 등록되었습니다. 관리자 답변을 기다려 주세요.'**
  String get inquirySubmitted;

  /// No description provided for @newInquiry.
  ///
  /// In ko, this message translates to:
  /// **'새 문의'**
  String get newInquiry;

  /// No description provided for @subject.
  ///
  /// In ko, this message translates to:
  /// **'제목'**
  String get subject;

  /// No description provided for @inquiryContent.
  ///
  /// In ko, this message translates to:
  /// **'문의 내용'**
  String get inquiryContent;

  /// No description provided for @submitInquiry.
  ///
  /// In ko, this message translates to:
  /// **'문의 등록'**
  String get submitInquiry;

  /// No description provided for @myInquiries.
  ///
  /// In ko, this message translates to:
  /// **'내 문의 목록'**
  String get myInquiries;

  /// No description provided for @noInquiries.
  ///
  /// In ko, this message translates to:
  /// **'등록한 문의가 없습니다.'**
  String get noInquiries;

  /// No description provided for @answered.
  ///
  /// In ko, this message translates to:
  /// **'답변 완료'**
  String get answered;

  /// No description provided for @pending.
  ///
  /// In ko, this message translates to:
  /// **'대기 중'**
  String get pending;

  /// No description provided for @replyAt.
  ///
  /// In ko, this message translates to:
  /// **'답변 {date}'**
  String replyAt(String date);

  /// No description provided for @adminReply.
  ///
  /// In ko, this message translates to:
  /// **'관리자 답변'**
  String get adminReply;

  /// No description provided for @replyTime.
  ///
  /// In ko, this message translates to:
  /// **'답변 시간: {date}'**
  String replyTime(String date);

  /// No description provided for @noContent.
  ///
  /// In ko, this message translates to:
  /// **'(내용 없음)'**
  String get noContent;

  /// No description provided for @untitled.
  ///
  /// In ko, this message translates to:
  /// **'(제목 없음)'**
  String get untitled;

  /// No description provided for @noNotices.
  ///
  /// In ko, this message translates to:
  /// **'등록된 공지가 없습니다.'**
  String get noNotices;

  /// No description provided for @korean.
  ///
  /// In ko, this message translates to:
  /// **'한국어'**
  String get korean;

  /// No description provided for @profileAndLogout.
  ///
  /// In ko, this message translates to:
  /// **'프로필 및 로그아웃'**
  String get profileAndLogout;

  /// No description provided for @inquirySubtitle.
  ///
  /// In ko, this message translates to:
  /// **'게시판으로 문의·답변 확인'**
  String get inquirySubtitle;

  /// No description provided for @notificationSettingsSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'습관 리마인더는 여기서 켜세요. (권한이 아닌 알림 메뉴)'**
  String get notificationSettingsSubtitle;

  /// No description provided for @soundAndFeedback.
  ///
  /// In ko, this message translates to:
  /// **'사운드·피드백'**
  String get soundAndFeedback;

  /// No description provided for @sound.
  ///
  /// In ko, this message translates to:
  /// **'사운드'**
  String get sound;

  /// No description provided for @soundSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'기록 완료 시 효과음'**
  String get soundSubtitle;

  /// No description provided for @haptic.
  ///
  /// In ko, this message translates to:
  /// **'햅틱'**
  String get haptic;

  /// No description provided for @hapticSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'진동 피드백'**
  String get hapticSubtitle;

  /// No description provided for @loading.
  ///
  /// In ko, this message translates to:
  /// **'로딩…'**
  String get loading;

  /// No description provided for @onboarding.
  ///
  /// In ko, this message translates to:
  /// **'온보딩'**
  String get onboarding;

  /// No description provided for @replayOnboarding.
  ///
  /// In ko, this message translates to:
  /// **'온보딩 다시 보기'**
  String get replayOnboarding;

  /// No description provided for @replayOnboardingSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'시작 화면을 다시 볼 수 있어요'**
  String get replayOnboardingSubtitle;

  /// No description provided for @showOnlyFirstLaunch.
  ///
  /// In ko, this message translates to:
  /// **'첫 실행만 보기'**
  String get showOnlyFirstLaunch;

  /// No description provided for @showOnlyFirstLaunchSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'끄면 앱을 열 때마다 온보딩을 볼 수 있어요'**
  String get showOnlyFirstLaunchSubtitle;

  /// No description provided for @logout.
  ///
  /// In ko, this message translates to:
  /// **'로그아웃'**
  String get logout;

  /// No description provided for @versionLabel.
  ///
  /// In ko, this message translates to:
  /// **'버전 {version}'**
  String versionLabel(String version);

  /// No description provided for @yearMonth.
  ///
  /// In ko, this message translates to:
  /// **'{year}년 {month}월'**
  String yearMonth(int year, int month);

  /// No description provided for @todaySummary.
  ///
  /// In ko, this message translates to:
  /// **'오늘의 요약'**
  String get todaySummary;

  /// No description provided for @totalHabits.
  ///
  /// In ko, this message translates to:
  /// **'전체 습관'**
  String get totalHabits;

  /// No description provided for @countItems.
  ///
  /// In ko, this message translates to:
  /// **'{count}개'**
  String countItems(int count);

  /// No description provided for @todayCompleted.
  ///
  /// In ko, this message translates to:
  /// **'오늘 완료'**
  String get todayCompleted;

  /// No description provided for @last7DaysSuccessRate.
  ///
  /// In ko, this message translates to:
  /// **'최근 7일 성공률'**
  String get last7DaysSuccessRate;

  /// No description provided for @last7DaysSuccessRateDescription.
  ///
  /// In ko, this message translates to:
  /// **'오늘을 포함한 7일 동안, 활성 습관의 시작일 이후「해야 할 날」대비 완료한 날의 비율입니다.'**
  String get last7DaysSuccessRateDescription;

  /// No description provided for @noActiveHabitsForRate.
  ///
  /// In ko, this message translates to:
  /// **'활성 습관이 없으면 표시되지 않습니다.'**
  String get noActiveHabitsForRate;

  /// No description provided for @achieved.
  ///
  /// In ko, this message translates to:
  /// **'달성'**
  String get achieved;

  /// No description provided for @successPairCount.
  ///
  /// In ko, this message translates to:
  /// **'{completed} / {possible} (습관·날 단위)'**
  String successPairCount(int completed, int possible);

  /// No description provided for @weeklySummary.
  ///
  /// In ko, this message translates to:
  /// **'주간 요약'**
  String get weeklySummary;

  /// No description provided for @weeklySuccessRate.
  ///
  /// In ko, this message translates to:
  /// **'주간 성공률'**
  String get weeklySuccessRate;

  /// No description provided for @weeklySuccessRateDescription.
  ///
  /// In ko, this message translates to:
  /// **'선택한 주(월~일) 동안, 활성 습관의 시작일 이후「해야 할 날」대비 완료한 날의 비율입니다.'**
  String get weeklySuccessRateDescription;

  /// No description provided for @monthlySummary.
  ///
  /// In ko, this message translates to:
  /// **'월간 요약'**
  String get monthlySummary;

  /// No description provided for @monthlySuccessRate.
  ///
  /// In ko, this message translates to:
  /// **'월간 성공률'**
  String get monthlySuccessRate;

  /// No description provided for @monthlySuccessRateDescription.
  ///
  /// In ko, this message translates to:
  /// **'선택한 달 동안, 활성 습관의 시작일 이후「해야 할 날」대비 완료한 날의 비율입니다.'**
  String get monthlySuccessRateDescription;

  /// No description provided for @completedCountLabel.
  ///
  /// In ko, this message translates to:
  /// **'완료 횟수'**
  String get completedCountLabel;

  /// No description provided for @countTimes.
  ///
  /// In ko, this message translates to:
  /// **'{count}회'**
  String countTimes(int count);

  /// No description provided for @completedByHabit.
  ///
  /// In ko, this message translates to:
  /// **'습관별 완료'**
  String get completedByHabit;

  /// No description provided for @noHabitsYet.
  ///
  /// In ko, this message translates to:
  /// **'등록된 습관이 없어요.'**
  String get noHabitsYet;

  /// No description provided for @aiFeedback.
  ///
  /// In ko, this message translates to:
  /// **'AI 피드백'**
  String get aiFeedback;

  /// No description provided for @streakByHabit.
  ///
  /// In ko, this message translates to:
  /// **'습관별 연속일'**
  String get streakByHabit;

  /// No description provided for @daysCount.
  ///
  /// In ko, this message translates to:
  /// **'{count}일'**
  String daysCount(int count);

  /// No description provided for @profileLoadFailed.
  ///
  /// In ko, this message translates to:
  /// **'프로필을 불러오지 못했습니다. 네트워크를 확인해 주세요.'**
  String get profileLoadFailed;

  /// No description provided for @nickname.
  ///
  /// In ko, this message translates to:
  /// **'닉네임'**
  String get nickname;

  /// No description provided for @nicknameHint.
  ///
  /// In ko, this message translates to:
  /// **'닉네임 (비워 두면 표시 안 함)'**
  String get nicknameHint;

  /// No description provided for @max20Chars.
  ///
  /// In ko, this message translates to:
  /// **'최대 20자'**
  String get max20Chars;

  /// No description provided for @save.
  ///
  /// In ko, this message translates to:
  /// **'저장'**
  String get save;

  /// No description provided for @saved.
  ///
  /// In ko, this message translates to:
  /// **'저장했어요.'**
  String get saved;

  /// No description provided for @saveFailed.
  ///
  /// In ko, this message translates to:
  /// **'저장 실패: {message}'**
  String saveFailed(String message);

  /// No description provided for @removeProfilePhoto.
  ///
  /// In ko, this message translates to:
  /// **'프로필 사진 제거'**
  String get removeProfilePhoto;

  /// No description provided for @removeProfilePhotoDescription.
  ///
  /// In ko, this message translates to:
  /// **'저장된 프로필 사진을 지울까요? (Google로 다시 로그인하면 사진이 다시 동기화될 수 있어요.)'**
  String get removeProfilePhotoDescription;

  /// No description provided for @remove.
  ///
  /// In ko, this message translates to:
  /// **'제거'**
  String get remove;

  /// No description provided for @profilePhotoRemoved.
  ///
  /// In ko, this message translates to:
  /// **'프로필 사진을 지웠어요.'**
  String get profilePhotoRemoved;

  /// No description provided for @processFailed.
  ///
  /// In ko, this message translates to:
  /// **'처리 실패: {message}'**
  String processFailed(String message);

  /// No description provided for @deleteAccount.
  ///
  /// In ko, this message translates to:
  /// **'회원 탈퇴'**
  String get deleteAccount;

  /// No description provided for @deleteAccountDescription.
  ///
  /// In ko, this message translates to:
  /// **'탈퇴하면 계정이 비활성화되며 로그인할 수 없습니다.\n사유를 입력한 뒤 탈퇴를 진행해 주세요.'**
  String get deleteAccountDescription;

  /// No description provided for @withdrawReason.
  ///
  /// In ko, this message translates to:
  /// **'탈퇴 사유'**
  String get withdrawReason;

  /// No description provided for @withdrawReasonHint.
  ///
  /// In ko, this message translates to:
  /// **'탈퇴 사유를 입력해 주세요.'**
  String get withdrawReasonHint;

  /// No description provided for @withdrawReasonRequired.
  ///
  /// In ko, this message translates to:
  /// **'탈퇴 사유를 입력해 주세요.'**
  String get withdrawReasonRequired;

  /// No description provided for @withdraw.
  ///
  /// In ko, this message translates to:
  /// **'탈퇴'**
  String get withdraw;

  /// No description provided for @withdrawFailed.
  ///
  /// In ko, this message translates to:
  /// **'탈퇴 처리 중 오류가 났어요. {message}'**
  String withdrawFailed(String message);

  /// No description provided for @noName.
  ///
  /// In ko, this message translates to:
  /// **'이름 없음'**
  String get noName;

  /// No description provided for @loginWithProvider.
  ///
  /// In ko, this message translates to:
  /// **'{provider} 로그인'**
  String loginWithProvider(String provider);

  /// No description provided for @changeNickname.
  ///
  /// In ko, this message translates to:
  /// **'닉네임 변경'**
  String get changeNickname;

  /// No description provided for @nicknameSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'문의·앱에 보이는 이름입니다. (최대 20자)'**
  String get nicknameSubtitle;

  /// No description provided for @revertToDefaultIcon.
  ///
  /// In ko, this message translates to:
  /// **'기본 아이콘으로 돌아갑니다.'**
  String get revertToDefaultIcon;

  /// No description provided for @accountDataWarning.
  ///
  /// In ko, this message translates to:
  /// **'습관·기록 데이터는 이 계정에 연동됩니다. 회원 탈퇴 시 서버와 기기에 저장된 데이터가 삭제되며 복구할 수 없습니다.'**
  String get accountDataWarning;

  /// No description provided for @withdrawing.
  ///
  /// In ko, this message translates to:
  /// **'탈퇴 처리 중…'**
  String get withdrawing;

  /// No description provided for @enterHabitName.
  ///
  /// In ko, this message translates to:
  /// **'습관명을 입력하세요'**
  String get enterHabitName;

  /// No description provided for @notificationPermissionRequired.
  ///
  /// In ko, this message translates to:
  /// **'알림 권한이 필요합니다. 설정에서 허용해 주세요.'**
  String get notificationPermissionRequired;

  /// No description provided for @serverSlowResponse.
  ///
  /// In ko, this message translates to:
  /// **'서버 응답이 지연되고 있습니다. 서버와 PostgreSQL이 실행 중인지 확인해 주세요.'**
  String get serverSlowResponse;

  /// No description provided for @goalTypeCompletion.
  ///
  /// In ko, this message translates to:
  /// **'완료 여부'**
  String get goalTypeCompletion;

  /// No description provided for @goalTypeCount.
  ///
  /// In ko, this message translates to:
  /// **'횟수'**
  String get goalTypeCount;

  /// No description provided for @goalTypeDuration.
  ///
  /// In ko, this message translates to:
  /// **'시간'**
  String get goalTypeDuration;

  /// No description provided for @goalTypeNumber.
  ///
  /// In ko, this message translates to:
  /// **'수치'**
  String get goalTypeNumber;

  /// No description provided for @createNewHabit.
  ///
  /// In ko, this message translates to:
  /// **'새 습관 만들기'**
  String get createNewHabit;

  /// No description provided for @habitName.
  ///
  /// In ko, this message translates to:
  /// **'습관명'**
  String get habitName;

  /// No description provided for @habitNameHint.
  ///
  /// In ko, this message translates to:
  /// **'예: 아침 물 500ml'**
  String get habitNameHint;

  /// No description provided for @categoryOptional.
  ///
  /// In ko, this message translates to:
  /// **'카테고리 (선택)'**
  String get categoryOptional;

  /// No description provided for @noneSelected.
  ///
  /// In ko, this message translates to:
  /// **'선택 안 함'**
  String get noneSelected;

  /// No description provided for @goalType.
  ///
  /// In ko, this message translates to:
  /// **'목표 유형'**
  String get goalType;

  /// No description provided for @habitTemplateOptional.
  ///
  /// In ko, this message translates to:
  /// **'템플릿 (선택)'**
  String get habitTemplateOptional;

  /// No description provided for @goalCountHint.
  ///
  /// In ko, this message translates to:
  /// **'목표 횟수 (예: 3)'**
  String get goalCountHint;

  /// No description provided for @goalDurationHint.
  ///
  /// In ko, this message translates to:
  /// **'목표 분 (예: 30)'**
  String get goalDurationHint;

  /// No description provided for @goalNumberHint.
  ///
  /// In ko, this message translates to:
  /// **'목표 수치'**
  String get goalNumberHint;

  /// No description provided for @startDate.
  ///
  /// In ko, this message translates to:
  /// **'시작일'**
  String get startDate;

  /// No description provided for @colorOptional.
  ///
  /// In ko, this message translates to:
  /// **'색상 (선택)'**
  String get colorOptional;

  /// No description provided for @iconOptional.
  ///
  /// In ko, this message translates to:
  /// **'아이콘 (선택)'**
  String get iconOptional;

  /// No description provided for @reminderNotification.
  ///
  /// In ko, this message translates to:
  /// **'리마인더 알림'**
  String get reminderNotification;

  /// No description provided for @reminderNotificationSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'매일 설정한 시간에 이 습관 알림'**
  String get reminderNotificationSubtitle;

  /// No description provided for @notificationTime.
  ///
  /// In ko, this message translates to:
  /// **'알림 시간'**
  String get notificationTime;

  /// No description provided for @editFailedTryAgain.
  ///
  /// In ko, this message translates to:
  /// **'수정에 실패했어요. 다시 시도해 주세요.'**
  String get editFailedTryAgain;

  /// No description provided for @deleteRecord.
  ///
  /// In ko, this message translates to:
  /// **'기록 삭제'**
  String get deleteRecord;

  /// No description provided for @deleteRecordForDate.
  ///
  /// In ko, this message translates to:
  /// **'{date} 기록을 삭제할까요?'**
  String deleteRecordForDate(String date);

  /// No description provided for @processFailedTryAgain.
  ///
  /// In ko, this message translates to:
  /// **'처리하지 못했어요. 다시 시도해 주세요.'**
  String get processFailedTryAgain;

  /// No description provided for @completeToday.
  ///
  /// In ko, this message translates to:
  /// **'오늘 완료하기'**
  String get completeToday;

  /// No description provided for @recordHistory.
  ///
  /// In ko, this message translates to:
  /// **'기록 히스토리'**
  String get recordHistory;

  /// No description provided for @noRecent30DaysRecords.
  ///
  /// In ko, this message translates to:
  /// **'최근 30일 기록이 없어요.'**
  String get noRecent30DaysRecords;

  /// No description provided for @deleteHabit.
  ///
  /// In ko, this message translates to:
  /// **'습관 삭제'**
  String get deleteHabit;

  /// No description provided for @deleteHabitDescription.
  ///
  /// In ko, this message translates to:
  /// **'이 습관을 삭제할까요?'**
  String get deleteHabitDescription;

  /// No description provided for @editHabit.
  ///
  /// In ko, this message translates to:
  /// **'습관 수정'**
  String get editHabit;

  /// No description provided for @goalValue.
  ///
  /// In ko, this message translates to:
  /// **'목표값'**
  String get goalValue;

  /// No description provided for @color.
  ///
  /// In ko, this message translates to:
  /// **'색상'**
  String get color;

  /// No description provided for @icon.
  ///
  /// In ko, this message translates to:
  /// **'아이콘'**
  String get icon;

  /// No description provided for @pageNotFound.
  ///
  /// In ko, this message translates to:
  /// **'페이지를 찾을 수 없습니다: {uri}'**
  String pageNotFound(String uri);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ko'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ko':
      return AppLocalizationsKo();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
