// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Study Mentor';

  @override
  String get languageSettingTitle => 'Language';

  @override
  String get languageSettingSubtitle => 'English / Arabic';

  @override
  String get languageDialogTitle => 'Choose Language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageArabic => 'Arabic';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonOk => 'OK';

  @override
  String get commonSave => 'Save';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonClose => 'Close';

  @override
  String get commonError => 'Error';

  @override
  String get commonLoading => 'Loading...';

  @override
  String get studentSettingsTitle => 'Settings';

  @override
  String get preferencesSection => 'Preferences';

  @override
  String get accountSection => 'Account';

  @override
  String get aboutSection => 'About';

  @override
  String get usageTimerNotificationTitle => 'Usage Timer Notification';

  @override
  String get usageTimerNotificationSubtitle =>
      'Show a notification counting down your remaining app time';

  @override
  String get cooldownTimerNotificationTitle => 'Cooldown Timer Notification';

  @override
  String get cooldownTimerNotificationSubtitle =>
      'Show a notification counting down your remaining cooldown time';

  @override
  String get appVersionLabel => 'App Version';

  @override
  String parentSettingsEmailPendingBanner(String email) {
    return 'A verification link was sent to $email. Your email address will update after you click it.';
  }

  @override
  String get parentSettingsAccountInfoSection => 'Account Information';

  @override
  String get parentSettingsChangePasswordSection => 'Change Password';

  @override
  String get parentSettingsPasswordHint =>
      'Leave all password fields empty to keep your current password.';

  @override
  String get fieldFullName => 'Full Name';

  @override
  String get validatorFullNameRequired => 'Full name is required.';

  @override
  String get validatorFullNameMinLength =>
      'Name must be at least 2 characters.';

  @override
  String get fieldEmail => 'Email';

  @override
  String get parentSettingsEmailHelper =>
      'Changing your email will send a verification link to the new address.';

  @override
  String get validatorEmailRequired => 'Email is required.';

  @override
  String get validatorEmailInvalid => 'Enter a valid email address.';

  @override
  String get fieldCurrentPassword => 'Current Password';

  @override
  String get validatorCurrentPasswordForEmail =>
      'Enter your current password to change your email.';

  @override
  String get validatorCurrentPasswordForNewPassword =>
      'Enter your current password to set a new one.';

  @override
  String get fieldNewPassword => 'New Password';

  @override
  String get validatorPasswordMinLength =>
      'Password must be at least 6 characters.';

  @override
  String get validatorEnterCurrentPasswordFirst =>
      'Enter your current password first.';

  @override
  String get fieldConfirmNewPassword => 'Confirm New Password';

  @override
  String get validatorPasswordsDoNotMatch => 'Passwords do not match.';

  @override
  String get saveChangesButton => 'Save Changes';

  @override
  String get profileUpdatedSuccess => 'Profile updated successfully.';

  @override
  String get couldNotLoadLinkedStudents =>
      'Could not load linked students. Check your connection.';

  @override
  String get dangerZoneSection => 'Danger Zone';

  @override
  String get deleteAccountTitle => 'Delete Account';

  @override
  String get deleteAccountDescription =>
      'Permanently removes your account and all data. You must delete all student accounts first.';

  @override
  String get deleteAccountBlockedTooltip =>
      'Remove all linked children before deleting your account.';

  @override
  String get deleteAccountRetryTooltip =>
      'Could not verify linked students. Please retry.';

  @override
  String get deleteMyAccountButton => 'Delete My Account';

  @override
  String get childLoadErrorNotice =>
      'Could not verify linked students. Deletion is disabled until this is resolved.';

  @override
  String get linkedChildrenNotice =>
      'You can only delete your account after removing all linked children. Go to the Students tab to delete each child\'s account first.';

  @override
  String get deleteYourAccountDialogTitle => 'Delete Your Account';

  @override
  String get deleteYourAccountDialogContent =>
      'This will permanently delete your account. Are you sure?';

  @override
  String get continueButton => 'Continue';

  @override
  String get confirmYourPasswordDialogTitle => 'Confirm Your Password';

  @override
  String get confirmPasswordDeleteWarning =>
      'Enter your current password to permanently delete your account. This cannot be undone.';

  @override
  String get validatorEnterCurrentPassword =>
      'Please enter your current password.';

  @override
  String get signInTitle => 'Sign In';

  @override
  String get fieldPassword => 'Password';

  @override
  String get validatorPasswordRequired => 'Password is required.';

  @override
  String get loginEmailValidator => 'Please enter a valid email address.';

  @override
  String get registerPromptButton => 'Not registered yet? Register as a Parent';

  @override
  String get forgotPasswordButton => 'Forgot Password?';

  @override
  String get registerAsParentTitle => 'Register as a Parent';

  @override
  String get fieldConfirmPassword => 'Confirm Password';

  @override
  String get registerButton => 'Register';

  @override
  String get alreadyRegisteredButton => 'Already registered? Sign In';

  @override
  String get resetPasswordTitle => 'Reset Password';

  @override
  String get passwordResetLinkSentMessage =>
      'Password reset link sent! Check your inbox.';

  @override
  String get sendResetLinkButton => 'Send Reset Link';

  @override
  String get confirmEmailTitle => 'Confirm Email';

  @override
  String get emailNotVerifiedYetMessage =>
      'Your email hasn\'t been verified yet. Check your inbox.';

  @override
  String get emailVerificationLinkSentMessage =>
      'Email verification link sent!';

  @override
  String get confirmEmailInstructions =>
      'Please check your inbox and verify your email to continue.';

  @override
  String get sendEmailVerificationButton => 'Send Email Verification Link';

  @override
  String get emailVerifiedButton => 'I\'ve Verified My Email';

  @override
  String get logOutButton => 'Log Out';

  @override
  String get dashboardTitle => 'Dashboard';

  @override
  String get nothingHereYetTitle => 'Nothing here yet.';

  @override
  String get activityAlertsWillAppearHere =>
      'Activity and alerts will appear here.';

  @override
  String get myChildrenTitle => 'My Children';

  @override
  String get validatorStudentPasswordRequired =>
      'Please enter the student\'s password.';

  @override
  String get removeStudentTitle => 'Remove Student';

  @override
  String removeStudentConfirmMessage(String studentName) {
    return 'This will permanently delete $studentName\'s account. Enter the password you created for them to confirm.';
  }

  @override
  String get fieldStudentPassword => 'Student\'s Password';

  @override
  String get removeButton => 'Remove';

  @override
  String get noChildrenAddedYetTitle => 'No children added yet.';

  @override
  String get useAddStudentButtonHint =>
      'Use the Add Student button to register your first child.';

  @override
  String studentNotActivatedBanner(int count, String names) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$names haven\'t activated their accounts yet.',
      one: '$names hasn\'t activated their account yet.',
    );
    return '$_temp0';
  }

  @override
  String get verifyEmailInstructionBanner =>
      'Ask them to open the app, log in with the credentials you created, and verify their email.';

  @override
  String get tapStudentCardHint =>
      'Tap on a student card to monitor their activity, manage app usage rules, and review their academic status.';

  @override
  String get incorrectPasswordRetryMessage =>
      'Incorrect password. Please try again.';

  @override
  String get deleteChildAccountTitle => 'Delete Child Account';

  @override
  String get deleteChildAccountWarningPrefix =>
      'You are about to permanently delete ';

  @override
  String get deleteChildAccountWarningSuffix =>
      '\'s account. This will remove all of their data and cannot be undone.';

  @override
  String studentCredentialsWillBeDeleted(String firstName) {
    return '$firstName\'s login credentials, progress, and settings will all be permanently deleted.';
  }

  @override
  String passwordYouCreatedForHint(String firstName) {
    return 'Password you created for $firstName';
  }

  @override
  String get deletePermanentlyButton => 'Delete Permanently';

  @override
  String gradeLabel(int grade) {
    return 'Grade $grade';
  }

  @override
  String get studentRegisteredSuccessTitle =>
      'Student Registered Successfully!';

  @override
  String get studentRegisteredSuccessDetail =>
      'On your child\'s phone, open the app and log in with the credentials you just created. They\'ll need to verify their email before getting started.';

  @override
  String get registerStudentTitle => 'Register Student';

  @override
  String get createNewStudentAccountSubtitle => 'Create a new student account';

  @override
  String get studentInformationSection => 'Student Information';

  @override
  String get fieldGrade => 'Grade';

  @override
  String get validatorGradeRequired => 'Please select a grade.';

  @override
  String get accountCredentialsSection => 'Account Credentials';

  @override
  String get fieldEmailAddress => 'Email Address';

  @override
  String get emailAddressHint => 'The student will use this to log in.';

  @override
  String get validatorConfirmPasswordRequired =>
      'Please confirm your password.';

  @override
  String get accountSettingsTitle => 'Account Settings';

  @override
  String get unsavedChangesDialogTitle => 'Unsaved Changes';

  @override
  String get unsavedChangesDialogContent =>
      'You have unsaved changes. Leave without saving?';

  @override
  String get stayButton => 'Stay';

  @override
  String get leaveButton => 'Leave';

  @override
  String get logoutConfirmationMessage =>
      'Are you sure you want to log out of your account?';

  @override
  String get requiredToChangeEmailHint =>
      'Required to change the email address.';

  @override
  String get studentProfileStaticTitle => 'Student Profile';

  @override
  String studentProfileUpdatedEmailPending(String email) {
    return 'Profile updated. A verification link was sent to $email.';
  }

  @override
  String studentSettingsEmailPendingBanner(String email) {
    return 'A verification link was sent to $email. The student\'s email will update after they click it.';
  }

  @override
  String get studentSettingsEmailHelper =>
      'Changing the email will send a verification link to the new address.';

  @override
  String get fieldStudentCurrentPassword => 'Student\'s Current Password';

  @override
  String get validatorStudentCurrentPasswordForEmail =>
      'Enter the student\'s current password to change their email.';

  @override
  String get validatorStudentCurrentPasswordForNewPassword =>
      'Enter the student\'s current password to set a new one.';

  @override
  String get validatorEnterStudentCurrentPasswordFirst =>
      'Enter the student\'s current password first.';

  @override
  String get discardChangesDialogContent =>
      'Refreshing will discard your unsaved changes. Continue?';

  @override
  String get discardAndRefreshButton => 'Discard & Refresh';

  @override
  String get stillLoadingAppListMessage =>
      'Still loading app list — please wait.';

  @override
  String deviceNotSyncedMessage(String name) {
    return '$name\'s device hasn\'t synced yet. Ask them to open the app once.';
  }

  @override
  String get allAppsAlreadyConfiguredMessage =>
      'All installed apps have already been configured.';

  @override
  String removeAppConfirmTitle(String appLabel) {
    return 'Remove $appLabel?';
  }

  @override
  String get removeAppConfirmMessage =>
      'Are you sure you want to stop monitoring this app? Your child will have unrestricted access to it.';

  @override
  String get configSavedSuccessMessage => 'Configuration saved successfully.';

  @override
  String get configurationsTitle => 'Configurations';

  @override
  String get screenTimeRewardTitle => 'Screen Time Reward per Quiz';

  @override
  String get screenTimeRewardDescription =>
      'Child earns this much unlocked screen time for every quiz they pass.';

  @override
  String get setCooldownTimeTitle => 'Set Cooldown Time';

  @override
  String get cooldownPeriodTitle => 'Cooldown Period';

  @override
  String get cooldownPeriodDescription =>
      'Lock duration after screen time runs out.';

  @override
  String get appRulesTitle => 'App Rules';

  @override
  String get noAppsConfiguredHint =>
      'No apps configured yet. Tap + to add your first app.';

  @override
  String monitoredCountLabel(int count) {
    return '$count monitored';
  }

  @override
  String pausedCountLabel(int count) {
    return '$count paused';
  }

  @override
  String manageAllAppsLabel(int count) {
    return 'Manage all $count apps';
  }

  @override
  String get quizSettingsTitle => 'Quiz Settings';

  @override
  String get questionsPerQuizLabel => 'Questions per Quiz';

  @override
  String get quizCountAutoLabel => 'Auto';

  @override
  String get quizCountAutoDescription =>
      'Smart Tutor will adjust the quiz length dynamically based on the child\'s current performance.';

  @override
  String quizCountFixedDescription(int count) {
    return 'Child must correctly answer $count questions to unlock their device.';
  }

  @override
  String get editProfileButton => 'Edit Profile';

  @override
  String get passwordRequiredToDeleteAccountMessage =>
      'Password is required to delete the account.';

  @override
  String get deleteStudentDialogTitle => 'Delete Student';

  @override
  String get deleteStudentWarningPrefix => 'This will permanently delete ';

  @override
  String get deleteStudentWarningSuffix =>
      '\'s account — progress, items, and settings. This cannot be undone.';

  @override
  String monitoredAndPausedLabel(int monitored, int paused) {
    return '$monitored monitored · $paused paused';
  }

  @override
  String get noAppsConfiguredTitle => 'No apps configured yet.';

  @override
  String get tapAddAppHint => 'Tap \"Add App\" below to get started.';

  @override
  String get appStatusPaused => 'Paused';

  @override
  String get appStatusMonitored => 'Monitored';

  @override
  String get addAppButton => 'Add App';

  @override
  String get installedAppsFilterLabel => 'Installed Apps';

  @override
  String get installedAppsFilterSubtitle => 'Apps downloaded by the student';

  @override
  String get allAppsFilterLabel => 'All Apps';

  @override
  String get allAppsFilterSubtitle => 'Includes system & pre-installed apps';

  @override
  String get selectAppsTitle => 'Select Apps';

  @override
  String get searchAppsHint => 'Search apps…';

  @override
  String get addSelectedButton => 'Add Selected';

  @override
  String noAppsMatchQuery(String query) {
    return 'No apps match \"$query\"';
  }

  @override
  String get noUserInstalledAppsFound => 'No user-installed apps found';

  @override
  String get switchToAllAppsHint => 'Switch to All Apps to see system apps';

  @override
  String get setRewardTimeTitle => 'Set Reward Time';

  @override
  String presetMinutesLabel(int minutes) {
    return '$minutes mins';
  }

  @override
  String get preset1HourLabel => '1 hour';

  @override
  String get saveTimeButton => 'Save Time';

  @override
  String get masteryTierAdvanced => 'Advanced';

  @override
  String get masteryTierProficient => 'Proficient';

  @override
  String get masteryTierDeveloping => 'Developing';

  @override
  String get masteryTierBeginner => 'Beginner';

  @override
  String get sortQuizzesTitle => 'Sort Quizzes';

  @override
  String get sortDateNewestToOldest => 'Date: Newest to Oldest';

  @override
  String get sortDateOldestToNewest => 'Date: Oldest to Newest';

  @override
  String get sortScoreHighestToLowest => 'Score: Highest to Lowest';

  @override
  String get sortScoreLowestToHighest => 'Score: Lowest to Highest';

  @override
  String get overallMasteryLevelLabel => 'Overall Mastery Level';

  @override
  String get accuracyLabel => 'Accuracy';

  @override
  String get quizzesDoneLabel => 'Quizzes Done';

  @override
  String get timeSpentLabel => 'Time Spent';

  @override
  String get skillsProgressTitle => 'Skills Progress';

  @override
  String get seeAllLabel => 'See All';

  @override
  String get quizHistoryTitle => 'Quiz History';

  @override
  String get sortSkillsTitle => 'Sort Skills';

  @override
  String get sortMasteryLowestFirst => 'Mastery: Lowest First';

  @override
  String get sortMasteryHighestFirst => 'Mastery: Highest First';

  @override
  String get sortAZLabel => 'A – Z';

  @override
  String get recommendationNotStarted =>
      'Not started yet — encourage trying this skill';

  @override
  String get recommendationUrgent =>
      'Needs urgent attention — short daily practice sessions recommended';

  @override
  String get recommendationProgress =>
      'Making progress — reviewing past mistakes will help';

  @override
  String get recommendationOnTrack =>
      'On track — a few more sessions will build mastery';

  @override
  String get recommendationStrong =>
      'Strong skill — occasional review to maintain';

  @override
  String get statTotalLabel => 'Total';

  @override
  String get allSkillsTitle => 'All Skills';

  @override
  String correctOfAttemptsLabel(int correct, int attempts) {
    return '$correct correct / $attempts attempts';
  }

  @override
  String get neverPracticedLabel => 'Never practiced';

  @override
  String lastPracticedLabel(String date) {
    return 'Last: $date';
  }

  @override
  String get uploadCurriculumTitle => 'Upload Curriculum';

  @override
  String get noSubjectsYetTitle => 'No Subjects Yet';

  @override
  String noSubjectsYetDescription(String studentName) {
    return 'Tap the \'+\' button in the top right to start tracking subjects or upload a new curriculum for $studentName.';
  }

  @override
  String get subjectsAndSkillsTitle => 'Subjects & Skills';

  @override
  String skillsTrackedLabel(int count) {
    return '$count skills tracked';
  }

  @override
  String get masteryLabel => 'Mastery';

  @override
  String removeSubjectConfirmTitle(String subjectName) {
    return 'Remove $subjectName?';
  }

  @override
  String get removeSubjectConfirmMessage =>
      'Are you sure you want to remove this subject?';

  @override
  String get searchSubjectsHint => 'Search subjects...';

  @override
  String addSelectedCountButton(int count) {
    return 'Add Selected ($count)';
  }

  @override
  String get noQuizzesYetMessage => 'No quizzes yet';

  @override
  String get allQuizzesTitle => 'All Quizzes';

  @override
  String get tabOverview => 'Overview';

  @override
  String get tabMastery => 'Mastery';

  @override
  String get tabHabits => 'Habits';

  @override
  String get reportsAnalysisTitle => 'Reports & Analysis';

  @override
  String get noReportAvailableMessage => 'No report available.';

  @override
  String get metricQuizzesLabel => 'Quizzes';

  @override
  String get studyTimeLabel => 'Study Time';

  @override
  String get accuracyTrendTitle => 'Accuracy Trend';

  @override
  String get weeklyAccuracyTrendSubtitle =>
      'Weekly accuracy over the past 6 weeks';

  @override
  String get notEnoughDataYetMessage => 'Not enough data yet';

  @override
  String get completeQuizzesTrendHint =>
      'Complete quizzes over multiple weeks to see a trend';

  @override
  String get streakProgressTitle => 'Streak Progress';

  @override
  String get currentStreakVsBestSubtitle => 'Current streak vs. personal best';

  @override
  String get currentStreakLabel => 'Current streak';

  @override
  String get personalBestLabel => 'Personal best';

  @override
  String get daysUnitLabel => 'days';

  @override
  String percentOfPersonalBest(int percent) {
    return '$percent% of personal best';
  }

  @override
  String get noStreakYetMessage =>
      'No streak yet — start studying to build one!';

  @override
  String get smartInsightsTitle => 'Smart Insights';

  @override
  String get insightNoQuizzes =>
      'No quizzes completed this week yet. Encourage your student to log in and start a session to keep their streak alive!';

  @override
  String insightOutstanding(int quizzes, int accuracy) {
    return '$quizzes quizzes completed this week with $accuracy% accuracy — an outstanding performance! The student is mastering the material at a high level. Keep the momentum going.';
  }

  @override
  String insightGoodWeek(int quizzes, int accuracy) {
    return 'Good week overall: $quizzes quizzes at $accuracy% accuracy. To push higher, visit the Mastery tab and focus on skills rated below 60%.';
  }

  @override
  String insightRoomToImprove(int quizzes, int accuracy) {
    return '$quizzes quizzes completed with $accuracy% accuracy. There is room to improve — check the Mastery tab to identify specific concept gaps that need attention.';
  }

  @override
  String insightStreakKept(int streak, int accuracy) {
    return 'The student has kept a $streak-day streak, which is great for consistency! Accuracy is at $accuracy% — reviewing weaker topics between sessions should help raise scores.';
  }

  @override
  String insightDefault(int accuracy, int quizzes) {
    return 'Accuracy was $accuracy% across $quizzes quizzes this week. Encourage shorter, more focused study sessions and review any topics marked as weak in the Mastery tab.';
  }

  @override
  String get noMasteryReportMessage => 'No mastery report available.';

  @override
  String get totalAverageMasteryLabel => 'Total Average Mastery';

  @override
  String masteryScorePercentLabel(String percent) {
    return '$percent% Mastery Score';
  }

  @override
  String get masteredLabel => 'Mastered';

  @override
  String get strongAreasTitle => '🔥 Strong Areas';

  @override
  String get noStrongAreasMessage => 'No strong areas identified yet.';

  @override
  String get needsWorkAreasTitle => '⚠️ Needs Work';

  @override
  String get noWeakAreasMessage => 'No weak areas identified yet.';

  @override
  String get errorAnalyticsTitle => 'Error Analytics';

  @override
  String commonMistakeTypesLabel(String subject) {
    return 'Common mistake types on $subject quizzes.';
  }

  @override
  String carelessMistakesLabel(int percent) {
    return 'Careless Mistakes ($percent%)';
  }

  @override
  String get carelessMistakesDescription =>
      'Answering too quickly on calculations';

  @override
  String conceptGapsLabel(int percent) {
    return 'Concept Gaps ($percent%)';
  }

  @override
  String get conceptGapsDescription => 'Struggles with newly introduced topics';

  @override
  String timePressureLabel(int percent) {
    return 'Time Pressure ($percent%)';
  }

  @override
  String get timePressureDescription =>
      'Failing to finish within the quiz timer';

  @override
  String get noHabitsReportMessage => 'No habits report available.';

  @override
  String get currentStreakStatLabel => 'Current Streak';

  @override
  String get longestStreakStatLabel => 'Longest Streak';

  @override
  String daysCountLabel(int count) {
    return '$count Days';
  }

  @override
  String get studyVsAppUsageTitle => 'Study vs Monitored App Usage';

  @override
  String get studyVsAppUsageSubtitle =>
      'Compare active learning time vs time blocked on other apps.';

  @override
  String get appUsageLegendLabel => 'App Usage';

  @override
  String get studyConsistencyGridTitle => 'Study Consistency Grid';

  @override
  String get activeStudyDaysSubtitle =>
      'Active study days over the last 4 weeks.';

  @override
  String get threeWeeksAgoLabel => '3w ago';

  @override
  String get twoWeeksAgoLabel => '2w ago';

  @override
  String get oneWeekAgoLabel => '1w ago';

  @override
  String get thisWeekLabel => 'This wk';

  @override
  String get dayAbbrevMon => 'M';

  @override
  String get dayAbbrevTue => 'T';

  @override
  String get dayAbbrevWed => 'W';

  @override
  String get dayAbbrevThu => 'T';

  @override
  String get dayAbbrevFri => 'F';

  @override
  String get dayAbbrevSat => 'S';

  @override
  String get dayAbbrevSun => 'S';

  @override
  String get legendLessLabel => 'Less';

  @override
  String get legendMoreLabel => 'More';

  @override
  String studentProfileTitle(String name) {
    return '$name\'s Profile';
  }

  @override
  String get gradeUnknownLabel => 'Grade —';

  @override
  String get thisWeekSublabel => 'This week';

  @override
  String get weeklyAvgSublabel => 'Weekly avg';

  @override
  String get dayStreakLabel => 'Day Streak';

  @override
  String get currentLabel => 'Current';

  @override
  String get manageSubjectsSubtitle =>
      'Manage subjects and view skill progress';

  @override
  String get reportsAnalyticsNavTitle => 'Reports & Analytics';

  @override
  String get weeklyReportsSubtitle =>
      'Weekly reports, accuracy trends, weak topics';

  @override
  String get appConfigurationsTitle => 'App Configurations';

  @override
  String get appConfigurationsSubtitle =>
      'Gateway timers, monitored apps, quiz rules';

  @override
  String get permissionDisplayNameSystemAlertWindow =>
      'Display Over Other Apps';

  @override
  String get permissionDisplayNamePackageUsageStats => 'Usage Access';

  @override
  String get permissionDisplayNamePostNotifications => 'Post Notifications';

  @override
  String get permissionDisplayNameAccessibilityService =>
      'Accessibility Service';

  @override
  String get permissionDisplayNameDeviceAdmin => 'Device Administrator';

  @override
  String get permissionDisplayNameBatteryOptimization =>
      'Disable Battery Optimization';

  @override
  String get permissionRationaleSystemAlertWindow =>
      'Display Over Other Apps is required to show study reminders and enforce app rules while you use other apps.';

  @override
  String get permissionRationalePackageUsageStats =>
      'Usage Access is required to track screen time and enforce the app usage limits set by the parent.';

  @override
  String get permissionRationalePostNotifications =>
      'Post Notifications is required to send you study reminders and important alerts from the parent.';

  @override
  String get permissionRationaleAccessibilityService =>
      'Accessibility Service is required to monitor which apps are open and enforce the rules set by the parent.';

  @override
  String get permissionRationaleDeviceAdmin =>
      'Device Administrator is required to protect the app from being uninstalled without the parent\'s permission.';

  @override
  String get permissionRationaleBatteryOptimization =>
      'Disabling Battery Optimization keeps background services running reliably. Without this, Android may shut down StudyMentor\'s background services on some devices, causing timers and app rules to stop working.';

  @override
  String get permissionParentRationalePostNotifications =>
      'StudyMentor notifies you when your child levels up, earns a badge, or hasn\'t studied in a few days. You can change this any time in Settings.';

  @override
  String get permissionParentRationaleBatteryOptimization =>
      'To reliably notify you about your child\'s activity, StudyMentor needs to run in the background. Without this, Android may delay or drop important alerts on some devices.';

  @override
  String stepOfTotalLabel(int step, int total) {
    return 'Step $step of $total';
  }

  @override
  String permissionEnabledMessage(String permissionName) {
    return '$permissionName has been enabled.';
  }

  @override
  String get permissionNotGrantedMessage =>
      'Permission not granted yet. Tap the button below to open Settings.';

  @override
  String get openSettingsButton => 'Open Settings';

  @override
  String get postNotificationsHint =>
      'Allow StudyMentor to send you notifications.';

  @override
  String get batteryOptimizationHint =>
      'Find \"StudyMentor\", select \"Don\'t optimize\" or \"Unrestricted\", then confirm.';

  @override
  String get systemAlertWindowHint =>
      'Find \"StudyMentor\" and enable \"Allow display over other apps\".';

  @override
  String get packageUsageStatsHint =>
      'Find \"StudyMentor\" and toggle Usage Access on.';

  @override
  String get accessibilityServiceHint =>
      'Under Installed Apps, select \"StudyMentor\" and enable it.';

  @override
  String get deviceAdminHint =>
      'Tap \"Activate this device admin app\" to confirm.';

  @override
  String get helpCenterTitle => 'Help Center';

  @override
  String get whatCanWeHelpWithTitle => 'What can we help with?';

  @override
  String get issueAppNotWorking => 'App isn\'t working properly';

  @override
  String get issueQuizQuestionError => 'Quiz question has an error';

  @override
  String get issueHowDoI => 'How do I...?';

  @override
  String get tellUsMoreTitle => 'Tell us more';

  @override
  String needHelpGreeting(String name) {
    return 'Need help, $name? I\'m here for you!';
  }

  @override
  String get describeIssueHint =>
      'Describe your issue here... Our team will help you out!';

  @override
  String charCounterLabel(int count) {
    return '$count/500';
  }

  @override
  String get sendToTeamButton => 'Send to Team';

  @override
  String get messageSentSuccessMessage =>
      'Message sent! Our team will get back to you soon.';

  @override
  String get messageSendErrorMessage =>
      'Couldn\'t send your message. Please try again.';

  @override
  String levelShortLabel(int level) {
    return 'Lv. $level';
  }

  @override
  String welcomeBackGreeting(String name) {
    return 'Welcome back, $name! ';
  }

  @override
  String get gardenGrowingMessage => 'Your garden is growing beautifully!';

  @override
  String get gardenLoadErrorMessage =>
      'Couldn\'t load your garden. Pull down to retry.';

  @override
  String get askParentAddSubjectsMessage => 'Ask a parent to add your subjects';

  @override
  String get owlEncouragementMessage =>
      'Great job today! Keep studying to help your garden bloom! 🌸';

  @override
  String get owlNameLabel => 'Hootie, your Study Buddy';

  @override
  String streakDaysCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String get lessonsLabel => 'Lessons';

  @override
  String get streakLabel => 'Streak';

  @override
  String get yourParentLabel => 'Your parent';

  @override
  String get rulesConfiguredByParentMessage =>
      'Rules configured by your parent.';

  @override
  String get screenTimeLabel => 'Screen Time';

  @override
  String timeRemainingLabel(String time) {
    return '$time left';
  }

  @override
  String usedTimeLabel(String time) {
    return 'Used: $time';
  }

  @override
  String limitTimeLabel(String time) {
    return 'Limit: $time';
  }

  @override
  String cooldownAfterLimitLabel(String time) {
    return 'Cooldown after limit: $time';
  }

  @override
  String get onCooldownTitle => 'You\'re on cooldown! 😴';

  @override
  String get cooldownMessage =>
      'Apps will unlock again soon. Time to study! 📚';

  @override
  String get remainingLabel => 'remaining';

  @override
  String get parentRulesIntroMessage =>
      'Your parent set these rules for all restricted apps:';

  @override
  String get noAppRulesSetMessage => 'No app rules set yet.';

  @override
  String get noAppRulesDescriptionMessage =>
      'Your parent hasn\'t configured any rules for your device yet.';

  @override
  String get backTooltip => 'Back';

  @override
  String levelLabel(int level) {
    return 'Level $level';
  }

  @override
  String get myProgressTitle => 'My Progress';

  @override
  String get totalXpLabel => 'Total XP';

  @override
  String get questionsLabel => 'Questions';

  @override
  String get coinsAvailableLabel => 'coins available';

  @override
  String get appSettingsTitle => 'App Settings';

  @override
  String get appSettingsSubtitle => 'Notifications, Sound';

  @override
  String get selectPdfFirstMessage => 'Please select a PDF file first.';

  @override
  String get enterSubjectNameMessage => 'Please enter a Subject Name.';

  @override
  String get subjectAlreadyExistsMessage => 'This subject already exists.';

  @override
  String get uploadingProcessingMessage => 'Uploading & processing…';

  @override
  String get uploadCurriculumDescription =>
      'Upload a PDF textbook to build an adaptive quiz from its content.';

  @override
  String get subjectNameLabel => 'Subject Name';

  @override
  String get subjectNameHint => 'e.g. Mathematics, Science...';

  @override
  String get removeFileButton => 'Remove File';

  @override
  String get tapToBrowsePdfMessage => 'Tap to browse PDF';

  @override
  String get onlyPdfSupportedMessage => 'Only .pdf files are supported';

  @override
  String get uploadAndIngestButton => 'Upload & Ingest';

  @override
  String get curriculumAddedSuccessTitle => 'Curriculum Added Successfully!';

  @override
  String curriculumAddedSuccessMessage(String subjectName) {
    return 'We\'ve successfully added \'$subjectName\' to your dashboard. The AI is now processing your textbook in the background to generate quiz questions.';
  }

  @override
  String get uploadAnotherButton => 'Upload Another';

  @override
  String get studyQuizTitle => 'Study Quiz';

  @override
  String masteryUpdateMessage(
    String subject,
    String oldPct,
    String newPct,
    String delta,
  ) {
    return '$subject: $oldPct% → $newPct% (+$delta%)';
  }

  @override
  String masteryUpdatedSimpleMessage(String subject) {
    return '$subject mastery updated!';
  }

  @override
  String get generatingQuizMessage => 'Generating your quiz…';

  @override
  String get submittingAnswersMessage => 'Submitting answers…';

  @override
  String get timeToPracticeTitle => 'Time to Practice!';

  @override
  String get quizPromptMessage =>
      'Your focus time is up. Let\'s do a quick quiz to keep your brain sharp!';

  @override
  String get startQuizButton => 'Start Quiz';

  @override
  String get tailoredToLevelMessage => 'Tailored to your current level';

  @override
  String get selectAnswerFirstMessage => 'Please select an answer first.';

  @override
  String get noMoreHintsMessage => 'No more hints available.';

  @override
  String hintNumberTitle(int number) {
    return 'Hint $number';
  }

  @override
  String questionOfTotalLabel(int current, int total) {
    return 'Question $current of $total';
  }

  @override
  String answeredCountLabel(int count) {
    return '$count answered';
  }

  @override
  String hintCountLabel(int count) {
    return 'Hint ($count)';
  }

  @override
  String get submitButton => 'Submit';

  @override
  String get nextButton => 'Next';

  @override
  String get veryEasyLabel => 'Very Easy';

  @override
  String get easyLabel => 'Easy';

  @override
  String get mediumLabel => 'Medium';

  @override
  String get hardLabel => 'Hard';

  @override
  String get veryHardLabel => 'Very Hard';

  @override
  String questionsCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count questions',
      one: '1 question',
    );
    return '$_temp0';
  }

  @override
  String get doneButton => 'Done';

  @override
  String get takeAnotherQuizButton => 'Take Another Quiz';

  @override
  String get somethingWentWrongTitle => 'Something went wrong';

  @override
  String get tryAgainButton => 'Try Again';

  @override
  String subjectGardenTitle(String subject) {
    return '$subject Garden';
  }

  @override
  String get loadSkillsErrorMessage =>
      'Couldn\'t load skills. Please go back and try again.';

  @override
  String overallMasteryLabel(String percent) {
    return 'Overall mastery: $percent%';
  }

  @override
  String get skillsTitle => 'Skills';

  @override
  String get strengthsTitle => 'Strengths';

  @override
  String get needsPracticeTitle => 'Needs Practice';

  @override
  String get practiceNowButton => 'Practice Now';

  @override
  String get growthProgressTitle => 'Growth Progress';

  @override
  String levelNumberLabel(int level) {
    return 'Level $level';
  }

  @override
  String get maxLevelBadge => 'MAX ✨';

  @override
  String get maxLevelReachedMessage => 'You\'ve reached the maximum level! 🌟';

  @override
  String percentMoreToLevelMessage(String percent, int level) {
    return '$percent% more to reach Level $level!';
  }

  @override
  String get flourishingLabel => 'Flourishing';

  @override
  String get masteryGrowingWellLabel => 'Growing Well';

  @override
  String get masteryMakingProgressLabel => 'Making Progress';

  @override
  String get masteryJustStartedLabel => 'Just Started';

  @override
  String get masteryNotStartedYetLabel => 'Not Started Yet';

  @override
  String get growthStageSeed => 'Seed';

  @override
  String get growthStageSprout => 'Sprout';

  @override
  String get growthStageSapling => 'Sapling';

  @override
  String get growthStageGrowing => 'Growing';

  @override
  String masteryAttemptsLabel(String percent, int attempts) {
    return '$percent% mastery  ·  $attempts attempts';
  }

  @override
  String get skillNotStartedLabel => 'Not started yet';

  @override
  String get avatarShopTitle => 'Avatar Shop';

  @override
  String get categoryHairStyle => 'Hair Style';

  @override
  String get categoryOutfit => 'Outfit';

  @override
  String get categoryHairColor => 'Hair Color';

  @override
  String get categoryOutfitColor => 'Outfit Color';

  @override
  String get categoryAccessory => 'Accessory';

  @override
  String get categoryFacialHair => 'Facial Hair';

  @override
  String get categoryBeardColor => 'Beard Color';

  @override
  String get categoryEyes => 'Eyes';

  @override
  String get categoryEyebrows => 'Eyebrows';

  @override
  String get categoryMouth => 'Mouth';

  @override
  String get categorySkinTone => 'Skin Tone';

  @override
  String unlocksAtLevelMessage(int level) {
    return 'Unlocks at Level $level';
  }

  @override
  String notEnoughCoinsMessage(int amount) {
    return 'Not enough coins! Need $amount more.';
  }

  @override
  String buyItemTitle(String itemName) {
    return 'Buy $itemName?';
  }

  @override
  String itemCostMessage(int price) {
    return 'This will cost $price coins.';
  }

  @override
  String get buyButton => 'Buy';

  @override
  String get levelUpTitle => '🎉 Level Up!';

  @override
  String levelUpSubtitleMessage(int level) {
    return 'You reached Level $level! Keep studying to\ngrow even stronger! 🌱';
  }

  @override
  String get awesomeButton => 'Awesome!';

  @override
  String get streakMilestoneOnARoll => 'On a Roll!';

  @override
  String get streakMilestoneWeekWarrior => 'Week Warrior!';

  @override
  String get streakMilestoneFortnightFocus => 'Fortnight Focus!';

  @override
  String get streakMilestoneMonthlyMaster => 'Monthly Master!';

  @override
  String get streakMilestoneGeneric => 'Streak Milestone!';

  @override
  String streakMilestoneDescriptionMessage(int days) {
    return 'You hit a $days-day learning streak!\nKeep it up!';
  }

  @override
  String coinsRewardLabel(int coins) {
    return '+$coins Coins';
  }

  @override
  String get aiSummaryNotAvailableMessage => 'AI Summary not available.';

  @override
  String get aiDailySummaryTitle => '✨ AI Daily Summary';

  @override
  String get smartInsightsLabel => 'Smart Insights';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get markAllAsReadButton => 'Mark all as read';

  @override
  String get allCaughtUpTitle => 'You\'re All Caught Up';

  @override
  String get allCaughtUpMessage =>
      'You\'re all caught up! Activity alerts will appear here.';

  @override
  String minutesAgoLabel(int minutes) {
    return '${minutes}m ago';
  }

  @override
  String hoursAgoLabel(int hours) {
    return '${hours}h ago';
  }

  @override
  String daysAgoLabel(int days) {
    return '${days}d ago';
  }

  @override
  String get xpLabel => 'XP';

  @override
  String get coinsLabel => 'Coins';

  @override
  String get unverifiedLabel => 'UNVERIFIED';

  @override
  String get waitingForVerificationMessage =>
      'Waiting for the student to verify their email and log in for the first time.';

  @override
  String get firstLoginCoinsRewardMessage =>
      '+3 coins will be awarded on first login';

  @override
  String get weeklyAccuracyLabel => 'Weekly Accuracy';

  @override
  String get navMyStudentsLabel => 'My Students';

  @override
  String get navHelpLabel => 'Help';

  @override
  String get navHomeLabel => 'Home';

  @override
  String get navShopLabel => 'Shop';

  @override
  String get noGradeLabel => 'No grade';

  @override
  String get tapToViewLabel => 'Tap to view';

  @override
  String get awaitingEmailVerificationLabel => 'Awaiting email verification';

  @override
  String xpAmountLabel(int xp) {
    return '$xp XP';
  }

  @override
  String questionsAttemptedLabel(int total) {
    return 'Questions Attempted ($total)';
  }

  @override
  String get correctLabel => 'Correct';

  @override
  String get incorrectLabel => 'Incorrect';

  @override
  String questionNumberLabel(int number) {
    return 'Question $number';
  }

  @override
  String get parentVerificationRequiredTitle => 'Parent Verification Required';

  @override
  String get logoutParentCredentialsMessage =>
      'To log out, please enter your parent\'s credentials.';

  @override
  String get parentEmailLabel => 'Parent\'s Email';

  @override
  String get parentPasswordLabel => 'Parent\'s Password';

  @override
  String get verifyAndLogOutButton => 'Verify & Log Out';

  @override
  String xpRewardLabel(int xp) {
    return '+$xp XP';
  }

  @override
  String notifLevelUpTitle(int level) {
    return 'You reached Level $level! 🎓';
  }

  @override
  String get notifLevelUpBody =>
      'Keep it up — more rewards are waiting at the next level.';

  @override
  String notifParentLevelUpTitle(String studentName, int level) {
    return '$studentName reached Level $level! 🎓';
  }

  @override
  String get notifParentLevelUpBody =>
      'They\'ve been working hard. Check their progress.';

  @override
  String notifStreakMilestoneTitle(int streak) {
    return '$streak-day streak! 🔥';
  }

  @override
  String notifStreakMilestoneBody(int streak) {
    return 'You\'ve studied $streak days in a row. Keep the fire going!';
  }

  @override
  String get notifNearMilestoneTitle => 'One more day! 🔥';

  @override
  String notifNearMilestoneBody(int nextMilestone) {
    return 'Keep going — your $nextMilestone-day reward is tomorrow.';
  }

  @override
  String get notifStreakReminderTitle => 'Don\'t break your streak! 🔥';

  @override
  String notifStreakReminderBody(int streak) {
    return 'One quiz keeps your $streak-day streak alive.';
  }

  @override
  String get notifStartStreakTitle => 'Start a new streak today!';

  @override
  String get notifStartStreakBody =>
      'Take a quick quiz and begin your learning streak.';

  @override
  String notifParentStreakBrokenTitle(String studentName) {
    return '$studentName\'s streak ended';
  }

  @override
  String notifParentStreakBrokenBody(int previousStreak) {
    return 'Their $previousStreak-day streak was broken. A little encouragement might help.';
  }

  @override
  String notifGardenNudgeTitle(String subject) {
    return 'Your $subject plant needs you 🌱';
  }

  @override
  String notifGardenNudgeBody(String subject) {
    return 'It\'s been a few days — come water your $subject garden!';
  }

  @override
  String notifInactivityTitle(String studentName) {
    return '$studentName hasn\'t quizzed in 3 days';
  }

  @override
  String get notifInactivityBody =>
      'A little encouragement might help them get back on track.';

  @override
  String notifParentStreakMilestoneTitle(String studentName, int streak) {
    return '$studentName hit a $streak-day streak! 🔥';
  }

  @override
  String get notifParentStreakMilestoneBody =>
      'They\'ve been on a roll — keep the encouragement coming!';

  @override
  String get parentNotifPerStudentSection => 'Students';

  @override
  String get parentStudentNotifAllLabel =>
      'All notifications from this student';

  @override
  String get parentNotifNoStudentsLinked => 'No students linked yet.';

  @override
  String get managePreferencesButton => 'Manage Preferences';

  @override
  String get parentPreferencesTitle => 'Preferences';

  @override
  String get parentNotificationsSection => 'Notifications';

  @override
  String get parentNotifProgressLabel => 'Child Progress Alerts';

  @override
  String get parentNotifProgressSubtitle => 'Level ups and badge achievements';

  @override
  String get parentNotifStreakLabel => 'Streak Alerts';

  @override
  String get parentNotifStreakSubtitle =>
      'Streak milestones and broken streaks';

  @override
  String get parentNotifInactivityLabel => 'Inactivity Reminders';

  @override
  String get parentNotifInactivitySubtitle =>
      'Alerts when a child hasn\'t studied in 3+ days';

  @override
  String get errInvalidCredentials =>
      'Invalid email or password. Please try again.';

  @override
  String get errNetworkError => 'Network error. Check your connection.';

  @override
  String get errNetworkErrorRetry =>
      'Network error. Check your connection and try again.';

  @override
  String get errWeakPassword => 'Password is too weak.';

  @override
  String get errWeakPasswordDetailed =>
      'Password is too weak. Please use at least 6 characters.';

  @override
  String get errEmailAlreadyInUse =>
      'That email address is already registered. Please use a different one.';

  @override
  String get errInvalidEmailFormat =>
      'That email address doesn\'t look right. Please check it.';

  @override
  String get errSessionExpired =>
      'Session expired. Please log out and log in again.';

  @override
  String get errTooManyAttempts =>
      'Too many attempts. Please wait a moment and try again.';

  @override
  String get errRegistrationFailed => 'Registration failed. Please try again.';

  @override
  String get errNoSignedInAccount =>
      'No signed-in account found. Please log in again.';

  @override
  String get errVerificationEmailFailed =>
      'Could not send verification email. Please try again.';

  @override
  String get errWrongCurrentPassword => 'Current password is incorrect.';

  @override
  String get errNewPasswordTooWeak =>
      'New password is too weak. Use at least 6 characters.';

  @override
  String get errEmailAlreadyInUseOther =>
      'That email address is already in use by another account.';

  @override
  String get errUpdateFailed => 'Update failed. Please try again.';

  @override
  String get errUploadFailed => 'Upload failed. Please try again.';

  @override
  String get errSubjectStillProcessing =>
      'A document for this subject is still being prepared. Please wait until it finishes before uploading another.';

  @override
  String get subjectPreparingLabel => 'Preparing your subject…';

  @override
  String get subjectStageParsing => 'Reading your document…';

  @override
  String get subjectStageAnalyzing => 'Finding topics…';

  @override
  String get subjectStageBuildingSkills => 'Building your skill tree…';

  @override
  String get subjectPreparingPracticeDisabled => 'Preparing…';

  @override
  String get subjectIngestFailed =>
      'We couldn\'t process this document. Please try uploading it again.';

  @override
  String get quizSubjectStillPreparing =>
      'This subject is still being prepared. Please try again in a moment.';

  @override
  String get errDeleteAccountFailed =>
      'Unable to delete account. Please try again.';

  @override
  String get errStudentSessionExpired =>
      'Session expired. Please log out and log in again before adding a student.';

  @override
  String get errStudentEmailAlreadyRegistered =>
      'This email is already registered. Try logging in or resetting the password.';

  @override
  String get errStudentWeakPassword =>
      'The password provided is too weak. Please use at least 6 characters.';

  @override
  String get errStudentInvalidEmail => 'The email address is badly formatted.';

  @override
  String get errUnexpected => 'An unexpected error occurred. Please try again.';

  @override
  String get shopItemPurchasedMessage => 'Purchase successful! 🎉';

  @override
  String get errPurchaseFailed => 'Purchase failed. Please try again.';

  @override
  String get errCouldNotLoadProfile =>
      'Could not load your profile. Please try again.';

  @override
  String get errInvalidParentCredentials =>
      'Invalid parent credentials. Logout denied.';

  @override
  String get confirmEmailSubtitle => 'One last step';

  @override
  String get createParentAccountSubtitle => 'Create your parent account';

  @override
  String get resetPasswordSubtitle => 'We\'ll email you a reset link';

  @override
  String get todayLabel => 'Today';

  @override
  String get studiedLabel => 'Studied';

  @override
  String get effortFocusTitle => 'Effort & Focus';

  @override
  String get effortFocusSubtitle => 'Where this week\'s quizzes came from';

  @override
  String get selfStartedLabel => 'Self-started';

  @override
  String get toUnlockAppsLabel => 'To unlock apps';

  @override
  String percentSelfStartedMessage(int percent) {
    return '$percent% of quizzes were self-started';
  }

  @override
  String get noSubjectsReportMessage => 'No subjects to report on yet.';

  @override
  String quizzesGuessingMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count quizzes showed rapid guessing',
      one: '1 quiz showed rapid guessing',
    );
    return '$_temp0';
  }

  @override
  String get restingStatusLabel => 'Resting';

  @override
  String get readyStatusLabel => 'Ready';

  @override
  String get markAsUnreadTooltip => 'Mark as unread';

  @override
  String get markAsReadTooltip => 'Mark as read';

  @override
  String get noActivitySummarizeMessage => 'No activity to summarize yet.';

  @override
  String get motivationLevel1 =>
      'You\'re a Seedling — every expert was once a beginner! 🌱';

  @override
  String get motivationLevel2 =>
      'You\'re a Sprout — you\'re growing fast, keep it up! 🌿';

  @override
  String get motivationLevel3 =>
      'You\'re an Explorer — curiosity is your superpower! 🔍';

  @override
  String get motivationLevel4 =>
      'You\'re a Curious Mind — great questions lead to great answers! 💡';

  @override
  String get motivationLevel5 =>
      'You\'re a Scholar — your hard work is really showing! 📚';

  @override
  String get motivationLevel6 =>
      'You\'re an Achiever — you make it look easy! ⭐';

  @override
  String get motivationLevel7 =>
      'You\'re a Champion — you inspire everyone around you! 🏆';

  @override
  String get motivationLevel8 =>
      'You\'re a Sage — your wisdom sets you apart! 🦉';

  @override
  String get motivationLevel9 =>
      'You\'re a Luminary — you light the way for others! ✨';

  @override
  String get motivationLevel10 =>
      'You\'re a Master — the pinnacle of excellence! 🌟';

  @override
  String get motivationDefault => 'Keep learning — you\'re doing amazing! 🚀';

  @override
  String get hourUnitLabel => 'hr';

  @override
  String get hoursUnitLabel => 'hrs';

  @override
  String get minuteUnitLabel => 'min';

  @override
  String get appsParentWatchesTitle => 'Apps your parent watches';

  @override
  String get restingNowSubtitle => 'Resting now · tap to see all';

  @override
  String appsCountSubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count apps · tap to see all',
      one: '1 app · tap to see all',
    );
    return '$_temp0';
  }

  @override
  String get noAppsWatchedMessage => 'No apps are being watched right now 🎉';

  @override
  String get globalTimeLimitsLabel => 'Global Time Limits';

  @override
  String get globalTimeLimitsTooltip =>
      'These limits apply to all restricted apps. When a student reaches the usage limit on any restricted app, they must wait the cooldown period before using it again.';

  @override
  String get usageAllowanceLabel => 'Usage Allowance';

  @override
  String get readyToPracticeMessage => 'Ready to practice?';

  @override
  String get gotItButton => 'Got it';

  @override
  String get finishButton => 'Finish';

  @override
  String get correctExclamationLabel => 'Correct!';

  @override
  String get solutionLabel => 'Solution';

  @override
  String get correctAnswerLabel => 'Correct answer';

  @override
  String reachLevelToUnlockMessage(int level) {
    return 'Reach Level $level to unlock this item.';
  }

  @override
  String coinPriceLabel(int price) {
    return '$price coins';
  }

  @override
  String balanceAfterLabel(int balance) {
    return 'Balance after: $balance 🪙';
  }

  @override
  String get appsRestingTitle => 'Apps are resting right now';

  @override
  String earnedFreeTimeLockedSubtitle(String time) {
    return 'You\'ve earned $time of free time today. Finish your quiz to unlock more.';
  }

  @override
  String get finishQuizUnlockApps => 'Finish your quiz to unlock your apps.';

  @override
  String earnedFreeTimeUnlockedTitle(String time) {
    return 'You\'ve earned $time of free time today';
  }

  @override
  String get appsUnlockedEnjoySubtitle =>
      'Your apps are unlocked — enjoy your free time.';

  @override
  String get appsUnlockedTitle => 'Your apps are unlocked';

  @override
  String get enjoyFreeTimeSubtitle => 'Enjoy your free time.';

  @override
  String get timeToRestTitle => 'Time to rest';

  @override
  String get screenTimeTitle => 'Screen time';

  @override
  String limitRestSummaryLabel(String limit, String rest) {
    return 'Limit $limit   ·   Rest $rest';
  }

  @override
  String get minLeftLabel => 'min left';

  @override
  String get secLeftLabel => 'sec left';

  @override
  String get restingLabel => 'resting';

  @override
  String get noTimeLimitMessage => 'No time limit set — enjoy learning!';

  @override
  String get questionsTodayLabel => 'questions today';

  @override
  String get noQuestionsYetMessage =>
      'No questions yet today — let\'s start! 🌱';

  @override
  String get topRankLabel => 'Top rank';

  @override
  String nextRankLabel(String rank) {
    return 'Next: $rank';
  }

  @override
  String get reachedTopMessage => 'You reached the top — amazing!';

  @override
  String xpProgressLabel(int current, int max) {
    return '$current / $max XP';
  }

  @override
  String totalSuffixLabel(String time) {
    return '$time total';
  }

  @override
  String get noStudyTimeWeekMessage => 'No study time logged this week yet.';

  @override
  String get mascotIdleMessage => 'What shall we learn today?';

  @override
  String get mascotHappyMessage => 'Great job! Keep it up!';

  @override
  String get mascotThinkingMessage => 'One moment…';

  @override
  String get mascotSadMessage => 'Don\'t worry — let\'s try again!';

  @override
  String get mascotCelebrationMessage => 'Amazing work! 🌟';

  @override
  String mascotHiGreeting(String name) {
    return 'Hi, $name! 👋';
  }
}
