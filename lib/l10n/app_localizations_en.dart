// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'HabitFable';

  @override
  String get navHome => 'Home';

  @override
  String get navHabits => 'Habits';

  @override
  String get navStats => 'Stats';

  @override
  String get navSettings => 'Settings';

  @override
  String get pressBackAgainToExit => 'Press once more to exit.';

  @override
  String get connectionErrorMessage =>
      'Unable to connect to server.\nCheck the API server on port 3000.\nWindows emulator: firewall often blocks 10.0.2.2. Run adb reverse tcp:3000 tcp:3000, then flutter run --dart-define=API_USE_LOCALHOST=true.\nReal device: set API_BASE_URL to your PC IP on the same Wi-Fi.';

  @override
  String get retry => 'Retry';

  @override
  String get todayHabitsTitle => 'Today\'s Habits';

  @override
  String get addNewHabit => 'Add New Habit';

  @override
  String get emptyHabitTitle => 'No habits yet.';

  @override
  String get emptyHabitDescription =>
      'Add your first habit with Add New Habit.';

  @override
  String get completedHeatmapTitle => 'Completion Heatmap';

  @override
  String get heatmapLess => 'Less';

  @override
  String get heatmapMore => 'More';

  @override
  String get todayProgressLabel => 'Today\'s Progress';

  @override
  String get todayProgressTitle => 'Today\'s Progress';

  @override
  String get todayProgressDescription =>
      'The ratio of habits completed against today\'s goal.';

  @override
  String completedHabitCount(int completed, int total) {
    return '$completed / $total habits completed';
  }

  @override
  String get completedTodayDialogTitle => 'Completed today!';

  @override
  String get confirm => 'OK';

  @override
  String get habitTitle => 'Habits';

  @override
  String get addHabit => 'Add Habit';

  @override
  String get noHabitsRegistered => 'No habits registered.';

  @override
  String get addHabitGuide => 'Tap + at the top right to add a habit.';

  @override
  String get activeHabits => 'Active Habits';

  @override
  String get hiddenHabits => 'Hidden Habits';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get accountManagement => 'Account';

  @override
  String get announcements => 'Announcements';

  @override
  String get serviceAnnouncementList => 'Service announcements';

  @override
  String get terms => 'Terms';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get inquiry => 'Inquiry';

  @override
  String get notificationSettings => 'Notification settings';

  @override
  String get displaySettings => 'Display settings';

  @override
  String get language => 'Language';

  @override
  String get theme => 'Theme';

  @override
  String get systemTheme => 'Follow system';

  @override
  String get lightTheme => 'Light mode';

  @override
  String get darkTheme => 'Dark mode';

  @override
  String get weekdayMon => 'Mon';

  @override
  String get weekdayTue => 'Tue';

  @override
  String get weekdayWed => 'Wed';

  @override
  String get weekdayThu => 'Thu';

  @override
  String get weekdayFri => 'Fri';

  @override
  String get weekdaySat => 'Sat';

  @override
  String get weekdaySun => 'Sun';

  @override
  String get ok => 'OK';

  @override
  String get day => 'Day';

  @override
  String get week => 'Week';

  @override
  String get month => 'Month';

  @override
  String get skip => 'Skip';

  @override
  String get next => 'Next';

  @override
  String get getStarted => 'Get Started';

  @override
  String get onboardingSubtitle1 => 'Small habits change your life';

  @override
  String get onboardingBody1 =>
      'Track a little every day and build consistency.';

  @override
  String get onboardingTitle2 => 'Habit Tracking';

  @override
  String get onboardingSubtitle2 => 'Quickly check what you did today';

  @override
  String get onboardingBody2 =>
      'Every completion builds streaks and statistics.';

  @override
  String get onboardingTitle3 => 'Get Started';

  @override
  String get onboardingSubtitle3 => 'Create your first habit right now';

  @override
  String get onboardingBody3 =>
      'Sign in, add a habit, and start tracking today.';

  @override
  String get loginFailed => 'Login failed';

  @override
  String get loginSubtitle => 'Start easily with your social account';

  @override
  String get loginWithGoogle => 'Continue with Google';

  @override
  String get loginWithKakao => 'Continue with Kakao';

  @override
  String get loginWithNaver => 'Continue with Naver';

  @override
  String loginError(String message) {
    return 'Login error: $message';
  }

  @override
  String get hideHabit => 'Hide Habit';

  @override
  String get hideHabitDescription =>
      'Hide this habit? Hidden habits disappear from Home and are shown under Hidden Habits.';

  @override
  String get cancel => 'Cancel';

  @override
  String get hide => 'Hide';

  @override
  String get hideFailed => 'Failed to hide habit.';

  @override
  String get unhideHabit => 'Unhide Habit';

  @override
  String get unhideHabitDescription =>
      'Unhide this habit? It will return to the active habit list.';

  @override
  String get unhide => 'Unhide';

  @override
  String get unhideFailed => 'Failed to unhide habit.';

  @override
  String get edit => 'Edit';

  @override
  String get delete => 'Delete';

  @override
  String get enterSubject => 'Please enter a subject.';

  @override
  String get enterContent => 'Please enter content.';

  @override
  String get inquirySubmitted =>
      'Inquiry submitted. Please wait for admin response.';

  @override
  String get newInquiry => 'New Inquiry';

  @override
  String get subject => 'Subject';

  @override
  String get inquiryContent => 'Inquiry content';

  @override
  String get submitInquiry => 'Submit Inquiry';

  @override
  String get myInquiries => 'My Inquiries';

  @override
  String get noInquiries => 'No inquiries submitted.';

  @override
  String get answered => 'Answered';

  @override
  String get pending => 'Pending';

  @override
  String replyAt(String date) {
    return 'Reply $date';
  }

  @override
  String get adminReply => 'Admin Reply';

  @override
  String replyTime(String date) {
    return 'Reply time: $date';
  }

  @override
  String get inquiryDeleteConfirm => 'Delete this inquiry?';

  @override
  String get inquiryDeleteRetentionNotice =>
      'Deleted inquiries are kept on the server for up to one year (365 days), then permanently removed. Legal retention periods may apply separately.';

  @override
  String get noContent => '(No content)';

  @override
  String get untitled => '(Untitled)';

  @override
  String get noNotices => 'No announcements available.';

  @override
  String get korean => '한국어';

  @override
  String get profileAndLogout => 'Profile and logout';

  @override
  String get inquirySubtitle => 'Submit inquiry and check reply';

  @override
  String get notificationSettingsSubtitle => 'Enable habit reminders here.';

  @override
  String get missedHabitSummaryPushTimeTitle => 'Missed habits summary alert';

  @override
  String get missedHabitSummaryPushTimeSubtitle =>
      'When to notify you about habits not completed today (your time zone). Default follows the server schedule.';

  @override
  String get missedHabitSummaryPushTimeDefaultLabel => 'Server default';

  @override
  String get soundAndFeedback => 'Completion feedback';

  @override
  String get sound => 'Completion sound';

  @override
  String get soundSubtitle =>
      'When on: sound in normal mode, vibration in silent/vibrate mode';

  @override
  String get haptic => 'Haptic';

  @override
  String get hapticSubtitle => 'Vibration feedback';

  @override
  String get loading => 'Loading…';

  @override
  String get onboarding => 'Onboarding';

  @override
  String get replayOnboarding => 'Replay onboarding';

  @override
  String get replayOnboardingSubtitle => 'See the intro screens again';

  @override
  String get showOnlyFirstLaunch => 'Show only on first launch';

  @override
  String get showOnlyFirstLaunchSubtitle =>
      'Turn off to show onboarding every launch';

  @override
  String get logout => 'Logout';

  @override
  String versionLabel(String version) {
    return 'Version $version';
  }

  @override
  String yearMonth(int year, int month) {
    return '$year-$month';
  }

  @override
  String get todaySummary => 'Today\'s Summary';

  @override
  String get totalHabits => 'Total habits';

  @override
  String countItems(int count) {
    return '$count';
  }

  @override
  String get todayCompleted => 'Completed today';

  @override
  String get last7DaysSuccessRate => 'Last 7-day success rate';

  @override
  String get last7DaysSuccessRateDescription =>
      'Completion ratio against required habit-days after each habit start date in the last 7 days including today.';

  @override
  String get noActiveHabitsForRate =>
      'Not shown when there are no active habits.';

  @override
  String get achieved => 'Achieved';

  @override
  String successPairCount(int completed, int possible) {
    return '$completed / $possible (habit-day pairs)';
  }

  @override
  String get weeklySummary => 'Weekly Summary';

  @override
  String get weeklySuccessRate => 'Weekly success rate';

  @override
  String get weeklySuccessRateDescription =>
      'Completion ratio against required habit-days after each habit start date for the selected week.';

  @override
  String get monthlySummary => 'Monthly Summary';

  @override
  String get monthlySuccessRate => 'Monthly success rate';

  @override
  String get monthlySuccessRateDescription =>
      'Completion ratio against required habit-days after each habit start date for the selected month.';

  @override
  String get completedCountLabel => 'Completion count';

  @override
  String countTimes(int count) {
    return '$count times';
  }

  @override
  String get completedByHabit => 'Completed by habit';

  @override
  String get noHabitsYet => 'No habits registered.';

  @override
  String get aiFeedback => 'AI Feedback';

  @override
  String get streakByHabit => 'Streak by habit';

  @override
  String daysCount(int count) {
    return '$count days';
  }

  @override
  String get profileLoadFailed =>
      'Failed to load profile. Please check your network.';

  @override
  String get nickname => 'Nickname';

  @override
  String get nicknameHint => 'Nickname (leave empty to hide)';

  @override
  String get max20Chars => 'Max 20 characters';

  @override
  String get save => 'Save';

  @override
  String get saved => 'Saved.';

  @override
  String saveFailed(String message) {
    return 'Save failed: $message';
  }

  @override
  String get profilePhotoManageTitle => 'Profile photo';

  @override
  String get profilePhotoManageSubtitle =>
      'Change the image URL or revert to the default icon.';

  @override
  String get profilePhotoDialogTitle => 'Change profile photo';

  @override
  String get profilePhotoUrlHint => 'Image URL starting with https://';

  @override
  String get profilePhotoInvalidUrl =>
      'Only http:// or https:// URLs are allowed.';

  @override
  String get profilePhotoUpdated => 'Profile photo updated.';

  @override
  String get resetProfilePhotoButton => 'Default icon';

  @override
  String get removeProfilePhoto => 'Remove profile photo';

  @override
  String get removeProfilePhotoDescription =>
      'Remove saved profile photo? (It may sync again after Google login.)';

  @override
  String get remove => 'Remove';

  @override
  String get profilePhotoRemoved => 'Profile photo removed.';

  @override
  String processFailed(String message) {
    return 'Process failed: $message';
  }

  @override
  String get deleteAccount => 'Delete Account';

  @override
  String get deleteAccountDescription =>
      'Your account is deactivated immediately and you cannot sign in again.\nHabits and records on the server are kept for up to one year (365 days) from deactivation, then deleted permanently. They cannot be restored before or after deletion.\nPlease enter a reason before proceeding.';

  @override
  String get withdrawReason => 'Withdrawal reason';

  @override
  String get withdrawReasonHint => 'Please enter the reason for withdrawal.';

  @override
  String get withdrawReasonRequired => 'Please enter a withdrawal reason.';

  @override
  String get withdraw => 'Withdraw';

  @override
  String withdrawFailed(String message) {
    return 'Withdrawal failed: $message';
  }

  @override
  String get noName => 'No name';

  @override
  String loginWithProvider(String provider) {
    return 'Login with $provider';
  }

  @override
  String get changeNickname => 'Change nickname';

  @override
  String get nicknameSubtitle =>
      'Name shown in inquiries and app. (Max 20 chars)';

  @override
  String get revertToDefaultIcon => 'Revert to default icon.';

  @override
  String get accountDataWarning =>
      'Habits and records are linked to this account. If you delete your account, sign-in is blocked immediately; server data is kept for up to one year (365 days) and then deleted permanently. After deletion it cannot be recovered. Data left on the device can be cleared separately (e.g. app storage settings).';

  @override
  String get emailSectionTitle => 'Email';

  @override
  String get emailStatusNone => 'Not registered';

  @override
  String get emailStatusVerified => 'Registered';

  @override
  String get emailRegisteredLabel => 'Registered email';

  @override
  String get emailEnterHint => 'you@example.com';

  @override
  String get emailRequired => 'Please enter your email address.';

  @override
  String get withdrawing => 'Withdrawing…';

  @override
  String get enterHabitName => 'Please enter a habit name.';

  @override
  String get notificationPermissionRequired =>
      'Notification permission is required. Please allow it in settings.';

  @override
  String get serverSlowResponse =>
      'Server response is delayed. Check if server and PostgreSQL are running.';

  @override
  String get goalTypeCompletion => 'Completion';

  @override
  String get goalTypeCount => 'Count';

  @override
  String get goalTypeDuration => 'Duration';

  @override
  String get goalTypeNumber => 'Number';

  @override
  String get createNewHabit => 'Create New Habit';

  @override
  String get habitName => 'Habit name';

  @override
  String get habitNameHint => 'e.g. Morning water 500ml';

  @override
  String get categoryOptional => 'Category (optional)';

  @override
  String get noneSelected => 'None';

  @override
  String get goalType => 'Goal type';

  @override
  String get habitTemplateOptional => 'Template (optional)';

  @override
  String get goalCountHint => 'Completed count (e.g. 3)';

  @override
  String get goalDurationHint => 'Target minutes (e.g. 30)';

  @override
  String get goalNumberHint => 'Completed value';

  @override
  String get startDate => 'Start date';

  @override
  String get colorOptional => 'Color (optional)';

  @override
  String get iconOptional => 'Icon (optional)';

  @override
  String get reminderNotification => 'Reminder notification';

  @override
  String get reminderNotificationSubtitle =>
      'Notify this habit at the selected time every day';

  @override
  String get notificationTime => 'Notification time';

  @override
  String get editFailedTryAgain => 'Edit failed. Please try again.';

  @override
  String get deleteRecord => 'Delete record';

  @override
  String deleteRecordForDate(String date) {
    return 'Delete record for $date?';
  }

  @override
  String get processFailedTryAgain => 'Could not process. Please try again.';

  @override
  String get completeToday => 'Complete today';

  @override
  String get completionPraiseCategoryHealth =>
      'You kept a health habit—your body will thank you!';

  @override
  String get completionPraiseCategoryExercise =>
      'You moved your body today. Great job!';

  @override
  String get completionPraiseCategoryReading => 'Time with a book well spent.';

  @override
  String get completionPraiseCategoryLearning =>
      'Another step in learning. Well done!';

  @override
  String get completionPraiseCategoryMeditation =>
      'You cared for your mind too. Balanced day!';

  @override
  String get completionPraiseCategoryHobby =>
      'Time for something you love—nice work!';

  @override
  String get completionPraiseCategoryWork =>
      'One work habit checked off. Productive!';

  @override
  String get completionPraiseCategoryLife =>
      'Daily life tidied up—feels good, right?';

  @override
  String get completionPraiseGoalCompletion =>
      'You finished today’s goal. Give yourself credit!';

  @override
  String get completionPraiseGoalCount =>
      'You hit your count goal. Consistency shines!';

  @override
  String get completionPraiseGoalDuration =>
      'You stuck to the time you set. Strong focus!';

  @override
  String get completionPraiseGoalNumber =>
      'One step closer to your number goal!';

  @override
  String get recordHistory => 'Record history';

  @override
  String get noRecent30DaysRecords => 'No records in the last 30 days.';

  @override
  String get deleteHabit => 'Delete habit';

  @override
  String get deleteHabitDescription => 'Delete this habit?';

  @override
  String get editHabit => 'Edit habit';

  @override
  String get goalValue => 'Completed value';

  @override
  String get color => 'Color';

  @override
  String get icon => 'Icon';

  @override
  String get supportMonetizationTitle => 'Support & remove ads';

  @override
  String get supportMonetizationSubtitle => 'Tip the app and hide banner ads';

  @override
  String get monetizationIntro =>
      'Ads and tips help cover hosting and development. You can remove banner ads with the option below.';

  @override
  String get removeAdsTitle => 'Remove ads';

  @override
  String get removeAdsDescription =>
      'Hides banner ads. Use “Restore purchases” on each device with the same store account if needed.';

  @override
  String get removeAdsPurchased => 'Ads are turned off for this install.';

  @override
  String get donationSectionTitle => 'Tips';

  @override
  String get donationSmallTitle => 'Small tip';

  @override
  String get donationSmallSubtitle => 'Helps keep the lights on';

  @override
  String get donationMediumTitle => 'Generous tip';

  @override
  String get donationMediumSubtitle => 'Makes a big difference';

  @override
  String get restorePurchases => 'Restore purchases';

  @override
  String get restorePurchasesRequested =>
      'Restore requested. It may take a moment to apply.';

  @override
  String get removeAdsThanks => 'Ads are off. Thank you!';

  @override
  String get donationThanks => 'Thanks for your support!';

  @override
  String get productsNotConfigured =>
      'Could not load store products. Check that in-app products are configured.';

  @override
  String get purchaseFailed => 'The purchase could not be completed.';

  @override
  String get storeBillingUnavailable =>
      'In-app purchases are unavailable. Check that you are signed in to the store and that the device date and time are correct.';

  @override
  String get monetizationUnsupported =>
      'Store purchases and ads are not available on this platform.';

  @override
  String pageNotFound(String uri) {
    return 'Page not found: $uri';
  }
}
