import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

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

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
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
    Locale('ar'),
    Locale('en'),
  ];

  /// The application title
  ///
  /// In en, this message translates to:
  /// **'StudyMentor'**
  String get appTitle;

  /// No description provided for @languageSettingTitle.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageSettingTitle;

  /// No description provided for @languageSettingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'English / Arabic'**
  String get languageSettingSubtitle;

  /// No description provided for @languageDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose Language'**
  String get languageDialogTitle;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageArabic.
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get languageArabic;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get commonOk;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @commonRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get commonRetry;

  /// No description provided for @commonDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// No description provided for @commonClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// No description provided for @commonError.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get commonError;

  /// No description provided for @commonLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get commonLoading;

  /// No description provided for @studentSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get studentSettingsTitle;

  /// No description provided for @preferencesSection.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferencesSection;

  /// No description provided for @accountSection.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get accountSection;

  /// No description provided for @aboutSection.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get aboutSection;

  /// No description provided for @usageTimerNotificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Usage Timer Notification'**
  String get usageTimerNotificationTitle;

  /// No description provided for @usageTimerNotificationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Show a notification counting down your remaining app time'**
  String get usageTimerNotificationSubtitle;

  /// No description provided for @cooldownTimerNotificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Cooldown Timer Notification'**
  String get cooldownTimerNotificationTitle;

  /// No description provided for @cooldownTimerNotificationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Show a notification counting down your remaining cooldown time'**
  String get cooldownTimerNotificationSubtitle;

  /// No description provided for @appVersionLabel.
  ///
  /// In en, this message translates to:
  /// **'App Version'**
  String get appVersionLabel;

  /// No description provided for @parentSettingsEmailPendingBanner.
  ///
  /// In en, this message translates to:
  /// **'A verification link was sent to {email}. Your email address will update after you click it.'**
  String parentSettingsEmailPendingBanner(String email);

  /// No description provided for @parentSettingsAccountInfoSection.
  ///
  /// In en, this message translates to:
  /// **'Account Information'**
  String get parentSettingsAccountInfoSection;

  /// No description provided for @parentSettingsChangePasswordSection.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get parentSettingsChangePasswordSection;

  /// No description provided for @parentSettingsPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Leave all password fields empty to keep your current password.'**
  String get parentSettingsPasswordHint;

  /// No description provided for @fieldFullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fieldFullName;

  /// No description provided for @validatorFullNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Full name is required.'**
  String get validatorFullNameRequired;

  /// No description provided for @validatorFullNameMinLength.
  ///
  /// In en, this message translates to:
  /// **'Name must be at least 2 characters.'**
  String get validatorFullNameMinLength;

  /// No description provided for @fieldEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get fieldEmail;

  /// No description provided for @parentSettingsEmailHelper.
  ///
  /// In en, this message translates to:
  /// **'Changing your email will send a verification link to the new address.'**
  String get parentSettingsEmailHelper;

  /// No description provided for @validatorEmailRequired.
  ///
  /// In en, this message translates to:
  /// **'Email is required.'**
  String get validatorEmailRequired;

  /// No description provided for @validatorEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address.'**
  String get validatorEmailInvalid;

  /// No description provided for @fieldCurrentPassword.
  ///
  /// In en, this message translates to:
  /// **'Current Password'**
  String get fieldCurrentPassword;

  /// No description provided for @validatorCurrentPasswordForEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter your current password to change your email.'**
  String get validatorCurrentPasswordForEmail;

  /// No description provided for @validatorCurrentPasswordForNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter your current password to set a new one.'**
  String get validatorCurrentPasswordForNewPassword;

  /// No description provided for @fieldNewPassword.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get fieldNewPassword;

  /// No description provided for @validatorPasswordMinLength.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters.'**
  String get validatorPasswordMinLength;

  /// No description provided for @validatorEnterCurrentPasswordFirst.
  ///
  /// In en, this message translates to:
  /// **'Enter your current password first.'**
  String get validatorEnterCurrentPasswordFirst;

  /// No description provided for @fieldConfirmNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm New Password'**
  String get fieldConfirmNewPassword;

  /// No description provided for @validatorPasswordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match.'**
  String get validatorPasswordsDoNotMatch;

  /// No description provided for @saveChangesButton.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChangesButton;

  /// No description provided for @profileUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully.'**
  String get profileUpdatedSuccess;

  /// No description provided for @couldNotLoadLinkedStudents.
  ///
  /// In en, this message translates to:
  /// **'Could not load linked students. Check your connection.'**
  String get couldNotLoadLinkedStudents;

  /// No description provided for @dangerZoneSection.
  ///
  /// In en, this message translates to:
  /// **'Danger Zone'**
  String get dangerZoneSection;

  /// No description provided for @deleteAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccountTitle;

  /// No description provided for @deleteAccountDescription.
  ///
  /// In en, this message translates to:
  /// **'Permanently removes your account and all data. You must delete all student accounts first.'**
  String get deleteAccountDescription;

  /// No description provided for @deleteAccountBlockedTooltip.
  ///
  /// In en, this message translates to:
  /// **'Remove all linked children before deleting your account.'**
  String get deleteAccountBlockedTooltip;

  /// No description provided for @deleteAccountRetryTooltip.
  ///
  /// In en, this message translates to:
  /// **'Could not verify linked students. Please retry.'**
  String get deleteAccountRetryTooltip;

  /// No description provided for @deleteMyAccountButton.
  ///
  /// In en, this message translates to:
  /// **'Delete My Account'**
  String get deleteMyAccountButton;

  /// No description provided for @childLoadErrorNotice.
  ///
  /// In en, this message translates to:
  /// **'Could not verify linked students. Deletion is disabled until this is resolved.'**
  String get childLoadErrorNotice;

  /// No description provided for @linkedChildrenNotice.
  ///
  /// In en, this message translates to:
  /// **'You can only delete your account after removing all linked children. Go to the Students tab to delete each child\'s account first.'**
  String get linkedChildrenNotice;

  /// No description provided for @deleteYourAccountDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Your Account'**
  String get deleteYourAccountDialogTitle;

  /// No description provided for @deleteYourAccountDialogContent.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete your account. Are you sure?'**
  String get deleteYourAccountDialogContent;

  /// No description provided for @continueButton.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueButton;

  /// No description provided for @confirmYourPasswordDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm Your Password'**
  String get confirmYourPasswordDialogTitle;

  /// No description provided for @confirmPasswordDeleteWarning.
  ///
  /// In en, this message translates to:
  /// **'Enter your current password to permanently delete your account. This cannot be undone.'**
  String get confirmPasswordDeleteWarning;

  /// No description provided for @validatorEnterCurrentPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter your current password.'**
  String get validatorEnterCurrentPassword;

  /// No description provided for @signInTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signInTitle;

  /// No description provided for @fieldPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get fieldPassword;

  /// No description provided for @validatorPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required.'**
  String get validatorPasswordRequired;

  /// No description provided for @loginEmailValidator.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address.'**
  String get loginEmailValidator;

  /// No description provided for @registerPromptButton.
  ///
  /// In en, this message translates to:
  /// **'Not registered yet? Register as a Parent'**
  String get registerPromptButton;

  /// No description provided for @forgotPasswordButton.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPasswordButton;

  /// No description provided for @registerAsParentTitle.
  ///
  /// In en, this message translates to:
  /// **'Register as a Parent'**
  String get registerAsParentTitle;

  /// No description provided for @fieldConfirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get fieldConfirmPassword;

  /// No description provided for @registerButton.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get registerButton;

  /// No description provided for @alreadyRegisteredButton.
  ///
  /// In en, this message translates to:
  /// **'Already registered? Sign In'**
  String get alreadyRegisteredButton;

  /// No description provided for @resetPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPasswordTitle;

  /// No description provided for @passwordResetLinkSentMessage.
  ///
  /// In en, this message translates to:
  /// **'Password reset link sent! Check your inbox.'**
  String get passwordResetLinkSentMessage;

  /// No description provided for @sendResetLinkButton.
  ///
  /// In en, this message translates to:
  /// **'Send Reset Link'**
  String get sendResetLinkButton;

  /// No description provided for @confirmEmailTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm Email'**
  String get confirmEmailTitle;

  /// No description provided for @emailNotVerifiedYetMessage.
  ///
  /// In en, this message translates to:
  /// **'Your email hasn\'t been verified yet. Check your inbox.'**
  String get emailNotVerifiedYetMessage;

  /// No description provided for @emailVerificationLinkSentMessage.
  ///
  /// In en, this message translates to:
  /// **'Email verification link sent!'**
  String get emailVerificationLinkSentMessage;

  /// No description provided for @confirmEmailInstructions.
  ///
  /// In en, this message translates to:
  /// **'Please check your inbox and verify your email to continue.'**
  String get confirmEmailInstructions;

  /// No description provided for @sendEmailVerificationButton.
  ///
  /// In en, this message translates to:
  /// **'Send Email Verification Link'**
  String get sendEmailVerificationButton;

  /// No description provided for @emailVerifiedButton.
  ///
  /// In en, this message translates to:
  /// **'I\'ve Verified My Email'**
  String get emailVerifiedButton;

  /// No description provided for @logOutButton.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get logOutButton;

  /// No description provided for @dashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboardTitle;

  /// No description provided for @nothingHereYetTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet.'**
  String get nothingHereYetTitle;

  /// No description provided for @activityAlertsWillAppearHere.
  ///
  /// In en, this message translates to:
  /// **'Activity and alerts will appear here.'**
  String get activityAlertsWillAppearHere;

  /// No description provided for @myChildrenTitle.
  ///
  /// In en, this message translates to:
  /// **'My Children'**
  String get myChildrenTitle;

  /// No description provided for @validatorStudentPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter the student\'s password.'**
  String get validatorStudentPasswordRequired;

  /// No description provided for @removeStudentTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove Student'**
  String get removeStudentTitle;

  /// No description provided for @removeStudentConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete {studentName}\'s account. Enter the password you created for them to confirm.'**
  String removeStudentConfirmMessage(String studentName);

  /// No description provided for @fieldStudentPassword.
  ///
  /// In en, this message translates to:
  /// **'Student\'s Password'**
  String get fieldStudentPassword;

  /// No description provided for @removeButton.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get removeButton;

  /// No description provided for @noChildrenAddedYetTitle.
  ///
  /// In en, this message translates to:
  /// **'No children added yet.'**
  String get noChildrenAddedYetTitle;

  /// No description provided for @useAddStudentButtonHint.
  ///
  /// In en, this message translates to:
  /// **'Use the Add Student button to register your first child.'**
  String get useAddStudentButtonHint;

  /// No description provided for @studentNotActivatedBanner.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{{names} hasn\'t activated their account yet.} other{{names} haven\'t activated their accounts yet.}}'**
  String studentNotActivatedBanner(int count, String names);

  /// No description provided for @verifyEmailInstructionBanner.
  ///
  /// In en, this message translates to:
  /// **'Ask them to open the app, log in with the credentials you created, and verify their email.'**
  String get verifyEmailInstructionBanner;

  /// No description provided for @tapStudentCardHint.
  ///
  /// In en, this message translates to:
  /// **'Tap on a student card to monitor their activity, manage app usage rules, and review their academic status.'**
  String get tapStudentCardHint;

  /// No description provided for @incorrectPasswordRetryMessage.
  ///
  /// In en, this message translates to:
  /// **'Incorrect password. Please try again.'**
  String get incorrectPasswordRetryMessage;

  /// No description provided for @deleteChildAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Child Account'**
  String get deleteChildAccountTitle;

  /// No description provided for @deleteChildAccountWarningPrefix.
  ///
  /// In en, this message translates to:
  /// **'You are about to permanently delete '**
  String get deleteChildAccountWarningPrefix;

  /// No description provided for @deleteChildAccountWarningSuffix.
  ///
  /// In en, this message translates to:
  /// **'\'s account. This will remove all of their data and cannot be undone.'**
  String get deleteChildAccountWarningSuffix;

  /// No description provided for @studentCredentialsWillBeDeleted.
  ///
  /// In en, this message translates to:
  /// **'{firstName}\'s login credentials, progress, and settings will all be permanently deleted.'**
  String studentCredentialsWillBeDeleted(String firstName);

  /// No description provided for @passwordYouCreatedForHint.
  ///
  /// In en, this message translates to:
  /// **'Password you created for {firstName}'**
  String passwordYouCreatedForHint(String firstName);

  /// No description provided for @deletePermanentlyButton.
  ///
  /// In en, this message translates to:
  /// **'Delete Permanently'**
  String get deletePermanentlyButton;

  /// No description provided for @gradeLabel.
  ///
  /// In en, this message translates to:
  /// **'Grade {grade}'**
  String gradeLabel(int grade);

  /// No description provided for @studentRegisteredSuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Student Registered Successfully!'**
  String get studentRegisteredSuccessTitle;

  /// No description provided for @studentRegisteredSuccessDetail.
  ///
  /// In en, this message translates to:
  /// **'On your child\'s phone, open the app and log in with the credentials you just created. They\'ll need to verify their email before getting started.'**
  String get studentRegisteredSuccessDetail;

  /// No description provided for @registerStudentTitle.
  ///
  /// In en, this message translates to:
  /// **'Register Student'**
  String get registerStudentTitle;

  /// No description provided for @createNewStudentAccountSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create a new student account'**
  String get createNewStudentAccountSubtitle;

  /// No description provided for @studentInformationSection.
  ///
  /// In en, this message translates to:
  /// **'Student Information'**
  String get studentInformationSection;

  /// No description provided for @fieldGrade.
  ///
  /// In en, this message translates to:
  /// **'Grade'**
  String get fieldGrade;

  /// No description provided for @validatorGradeRequired.
  ///
  /// In en, this message translates to:
  /// **'Please select a grade.'**
  String get validatorGradeRequired;

  /// No description provided for @accountCredentialsSection.
  ///
  /// In en, this message translates to:
  /// **'Account Credentials'**
  String get accountCredentialsSection;

  /// No description provided for @fieldEmailAddress.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get fieldEmailAddress;

  /// No description provided for @emailAddressHint.
  ///
  /// In en, this message translates to:
  /// **'The student will use this to log in.'**
  String get emailAddressHint;

  /// No description provided for @validatorConfirmPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Please confirm your password.'**
  String get validatorConfirmPasswordRequired;

  /// No description provided for @accountSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Account Settings'**
  String get accountSettingsTitle;

  /// No description provided for @unsavedChangesDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Unsaved Changes'**
  String get unsavedChangesDialogTitle;

  /// No description provided for @unsavedChangesDialogContent.
  ///
  /// In en, this message translates to:
  /// **'You have unsaved changes. Leave without saving?'**
  String get unsavedChangesDialogContent;

  /// No description provided for @stayButton.
  ///
  /// In en, this message translates to:
  /// **'Stay'**
  String get stayButton;

  /// No description provided for @leaveButton.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get leaveButton;

  /// No description provided for @logoutConfirmationMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out of your account?'**
  String get logoutConfirmationMessage;

  /// No description provided for @requiredToChangeEmailHint.
  ///
  /// In en, this message translates to:
  /// **'Required to change the email address.'**
  String get requiredToChangeEmailHint;

  /// No description provided for @studentProfileStaticTitle.
  ///
  /// In en, this message translates to:
  /// **'Student Profile'**
  String get studentProfileStaticTitle;

  /// No description provided for @studentProfileUpdatedEmailPending.
  ///
  /// In en, this message translates to:
  /// **'Profile updated. A verification link was sent to {email}.'**
  String studentProfileUpdatedEmailPending(String email);

  /// No description provided for @studentSettingsEmailPendingBanner.
  ///
  /// In en, this message translates to:
  /// **'A verification link was sent to {email}. The student\'s email will update after they click it.'**
  String studentSettingsEmailPendingBanner(String email);

  /// No description provided for @studentSettingsEmailHelper.
  ///
  /// In en, this message translates to:
  /// **'Changing the email will send a verification link to the new address.'**
  String get studentSettingsEmailHelper;

  /// No description provided for @fieldStudentCurrentPassword.
  ///
  /// In en, this message translates to:
  /// **'Student\'s Current Password'**
  String get fieldStudentCurrentPassword;

  /// No description provided for @validatorStudentCurrentPasswordForEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter the student\'s current password to change their email.'**
  String get validatorStudentCurrentPasswordForEmail;

  /// No description provided for @validatorStudentCurrentPasswordForNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter the student\'s current password to set a new one.'**
  String get validatorStudentCurrentPasswordForNewPassword;

  /// No description provided for @validatorEnterStudentCurrentPasswordFirst.
  ///
  /// In en, this message translates to:
  /// **'Enter the student\'s current password first.'**
  String get validatorEnterStudentCurrentPasswordFirst;

  /// No description provided for @discardChangesDialogContent.
  ///
  /// In en, this message translates to:
  /// **'Refreshing will discard your unsaved changes. Continue?'**
  String get discardChangesDialogContent;

  /// No description provided for @discardAndRefreshButton.
  ///
  /// In en, this message translates to:
  /// **'Discard & Refresh'**
  String get discardAndRefreshButton;

  /// No description provided for @stillLoadingAppListMessage.
  ///
  /// In en, this message translates to:
  /// **'Still loading app list — please wait.'**
  String get stillLoadingAppListMessage;

  /// No description provided for @deviceNotSyncedMessage.
  ///
  /// In en, this message translates to:
  /// **'{name}\'s device hasn\'t synced yet. Ask them to open the app once.'**
  String deviceNotSyncedMessage(String name);

  /// No description provided for @allAppsAlreadyConfiguredMessage.
  ///
  /// In en, this message translates to:
  /// **'All installed apps have already been configured.'**
  String get allAppsAlreadyConfiguredMessage;

  /// No description provided for @removeAppConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove {appLabel}?'**
  String removeAppConfirmTitle(String appLabel);

  /// No description provided for @removeAppConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to stop monitoring this app? Your child will have unrestricted access to it.'**
  String get removeAppConfirmMessage;

  /// No description provided for @configSavedSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'Configuration saved successfully.'**
  String get configSavedSuccessMessage;

  /// No description provided for @configurationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Configurations'**
  String get configurationsTitle;

  /// No description provided for @screenTimeRewardTitle.
  ///
  /// In en, this message translates to:
  /// **'Screen Time Reward per Quiz'**
  String get screenTimeRewardTitle;

  /// No description provided for @screenTimeRewardDescription.
  ///
  /// In en, this message translates to:
  /// **'Child earns this much unlocked screen time for every quiz they pass.'**
  String get screenTimeRewardDescription;

  /// No description provided for @setCooldownTimeTitle.
  ///
  /// In en, this message translates to:
  /// **'Set Cooldown Time'**
  String get setCooldownTimeTitle;

  /// No description provided for @cooldownPeriodTitle.
  ///
  /// In en, this message translates to:
  /// **'Cooldown Period'**
  String get cooldownPeriodTitle;

  /// No description provided for @cooldownPeriodDescription.
  ///
  /// In en, this message translates to:
  /// **'Lock duration after screen time runs out.'**
  String get cooldownPeriodDescription;

  /// No description provided for @appRulesTitle.
  ///
  /// In en, this message translates to:
  /// **'App Rules'**
  String get appRulesTitle;

  /// No description provided for @noAppsConfiguredHint.
  ///
  /// In en, this message translates to:
  /// **'No apps configured yet. Tap + to add your first app.'**
  String get noAppsConfiguredHint;

  /// No description provided for @monitoredCountLabel.
  ///
  /// In en, this message translates to:
  /// **'{count} monitored'**
  String monitoredCountLabel(int count);

  /// No description provided for @pausedCountLabel.
  ///
  /// In en, this message translates to:
  /// **'{count} paused'**
  String pausedCountLabel(int count);

  /// No description provided for @manageAllAppsLabel.
  ///
  /// In en, this message translates to:
  /// **'Manage all {count} apps'**
  String manageAllAppsLabel(int count);

  /// No description provided for @quizSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Quiz Settings'**
  String get quizSettingsTitle;

  /// No description provided for @questionsPerQuizLabel.
  ///
  /// In en, this message translates to:
  /// **'Questions per Quiz'**
  String get questionsPerQuizLabel;

  /// No description provided for @quizCountAutoLabel.
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get quizCountAutoLabel;

  /// No description provided for @quizCountAutoDescription.
  ///
  /// In en, this message translates to:
  /// **'Smart Tutor will adjust the quiz length dynamically based on the child\'s current performance.'**
  String get quizCountAutoDescription;

  /// No description provided for @quizCountFixedDescription.
  ///
  /// In en, this message translates to:
  /// **'Child must correctly answer {count} questions to unlock their device.'**
  String quizCountFixedDescription(int count);

  /// No description provided for @editProfileButton.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfileButton;

  /// No description provided for @passwordRequiredToDeleteAccountMessage.
  ///
  /// In en, this message translates to:
  /// **'Password is required to delete the account.'**
  String get passwordRequiredToDeleteAccountMessage;

  /// No description provided for @deleteStudentDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Student'**
  String get deleteStudentDialogTitle;

  /// No description provided for @deleteStudentWarningPrefix.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete '**
  String get deleteStudentWarningPrefix;

  /// No description provided for @deleteStudentWarningSuffix.
  ///
  /// In en, this message translates to:
  /// **'\'s account — progress, items, and settings. This cannot be undone.'**
  String get deleteStudentWarningSuffix;

  /// No description provided for @monitoredAndPausedLabel.
  ///
  /// In en, this message translates to:
  /// **'{monitored} monitored · {paused} paused'**
  String monitoredAndPausedLabel(int monitored, int paused);

  /// No description provided for @noAppsConfiguredTitle.
  ///
  /// In en, this message translates to:
  /// **'No apps configured yet.'**
  String get noAppsConfiguredTitle;

  /// No description provided for @tapAddAppHint.
  ///
  /// In en, this message translates to:
  /// **'Tap \"Add App\" below to get started.'**
  String get tapAddAppHint;

  /// No description provided for @appStatusPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get appStatusPaused;

  /// No description provided for @appStatusMonitored.
  ///
  /// In en, this message translates to:
  /// **'Monitored'**
  String get appStatusMonitored;

  /// No description provided for @addAppButton.
  ///
  /// In en, this message translates to:
  /// **'Add App'**
  String get addAppButton;

  /// No description provided for @installedAppsFilterLabel.
  ///
  /// In en, this message translates to:
  /// **'Installed Apps'**
  String get installedAppsFilterLabel;

  /// No description provided for @installedAppsFilterSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Apps downloaded by the student'**
  String get installedAppsFilterSubtitle;

  /// No description provided for @allAppsFilterLabel.
  ///
  /// In en, this message translates to:
  /// **'All Apps'**
  String get allAppsFilterLabel;

  /// No description provided for @allAppsFilterSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Includes system & pre-installed apps'**
  String get allAppsFilterSubtitle;

  /// No description provided for @selectAppsTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Apps'**
  String get selectAppsTitle;

  /// No description provided for @searchAppsHint.
  ///
  /// In en, this message translates to:
  /// **'Search apps…'**
  String get searchAppsHint;

  /// No description provided for @addSelectedButton.
  ///
  /// In en, this message translates to:
  /// **'Add Selected'**
  String get addSelectedButton;

  /// No description provided for @noAppsMatchQuery.
  ///
  /// In en, this message translates to:
  /// **'No apps match \"{query}\"'**
  String noAppsMatchQuery(String query);

  /// No description provided for @noUserInstalledAppsFound.
  ///
  /// In en, this message translates to:
  /// **'No user-installed apps found'**
  String get noUserInstalledAppsFound;

  /// No description provided for @switchToAllAppsHint.
  ///
  /// In en, this message translates to:
  /// **'Switch to All Apps to see system apps'**
  String get switchToAllAppsHint;

  /// No description provided for @setRewardTimeTitle.
  ///
  /// In en, this message translates to:
  /// **'Set Reward Time'**
  String get setRewardTimeTitle;

  /// No description provided for @presetMinutesLabel.
  ///
  /// In en, this message translates to:
  /// **'{minutes} mins'**
  String presetMinutesLabel(int minutes);

  /// No description provided for @preset1HourLabel.
  ///
  /// In en, this message translates to:
  /// **'1 hour'**
  String get preset1HourLabel;

  /// No description provided for @saveTimeButton.
  ///
  /// In en, this message translates to:
  /// **'Save Time'**
  String get saveTimeButton;

  /// No description provided for @masteryTierAdvanced.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get masteryTierAdvanced;

  /// No description provided for @masteryTierProficient.
  ///
  /// In en, this message translates to:
  /// **'Proficient'**
  String get masteryTierProficient;

  /// No description provided for @masteryTierDeveloping.
  ///
  /// In en, this message translates to:
  /// **'Developing'**
  String get masteryTierDeveloping;

  /// No description provided for @masteryTierBeginner.
  ///
  /// In en, this message translates to:
  /// **'Beginner'**
  String get masteryTierBeginner;

  /// No description provided for @sortQuizzesTitle.
  ///
  /// In en, this message translates to:
  /// **'Sort Quizzes'**
  String get sortQuizzesTitle;

  /// No description provided for @sortDateNewestToOldest.
  ///
  /// In en, this message translates to:
  /// **'Date: Newest to Oldest'**
  String get sortDateNewestToOldest;

  /// No description provided for @sortDateOldestToNewest.
  ///
  /// In en, this message translates to:
  /// **'Date: Oldest to Newest'**
  String get sortDateOldestToNewest;

  /// No description provided for @sortScoreHighestToLowest.
  ///
  /// In en, this message translates to:
  /// **'Score: Highest to Lowest'**
  String get sortScoreHighestToLowest;

  /// No description provided for @sortScoreLowestToHighest.
  ///
  /// In en, this message translates to:
  /// **'Score: Lowest to Highest'**
  String get sortScoreLowestToHighest;

  /// No description provided for @overallMasteryLevelLabel.
  ///
  /// In en, this message translates to:
  /// **'Overall Mastery Level'**
  String get overallMasteryLevelLabel;

  /// No description provided for @accuracyLabel.
  ///
  /// In en, this message translates to:
  /// **'Accuracy'**
  String get accuracyLabel;

  /// No description provided for @quizzesDoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Quizzes Done'**
  String get quizzesDoneLabel;

  /// No description provided for @timeSpentLabel.
  ///
  /// In en, this message translates to:
  /// **'Time Spent'**
  String get timeSpentLabel;

  /// No description provided for @skillsProgressTitle.
  ///
  /// In en, this message translates to:
  /// **'Skills Progress'**
  String get skillsProgressTitle;

  /// No description provided for @seeAllLabel.
  ///
  /// In en, this message translates to:
  /// **'See All'**
  String get seeAllLabel;

  /// No description provided for @quizHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Quiz History'**
  String get quizHistoryTitle;

  /// No description provided for @sortSkillsTitle.
  ///
  /// In en, this message translates to:
  /// **'Sort Skills'**
  String get sortSkillsTitle;

  /// No description provided for @sortMasteryLowestFirst.
  ///
  /// In en, this message translates to:
  /// **'Mastery: Lowest First'**
  String get sortMasteryLowestFirst;

  /// No description provided for @sortMasteryHighestFirst.
  ///
  /// In en, this message translates to:
  /// **'Mastery: Highest First'**
  String get sortMasteryHighestFirst;

  /// No description provided for @sortAZLabel.
  ///
  /// In en, this message translates to:
  /// **'A – Z'**
  String get sortAZLabel;

  /// No description provided for @recommendationNotStarted.
  ///
  /// In en, this message translates to:
  /// **'Not started yet — encourage trying this skill'**
  String get recommendationNotStarted;

  /// No description provided for @recommendationUrgent.
  ///
  /// In en, this message translates to:
  /// **'Needs urgent attention — short daily practice sessions recommended'**
  String get recommendationUrgent;

  /// No description provided for @recommendationProgress.
  ///
  /// In en, this message translates to:
  /// **'Making progress — reviewing past mistakes will help'**
  String get recommendationProgress;

  /// No description provided for @recommendationOnTrack.
  ///
  /// In en, this message translates to:
  /// **'On track — a few more sessions will build mastery'**
  String get recommendationOnTrack;

  /// No description provided for @recommendationStrong.
  ///
  /// In en, this message translates to:
  /// **'Strong skill — occasional review to maintain'**
  String get recommendationStrong;

  /// No description provided for @statTotalLabel.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get statTotalLabel;

  /// No description provided for @allSkillsTitle.
  ///
  /// In en, this message translates to:
  /// **'All Skills'**
  String get allSkillsTitle;

  /// No description provided for @correctOfAttemptsLabel.
  ///
  /// In en, this message translates to:
  /// **'{correct} correct / {attempts} attempts'**
  String correctOfAttemptsLabel(int correct, int attempts);

  /// No description provided for @neverPracticedLabel.
  ///
  /// In en, this message translates to:
  /// **'Never practiced'**
  String get neverPracticedLabel;

  /// No description provided for @lastPracticedLabel.
  ///
  /// In en, this message translates to:
  /// **'Last: {date}'**
  String lastPracticedLabel(String date);

  /// No description provided for @uploadCurriculumTitle.
  ///
  /// In en, this message translates to:
  /// **'Upload Curriculum'**
  String get uploadCurriculumTitle;

  /// No description provided for @noSubjectsYetTitle.
  ///
  /// In en, this message translates to:
  /// **'No Subjects Yet'**
  String get noSubjectsYetTitle;

  /// No description provided for @noSubjectsYetDescription.
  ///
  /// In en, this message translates to:
  /// **'Tap the \'+\' button in the top right to start tracking subjects or upload a new curriculum for {studentName}.'**
  String noSubjectsYetDescription(String studentName);

  /// No description provided for @subjectsAndSkillsTitle.
  ///
  /// In en, this message translates to:
  /// **'Subjects & Skills'**
  String get subjectsAndSkillsTitle;

  /// No description provided for @skillsTrackedLabel.
  ///
  /// In en, this message translates to:
  /// **'{count} skills tracked'**
  String skillsTrackedLabel(int count);

  /// No description provided for @masteryLabel.
  ///
  /// In en, this message translates to:
  /// **'Mastery'**
  String get masteryLabel;

  /// No description provided for @removeSubjectConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove {subjectName}?'**
  String removeSubjectConfirmTitle(String subjectName);

  /// No description provided for @removeSubjectConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove this subject?'**
  String get removeSubjectConfirmMessage;

  /// No description provided for @searchSubjectsHint.
  ///
  /// In en, this message translates to:
  /// **'Search subjects...'**
  String get searchSubjectsHint;

  /// No description provided for @addSelectedCountButton.
  ///
  /// In en, this message translates to:
  /// **'Add Selected ({count})'**
  String addSelectedCountButton(int count);

  /// No description provided for @noQuizzesYetMessage.
  ///
  /// In en, this message translates to:
  /// **'No quizzes yet'**
  String get noQuizzesYetMessage;

  /// No description provided for @allQuizzesTitle.
  ///
  /// In en, this message translates to:
  /// **'All Quizzes'**
  String get allQuizzesTitle;

  /// No description provided for @tabOverview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get tabOverview;

  /// No description provided for @tabMastery.
  ///
  /// In en, this message translates to:
  /// **'Mastery'**
  String get tabMastery;

  /// No description provided for @tabHabits.
  ///
  /// In en, this message translates to:
  /// **'Habits'**
  String get tabHabits;

  /// No description provided for @reportsAnalysisTitle.
  ///
  /// In en, this message translates to:
  /// **'Reports & Analysis'**
  String get reportsAnalysisTitle;

  /// No description provided for @noReportAvailableMessage.
  ///
  /// In en, this message translates to:
  /// **'No report available.'**
  String get noReportAvailableMessage;

  /// No description provided for @metricQuizzesLabel.
  ///
  /// In en, this message translates to:
  /// **'Quizzes'**
  String get metricQuizzesLabel;

  /// No description provided for @studyTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Study Time'**
  String get studyTimeLabel;

  /// No description provided for @accuracyTrendTitle.
  ///
  /// In en, this message translates to:
  /// **'Accuracy Trend'**
  String get accuracyTrendTitle;

  /// No description provided for @weeklyAccuracyTrendSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Weekly accuracy over the past 6 weeks'**
  String get weeklyAccuracyTrendSubtitle;

  /// No description provided for @notEnoughDataYetMessage.
  ///
  /// In en, this message translates to:
  /// **'Not enough data yet'**
  String get notEnoughDataYetMessage;

  /// No description provided for @completeQuizzesTrendHint.
  ///
  /// In en, this message translates to:
  /// **'Complete quizzes over multiple weeks to see a trend'**
  String get completeQuizzesTrendHint;

  /// No description provided for @streakProgressTitle.
  ///
  /// In en, this message translates to:
  /// **'Streak Progress'**
  String get streakProgressTitle;

  /// No description provided for @currentStreakVsBestSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Current streak vs. personal best'**
  String get currentStreakVsBestSubtitle;

  /// No description provided for @currentStreakLabel.
  ///
  /// In en, this message translates to:
  /// **'Current streak'**
  String get currentStreakLabel;

  /// No description provided for @personalBestLabel.
  ///
  /// In en, this message translates to:
  /// **'Personal best'**
  String get personalBestLabel;

  /// No description provided for @daysUnitLabel.
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get daysUnitLabel;

  /// No description provided for @percentOfPersonalBest.
  ///
  /// In en, this message translates to:
  /// **'{percent}% of personal best'**
  String percentOfPersonalBest(int percent);

  /// No description provided for @noStreakYetMessage.
  ///
  /// In en, this message translates to:
  /// **'No streak yet — start studying to build one!'**
  String get noStreakYetMessage;

  /// No description provided for @smartInsightsTitle.
  ///
  /// In en, this message translates to:
  /// **'Smart Insights'**
  String get smartInsightsTitle;

  /// No description provided for @insightNoQuizzes.
  ///
  /// In en, this message translates to:
  /// **'No quizzes completed this week yet. Encourage your student to log in and start a session to keep their streak alive!'**
  String get insightNoQuizzes;

  /// No description provided for @insightOutstanding.
  ///
  /// In en, this message translates to:
  /// **'{quizzes} quizzes completed this week with {accuracy}% accuracy — an outstanding performance! The student is mastering the material at a high level. Keep the momentum going.'**
  String insightOutstanding(int quizzes, int accuracy);

  /// No description provided for @insightGoodWeek.
  ///
  /// In en, this message translates to:
  /// **'Good week overall: {quizzes} quizzes at {accuracy}% accuracy. To push higher, visit the Mastery tab and focus on skills rated below 60%.'**
  String insightGoodWeek(int quizzes, int accuracy);

  /// No description provided for @insightRoomToImprove.
  ///
  /// In en, this message translates to:
  /// **'{quizzes} quizzes completed with {accuracy}% accuracy. There is room to improve — check the Mastery tab to identify specific concept gaps that need attention.'**
  String insightRoomToImprove(int quizzes, int accuracy);

  /// No description provided for @insightStreakKept.
  ///
  /// In en, this message translates to:
  /// **'The student has kept a {streak}-day streak, which is great for consistency! Accuracy is at {accuracy}% — reviewing weaker topics between sessions should help raise scores.'**
  String insightStreakKept(int streak, int accuracy);

  /// No description provided for @insightDefault.
  ///
  /// In en, this message translates to:
  /// **'Accuracy was {accuracy}% across {quizzes} quizzes this week. Encourage shorter, more focused study sessions and review any topics marked as weak in the Mastery tab.'**
  String insightDefault(int accuracy, int quizzes);

  /// No description provided for @noMasteryReportMessage.
  ///
  /// In en, this message translates to:
  /// **'No mastery report available.'**
  String get noMasteryReportMessage;

  /// No description provided for @totalAverageMasteryLabel.
  ///
  /// In en, this message translates to:
  /// **'Total Average Mastery'**
  String get totalAverageMasteryLabel;

  /// No description provided for @masteryScorePercentLabel.
  ///
  /// In en, this message translates to:
  /// **'{percent}% Mastery Score'**
  String masteryScorePercentLabel(String percent);

  /// No description provided for @masteredLabel.
  ///
  /// In en, this message translates to:
  /// **'Mastered'**
  String get masteredLabel;

  /// No description provided for @strongAreasTitle.
  ///
  /// In en, this message translates to:
  /// **'🔥 Strong Areas'**
  String get strongAreasTitle;

  /// No description provided for @noStrongAreasMessage.
  ///
  /// In en, this message translates to:
  /// **'No strong areas identified yet.'**
  String get noStrongAreasMessage;

  /// No description provided for @needsWorkAreasTitle.
  ///
  /// In en, this message translates to:
  /// **'⚠️ Needs Work'**
  String get needsWorkAreasTitle;

  /// No description provided for @noWeakAreasMessage.
  ///
  /// In en, this message translates to:
  /// **'No weak areas identified yet.'**
  String get noWeakAreasMessage;

  /// No description provided for @errorAnalyticsTitle.
  ///
  /// In en, this message translates to:
  /// **'Error Analytics'**
  String get errorAnalyticsTitle;

  /// No description provided for @commonMistakeTypesLabel.
  ///
  /// In en, this message translates to:
  /// **'Common mistake types on {subject} quizzes.'**
  String commonMistakeTypesLabel(String subject);

  /// No description provided for @carelessMistakesLabel.
  ///
  /// In en, this message translates to:
  /// **'Careless Mistakes ({percent}%)'**
  String carelessMistakesLabel(int percent);

  /// No description provided for @carelessMistakesDescription.
  ///
  /// In en, this message translates to:
  /// **'Answering too quickly on calculations'**
  String get carelessMistakesDescription;

  /// No description provided for @conceptGapsLabel.
  ///
  /// In en, this message translates to:
  /// **'Concept Gaps ({percent}%)'**
  String conceptGapsLabel(int percent);

  /// No description provided for @conceptGapsDescription.
  ///
  /// In en, this message translates to:
  /// **'Struggles with newly introduced topics'**
  String get conceptGapsDescription;

  /// No description provided for @timePressureLabel.
  ///
  /// In en, this message translates to:
  /// **'Time Pressure ({percent}%)'**
  String timePressureLabel(int percent);

  /// No description provided for @timePressureDescription.
  ///
  /// In en, this message translates to:
  /// **'Failing to finish within the quiz timer'**
  String get timePressureDescription;

  /// No description provided for @noHabitsReportMessage.
  ///
  /// In en, this message translates to:
  /// **'No habits report available.'**
  String get noHabitsReportMessage;

  /// No description provided for @currentStreakStatLabel.
  ///
  /// In en, this message translates to:
  /// **'Current Streak'**
  String get currentStreakStatLabel;

  /// No description provided for @longestStreakStatLabel.
  ///
  /// In en, this message translates to:
  /// **'Longest Streak'**
  String get longestStreakStatLabel;

  /// No description provided for @daysCountLabel.
  ///
  /// In en, this message translates to:
  /// **'{count} Days'**
  String daysCountLabel(int count);

  /// No description provided for @studyVsAppUsageTitle.
  ///
  /// In en, this message translates to:
  /// **'Study vs Monitored App Usage'**
  String get studyVsAppUsageTitle;

  /// No description provided for @studyVsAppUsageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Compare active learning time vs time blocked on other apps.'**
  String get studyVsAppUsageSubtitle;

  /// No description provided for @appUsageLegendLabel.
  ///
  /// In en, this message translates to:
  /// **'App Usage'**
  String get appUsageLegendLabel;

  /// No description provided for @studyConsistencyGridTitle.
  ///
  /// In en, this message translates to:
  /// **'Study Consistency Grid'**
  String get studyConsistencyGridTitle;

  /// No description provided for @activeStudyDaysSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Active study days over the last 4 weeks.'**
  String get activeStudyDaysSubtitle;

  /// No description provided for @threeWeeksAgoLabel.
  ///
  /// In en, this message translates to:
  /// **'3w ago'**
  String get threeWeeksAgoLabel;

  /// No description provided for @twoWeeksAgoLabel.
  ///
  /// In en, this message translates to:
  /// **'2w ago'**
  String get twoWeeksAgoLabel;

  /// No description provided for @oneWeekAgoLabel.
  ///
  /// In en, this message translates to:
  /// **'1w ago'**
  String get oneWeekAgoLabel;

  /// No description provided for @thisWeekLabel.
  ///
  /// In en, this message translates to:
  /// **'This wk'**
  String get thisWeekLabel;

  /// No description provided for @dayAbbrevMon.
  ///
  /// In en, this message translates to:
  /// **'M'**
  String get dayAbbrevMon;

  /// No description provided for @dayAbbrevTue.
  ///
  /// In en, this message translates to:
  /// **'T'**
  String get dayAbbrevTue;

  /// No description provided for @dayAbbrevWed.
  ///
  /// In en, this message translates to:
  /// **'W'**
  String get dayAbbrevWed;

  /// No description provided for @dayAbbrevThu.
  ///
  /// In en, this message translates to:
  /// **'T'**
  String get dayAbbrevThu;

  /// No description provided for @dayAbbrevFri.
  ///
  /// In en, this message translates to:
  /// **'F'**
  String get dayAbbrevFri;

  /// No description provided for @dayAbbrevSat.
  ///
  /// In en, this message translates to:
  /// **'S'**
  String get dayAbbrevSat;

  /// No description provided for @dayAbbrevSun.
  ///
  /// In en, this message translates to:
  /// **'S'**
  String get dayAbbrevSun;

  /// No description provided for @legendLessLabel.
  ///
  /// In en, this message translates to:
  /// **'Less'**
  String get legendLessLabel;

  /// No description provided for @legendMoreLabel.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get legendMoreLabel;

  /// No description provided for @studentProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'{name}\'s Profile'**
  String studentProfileTitle(String name);

  /// No description provided for @gradeUnknownLabel.
  ///
  /// In en, this message translates to:
  /// **'Grade —'**
  String get gradeUnknownLabel;

  /// No description provided for @thisWeekSublabel.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get thisWeekSublabel;

  /// No description provided for @weeklyAvgSublabel.
  ///
  /// In en, this message translates to:
  /// **'Weekly avg'**
  String get weeklyAvgSublabel;

  /// No description provided for @dayStreakLabel.
  ///
  /// In en, this message translates to:
  /// **'Day Streak'**
  String get dayStreakLabel;

  /// No description provided for @currentLabel.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get currentLabel;

  /// No description provided for @manageSubjectsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage subjects and view skill progress'**
  String get manageSubjectsSubtitle;

  /// No description provided for @reportsAnalyticsNavTitle.
  ///
  /// In en, this message translates to:
  /// **'Reports & Analytics'**
  String get reportsAnalyticsNavTitle;

  /// No description provided for @weeklyReportsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Weekly reports, accuracy trends, weak topics'**
  String get weeklyReportsSubtitle;

  /// No description provided for @appConfigurationsTitle.
  ///
  /// In en, this message translates to:
  /// **'App Configurations'**
  String get appConfigurationsTitle;

  /// No description provided for @appConfigurationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Gateway timers, monitored apps, quiz rules'**
  String get appConfigurationsSubtitle;

  /// No description provided for @permissionDisplayNameSystemAlertWindow.
  ///
  /// In en, this message translates to:
  /// **'Display Over Other Apps'**
  String get permissionDisplayNameSystemAlertWindow;

  /// No description provided for @permissionDisplayNamePackageUsageStats.
  ///
  /// In en, this message translates to:
  /// **'Usage Access'**
  String get permissionDisplayNamePackageUsageStats;

  /// No description provided for @permissionDisplayNamePostNotifications.
  ///
  /// In en, this message translates to:
  /// **'Post Notifications'**
  String get permissionDisplayNamePostNotifications;

  /// No description provided for @permissionDisplayNameAccessibilityService.
  ///
  /// In en, this message translates to:
  /// **'Accessibility Service'**
  String get permissionDisplayNameAccessibilityService;

  /// No description provided for @permissionDisplayNameDeviceAdmin.
  ///
  /// In en, this message translates to:
  /// **'Device Administrator'**
  String get permissionDisplayNameDeviceAdmin;

  /// No description provided for @permissionDisplayNameBatteryOptimization.
  ///
  /// In en, this message translates to:
  /// **'Disable Battery Optimization'**
  String get permissionDisplayNameBatteryOptimization;

  /// No description provided for @permissionRationaleSystemAlertWindow.
  ///
  /// In en, this message translates to:
  /// **'Display Over Other Apps is required to show study reminders and enforce app rules while you use other apps.'**
  String get permissionRationaleSystemAlertWindow;

  /// No description provided for @permissionRationalePackageUsageStats.
  ///
  /// In en, this message translates to:
  /// **'Usage Access is required to track screen time and enforce the app usage limits set by the parent.'**
  String get permissionRationalePackageUsageStats;

  /// No description provided for @permissionRationalePostNotifications.
  ///
  /// In en, this message translates to:
  /// **'Post Notifications is required to send you study reminders and important alerts from the parent.'**
  String get permissionRationalePostNotifications;

  /// No description provided for @permissionRationaleAccessibilityService.
  ///
  /// In en, this message translates to:
  /// **'Accessibility Service is required to monitor which apps are open and enforce the rules set by the parent.'**
  String get permissionRationaleAccessibilityService;

  /// No description provided for @permissionRationaleDeviceAdmin.
  ///
  /// In en, this message translates to:
  /// **'Device Administrator is required to protect the app from being uninstalled without the parent\'s permission.'**
  String get permissionRationaleDeviceAdmin;

  /// No description provided for @permissionRationaleBatteryOptimization.
  ///
  /// In en, this message translates to:
  /// **'Disabling Battery Optimization keeps background services running reliably. Without this, Android may shut down StudyMentor\'s background services on some devices, causing timers and app rules to stop working.'**
  String get permissionRationaleBatteryOptimization;

  /// No description provided for @permissionParentRationalePostNotifications.
  ///
  /// In en, this message translates to:
  /// **'StudyMentor notifies you when your child levels up, earns a badge, or hasn\'t studied in a few days. You can change this any time in Settings.'**
  String get permissionParentRationalePostNotifications;

  /// No description provided for @permissionParentRationaleBatteryOptimization.
  ///
  /// In en, this message translates to:
  /// **'To reliably notify you about your child\'s activity, StudyMentor needs to run in the background. Without this, Android may delay or drop important alerts on some devices.'**
  String get permissionParentRationaleBatteryOptimization;

  /// No description provided for @stepOfTotalLabel.
  ///
  /// In en, this message translates to:
  /// **'Step {step} of {total}'**
  String stepOfTotalLabel(int step, int total);

  /// No description provided for @permissionEnabledMessage.
  ///
  /// In en, this message translates to:
  /// **'{permissionName} has been enabled.'**
  String permissionEnabledMessage(String permissionName);

  /// No description provided for @permissionNotGrantedMessage.
  ///
  /// In en, this message translates to:
  /// **'Permission not granted yet. Tap the button below to open Settings.'**
  String get permissionNotGrantedMessage;

  /// No description provided for @openSettingsButton.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get openSettingsButton;

  /// No description provided for @postNotificationsHint.
  ///
  /// In en, this message translates to:
  /// **'Allow StudyMentor to send you notifications.'**
  String get postNotificationsHint;

  /// No description provided for @batteryOptimizationHint.
  ///
  /// In en, this message translates to:
  /// **'Find \"StudyMentor\", select \"Don\'t optimize\" or \"Unrestricted\", then confirm.'**
  String get batteryOptimizationHint;

  /// No description provided for @systemAlertWindowHint.
  ///
  /// In en, this message translates to:
  /// **'Find \"StudyMentor\" and enable \"Allow display over other apps\".'**
  String get systemAlertWindowHint;

  /// No description provided for @packageUsageStatsHint.
  ///
  /// In en, this message translates to:
  /// **'Find \"StudyMentor\" and toggle Usage Access on.'**
  String get packageUsageStatsHint;

  /// No description provided for @accessibilityServiceHint.
  ///
  /// In en, this message translates to:
  /// **'Under Installed Apps, select \"StudyMentor\" and enable it.'**
  String get accessibilityServiceHint;

  /// No description provided for @deviceAdminHint.
  ///
  /// In en, this message translates to:
  /// **'Tap \"Activate this device admin app\" to confirm.'**
  String get deviceAdminHint;

  /// No description provided for @helpCenterTitle.
  ///
  /// In en, this message translates to:
  /// **'Help Center'**
  String get helpCenterTitle;

  /// No description provided for @whatCanWeHelpWithTitle.
  ///
  /// In en, this message translates to:
  /// **'What can we help with?'**
  String get whatCanWeHelpWithTitle;

  /// No description provided for @issueAppNotWorking.
  ///
  /// In en, this message translates to:
  /// **'App isn\'t working properly'**
  String get issueAppNotWorking;

  /// No description provided for @issueQuizQuestionError.
  ///
  /// In en, this message translates to:
  /// **'Quiz question has an error'**
  String get issueQuizQuestionError;

  /// No description provided for @issueHowDoI.
  ///
  /// In en, this message translates to:
  /// **'How do I...?'**
  String get issueHowDoI;

  /// No description provided for @tellUsMoreTitle.
  ///
  /// In en, this message translates to:
  /// **'Tell us more'**
  String get tellUsMoreTitle;

  /// No description provided for @needHelpGreeting.
  ///
  /// In en, this message translates to:
  /// **'Need help, {name}? I\'m here for you!'**
  String needHelpGreeting(String name);

  /// No description provided for @describeIssueHint.
  ///
  /// In en, this message translates to:
  /// **'Describe your issue here... Our team will help you out!'**
  String get describeIssueHint;

  /// No description provided for @charCounterLabel.
  ///
  /// In en, this message translates to:
  /// **'{count}/500'**
  String charCounterLabel(int count);

  /// No description provided for @sendToTeamButton.
  ///
  /// In en, this message translates to:
  /// **'Send to Team'**
  String get sendToTeamButton;

  /// No description provided for @messageSentSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'Message sent! Our team will get back to you soon.'**
  String get messageSentSuccessMessage;

  /// No description provided for @messageSendErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t send your message. Please try again.'**
  String get messageSendErrorMessage;

  /// No description provided for @levelShortLabel.
  ///
  /// In en, this message translates to:
  /// **'Lv. {level}'**
  String levelShortLabel(int level);

  /// No description provided for @welcomeBackGreeting.
  ///
  /// In en, this message translates to:
  /// **'Welcome back, {name}! '**
  String welcomeBackGreeting(String name);

  /// No description provided for @gardenGrowingMessage.
  ///
  /// In en, this message translates to:
  /// **'Your garden is growing beautifully!'**
  String get gardenGrowingMessage;

  /// No description provided for @gardenLoadErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your garden. Pull down to retry.'**
  String get gardenLoadErrorMessage;

  /// No description provided for @askParentAddSubjectsMessage.
  ///
  /// In en, this message translates to:
  /// **'Ask a parent to add your subjects'**
  String get askParentAddSubjectsMessage;

  /// No description provided for @owlEncouragementMessage.
  ///
  /// In en, this message translates to:
  /// **'Great job today! Keep studying to help your garden bloom! 🌸'**
  String get owlEncouragementMessage;

  /// No description provided for @owlNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Hootie, your Study Buddy'**
  String get owlNameLabel;

  /// No description provided for @streakDaysCountLabel.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day} other{{count} days}}'**
  String streakDaysCountLabel(int count);

  /// No description provided for @lessonsLabel.
  ///
  /// In en, this message translates to:
  /// **'Lessons'**
  String get lessonsLabel;

  /// No description provided for @streakLabel.
  ///
  /// In en, this message translates to:
  /// **'Streak'**
  String get streakLabel;

  /// No description provided for @yourParentLabel.
  ///
  /// In en, this message translates to:
  /// **'Your parent'**
  String get yourParentLabel;

  /// No description provided for @rulesConfiguredByParentMessage.
  ///
  /// In en, this message translates to:
  /// **'Rules configured by your parent.'**
  String get rulesConfiguredByParentMessage;

  /// No description provided for @screenTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Screen Time'**
  String get screenTimeLabel;

  /// No description provided for @timeRemainingLabel.
  ///
  /// In en, this message translates to:
  /// **'{time} left'**
  String timeRemainingLabel(String time);

  /// No description provided for @usedTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Used: {time}'**
  String usedTimeLabel(String time);

  /// No description provided for @limitTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Limit: {time}'**
  String limitTimeLabel(String time);

  /// No description provided for @cooldownAfterLimitLabel.
  ///
  /// In en, this message translates to:
  /// **'Cooldown after limit: {time}'**
  String cooldownAfterLimitLabel(String time);

  /// No description provided for @onCooldownTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'re on cooldown! 😴'**
  String get onCooldownTitle;

  /// No description provided for @cooldownMessage.
  ///
  /// In en, this message translates to:
  /// **'Apps will unlock again soon. Time to study! 📚'**
  String get cooldownMessage;

  /// No description provided for @remainingLabel.
  ///
  /// In en, this message translates to:
  /// **'remaining'**
  String get remainingLabel;

  /// No description provided for @parentRulesIntroMessage.
  ///
  /// In en, this message translates to:
  /// **'Your parent set these rules for all restricted apps:'**
  String get parentRulesIntroMessage;

  /// No description provided for @noAppRulesSetMessage.
  ///
  /// In en, this message translates to:
  /// **'No app rules set yet.'**
  String get noAppRulesSetMessage;

  /// No description provided for @noAppRulesDescriptionMessage.
  ///
  /// In en, this message translates to:
  /// **'Your parent hasn\'t configured any rules for your device yet.'**
  String get noAppRulesDescriptionMessage;

  /// No description provided for @backTooltip.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get backTooltip;

  /// No description provided for @levelLabel.
  ///
  /// In en, this message translates to:
  /// **'Level {level}'**
  String levelLabel(int level);

  /// No description provided for @myProgressTitle.
  ///
  /// In en, this message translates to:
  /// **'My Progress'**
  String get myProgressTitle;

  /// No description provided for @totalXpLabel.
  ///
  /// In en, this message translates to:
  /// **'Total XP'**
  String get totalXpLabel;

  /// No description provided for @questionsLabel.
  ///
  /// In en, this message translates to:
  /// **'Questions'**
  String get questionsLabel;

  /// No description provided for @coinsAvailableLabel.
  ///
  /// In en, this message translates to:
  /// **'coins available'**
  String get coinsAvailableLabel;

  /// No description provided for @appSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'App Settings'**
  String get appSettingsTitle;

  /// No description provided for @appSettingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications, Sound'**
  String get appSettingsSubtitle;

  /// No description provided for @selectPdfFirstMessage.
  ///
  /// In en, this message translates to:
  /// **'Please select a PDF file first.'**
  String get selectPdfFirstMessage;

  /// No description provided for @enterSubjectNameMessage.
  ///
  /// In en, this message translates to:
  /// **'Please enter a Subject Name.'**
  String get enterSubjectNameMessage;

  /// No description provided for @subjectAlreadyExistsMessage.
  ///
  /// In en, this message translates to:
  /// **'This subject already exists.'**
  String get subjectAlreadyExistsMessage;

  /// No description provided for @uploadingProcessingMessage.
  ///
  /// In en, this message translates to:
  /// **'Uploading & processing…'**
  String get uploadingProcessingMessage;

  /// No description provided for @uploadCurriculumDescription.
  ///
  /// In en, this message translates to:
  /// **'Upload a PDF textbook to build an adaptive quiz from its content.'**
  String get uploadCurriculumDescription;

  /// No description provided for @subjectNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Subject Name'**
  String get subjectNameLabel;

  /// No description provided for @subjectNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Mathematics, Science...'**
  String get subjectNameHint;

  /// No description provided for @removeFileButton.
  ///
  /// In en, this message translates to:
  /// **'Remove File'**
  String get removeFileButton;

  /// No description provided for @tapToBrowsePdfMessage.
  ///
  /// In en, this message translates to:
  /// **'Tap to browse PDF'**
  String get tapToBrowsePdfMessage;

  /// No description provided for @onlyPdfSupportedMessage.
  ///
  /// In en, this message translates to:
  /// **'Only .pdf files are supported'**
  String get onlyPdfSupportedMessage;

  /// No description provided for @uploadAndIngestButton.
  ///
  /// In en, this message translates to:
  /// **'Upload & Ingest'**
  String get uploadAndIngestButton;

  /// No description provided for @curriculumAddedSuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Curriculum Added Successfully!'**
  String get curriculumAddedSuccessTitle;

  /// No description provided for @curriculumAddedSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'We\'ve successfully added \'{subjectName}\' to your dashboard. The AI is now processing your textbook in the background to generate quiz questions.'**
  String curriculumAddedSuccessMessage(String subjectName);

  /// No description provided for @uploadAnotherButton.
  ///
  /// In en, this message translates to:
  /// **'Upload Another'**
  String get uploadAnotherButton;

  /// No description provided for @studyQuizTitle.
  ///
  /// In en, this message translates to:
  /// **'Study Quiz'**
  String get studyQuizTitle;

  /// No description provided for @masteryUpdateMessage.
  ///
  /// In en, this message translates to:
  /// **'{subject}: {oldPct}% → {newPct}% (+{delta}%)'**
  String masteryUpdateMessage(
    String subject,
    String oldPct,
    String newPct,
    String delta,
  );

  /// No description provided for @masteryUpdatedSimpleMessage.
  ///
  /// In en, this message translates to:
  /// **'{subject} mastery updated!'**
  String masteryUpdatedSimpleMessage(String subject);

  /// No description provided for @generatingQuizMessage.
  ///
  /// In en, this message translates to:
  /// **'Generating your quiz…'**
  String get generatingQuizMessage;

  /// No description provided for @submittingAnswersMessage.
  ///
  /// In en, this message translates to:
  /// **'Submitting answers…'**
  String get submittingAnswersMessage;

  /// No description provided for @timeToPracticeTitle.
  ///
  /// In en, this message translates to:
  /// **'Time to Practice!'**
  String get timeToPracticeTitle;

  /// No description provided for @quizPromptMessage.
  ///
  /// In en, this message translates to:
  /// **'Your focus time is up. Let\'s do a quick quiz to keep your brain sharp!'**
  String get quizPromptMessage;

  /// No description provided for @startQuizButton.
  ///
  /// In en, this message translates to:
  /// **'Start Quiz'**
  String get startQuizButton;

  /// No description provided for @tailoredToLevelMessage.
  ///
  /// In en, this message translates to:
  /// **'Tailored to your current level'**
  String get tailoredToLevelMessage;

  /// No description provided for @selectAnswerFirstMessage.
  ///
  /// In en, this message translates to:
  /// **'Please select an answer first.'**
  String get selectAnswerFirstMessage;

  /// No description provided for @noMoreHintsMessage.
  ///
  /// In en, this message translates to:
  /// **'No more hints available.'**
  String get noMoreHintsMessage;

  /// No description provided for @hintNumberTitle.
  ///
  /// In en, this message translates to:
  /// **'Hint {number}'**
  String hintNumberTitle(int number);

  /// No description provided for @questionOfTotalLabel.
  ///
  /// In en, this message translates to:
  /// **'Question {current} of {total}'**
  String questionOfTotalLabel(int current, int total);

  /// No description provided for @answeredCountLabel.
  ///
  /// In en, this message translates to:
  /// **'{count} answered'**
  String answeredCountLabel(int count);

  /// No description provided for @hintCountLabel.
  ///
  /// In en, this message translates to:
  /// **'Hint ({count})'**
  String hintCountLabel(int count);

  /// No description provided for @submitButton.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submitButton;

  /// No description provided for @nextButton.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get nextButton;

  /// No description provided for @veryEasyLabel.
  ///
  /// In en, this message translates to:
  /// **'Very Easy'**
  String get veryEasyLabel;

  /// No description provided for @easyLabel.
  ///
  /// In en, this message translates to:
  /// **'Easy'**
  String get easyLabel;

  /// No description provided for @mediumLabel.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get mediumLabel;

  /// No description provided for @hardLabel.
  ///
  /// In en, this message translates to:
  /// **'Hard'**
  String get hardLabel;

  /// No description provided for @veryHardLabel.
  ///
  /// In en, this message translates to:
  /// **'Very Hard'**
  String get veryHardLabel;

  /// No description provided for @questionsCountLabel.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 question} other{{count} questions}}'**
  String questionsCountLabel(int count);

  /// No description provided for @doneButton.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get doneButton;

  /// No description provided for @takeAnotherQuizButton.
  ///
  /// In en, this message translates to:
  /// **'Take Another Quiz'**
  String get takeAnotherQuizButton;

  /// No description provided for @somethingWentWrongTitle.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get somethingWentWrongTitle;

  /// No description provided for @tryAgainButton.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get tryAgainButton;

  /// No description provided for @subjectGardenTitle.
  ///
  /// In en, this message translates to:
  /// **'{subject} Garden'**
  String subjectGardenTitle(String subject);

  /// No description provided for @loadSkillsErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load skills. Please go back and try again.'**
  String get loadSkillsErrorMessage;

  /// No description provided for @overallMasteryLabel.
  ///
  /// In en, this message translates to:
  /// **'Overall mastery: {percent}%'**
  String overallMasteryLabel(String percent);

  /// No description provided for @skillsTitle.
  ///
  /// In en, this message translates to:
  /// **'Skills'**
  String get skillsTitle;

  /// No description provided for @strengthsTitle.
  ///
  /// In en, this message translates to:
  /// **'Strengths'**
  String get strengthsTitle;

  /// No description provided for @needsPracticeTitle.
  ///
  /// In en, this message translates to:
  /// **'Needs Practice'**
  String get needsPracticeTitle;

  /// No description provided for @practiceNowButton.
  ///
  /// In en, this message translates to:
  /// **'Practice Now'**
  String get practiceNowButton;

  /// No description provided for @growthProgressTitle.
  ///
  /// In en, this message translates to:
  /// **'Growth Progress'**
  String get growthProgressTitle;

  /// No description provided for @levelNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Level {level}'**
  String levelNumberLabel(int level);

  /// No description provided for @maxLevelBadge.
  ///
  /// In en, this message translates to:
  /// **'MAX ✨'**
  String get maxLevelBadge;

  /// No description provided for @maxLevelReachedMessage.
  ///
  /// In en, this message translates to:
  /// **'You\'ve reached the maximum level! 🌟'**
  String get maxLevelReachedMessage;

  /// No description provided for @percentMoreToLevelMessage.
  ///
  /// In en, this message translates to:
  /// **'{percent}% more to reach Level {level}!'**
  String percentMoreToLevelMessage(String percent, int level);

  /// No description provided for @flourishingLabel.
  ///
  /// In en, this message translates to:
  /// **'Flourishing'**
  String get flourishingLabel;

  /// No description provided for @masteryGrowingWellLabel.
  ///
  /// In en, this message translates to:
  /// **'Growing Well'**
  String get masteryGrowingWellLabel;

  /// No description provided for @masteryMakingProgressLabel.
  ///
  /// In en, this message translates to:
  /// **'Making Progress'**
  String get masteryMakingProgressLabel;

  /// No description provided for @masteryJustStartedLabel.
  ///
  /// In en, this message translates to:
  /// **'Just Started'**
  String get masteryJustStartedLabel;

  /// No description provided for @masteryNotStartedYetLabel.
  ///
  /// In en, this message translates to:
  /// **'Not Started Yet'**
  String get masteryNotStartedYetLabel;

  /// No description provided for @growthStageSeed.
  ///
  /// In en, this message translates to:
  /// **'Seed'**
  String get growthStageSeed;

  /// No description provided for @growthStageSprout.
  ///
  /// In en, this message translates to:
  /// **'Sprout'**
  String get growthStageSprout;

  /// No description provided for @growthStageSapling.
  ///
  /// In en, this message translates to:
  /// **'Sapling'**
  String get growthStageSapling;

  /// No description provided for @growthStageGrowing.
  ///
  /// In en, this message translates to:
  /// **'Growing'**
  String get growthStageGrowing;

  /// No description provided for @masteryAttemptsLabel.
  ///
  /// In en, this message translates to:
  /// **'{percent}% mastery  ·  {attempts} attempts'**
  String masteryAttemptsLabel(String percent, int attempts);

  /// No description provided for @skillNotStartedLabel.
  ///
  /// In en, this message translates to:
  /// **'Not started yet'**
  String get skillNotStartedLabel;

  /// No description provided for @avatarShopTitle.
  ///
  /// In en, this message translates to:
  /// **'Avatar Shop'**
  String get avatarShopTitle;

  /// No description provided for @categoryHairStyle.
  ///
  /// In en, this message translates to:
  /// **'Hair Style'**
  String get categoryHairStyle;

  /// No description provided for @categoryOutfit.
  ///
  /// In en, this message translates to:
  /// **'Outfit'**
  String get categoryOutfit;

  /// No description provided for @categoryHairColor.
  ///
  /// In en, this message translates to:
  /// **'Hair Color'**
  String get categoryHairColor;

  /// No description provided for @categoryOutfitColor.
  ///
  /// In en, this message translates to:
  /// **'Outfit Color'**
  String get categoryOutfitColor;

  /// No description provided for @categoryAccessory.
  ///
  /// In en, this message translates to:
  /// **'Accessory'**
  String get categoryAccessory;

  /// No description provided for @categoryFacialHair.
  ///
  /// In en, this message translates to:
  /// **'Facial Hair'**
  String get categoryFacialHair;

  /// No description provided for @categoryBeardColor.
  ///
  /// In en, this message translates to:
  /// **'Beard Color'**
  String get categoryBeardColor;

  /// No description provided for @categoryEyes.
  ///
  /// In en, this message translates to:
  /// **'Eyes'**
  String get categoryEyes;

  /// No description provided for @categoryEyebrows.
  ///
  /// In en, this message translates to:
  /// **'Eyebrows'**
  String get categoryEyebrows;

  /// No description provided for @categoryMouth.
  ///
  /// In en, this message translates to:
  /// **'Mouth'**
  String get categoryMouth;

  /// No description provided for @categorySkinTone.
  ///
  /// In en, this message translates to:
  /// **'Skin Tone'**
  String get categorySkinTone;

  /// No description provided for @unlocksAtLevelMessage.
  ///
  /// In en, this message translates to:
  /// **'Unlocks at Level {level}'**
  String unlocksAtLevelMessage(int level);

  /// No description provided for @notEnoughCoinsMessage.
  ///
  /// In en, this message translates to:
  /// **'Not enough coins! Need {amount} more.'**
  String notEnoughCoinsMessage(int amount);

  /// No description provided for @buyItemTitle.
  ///
  /// In en, this message translates to:
  /// **'Buy {itemName}?'**
  String buyItemTitle(String itemName);

  /// No description provided for @itemCostMessage.
  ///
  /// In en, this message translates to:
  /// **'This will cost {price} coins.'**
  String itemCostMessage(int price);

  /// No description provided for @buyButton.
  ///
  /// In en, this message translates to:
  /// **'Buy'**
  String get buyButton;

  /// No description provided for @levelUpTitle.
  ///
  /// In en, this message translates to:
  /// **'🎉 Level Up!'**
  String get levelUpTitle;

  /// No description provided for @levelUpSubtitleMessage.
  ///
  /// In en, this message translates to:
  /// **'You reached Level {level}! Keep studying to\ngrow even stronger! 🌱'**
  String levelUpSubtitleMessage(int level);

  /// No description provided for @awesomeButton.
  ///
  /// In en, this message translates to:
  /// **'Awesome!'**
  String get awesomeButton;

  /// No description provided for @streakMilestoneOnARoll.
  ///
  /// In en, this message translates to:
  /// **'On a Roll!'**
  String get streakMilestoneOnARoll;

  /// No description provided for @streakMilestoneWeekWarrior.
  ///
  /// In en, this message translates to:
  /// **'Week Warrior!'**
  String get streakMilestoneWeekWarrior;

  /// No description provided for @streakMilestoneFortnightFocus.
  ///
  /// In en, this message translates to:
  /// **'Fortnight Focus!'**
  String get streakMilestoneFortnightFocus;

  /// No description provided for @streakMilestoneMonthlyMaster.
  ///
  /// In en, this message translates to:
  /// **'Monthly Master!'**
  String get streakMilestoneMonthlyMaster;

  /// No description provided for @streakMilestoneGeneric.
  ///
  /// In en, this message translates to:
  /// **'Streak Milestone!'**
  String get streakMilestoneGeneric;

  /// No description provided for @streakMilestoneDescriptionMessage.
  ///
  /// In en, this message translates to:
  /// **'You hit a {days}-day learning streak!\nKeep it up!'**
  String streakMilestoneDescriptionMessage(int days);

  /// No description provided for @coinsRewardLabel.
  ///
  /// In en, this message translates to:
  /// **'+{coins} Coins'**
  String coinsRewardLabel(int coins);

  /// No description provided for @aiSummaryNotAvailableMessage.
  ///
  /// In en, this message translates to:
  /// **'AI Summary not available.'**
  String get aiSummaryNotAvailableMessage;

  /// No description provided for @aiDailySummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'✨ AI Daily Summary'**
  String get aiDailySummaryTitle;

  /// No description provided for @smartInsightsLabel.
  ///
  /// In en, this message translates to:
  /// **'Smart Insights'**
  String get smartInsightsLabel;

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @markAllAsReadButton.
  ///
  /// In en, this message translates to:
  /// **'Mark all as read'**
  String get markAllAsReadButton;

  /// No description provided for @allCaughtUpTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'re All Caught Up'**
  String get allCaughtUpTitle;

  /// No description provided for @allCaughtUpMessage.
  ///
  /// In en, this message translates to:
  /// **'You\'re all caught up! Activity alerts will appear here.'**
  String get allCaughtUpMessage;

  /// No description provided for @minutesAgoLabel.
  ///
  /// In en, this message translates to:
  /// **'{minutes}m ago'**
  String minutesAgoLabel(int minutes);

  /// No description provided for @hoursAgoLabel.
  ///
  /// In en, this message translates to:
  /// **'{hours}h ago'**
  String hoursAgoLabel(int hours);

  /// No description provided for @daysAgoLabel.
  ///
  /// In en, this message translates to:
  /// **'{days}d ago'**
  String daysAgoLabel(int days);

  /// No description provided for @xpLabel.
  ///
  /// In en, this message translates to:
  /// **'XP'**
  String get xpLabel;

  /// No description provided for @coinsLabel.
  ///
  /// In en, this message translates to:
  /// **'Coins'**
  String get coinsLabel;

  /// No description provided for @unverifiedLabel.
  ///
  /// In en, this message translates to:
  /// **'UNVERIFIED'**
  String get unverifiedLabel;

  /// No description provided for @waitingForVerificationMessage.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the student to verify their email and log in for the first time.'**
  String get waitingForVerificationMessage;

  /// No description provided for @firstLoginCoinsRewardMessage.
  ///
  /// In en, this message translates to:
  /// **'+3 coins will be awarded on first login'**
  String get firstLoginCoinsRewardMessage;

  /// No description provided for @weeklyAccuracyLabel.
  ///
  /// In en, this message translates to:
  /// **'Weekly Accuracy'**
  String get weeklyAccuracyLabel;

  /// No description provided for @navMyStudentsLabel.
  ///
  /// In en, this message translates to:
  /// **'My Students'**
  String get navMyStudentsLabel;

  /// No description provided for @navHelpLabel.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get navHelpLabel;

  /// No description provided for @navHomeLabel.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHomeLabel;

  /// No description provided for @navShopLabel.
  ///
  /// In en, this message translates to:
  /// **'Shop'**
  String get navShopLabel;

  /// No description provided for @noGradeLabel.
  ///
  /// In en, this message translates to:
  /// **'No grade'**
  String get noGradeLabel;

  /// No description provided for @tapToViewLabel.
  ///
  /// In en, this message translates to:
  /// **'Tap to view'**
  String get tapToViewLabel;

  /// No description provided for @awaitingEmailVerificationLabel.
  ///
  /// In en, this message translates to:
  /// **'Awaiting email verification'**
  String get awaitingEmailVerificationLabel;

  /// No description provided for @xpAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'{xp} XP'**
  String xpAmountLabel(int xp);

  /// No description provided for @questionsAttemptedLabel.
  ///
  /// In en, this message translates to:
  /// **'Questions Attempted ({total})'**
  String questionsAttemptedLabel(int total);

  /// No description provided for @correctLabel.
  ///
  /// In en, this message translates to:
  /// **'Correct'**
  String get correctLabel;

  /// No description provided for @incorrectLabel.
  ///
  /// In en, this message translates to:
  /// **'Incorrect'**
  String get incorrectLabel;

  /// No description provided for @questionNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Question {number}'**
  String questionNumberLabel(int number);

  /// No description provided for @parentVerificationRequiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Parent Verification Required'**
  String get parentVerificationRequiredTitle;

  /// No description provided for @logoutParentCredentialsMessage.
  ///
  /// In en, this message translates to:
  /// **'To log out, please enter your parent\'s credentials.'**
  String get logoutParentCredentialsMessage;

  /// No description provided for @parentEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Parent\'s Email'**
  String get parentEmailLabel;

  /// No description provided for @parentPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Parent\'s Password'**
  String get parentPasswordLabel;

  /// No description provided for @verifyAndLogOutButton.
  ///
  /// In en, this message translates to:
  /// **'Verify & Log Out'**
  String get verifyAndLogOutButton;

  /// No description provided for @xpRewardLabel.
  ///
  /// In en, this message translates to:
  /// **'+{xp} XP'**
  String xpRewardLabel(int xp);

  /// No description provided for @notifLevelUpTitle.
  ///
  /// In en, this message translates to:
  /// **'You reached Level {level}! 🎓'**
  String notifLevelUpTitle(int level);

  /// No description provided for @notifLevelUpBody.
  ///
  /// In en, this message translates to:
  /// **'Keep it up — more rewards are waiting at the next level.'**
  String get notifLevelUpBody;

  /// No description provided for @notifParentLevelUpTitle.
  ///
  /// In en, this message translates to:
  /// **'{studentName} reached Level {level}! 🎓'**
  String notifParentLevelUpTitle(String studentName, int level);

  /// No description provided for @notifParentLevelUpBody.
  ///
  /// In en, this message translates to:
  /// **'They\'ve been working hard. Check their progress.'**
  String get notifParentLevelUpBody;

  /// No description provided for @notifStreakMilestoneTitle.
  ///
  /// In en, this message translates to:
  /// **'{streak}-day streak! 🔥'**
  String notifStreakMilestoneTitle(int streak);

  /// No description provided for @notifStreakMilestoneBody.
  ///
  /// In en, this message translates to:
  /// **'You\'ve studied {streak} days in a row. Keep the fire going!'**
  String notifStreakMilestoneBody(int streak);

  /// No description provided for @notifNearMilestoneTitle.
  ///
  /// In en, this message translates to:
  /// **'One more day! 🔥'**
  String get notifNearMilestoneTitle;

  /// No description provided for @notifNearMilestoneBody.
  ///
  /// In en, this message translates to:
  /// **'Keep going — your {nextMilestone}-day reward is tomorrow.'**
  String notifNearMilestoneBody(int nextMilestone);

  /// No description provided for @notifStreakReminderTitle.
  ///
  /// In en, this message translates to:
  /// **'Don\'t break your streak! 🔥'**
  String get notifStreakReminderTitle;

  /// No description provided for @notifStreakReminderBody.
  ///
  /// In en, this message translates to:
  /// **'One quiz keeps your {streak}-day streak alive.'**
  String notifStreakReminderBody(int streak);

  /// No description provided for @notifStartStreakTitle.
  ///
  /// In en, this message translates to:
  /// **'Start a new streak today!'**
  String get notifStartStreakTitle;

  /// No description provided for @notifStartStreakBody.
  ///
  /// In en, this message translates to:
  /// **'Take a quick quiz and begin your learning streak.'**
  String get notifStartStreakBody;

  /// No description provided for @notifParentStreakBrokenTitle.
  ///
  /// In en, this message translates to:
  /// **'{studentName}\'s streak ended'**
  String notifParentStreakBrokenTitle(String studentName);

  /// No description provided for @notifParentStreakBrokenBody.
  ///
  /// In en, this message translates to:
  /// **'Their {previousStreak}-day streak was broken. A little encouragement might help.'**
  String notifParentStreakBrokenBody(int previousStreak);

  /// No description provided for @notifGardenNudgeTitle.
  ///
  /// In en, this message translates to:
  /// **'Your {subject} plant needs you 🌱'**
  String notifGardenNudgeTitle(String subject);

  /// No description provided for @notifGardenNudgeBody.
  ///
  /// In en, this message translates to:
  /// **'It\'s been a few days — come water your {subject} garden!'**
  String notifGardenNudgeBody(String subject);

  /// No description provided for @notifInactivityTitle.
  ///
  /// In en, this message translates to:
  /// **'{studentName} hasn\'t quizzed in 3 days'**
  String notifInactivityTitle(String studentName);

  /// No description provided for @notifInactivityBody.
  ///
  /// In en, this message translates to:
  /// **'A little encouragement might help them get back on track.'**
  String get notifInactivityBody;

  /// No description provided for @notifParentStreakMilestoneTitle.
  ///
  /// In en, this message translates to:
  /// **'{studentName} hit a {streak}-day streak! 🔥'**
  String notifParentStreakMilestoneTitle(String studentName, int streak);

  /// No description provided for @notifParentStreakMilestoneBody.
  ///
  /// In en, this message translates to:
  /// **'They\'ve been on a roll — keep the encouragement coming!'**
  String get notifParentStreakMilestoneBody;

  /// No description provided for @parentNotifPerStudentSection.
  ///
  /// In en, this message translates to:
  /// **'Students'**
  String get parentNotifPerStudentSection;

  /// No description provided for @parentStudentNotifAllLabel.
  ///
  /// In en, this message translates to:
  /// **'All notifications from this student'**
  String get parentStudentNotifAllLabel;

  /// No description provided for @parentNotifNoStudentsLinked.
  ///
  /// In en, this message translates to:
  /// **'No students linked yet.'**
  String get parentNotifNoStudentsLinked;

  /// No description provided for @managePreferencesButton.
  ///
  /// In en, this message translates to:
  /// **'Manage Preferences'**
  String get managePreferencesButton;

  /// No description provided for @parentPreferencesTitle.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get parentPreferencesTitle;

  /// No description provided for @parentNotificationsSection.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get parentNotificationsSection;

  /// No description provided for @parentNotifProgressLabel.
  ///
  /// In en, this message translates to:
  /// **'Child Progress Alerts'**
  String get parentNotifProgressLabel;

  /// No description provided for @parentNotifProgressSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Level ups and badge achievements'**
  String get parentNotifProgressSubtitle;

  /// No description provided for @parentNotifStreakLabel.
  ///
  /// In en, this message translates to:
  /// **'Streak Alerts'**
  String get parentNotifStreakLabel;

  /// No description provided for @parentNotifStreakSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Streak milestones and broken streaks'**
  String get parentNotifStreakSubtitle;

  /// No description provided for @parentNotifInactivityLabel.
  ///
  /// In en, this message translates to:
  /// **'Inactivity Reminders'**
  String get parentNotifInactivityLabel;

  /// No description provided for @parentNotifInactivitySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Alerts when a child hasn\'t studied in 3+ days'**
  String get parentNotifInactivitySubtitle;

  /// No description provided for @errInvalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Invalid email or password. Please try again.'**
  String get errInvalidCredentials;

  /// No description provided for @errNetworkError.
  ///
  /// In en, this message translates to:
  /// **'Network error. Check your connection.'**
  String get errNetworkError;

  /// No description provided for @errNetworkErrorRetry.
  ///
  /// In en, this message translates to:
  /// **'Network error. Check your connection and try again.'**
  String get errNetworkErrorRetry;

  /// No description provided for @errWeakPassword.
  ///
  /// In en, this message translates to:
  /// **'Password is too weak.'**
  String get errWeakPassword;

  /// No description provided for @errWeakPasswordDetailed.
  ///
  /// In en, this message translates to:
  /// **'Password is too weak. Please use at least 6 characters.'**
  String get errWeakPasswordDetailed;

  /// No description provided for @errEmailAlreadyInUse.
  ///
  /// In en, this message translates to:
  /// **'That email address is already registered. Please use a different one.'**
  String get errEmailAlreadyInUse;

  /// No description provided for @errInvalidEmailFormat.
  ///
  /// In en, this message translates to:
  /// **'That email address doesn\'t look right. Please check it.'**
  String get errInvalidEmailFormat;

  /// No description provided for @errSessionExpired.
  ///
  /// In en, this message translates to:
  /// **'Session expired. Please log out and log in again.'**
  String get errSessionExpired;

  /// No description provided for @errTooManyAttempts.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Please wait a moment and try again.'**
  String get errTooManyAttempts;

  /// No description provided for @errRegistrationFailed.
  ///
  /// In en, this message translates to:
  /// **'Registration failed. Please try again.'**
  String get errRegistrationFailed;

  /// No description provided for @errNoSignedInAccount.
  ///
  /// In en, this message translates to:
  /// **'No signed-in account found. Please log in again.'**
  String get errNoSignedInAccount;

  /// No description provided for @errVerificationEmailFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not send verification email. Please try again.'**
  String get errVerificationEmailFailed;

  /// No description provided for @errWrongCurrentPassword.
  ///
  /// In en, this message translates to:
  /// **'Current password is incorrect.'**
  String get errWrongCurrentPassword;

  /// No description provided for @errNewPasswordTooWeak.
  ///
  /// In en, this message translates to:
  /// **'New password is too weak. Use at least 6 characters.'**
  String get errNewPasswordTooWeak;

  /// No description provided for @errEmailAlreadyInUseOther.
  ///
  /// In en, this message translates to:
  /// **'That email address is already in use by another account.'**
  String get errEmailAlreadyInUseOther;

  /// No description provided for @errUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Update failed. Please try again.'**
  String get errUpdateFailed;

  /// No description provided for @errUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Upload failed. Please try again.'**
  String get errUploadFailed;

  /// No description provided for @errSubjectStillProcessing.
  ///
  /// In en, this message translates to:
  /// **'A document for this subject is still being prepared. Please wait until it finishes before uploading another.'**
  String get errSubjectStillProcessing;

  /// No description provided for @subjectPreparingLabel.
  ///
  /// In en, this message translates to:
  /// **'Preparing your subject…'**
  String get subjectPreparingLabel;

  /// No description provided for @subjectStageParsing.
  ///
  /// In en, this message translates to:
  /// **'Reading your document…'**
  String get subjectStageParsing;

  /// No description provided for @subjectStageAnalyzing.
  ///
  /// In en, this message translates to:
  /// **'Finding topics…'**
  String get subjectStageAnalyzing;

  /// No description provided for @subjectStageBuildingSkills.
  ///
  /// In en, this message translates to:
  /// **'Building your skill tree…'**
  String get subjectStageBuildingSkills;

  /// No description provided for @subjectPreparingPracticeDisabled.
  ///
  /// In en, this message translates to:
  /// **'Preparing…'**
  String get subjectPreparingPracticeDisabled;

  /// No description provided for @subjectIngestFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t process this document. Please try uploading it again.'**
  String get subjectIngestFailed;

  /// No description provided for @quizSubjectStillPreparing.
  ///
  /// In en, this message translates to:
  /// **'This subject is still being prepared. Please try again in a moment.'**
  String get quizSubjectStillPreparing;

  /// No description provided for @errDeleteAccountFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to delete account. Please try again.'**
  String get errDeleteAccountFailed;

  /// No description provided for @errStudentSessionExpired.
  ///
  /// In en, this message translates to:
  /// **'Session expired. Please log out and log in again before adding a student.'**
  String get errStudentSessionExpired;

  /// No description provided for @errStudentEmailAlreadyRegistered.
  ///
  /// In en, this message translates to:
  /// **'This email is already registered. Try logging in or resetting the password.'**
  String get errStudentEmailAlreadyRegistered;

  /// No description provided for @errStudentWeakPassword.
  ///
  /// In en, this message translates to:
  /// **'The password provided is too weak. Please use at least 6 characters.'**
  String get errStudentWeakPassword;

  /// No description provided for @errStudentInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'The email address is badly formatted.'**
  String get errStudentInvalidEmail;

  /// No description provided for @errUnexpected.
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred. Please try again.'**
  String get errUnexpected;

  /// No description provided for @shopItemPurchasedMessage.
  ///
  /// In en, this message translates to:
  /// **'Purchase successful! 🎉'**
  String get shopItemPurchasedMessage;

  /// No description provided for @errPurchaseFailed.
  ///
  /// In en, this message translates to:
  /// **'Purchase failed. Please try again.'**
  String get errPurchaseFailed;

  /// No description provided for @errCouldNotLoadProfile.
  ///
  /// In en, this message translates to:
  /// **'Could not load your profile. Please try again.'**
  String get errCouldNotLoadProfile;

  /// No description provided for @errInvalidParentCredentials.
  ///
  /// In en, this message translates to:
  /// **'Invalid parent credentials. Logout denied.'**
  String get errInvalidParentCredentials;

  /// No description provided for @confirmEmailSubtitle.
  ///
  /// In en, this message translates to:
  /// **'One last step'**
  String get confirmEmailSubtitle;

  /// No description provided for @createParentAccountSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create your parent account'**
  String get createParentAccountSubtitle;

  /// No description provided for @resetPasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We\'ll email you a reset link'**
  String get resetPasswordSubtitle;

  /// No description provided for @todayLabel.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get todayLabel;

  /// No description provided for @studiedLabel.
  ///
  /// In en, this message translates to:
  /// **'Studied'**
  String get studiedLabel;

  /// No description provided for @effortFocusTitle.
  ///
  /// In en, this message translates to:
  /// **'Effort & Focus'**
  String get effortFocusTitle;

  /// No description provided for @effortFocusSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Where this week\'s quizzes came from'**
  String get effortFocusSubtitle;

  /// No description provided for @selfStartedLabel.
  ///
  /// In en, this message translates to:
  /// **'Self-started'**
  String get selfStartedLabel;

  /// No description provided for @toUnlockAppsLabel.
  ///
  /// In en, this message translates to:
  /// **'To unlock apps'**
  String get toUnlockAppsLabel;

  /// No description provided for @percentSelfStartedMessage.
  ///
  /// In en, this message translates to:
  /// **'{percent}% of quizzes were self-started'**
  String percentSelfStartedMessage(int percent);

  /// No description provided for @noSubjectsReportMessage.
  ///
  /// In en, this message translates to:
  /// **'No subjects to report on yet.'**
  String get noSubjectsReportMessage;

  /// No description provided for @quizzesGuessingMessage.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 quiz showed rapid guessing} other{{count} quizzes showed rapid guessing}}'**
  String quizzesGuessingMessage(int count);

  /// No description provided for @restingStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Resting'**
  String get restingStatusLabel;

  /// No description provided for @readyStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get readyStatusLabel;

  /// No description provided for @markAsUnreadTooltip.
  ///
  /// In en, this message translates to:
  /// **'Mark as unread'**
  String get markAsUnreadTooltip;

  /// No description provided for @markAsReadTooltip.
  ///
  /// In en, this message translates to:
  /// **'Mark as read'**
  String get markAsReadTooltip;

  /// No description provided for @noActivitySummarizeMessage.
  ///
  /// In en, this message translates to:
  /// **'No activity to summarize yet.'**
  String get noActivitySummarizeMessage;

  /// No description provided for @motivationLevel1.
  ///
  /// In en, this message translates to:
  /// **'You\'re a Seedling — every expert was once a beginner! 🌱'**
  String get motivationLevel1;

  /// No description provided for @motivationLevel2.
  ///
  /// In en, this message translates to:
  /// **'You\'re a Sprout — you\'re growing fast, keep it up! 🌿'**
  String get motivationLevel2;

  /// No description provided for @motivationLevel3.
  ///
  /// In en, this message translates to:
  /// **'You\'re an Explorer — curiosity is your superpower! 🔍'**
  String get motivationLevel3;

  /// No description provided for @motivationLevel4.
  ///
  /// In en, this message translates to:
  /// **'You\'re a Curious Mind — great questions lead to great answers! 💡'**
  String get motivationLevel4;

  /// No description provided for @motivationLevel5.
  ///
  /// In en, this message translates to:
  /// **'You\'re a Scholar — your hard work is really showing! 📚'**
  String get motivationLevel5;

  /// No description provided for @motivationLevel6.
  ///
  /// In en, this message translates to:
  /// **'You\'re an Achiever — you make it look easy! ⭐'**
  String get motivationLevel6;

  /// No description provided for @motivationLevel7.
  ///
  /// In en, this message translates to:
  /// **'You\'re a Champion — you inspire everyone around you! 🏆'**
  String get motivationLevel7;

  /// No description provided for @motivationLevel8.
  ///
  /// In en, this message translates to:
  /// **'You\'re a Sage — your wisdom sets you apart! 🦉'**
  String get motivationLevel8;

  /// No description provided for @motivationLevel9.
  ///
  /// In en, this message translates to:
  /// **'You\'re a Luminary — you light the way for others! ✨'**
  String get motivationLevel9;

  /// No description provided for @motivationLevel10.
  ///
  /// In en, this message translates to:
  /// **'You\'re a Master — the pinnacle of excellence! 🌟'**
  String get motivationLevel10;

  /// No description provided for @motivationDefault.
  ///
  /// In en, this message translates to:
  /// **'Keep learning — you\'re doing amazing! 🚀'**
  String get motivationDefault;

  /// No description provided for @rankLevel1.
  ///
  /// In en, this message translates to:
  /// **'Seedling'**
  String get rankLevel1;

  /// No description provided for @rankLevel2.
  ///
  /// In en, this message translates to:
  /// **'Sprout'**
  String get rankLevel2;

  /// No description provided for @rankLevel3.
  ///
  /// In en, this message translates to:
  /// **'Explorer'**
  String get rankLevel3;

  /// No description provided for @rankLevel4.
  ///
  /// In en, this message translates to:
  /// **'Curious Mind'**
  String get rankLevel4;

  /// No description provided for @rankLevel5.
  ///
  /// In en, this message translates to:
  /// **'Scholar'**
  String get rankLevel5;

  /// No description provided for @rankLevel6.
  ///
  /// In en, this message translates to:
  /// **'Achiever'**
  String get rankLevel6;

  /// No description provided for @rankLevel7.
  ///
  /// In en, this message translates to:
  /// **'Champion'**
  String get rankLevel7;

  /// No description provided for @rankLevel8.
  ///
  /// In en, this message translates to:
  /// **'Sage'**
  String get rankLevel8;

  /// No description provided for @rankLevel9.
  ///
  /// In en, this message translates to:
  /// **'Luminary'**
  String get rankLevel9;

  /// No description provided for @rankLevel10.
  ///
  /// In en, this message translates to:
  /// **'Master'**
  String get rankLevel10;

  /// No description provided for @hourUnitLabel.
  ///
  /// In en, this message translates to:
  /// **'hr'**
  String get hourUnitLabel;

  /// No description provided for @hoursUnitLabel.
  ///
  /// In en, this message translates to:
  /// **'hrs'**
  String get hoursUnitLabel;

  /// No description provided for @minuteUnitLabel.
  ///
  /// In en, this message translates to:
  /// **'min'**
  String get minuteUnitLabel;

  /// No description provided for @appsParentWatchesTitle.
  ///
  /// In en, this message translates to:
  /// **'Apps your parent watches'**
  String get appsParentWatchesTitle;

  /// No description provided for @restingNowSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Resting now · tap to see all'**
  String get restingNowSubtitle;

  /// No description provided for @appsCountSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 app · tap to see all} other{{count} apps · tap to see all}}'**
  String appsCountSubtitle(int count);

  /// No description provided for @noAppsWatchedMessage.
  ///
  /// In en, this message translates to:
  /// **'No apps are being watched right now 🎉'**
  String get noAppsWatchedMessage;

  /// No description provided for @globalTimeLimitsLabel.
  ///
  /// In en, this message translates to:
  /// **'Global Time Limits'**
  String get globalTimeLimitsLabel;

  /// No description provided for @globalTimeLimitsTooltip.
  ///
  /// In en, this message translates to:
  /// **'These limits apply to all restricted apps. When a student reaches the usage limit on any restricted app, they must wait the cooldown period before using it again.'**
  String get globalTimeLimitsTooltip;

  /// No description provided for @usageAllowanceLabel.
  ///
  /// In en, this message translates to:
  /// **'Usage Allowance'**
  String get usageAllowanceLabel;

  /// No description provided for @readyToPracticeMessage.
  ///
  /// In en, this message translates to:
  /// **'Ready to practice?'**
  String get readyToPracticeMessage;

  /// No description provided for @gotItButton.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get gotItButton;

  /// No description provided for @finishButton.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get finishButton;

  /// No description provided for @correctExclamationLabel.
  ///
  /// In en, this message translates to:
  /// **'Correct!'**
  String get correctExclamationLabel;

  /// No description provided for @solutionLabel.
  ///
  /// In en, this message translates to:
  /// **'Solution'**
  String get solutionLabel;

  /// No description provided for @correctAnswerLabel.
  ///
  /// In en, this message translates to:
  /// **'Correct answer'**
  String get correctAnswerLabel;

  /// No description provided for @reachLevelToUnlockMessage.
  ///
  /// In en, this message translates to:
  /// **'Reach Level {level} to unlock this item.'**
  String reachLevelToUnlockMessage(int level);

  /// No description provided for @coinPriceLabel.
  ///
  /// In en, this message translates to:
  /// **'{price} coins'**
  String coinPriceLabel(int price);

  /// No description provided for @balanceAfterLabel.
  ///
  /// In en, this message translates to:
  /// **'Balance after: {balance} 🪙'**
  String balanceAfterLabel(int balance);

  /// No description provided for @appsRestingTitle.
  ///
  /// In en, this message translates to:
  /// **'Apps are resting right now'**
  String get appsRestingTitle;

  /// No description provided for @earnedFreeTimeLockedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'You\'ve earned {time} of free time today. Finish your quiz to unlock more.'**
  String earnedFreeTimeLockedSubtitle(String time);

  /// No description provided for @finishQuizUnlockApps.
  ///
  /// In en, this message translates to:
  /// **'Finish your quiz to unlock your apps.'**
  String get finishQuizUnlockApps;

  /// No description provided for @earnedFreeTimeUnlockedTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'ve earned {time} of free time today'**
  String earnedFreeTimeUnlockedTitle(String time);

  /// No description provided for @appsUnlockedEnjoySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your apps are unlocked — enjoy your free time.'**
  String get appsUnlockedEnjoySubtitle;

  /// No description provided for @appsUnlockedTitle.
  ///
  /// In en, this message translates to:
  /// **'Your apps are unlocked'**
  String get appsUnlockedTitle;

  /// No description provided for @enjoyFreeTimeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enjoy your free time.'**
  String get enjoyFreeTimeSubtitle;

  /// No description provided for @timeToRestTitle.
  ///
  /// In en, this message translates to:
  /// **'Time to rest'**
  String get timeToRestTitle;

  /// No description provided for @screenTimeTitle.
  ///
  /// In en, this message translates to:
  /// **'Screen time'**
  String get screenTimeTitle;

  /// No description provided for @limitRestSummaryLabel.
  ///
  /// In en, this message translates to:
  /// **'Limit {limit}   ·   Rest {rest}'**
  String limitRestSummaryLabel(String limit, String rest);

  /// No description provided for @minLeftLabel.
  ///
  /// In en, this message translates to:
  /// **'min left'**
  String get minLeftLabel;

  /// No description provided for @secLeftLabel.
  ///
  /// In en, this message translates to:
  /// **'sec left'**
  String get secLeftLabel;

  /// No description provided for @restingLabel.
  ///
  /// In en, this message translates to:
  /// **'resting'**
  String get restingLabel;

  /// No description provided for @noTimeLimitMessage.
  ///
  /// In en, this message translates to:
  /// **'No time limit set — enjoy learning!'**
  String get noTimeLimitMessage;

  /// No description provided for @questionsTodayLabel.
  ///
  /// In en, this message translates to:
  /// **'questions today'**
  String get questionsTodayLabel;

  /// No description provided for @noQuestionsYetMessage.
  ///
  /// In en, this message translates to:
  /// **'No questions yet today — let\'s start! 🌱'**
  String get noQuestionsYetMessage;

  /// No description provided for @topRankLabel.
  ///
  /// In en, this message translates to:
  /// **'Top rank'**
  String get topRankLabel;

  /// No description provided for @nextRankLabel.
  ///
  /// In en, this message translates to:
  /// **'Next: {rank}'**
  String nextRankLabel(String rank);

  /// No description provided for @reachedTopMessage.
  ///
  /// In en, this message translates to:
  /// **'You reached the top — amazing!'**
  String get reachedTopMessage;

  /// No description provided for @xpProgressLabel.
  ///
  /// In en, this message translates to:
  /// **'{current} / {max} XP'**
  String xpProgressLabel(int current, int max);

  /// No description provided for @totalSuffixLabel.
  ///
  /// In en, this message translates to:
  /// **'{time} total'**
  String totalSuffixLabel(String time);

  /// No description provided for @noStudyTimeWeekMessage.
  ///
  /// In en, this message translates to:
  /// **'No study time logged this week yet.'**
  String get noStudyTimeWeekMessage;

  /// No description provided for @mascotIdleMessage.
  ///
  /// In en, this message translates to:
  /// **'What shall we learn today?'**
  String get mascotIdleMessage;

  /// No description provided for @mascotHappyMessage.
  ///
  /// In en, this message translates to:
  /// **'Great job! Keep it up!'**
  String get mascotHappyMessage;

  /// No description provided for @mascotThinkingMessage.
  ///
  /// In en, this message translates to:
  /// **'One moment…'**
  String get mascotThinkingMessage;

  /// No description provided for @mascotSadMessage.
  ///
  /// In en, this message translates to:
  /// **'Don\'t worry — let\'s try again!'**
  String get mascotSadMessage;

  /// No description provided for @mascotCelebrationMessage.
  ///
  /// In en, this message translates to:
  /// **'Amazing work! 🌟'**
  String get mascotCelebrationMessage;

  /// No description provided for @mascotHiGreeting.
  ///
  /// In en, this message translates to:
  /// **'Hi, {name}! 👋'**
  String mascotHiGreeting(String name);
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
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
