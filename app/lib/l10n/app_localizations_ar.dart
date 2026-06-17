// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'ستادي مينتور';

  @override
  String get languageSettingTitle => 'اللغة';

  @override
  String get languageSettingSubtitle => 'العربية / الإنجليزية';

  @override
  String get languageDialogTitle => 'اختر اللغة';

  @override
  String get languageEnglish => 'الإنجليزية';

  @override
  String get languageArabic => 'العربية';

  @override
  String get commonCancel => 'إلغاء';

  @override
  String get commonOk => 'حسنًا';

  @override
  String get commonSave => 'حفظ';

  @override
  String get commonRetry => 'إعادة المحاولة';

  @override
  String get commonDelete => 'حذف';

  @override
  String get commonClose => 'إغلاق';

  @override
  String get commonError => 'خطأ';

  @override
  String get commonLoading => 'جارٍ التحميل...';

  @override
  String get studentSettingsTitle => 'الإعدادات';

  @override
  String get preferencesSection => 'التفضيلات';

  @override
  String get accountSection => 'الحساب';

  @override
  String get aboutSection => 'حول';

  @override
  String get pushNotificationsTitle => 'الإشعارات';

  @override
  String get pushNotificationsSubtitle => 'تلقي تذكيرات وتحديثات الدراسة';

  @override
  String get soundEffectsTitle => 'المؤثرات الصوتية';

  @override
  String get soundEffectsSubtitle => 'أصوات الأزرار والتفاعلات';

  @override
  String get backgroundMusicTitle => 'الموسيقى الخلفية';

  @override
  String get backgroundMusicSubtitle => 'تشغيل الموسيقى أثناء الدراسة';

  @override
  String get usageTimerNotificationTitle => 'إشعار مؤقت الاستخدام';

  @override
  String get usageTimerNotificationSubtitle =>
      'إظهار إشعار يعرض العد التنازلي للوقت المتبقي من استخدام التطبيق';

  @override
  String get cooldownTimerNotificationTitle => 'إشعار مؤقت الاستراحة';

  @override
  String get cooldownTimerNotificationSubtitle =>
      'إظهار إشعار يعرض العد التنازلي للوقت المتبقي من الاستراحة';

  @override
  String get appVersionLabel => 'إصدار التطبيق';

  @override
  String parentSettingsEmailPendingBanner(String email) {
    return 'تم إرسال رابط تأكيد إلى $email. سيتم تحديث بريدك الإلكتروني بعد الضغط عليه.';
  }

  @override
  String get parentSettingsAccountInfoSection => 'معلومات الحساب';

  @override
  String get parentSettingsChangePasswordSection => 'تغيير كلمة المرور';

  @override
  String get parentSettingsPasswordHint =>
      'اترك جميع حقول كلمة المرور فارغة للاحتفاظ بكلمة المرور الحالية.';

  @override
  String get fieldFullName => 'الاسم الكامل';

  @override
  String get validatorFullNameRequired => 'الاسم الكامل مطلوب.';

  @override
  String get validatorFullNameMinLength =>
      'يجب أن يكون الاسم مكونًا من حرفين على الأقل.';

  @override
  String get fieldEmail => 'البريد الإلكتروني';

  @override
  String get parentSettingsEmailHelper =>
      'سيتم إرسال رابط تأكيد إلى عنوان البريد الإلكتروني الجديد عند تغييره.';

  @override
  String get validatorEmailRequired => 'البريد الإلكتروني مطلوب.';

  @override
  String get validatorEmailInvalid => 'أدخل بريدًا إلكترونيًا صالحًا.';

  @override
  String get fieldCurrentPassword => 'كلمة المرور الحالية';

  @override
  String get validatorCurrentPasswordForEmail =>
      'أدخل كلمة مرورك الحالية لتغيير بريدك الإلكتروني.';

  @override
  String get validatorCurrentPasswordForNewPassword =>
      'أدخل كلمة مرورك الحالية لتعيين كلمة مرور جديدة.';

  @override
  String get fieldNewPassword => 'كلمة المرور الجديدة';

  @override
  String get validatorPasswordMinLength =>
      'يجب أن تكون كلمة المرور 6 أحرف على الأقل.';

  @override
  String get validatorEnterCurrentPasswordFirst =>
      'أدخل كلمة مرورك الحالية أولاً.';

  @override
  String get fieldConfirmNewPassword => 'تأكيد كلمة المرور الجديدة';

  @override
  String get validatorPasswordsDoNotMatch => 'كلمتا المرور غير متطابقتين.';

  @override
  String get saveChangesButton => 'حفظ التغييرات';

  @override
  String get profileUpdatedSuccess => 'تم تحديث الملف الشخصي بنجاح.';

  @override
  String get couldNotLoadLinkedStudents =>
      'تعذر تحميل الطلاب المرتبطين. تحقق من اتصالك.';

  @override
  String get dangerZoneSection => 'منطقة الخطر';

  @override
  String get deleteAccountTitle => 'حذف الحساب';

  @override
  String get deleteAccountDescription =>
      'يحذف حسابك وجميع بياناتك بشكل نهائي. يجب حذف جميع حسابات الطلاب أولاً.';

  @override
  String get deleteAccountBlockedTooltip =>
      'أزل جميع الأطفال المرتبطين قبل حذف حسابك.';

  @override
  String get deleteAccountRetryTooltip =>
      'تعذر التحقق من الطلاب المرتبطين. يرجى إعادة المحاولة.';

  @override
  String get deleteMyAccountButton => 'حذف حسابي';

  @override
  String get childLoadErrorNotice =>
      'تعذر التحقق من الطلاب المرتبطين. تم تعطيل الحذف حتى يتم حل هذه المشكلة.';

  @override
  String get linkedChildrenNotice =>
      'لا يمكنك حذف حسابك إلا بعد إزالة جميع الأطفال المرتبطين. انتقل إلى تبويب الطلاب لحذف حساب كل طفل أولاً.';

  @override
  String get deleteYourAccountDialogTitle => 'حذف حسابك';

  @override
  String get deleteYourAccountDialogContent =>
      'سيؤدي هذا إلى حذف حسابك بشكل نهائي. هل أنت متأكد؟';

  @override
  String get continueButton => 'استمرار';

  @override
  String get confirmYourPasswordDialogTitle => 'تأكيد كلمة المرور';

  @override
  String get confirmPasswordDeleteWarning =>
      'أدخل كلمة مرورك الحالية لحذف حسابك بشكل نهائي. لا يمكن التراجع عن هذا الإجراء.';

  @override
  String get validatorEnterCurrentPassword => 'يرجى إدخال كلمة مرورك الحالية.';

  @override
  String get signInTitle => 'تسجيل الدخول';

  @override
  String get fieldPassword => 'كلمة المرور';

  @override
  String get validatorPasswordRequired => 'كلمة المرور مطلوبة.';

  @override
  String get loginEmailValidator => 'يرجى إدخال بريد إلكتروني صالح.';

  @override
  String get registerPromptButton => 'لم تسجل بعد؟ سجل كولي أمر';

  @override
  String get forgotPasswordButton => 'هل نسيت كلمة المرور؟';

  @override
  String get registerAsParentTitle => 'التسجيل كولي أمر';

  @override
  String get fieldConfirmPassword => 'تأكيد كلمة المرور';

  @override
  String get registerButton => 'تسجيل';

  @override
  String get alreadyRegisteredButton => 'مسجل بالفعل؟ سجل الدخول';

  @override
  String get resetPasswordTitle => 'إعادة تعيين كلمة المرور';

  @override
  String get passwordResetLinkSentMessage =>
      'تم إرسال رابط إعادة تعيين كلمة المرور! تحقق من بريدك الوارد.';

  @override
  String get sendResetLinkButton => 'إرسال رابط إعادة التعيين';

  @override
  String get confirmEmailTitle => 'تأكيد البريد الإلكتروني';

  @override
  String get emailNotVerifiedYetMessage =>
      'لم يتم تأكيد بريدك الإلكتروني بعد. تحقق من بريدك الوارد.';

  @override
  String get emailVerificationLinkSentMessage =>
      'تم إرسال رابط تأكيد البريد الإلكتروني!';

  @override
  String get confirmEmailInstructions =>
      'يرجى التحقق من بريدك الوارد وتأكيد بريدك الإلكتروني للاستمرار.';

  @override
  String get sendEmailVerificationButton =>
      'إرسال رابط تأكيد البريد الإلكتروني';

  @override
  String get emailVerifiedButton => 'لقد قمت بتأكيد بريدي الإلكتروني';

  @override
  String get logOutButton => 'تسجيل الخروج';

  @override
  String get dashboardTitle => 'لوحة التحكم';

  @override
  String get nothingHereYetTitle => 'لا يوجد شيء هنا حتى الآن.';

  @override
  String get activityAlertsWillAppearHere => 'ستظهر الأنشطة والتنبيهات هنا.';

  @override
  String get myChildrenTitle => 'أطفالي';

  @override
  String get validatorStudentPasswordRequired => 'يرجى إدخال كلمة مرور الطالب.';

  @override
  String get removeStudentTitle => 'إزالة الطالب';

  @override
  String removeStudentConfirmMessage(String studentName) {
    return 'سيؤدي هذا إلى حذف حساب $studentName بشكل نهائي. أدخل كلمة المرور التي أنشأتها له للتأكيد.';
  }

  @override
  String get fieldStudentPassword => 'كلمة مرور الطالب';

  @override
  String get removeButton => 'إزالة';

  @override
  String get noChildrenAddedYetTitle => 'لم تتم إضافة أي أطفال حتى الآن.';

  @override
  String get useAddStudentButtonHint =>
      'استخدم زر إضافة طالب لتسجيل طفلك الأول.';

  @override
  String studentNotActivatedBanner(int count, String names) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$names لم يقوموا بتفعيل حساباتهم بعد.',
      one: '$names لم يقم بتفعيل حسابه بعد.',
    );
    return '$_temp0';
  }

  @override
  String get verifyEmailInstructionBanner =>
      'اطلب منهم فتح التطبيق وتسجيل الدخول ببيانات الاعتماد التي أنشأتها، وتأكيد بريدهم الإلكتروني.';

  @override
  String get tapStudentCardHint =>
      'اضغط على بطاقة الطالب لمراقبة نشاطه، وإدارة قواعد استخدام التطبيق، ومراجعة حالته الدراسية.';

  @override
  String get incorrectPasswordRetryMessage =>
      'كلمة المرور غير صحيحة. يرجى المحاولة مرة أخرى.';

  @override
  String get deleteChildAccountTitle => 'حذف حساب الطفل';

  @override
  String get deleteChildAccountWarningPrefix => 'أنت على وشك حذف حساب ';

  @override
  String get deleteChildAccountWarningSuffix =>
      ' بشكل نهائي. سيؤدي هذا إلى إزالة جميع بياناته ولا يمكن التراجع عن هذا الإجراء.';

  @override
  String studentCredentialsWillBeDeleted(String firstName) {
    return 'سيتم حذف بيانات تسجيل دخول $firstName وتقدمه وإعداداته بشكل نهائي.';
  }

  @override
  String passwordYouCreatedForHint(String firstName) {
    return 'كلمة المرور التي أنشأتها لـ $firstName';
  }

  @override
  String get deletePermanentlyButton => 'حذف نهائيًا';

  @override
  String gradeLabel(int grade) {
    return 'الصف $grade';
  }

  @override
  String get studentRegisteredSuccessTitle => 'تم تسجيل الطالب بنجاح!';

  @override
  String get studentRegisteredSuccessDetail =>
      'على هاتف طفلك، افتح التطبيق وسجل الدخول ببيانات الاعتماد التي أنشأتها للتو. سيحتاج إلى تأكيد بريده الإلكتروني قبل البدء.';

  @override
  String get registerStudentTitle => 'تسجيل طالب';

  @override
  String get createNewStudentAccountSubtitle => 'إنشاء حساب طالب جديد';

  @override
  String get studentInformationSection => 'معلومات الطالب';

  @override
  String get fieldGrade => 'الصف';

  @override
  String get validatorGradeRequired => 'يرجى اختيار الصف.';

  @override
  String get accountCredentialsSection => 'بيانات اعتماد الحساب';

  @override
  String get fieldEmailAddress => 'البريد الإلكتروني';

  @override
  String get emailAddressHint => 'سيستخدم الطالب هذا لتسجيل الدخول.';

  @override
  String get validatorConfirmPasswordRequired => 'يرجى تأكيد كلمة المرور.';

  @override
  String get accountSettingsTitle => 'إعدادات الحساب';

  @override
  String get unsavedChangesDialogTitle => 'تغييرات غير محفوظة';

  @override
  String get unsavedChangesDialogContent =>
      'لديك تغييرات غير محفوظة. هل تريد الخروج دون حفظها؟';

  @override
  String get stayButton => 'البقاء';

  @override
  String get leaveButton => 'خروج';

  @override
  String get logoutConfirmationMessage =>
      'هل أنت متأكد من رغبتك في تسجيل الخروج من حسابك؟';

  @override
  String get requiredToChangeEmailHint =>
      'مطلوب لتغيير عنوان البريد الإلكتروني.';

  @override
  String get studentProfileStaticTitle => 'الملف الشخصي للطالب';

  @override
  String studentProfileUpdatedEmailPending(String email) {
    return 'تم تحديث الملف الشخصي. تم إرسال رابط تأكيد إلى $email.';
  }

  @override
  String studentSettingsEmailPendingBanner(String email) {
    return 'تم إرسال رابط تأكيد إلى $email. سيتم تحديث بريد الطالب الإلكتروني بعد الضغط عليه.';
  }

  @override
  String get studentSettingsEmailHelper =>
      'سيؤدي تغيير البريد الإلكتروني إلى إرسال رابط تأكيد إلى العنوان الجديد.';

  @override
  String get fieldStudentCurrentPassword => 'كلمة مرور الطالب الحالية';

  @override
  String get validatorStudentCurrentPasswordForEmail =>
      'أدخل كلمة مرور الطالب الحالية لتغيير بريده الإلكتروني.';

  @override
  String get validatorStudentCurrentPasswordForNewPassword =>
      'أدخل كلمة مرور الطالب الحالية لتعيين كلمة مرور جديدة.';

  @override
  String get validatorEnterStudentCurrentPasswordFirst =>
      'أدخل كلمة مرور الطالب الحالية أولاً.';

  @override
  String get discardChangesDialogContent =>
      'سيؤدي التحديث إلى تجاهل التغييرات غير المحفوظة. هل تريد الاستمرار؟';

  @override
  String get discardAndRefreshButton => 'تجاهل وتحديث';

  @override
  String get stillLoadingAppListMessage =>
      'لا يزال جاري تحميل قائمة التطبيقات — يرجى الانتظار.';

  @override
  String deviceNotSyncedMessage(String name) {
    return 'لم تتم مزامنة جهاز $name بعد. اطلب منه فتح التطبيق مرة واحدة.';
  }

  @override
  String get allAppsAlreadyConfiguredMessage =>
      'تم إعداد جميع التطبيقات المثبتة بالفعل.';

  @override
  String removeAppConfirmTitle(String appLabel) {
    return 'إزالة $appLabel؟';
  }

  @override
  String get removeAppConfirmMessage =>
      'هل أنت متأكد من رغبتك في إيقاف مراقبة هذا التطبيق؟ سيتمكن طفلك من الوصول إليه دون قيود.';

  @override
  String get configSavedSuccessMessage => 'تم حفظ الإعدادات بنجاح.';

  @override
  String get configurationsTitle => 'الإعدادات';

  @override
  String get screenTimeRewardTitle => 'مكافأة وقت الشاشة لكل اختبار';

  @override
  String get screenTimeRewardDescription =>
      'يحصل الطفل على هذا القدر من وقت الشاشة غير المقيد عن كل اختبار ينجح فيه.';

  @override
  String get setCooldownTimeTitle => 'تحديد فترة الاستراحة';

  @override
  String get cooldownPeriodTitle => 'فترة الاستراحة';

  @override
  String get cooldownPeriodDescription => 'مدة القفل بعد انتهاء وقت الاستخدام.';

  @override
  String get appRulesTitle => 'قواعد التطبيقات';

  @override
  String get noAppsConfiguredHint =>
      'لا توجد تطبيقات مُعدّة حتى الآن. اضغط على + لإضافة أول تطبيق.';

  @override
  String monitoredCountLabel(int count) {
    return '$count مُراقَب';
  }

  @override
  String pausedCountLabel(int count) {
    return '$count متوقف';
  }

  @override
  String manageAllAppsLabel(int count) {
    return 'إدارة جميع التطبيقات ($count)';
  }

  @override
  String get quizSettingsTitle => 'إعدادات الاختبار';

  @override
  String get questionsPerQuizLabel => 'عدد الأسئلة لكل اختبار';

  @override
  String get quizCountAutoLabel => 'تلقائي';

  @override
  String get quizCountAutoDescription =>
      'سيقوم المعلم الذكي بضبط طول الاختبار ديناميكيًا بناءً على أداء الطفل الحالي.';

  @override
  String quizCountFixedDescription(int count) {
    return 'يجب على الطفل الإجابة بشكل صحيح عن $count أسئلة لإلغاء قفل جهازه.';
  }

  @override
  String get editProfileButton => 'تعديل الملف الشخصي';

  @override
  String get passwordRequiredToDeleteAccountMessage =>
      'كلمة المرور مطلوبة لحذف الحساب.';

  @override
  String get deleteStudentDialogTitle => 'حذف الطالب';

  @override
  String get deleteStudentWarningPrefix => 'سيؤدي هذا إلى حذف حساب ';

  @override
  String get deleteStudentWarningSuffix =>
      ' بشكل نهائي — التقدم والعناصر والإعدادات. لا يمكن التراجع عن هذا الإجراء.';

  @override
  String monitoredAndPausedLabel(int monitored, int paused) {
    return '$monitored مُراقَب · $paused متوقف';
  }

  @override
  String get noAppsConfiguredTitle => 'لا توجد تطبيقات مُعدّة حتى الآن.';

  @override
  String get tapAddAppHint => 'اضغط على \"إضافة تطبيق\" أدناه للبدء.';

  @override
  String get appStatusPaused => 'متوقف';

  @override
  String get appStatusMonitored => 'مُراقَب';

  @override
  String get addAppButton => 'إضافة تطبيق';

  @override
  String get installedAppsFilterLabel => 'التطبيقات المثبتة';

  @override
  String get installedAppsFilterSubtitle =>
      'التطبيقات التي قام الطالب بتنزيلها';

  @override
  String get allAppsFilterLabel => 'جميع التطبيقات';

  @override
  String get allAppsFilterSubtitle => 'يشمل تطبيقات النظام والمثبتة مسبقًا';

  @override
  String get selectAppsTitle => 'اختر التطبيقات';

  @override
  String get searchAppsHint => 'البحث عن تطبيقات…';

  @override
  String get addSelectedButton => 'إضافة المحدد';

  @override
  String noAppsMatchQuery(String query) {
    return 'لا توجد تطبيقات تطابق \"$query\"';
  }

  @override
  String get noUserInstalledAppsFound =>
      'لم يتم العثور على تطبيقات مثبتة من قِبل المستخدم';

  @override
  String get switchToAllAppsHint =>
      'بدّل إلى جميع التطبيقات لرؤية تطبيقات النظام';

  @override
  String get setRewardTimeTitle => 'تحديد وقت المكافأة';

  @override
  String presetMinutesLabel(int minutes) {
    return '$minutes دقيقة';
  }

  @override
  String get preset1HourLabel => 'ساعة واحدة';

  @override
  String get saveTimeButton => 'حفظ الوقت';

  @override
  String get masteryTierAdvanced => 'متقدم';

  @override
  String get masteryTierProficient => 'ماهر';

  @override
  String get masteryTierDeveloping => 'في تطور';

  @override
  String get masteryTierBeginner => 'مبتدئ';

  @override
  String get sortQuizzesTitle => 'ترتيب الاختبارات';

  @override
  String get sortDateNewestToOldest => 'التاريخ: من الأحدث إلى الأقدم';

  @override
  String get sortDateOldestToNewest => 'التاريخ: من الأقدم إلى الأحدث';

  @override
  String get sortScoreHighestToLowest => 'الدرجة: من الأعلى إلى الأقل';

  @override
  String get sortScoreLowestToHighest => 'الدرجة: من الأقل إلى الأعلى';

  @override
  String get overallMasteryLevelLabel => 'مستوى التمكن الإجمالي';

  @override
  String get accuracyLabel => 'الدقة';

  @override
  String get quizzesDoneLabel => 'الاختبارات المكتملة';

  @override
  String get timeSpentLabel => 'الوقت المستغرق';

  @override
  String get skillsProgressTitle => 'تقدم المهارات';

  @override
  String get seeAllLabel => 'عرض الكل';

  @override
  String get quizHistoryTitle => 'سجل الاختبارات';

  @override
  String get sortSkillsTitle => 'ترتيب المهارات';

  @override
  String get sortMasteryLowestFirst => 'التمكن: من الأقل أولاً';

  @override
  String get sortMasteryHighestFirst => 'التمكن: من الأعلى أولاً';

  @override
  String get sortAZLabel => 'أ - ي';

  @override
  String get recommendationNotStarted =>
      'لم تبدأ بعد — شجّع طفلك على تجربة هذه المهارة';

  @override
  String get recommendationUrgent =>
      'تحتاج إلى اهتمام عاجل — يُنصح بجلسات تدريب يومية قصيرة';

  @override
  String get recommendationProgress =>
      'تقدم جيد — مراجعة الأخطاء السابقة ستساعد';

  @override
  String get recommendationOnTrack =>
      'على المسار الصحيح — جلسات قليلة أخرى ستحقق التمكن';

  @override
  String get recommendationStrong => 'مهارة قوية — مراجعة دورية للحفاظ عليها';

  @override
  String get statTotalLabel => 'الإجمالي';

  @override
  String get allSkillsTitle => 'جميع المهارات';

  @override
  String correctOfAttemptsLabel(int correct, int attempts) {
    return '$correct صحيحة / $attempts محاولات';
  }

  @override
  String get neverPracticedLabel => 'لم تتم الممارسة من قبل';

  @override
  String lastPracticedLabel(String date) {
    return 'آخر مرة: $date';
  }

  @override
  String get uploadCurriculumTitle => 'رفع المنهج';

  @override
  String get noSubjectsYetTitle => 'لا توجد مواد بعد';

  @override
  String noSubjectsYetDescription(String studentName) {
    return 'اضغط على زر \"+\" في الأعلى لبدء تتبع المواد أو رفع منهج جديد لـ $studentName.';
  }

  @override
  String get subjectsAndSkillsTitle => 'المواد والمهارات';

  @override
  String skillsTrackedLabel(int count) {
    return '$count مهارة مُتتبعة';
  }

  @override
  String get masteryLabel => 'التمكن';

  @override
  String removeSubjectConfirmTitle(String subjectName) {
    return 'إزالة $subjectName؟';
  }

  @override
  String get removeSubjectConfirmMessage =>
      'هل أنت متأكد من رغبتك في إزالة هذه المادة؟';

  @override
  String get searchSubjectsHint => 'البحث عن المواد...';

  @override
  String addSelectedCountButton(int count) {
    return 'إضافة المحدد ($count)';
  }

  @override
  String get noQuizzesYetMessage => 'لا توجد اختبارات بعد';

  @override
  String get allQuizzesTitle => 'جميع الاختبارات';

  @override
  String get tabOverview => 'نظرة عامة';

  @override
  String get tabMastery => 'التمكن';

  @override
  String get tabHabits => 'العادات';

  @override
  String get reportsAnalysisTitle => 'التقارير والتحليلات';

  @override
  String get noReportAvailableMessage => 'لا يوجد تقرير متاح.';

  @override
  String get metricQuizzesLabel => 'الاختبارات';

  @override
  String get studyTimeLabel => 'وقت الدراسة';

  @override
  String get accuracyTrendTitle => 'اتجاه الدقة';

  @override
  String get weeklyAccuracyTrendSubtitle => 'الدقة الأسبوعية خلال آخر 6 أسابيع';

  @override
  String get notEnoughDataYetMessage => 'لا توجد بيانات كافية بعد';

  @override
  String get completeQuizzesTrendHint =>
      'أكمل اختبارات على مدار عدة أسابيع لرؤية الاتجاه';

  @override
  String get streakProgressTitle => 'تقدم سلسلة الأيام';

  @override
  String get currentStreakVsBestSubtitle =>
      'السلسلة الحالية مقارنة بأفضل سلسلة';

  @override
  String get currentStreakLabel => 'السلسلة الحالية';

  @override
  String get personalBestLabel => 'أفضل رقم شخصي';

  @override
  String get daysUnitLabel => 'أيام';

  @override
  String percentOfPersonalBest(int percent) {
    return '$percent% من أفضل رقم شخصي';
  }

  @override
  String get noStreakYetMessage =>
      'لا توجد سلسلة بعد — ابدأ الدراسة لبناء واحدة!';

  @override
  String get smartInsightsTitle => 'رؤى ذكية';

  @override
  String get insightNoQuizzes =>
      'لم يتم إكمال أي اختبارات هذا الأسبوع بعد. شجّع طفلك على تسجيل الدخول وبدء جلسة للحفاظ على سلسلته!';

  @override
  String insightOutstanding(int quizzes, int accuracy) {
    return 'تم إكمال $quizzes اختبارات هذا الأسبوع بدقة $accuracy% — أداء متميز! يتمكن الطالب من المادة بمستوى عالٍ. حافظ على هذا الزخم.';
  }

  @override
  String insightGoodWeek(int quizzes, int accuracy) {
    return 'أسبوع جيد بشكل عام: $quizzes اختبارات بدقة $accuracy%. لتحسين الأداء أكثر، تفقد تبويب التمكن وركّز على المهارات الأقل من 60%.';
  }

  @override
  String insightRoomToImprove(int quizzes, int accuracy) {
    return 'تم إكمال $quizzes اختبارات بدقة $accuracy%. هناك مجال للتحسين — تفقد تبويب التمكن لتحديد ثغرات المفاهيم التي تحتاج إلى اهتمام.';
  }

  @override
  String insightStreakKept(int streak, int accuracy) {
    return 'حافظ الطالب على سلسلة لمدة $streak أيام، وهذا رائع للاستمرارية! الدقة عند $accuracy% — مراجعة المواضيع الأضعف بين الجلسات قد تساعد في رفع الدرجات.';
  }

  @override
  String insightDefault(int accuracy, int quizzes) {
    return 'كانت الدقة $accuracy% خلال $quizzes اختبارات هذا الأسبوع. شجّع على جلسات دراسة أقصر وأكثر تركيزًا، وراجع أي مواضيع مُحددة كضعيفة في تبويب التمكن.';
  }

  @override
  String get noMasteryReportMessage => 'لا يوجد تقرير تمكن متاح.';

  @override
  String get totalAverageMasteryLabel => 'متوسط التمكن الإجمالي';

  @override
  String masteryScorePercentLabel(String percent) {
    return '$percent% درجة التمكن';
  }

  @override
  String get masteredLabel => 'متمكن';

  @override
  String get strongAreasTitle => '🔥 نقاط القوة';

  @override
  String get noStrongAreasMessage => 'لم يتم تحديد نقاط قوة بعد.';

  @override
  String get needsWorkAreasTitle => '⚠️ تحتاج إلى عمل';

  @override
  String get noWeakAreasMessage => 'لم يتم تحديد نقاط ضعف بعد.';

  @override
  String get errorAnalyticsTitle => 'تحليلات الأخطاء';

  @override
  String commonMistakeTypesLabel(String subject) {
    return 'أكثر أنواع الأخطاء شيوعًا في اختبارات $subject.';
  }

  @override
  String carelessMistakesLabel(int percent) {
    return 'أخطاء عدم الانتباه ($percent%)';
  }

  @override
  String get carelessMistakesDescription => 'الإجابة بسرعة كبيرة على الحسابات';

  @override
  String conceptGapsLabel(int percent) {
    return 'ثغرات في المفاهيم ($percent%)';
  }

  @override
  String get conceptGapsDescription => 'صعوبة في المواضيع المُقدمة حديثًا';

  @override
  String timePressureLabel(int percent) {
    return 'ضغط الوقت ($percent%)';
  }

  @override
  String get timePressureDescription => 'عدم الانتهاء ضمن مؤقت الاختبار';

  @override
  String get noHabitsReportMessage => 'لا يوجد تقرير عادات متاح.';

  @override
  String get currentStreakStatLabel => 'السلسلة الحالية';

  @override
  String get longestStreakStatLabel => 'أطول سلسلة';

  @override
  String daysCountLabel(int count) {
    return '$count أيام';
  }

  @override
  String get studyVsAppUsageTitle =>
      'وقت الدراسة مقابل استخدام التطبيقات المُراقبة';

  @override
  String get studyVsAppUsageSubtitle =>
      'قارن وقت التعلم النشط بالوقت المحظور على تطبيقات أخرى.';

  @override
  String get appUsageLegendLabel => 'استخدام التطبيقات';

  @override
  String get studyConsistencyGridTitle => 'شبكة استمرارية الدراسة';

  @override
  String get activeStudyDaysSubtitle =>
      'أيام الدراسة النشطة خلال آخر 4 أسابيع.';

  @override
  String get threeWeeksAgoLabel => 'قبل 3 أسابيع';

  @override
  String get twoWeeksAgoLabel => 'قبل أسبوعين';

  @override
  String get oneWeekAgoLabel => 'قبل أسبوع';

  @override
  String get thisWeekLabel => 'هذا الأسبوع';

  @override
  String get dayAbbrevMon => 'ن';

  @override
  String get dayAbbrevTue => 'ث';

  @override
  String get dayAbbrevWed => 'ر';

  @override
  String get dayAbbrevThu => 'خ';

  @override
  String get dayAbbrevFri => 'ج';

  @override
  String get dayAbbrevSat => 'س';

  @override
  String get dayAbbrevSun => 'ح';

  @override
  String get legendLessLabel => 'أقل';

  @override
  String get legendMoreLabel => 'أكثر';

  @override
  String studentProfileTitle(String name) {
    return 'ملف $name';
  }

  @override
  String get gradeUnknownLabel => 'الصف —';

  @override
  String get thisWeekSublabel => 'هذا الأسبوع';

  @override
  String get weeklyAvgSublabel => 'المتوسط الأسبوعي';

  @override
  String get dayStreakLabel => 'أيام متتالية';

  @override
  String get currentLabel => 'الحالي';

  @override
  String get manageSubjectsSubtitle => 'إدارة المواد وعرض تقدم المهارات';

  @override
  String get reportsAnalyticsNavTitle => 'التقارير والتحليلات';

  @override
  String get weeklyReportsSubtitle =>
      'التقارير الأسبوعية، اتجاهات الدقة، المواضيع الضعيفة';

  @override
  String get appConfigurationsTitle => 'إعدادات التطبيق';

  @override
  String get appConfigurationsSubtitle =>
      'مؤقتات البوابة، التطبيقات المراقبة، قواعد الاختبارات';

  @override
  String get permissionDisplayNameSystemAlertWindow =>
      'العرض فوق التطبيقات الأخرى';

  @override
  String get permissionDisplayNamePackageUsageStats =>
      'الوصول إلى بيانات الاستخدام';

  @override
  String get permissionDisplayNamePostNotifications => 'الإشعارات';

  @override
  String get permissionDisplayNameAccessibilityService => 'خدمة إمكانية الوصول';

  @override
  String get permissionDisplayNameDeviceAdmin => 'مسؤول الجهاز';

  @override
  String get permissionDisplayNameBatteryOptimization => 'تعطيل تحسين البطارية';

  @override
  String get permissionRationaleSystemAlertWindow =>
      'العرض فوق التطبيقات الأخرى مطلوب لإظهار تذكيرات الدراسة وتطبيق قواعد التطبيق أثناء استخدامك لتطبيقات أخرى.';

  @override
  String get permissionRationalePackageUsageStats =>
      'الوصول إلى بيانات الاستخدام مطلوب لتتبع وقت الشاشة وتطبيق حدود استخدام التطبيقات التي حددها ولي الأمر.';

  @override
  String get permissionRationalePostNotifications =>
      'الإشعارات مطلوبة لإرسال تذكيرات الدراسة والتنبيهات المهمة من ولي الأمر.';

  @override
  String get permissionRationaleAccessibilityService =>
      'خدمة إمكانية الوصول مطلوبة لمراقبة التطبيقات المفتوحة وتطبيق القواعد التي حددها ولي الأمر.';

  @override
  String get permissionRationaleDeviceAdmin =>
      'مسؤول الجهاز مطلوب لحماية التطبيق من إزالة التثبيت دون إذن ولي الأمر.';

  @override
  String get permissionRationaleBatteryOptimization =>
      'تعطيل تحسين البطارية يحافظ على عمل الخدمات الخلفية بشكل موثوق. بدون هذا، قد يقوم نظام أندرويد بإيقاف خدمات StudyMentor الخلفية على بعض الأجهزة، مما يؤدي إلى توقف المؤقتات وقواعد التطبيق عن العمل.';

  @override
  String get permissionParentRationalePostNotifications =>
      'يُرسل StudyMentor إشعارًا عندما يرتقي طفلك بمستواه، يحصل على شعار، أو لم يدرس منذ عدة أيام. يمكنك تغيير ذلك في أي وقت من الإعدادات.';

  @override
  String get permissionParentRationaleBatteryOptimization =>
      'لإشعارك بشكل موثوق بنشاط طفلك، يحتاج StudyMentor إلى العمل في الخلفية. بدون هذا، قد يؤخر أندرويد أو يفقد التنبيهات المهمة على بعض الأجهزة.';

  @override
  String stepOfTotalLabel(int step, int total) {
    return 'الخطوة $step من $total';
  }

  @override
  String permissionEnabledMessage(String permissionName) {
    return 'تم تفعيل $permissionName.';
  }

  @override
  String get permissionNotGrantedMessage =>
      'لم يتم منح الإذن بعد. اضغط على الزر أدناه لفتح الإعدادات.';

  @override
  String get openSettingsButton => 'فتح الإعدادات';

  @override
  String get postNotificationsHint =>
      'اسمح لـ StudyMentor بإرسال الإشعارات إليك.';

  @override
  String get batteryOptimizationHint =>
      'ابحث عن \"StudyMentor\"، اختر \"عدم التحسين\" أو \"غير مقيد\"، ثم قم بالتأكيد.';

  @override
  String get systemAlertWindowHint =>
      'ابحث عن \"StudyMentor\" وفعّل \"السماح بالعرض فوق التطبيقات الأخرى\".';

  @override
  String get packageUsageStatsHint =>
      'ابحث عن \"StudyMentor\" وفعّل إذن الوصول إلى الاستخدام.';

  @override
  String get accessibilityServiceHint =>
      'ضمن التطبيقات المثبتة، اختر \"StudyMentor\" وفعّله.';

  @override
  String get deviceAdminHint =>
      'اضغط على \"تفعيل تطبيق إدارة الجهاز هذا\" للتأكيد.';

  @override
  String get helpCenterTitle => 'مركز المساعدة';

  @override
  String get whatCanWeHelpWithTitle => 'بماذا يمكننا مساعدتك؟';

  @override
  String get issueAppNotWorking => 'التطبيق لا يعمل بشكل صحيح';

  @override
  String get issueQuizQuestionError => 'سؤال الاختبار يحتوي على خطأ';

  @override
  String get issueHowDoI => 'كيف يمكنني...؟';

  @override
  String get tellUsMoreTitle => 'أخبرنا بالمزيد';

  @override
  String needHelpGreeting(String name) {
    return 'هل تحتاج إلى مساعدة يا $name؟ أنا هنا من أجلك!';
  }

  @override
  String get describeIssueHint => 'صف مشكلتك هنا... سيساعدك فريقنا!';

  @override
  String charCounterLabel(int count) {
    return '$count/500';
  }

  @override
  String get sendToTeamButton => 'إرسال إلى الفريق';

  @override
  String get messageSentSuccessMessage =>
      'تم إرسال الرسالة! سيتواصل معك فريقنا قريبًا.';

  @override
  String get messageSendErrorMessage => 'تعذر إرسال رسالتك. حاول مرة أخرى.';

  @override
  String levelShortLabel(int level) {
    return 'المستوى $level';
  }

  @override
  String welcomeBackGreeting(String name) {
    return 'مرحبًا بعودتك، $name! ';
  }

  @override
  String get gardenGrowingMessage => 'حديقتك تنمو بشكل رائع!';

  @override
  String get gardenLoadErrorMessage =>
      'تعذر تحميل حديقتك. اسحب للأسفل لإعادة المحاولة.';

  @override
  String get askParentAddSubjectsMessage =>
      'اطلب من أحد والديك إضافة موادك الدراسية';

  @override
  String get owlEncouragementMessage =>
      'أحسنت اليوم! استمر في الدراسة لتساعد حديقتك على التزهر! 🌸';

  @override
  String get owlNameLabel => 'هوتي، صديقك في الدراسة';

  @override
  String streakDaysCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count أيام',
      one: 'يوم واحد',
    );
    return '$_temp0';
  }

  @override
  String get lessonsLabel => 'الدروس';

  @override
  String get streakLabel => 'التتابع';

  @override
  String get yourParentLabel => 'ولي أمرك';

  @override
  String get rulesConfiguredByParentMessage => 'القواعد التي حددها ولي أمرك.';

  @override
  String get screenTimeLabel => 'وقت الشاشة';

  @override
  String timeRemainingLabel(String time) {
    return '$time متبقي';
  }

  @override
  String usedTimeLabel(String time) {
    return 'المستخدم: $time';
  }

  @override
  String limitTimeLabel(String time) {
    return 'الحد: $time';
  }

  @override
  String cooldownAfterLimitLabel(String time) {
    return 'فترة الانتظار بعد الحد: $time';
  }

  @override
  String get onCooldownTitle => 'أنت في فترة انتظار! 😴';

  @override
  String get cooldownMessage => 'ستُفتح التطبيقات قريبًا. حان وقت الدراسة! 📚';

  @override
  String get remainingLabel => 'متبقي';

  @override
  String get parentRulesIntroMessage =>
      'وضع ولي أمرك هذه القواعد لجميع التطبيقات المقيدة:';

  @override
  String get noAppRulesSetMessage => 'لا توجد قواعد تطبيقات بعد.';

  @override
  String get noAppRulesDescriptionMessage =>
      'لم يقم ولي أمرك بتكوين أي قواعد لجهازك حتى الآن.';

  @override
  String get backTooltip => 'رجوع';

  @override
  String levelLabel(int level) {
    return 'المستوى $level';
  }

  @override
  String get myProgressTitle => 'تقدمي';

  @override
  String get totalXpLabel => 'إجمالي نقاط الخبرة';

  @override
  String get questionsLabel => 'الأسئلة';

  @override
  String get coinsAvailableLabel => 'عملة متاحة';

  @override
  String get appSettingsTitle => 'إعدادات التطبيق';

  @override
  String get appSettingsSubtitle => 'الإشعارات، الصوت';

  @override
  String get selectPdfFirstMessage => 'يرجى اختيار ملف PDF أولاً.';

  @override
  String get enterSubjectNameMessage => 'يرجى إدخال اسم المادة.';

  @override
  String get subjectAlreadyExistsMessage => 'هذه المادة موجودة بالفعل.';

  @override
  String get uploadingProcessingMessage => 'جارٍ الرفع والمعالجة…';

  @override
  String get uploadCurriculumDescription =>
      'قم برفع كتاب PDF لإنشاء اختبار تكيفي من محتواه.';

  @override
  String get subjectNameLabel => 'اسم المادة';

  @override
  String get subjectNameHint => 'مثال: الرياضيات، العلوم...';

  @override
  String get removeFileButton => 'إزالة الملف';

  @override
  String get tapToBrowsePdfMessage => 'اضغط لتصفح ملف PDF';

  @override
  String get onlyPdfSupportedMessage => 'يتم دعم ملفات PDF فقط';

  @override
  String get uploadAndIngestButton => 'رفع ومعالجة';

  @override
  String get curriculumAddedSuccessTitle => 'تمت إضافة المنهج بنجاح!';

  @override
  String curriculumAddedSuccessMessage(String subjectName) {
    return 'لقد أضفنا بنجاح \'$subjectName\' إلى لوحة التحكم الخاصة بك. يقوم الذكاء الاصطناعي الآن بمعالجة كتابك في الخلفية لإنشاء أسئلة الاختبار.';
  }

  @override
  String get uploadAnotherButton => 'رفع ملف آخر';

  @override
  String get studyQuizTitle => 'اختبار الدراسة';

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
    return 'تم تحديث مستوى التمكن في $subject!';
  }

  @override
  String get generatingQuizMessage => 'جارٍ إنشاء اختبارك…';

  @override
  String get submittingAnswersMessage => 'جارٍ إرسال الإجابات…';

  @override
  String get timeToPracticeTitle => 'حان وقت التدريب!';

  @override
  String get quizPromptMessage =>
      'انتهى وقت التركيز. لنقم باختبار سريع لتنشيط عقلك!';

  @override
  String get startQuizButton => 'ابدأ الاختبار';

  @override
  String get tailoredToLevelMessage => 'مصمم خصيصًا لمستواك الحالي';

  @override
  String get selectAnswerFirstMessage => 'يرجى اختيار إجابة أولاً.';

  @override
  String get noMoreHintsMessage => 'لا توجد تلميحات أخرى متاحة.';

  @override
  String hintNumberTitle(int number) {
    return 'تلميح $number';
  }

  @override
  String questionOfTotalLabel(int current, int total) {
    return 'السؤال $current من $total';
  }

  @override
  String answeredCountLabel(int count) {
    return '$count مُجابة';
  }

  @override
  String hintCountLabel(int count) {
    return 'تلميح ($count)';
  }

  @override
  String get submitButton => 'إرسال';

  @override
  String get nextButton => 'التالي';

  @override
  String get veryEasyLabel => 'سهل جدًا';

  @override
  String get easyLabel => 'سهل';

  @override
  String get mediumLabel => 'متوسط';

  @override
  String get hardLabel => 'صعب';

  @override
  String get veryHardLabel => 'صعب جدًا';

  @override
  String questionsCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count أسئلة',
      one: 'سؤال واحد',
    );
    return '$_temp0';
  }

  @override
  String get doneButton => 'تم';

  @override
  String get takeAnotherQuizButton => 'إجراء اختبار آخر';

  @override
  String get somethingWentWrongTitle => 'حدث خطأ ما';

  @override
  String get tryAgainButton => 'حاول مرة أخرى';

  @override
  String subjectGardenTitle(String subject) {
    return 'حديقة $subject';
  }

  @override
  String get loadSkillsErrorMessage =>
      'تعذر تحميل المهارات. يرجى الرجوع والمحاولة مرة أخرى.';

  @override
  String overallMasteryLabel(String percent) {
    return 'التمكن الكلي: $percent%';
  }

  @override
  String get skillsTitle => 'المهارات';

  @override
  String get strengthsTitle => 'نقاط القوة';

  @override
  String get needsPracticeTitle => 'يحتاج إلى تدريب';

  @override
  String get practiceNowButton => 'تدرب الآن';

  @override
  String get growthProgressTitle => 'تقدم النمو';

  @override
  String levelNumberLabel(int level) {
    return 'المستوى $level';
  }

  @override
  String get maxLevelBadge => 'الحد الأقصى ✨';

  @override
  String get maxLevelReachedMessage => 'لقد وصلت إلى المستوى الأقصى! 🌟';

  @override
  String percentMoreToLevelMessage(String percent, int level) {
    return '$percent% أخرى للوصول إلى المستوى $level!';
  }

  @override
  String get flourishingLabel => 'مزدهر';

  @override
  String get masteryGrowingWellLabel => 'ينمو بشكل جيد';

  @override
  String get masteryMakingProgressLabel => 'يحقق تقدمًا';

  @override
  String get masteryJustStartedLabel => 'بدأ للتو';

  @override
  String get masteryNotStartedYetLabel => 'لم يبدأ بعد';

  @override
  String get growthStageSeed => 'بذرة';

  @override
  String get growthStageSprout => 'برعم';

  @override
  String get growthStageSapling => 'شتلة';

  @override
  String get growthStageGrowing => 'ينمو';

  @override
  String masteryAttemptsLabel(String percent, int attempts) {
    return '$percent% تمكن  ·  $attempts محاولة';
  }

  @override
  String get skillNotStartedLabel => 'لم يبدأ بعد';

  @override
  String get avatarShopTitle => 'متجر الصور الرمزية';

  @override
  String get categoryHairStyle => 'تصفيفة الشعر';

  @override
  String get categoryOutfit => 'الملابس';

  @override
  String get categoryHairColor => 'لون الشعر';

  @override
  String get categoryOutfitColor => 'لون الملابس';

  @override
  String get categoryAccessory => 'إكسسوار';

  @override
  String get categoryFacialHair => 'شعر الوجه';

  @override
  String get categoryBeardColor => 'لون اللحية';

  @override
  String get categoryEyes => 'العيون';

  @override
  String get categoryEyebrows => 'الحواجب';

  @override
  String get categoryMouth => 'الفم';

  @override
  String get categorySkinTone => 'لون البشرة';

  @override
  String unlocksAtLevelMessage(int level) {
    return 'يُفتح عند المستوى $level';
  }

  @override
  String notEnoughCoinsMessage(int amount) {
    return 'لا توجد عملات كافية! تحتاج إلى $amount عملة إضافية.';
  }

  @override
  String buyItemTitle(String itemName) {
    return 'شراء $itemName؟';
  }

  @override
  String itemCostMessage(int price) {
    return 'سيكلف هذا $price عملة.';
  }

  @override
  String get buyButton => 'شراء';

  @override
  String get levelUpTitle => '🎉 ترقية المستوى!';

  @override
  String levelUpSubtitleMessage(int level) {
    return 'لقد وصلت إلى المستوى $level! استمر في الدراسة لتصبح أقوى! 🌱';
  }

  @override
  String get awesomeButton => 'رائع!';

  @override
  String get streakMilestoneOnARoll => 'في طريقك للنجاح!';

  @override
  String get streakMilestoneWeekWarrior => 'محارب الأسبوع!';

  @override
  String get streakMilestoneFortnightFocus => 'تركيز أسبوعين!';

  @override
  String get streakMilestoneMonthlyMaster => 'سيد الشهر!';

  @override
  String get streakMilestoneGeneric => 'إنجاز متتالي!';

  @override
  String streakMilestoneDescriptionMessage(int days) {
    return 'لقد حققت سلسلة تعلم لمدة $days يومًا!\nواستمر!';
  }

  @override
  String coinsRewardLabel(int coins) {
    return '+$coins عملة';
  }

  @override
  String get aiSummaryNotAvailableMessage => 'ملخص الذكاء الاصطناعي غير متوفر.';

  @override
  String get aiDailySummaryTitle => '✨ الملخص اليومي';

  @override
  String get smartInsightsLabel => 'رؤى ذكية';

  @override
  String get notificationsTitle => 'الإشعارات';

  @override
  String get markAllAsReadButton => 'تحديد الكل كمقروء';

  @override
  String get allCaughtUpTitle => 'أنت على اطلاع بكل شيء';

  @override
  String get allCaughtUpMessage =>
      'أنت على اطلاع بكل شيء! ستظهر تنبيهات النشاط هنا.';

  @override
  String minutesAgoLabel(int minutes) {
    return 'قبل $minutes د';
  }

  @override
  String hoursAgoLabel(int hours) {
    return 'قبل $hours س';
  }

  @override
  String daysAgoLabel(int days) {
    return 'قبل $days ي';
  }

  @override
  String get xpLabel => 'خبرة';

  @override
  String get coinsLabel => 'عملات';

  @override
  String get unverifiedLabel => 'غير مُفعّل';

  @override
  String get waitingForVerificationMessage =>
      'في انتظار تفعيل الطالب لبريده الإلكتروني وتسجيل الدخول لأول مرة.';

  @override
  String get firstLoginCoinsRewardMessage =>
      'ستُمنح 3 عملات عند أول تسجيل دخول';

  @override
  String get weeklyAccuracyLabel => 'الدقة الأسبوعية';

  @override
  String get navMyStudentsLabel => 'أبنائي';

  @override
  String get navHelpLabel => 'المساعدة';

  @override
  String get navHomeLabel => 'الرئيسية';

  @override
  String get navShopLabel => 'المتجر';

  @override
  String get noGradeLabel => 'بدون صف';

  @override
  String get tapToViewLabel => 'اضغط للعرض';

  @override
  String get awaitingEmailVerificationLabel =>
      'في انتظار تفعيل البريد الإلكتروني';

  @override
  String xpAmountLabel(int xp) {
    return '$xp خبرة';
  }

  @override
  String questionsAttemptedLabel(int total) {
    return 'الأسئلة المُحاولة ($total)';
  }

  @override
  String get correctLabel => 'صحيح';

  @override
  String get incorrectLabel => 'غير صحيح';

  @override
  String questionNumberLabel(int number) {
    return 'السؤال $number';
  }

  @override
  String get parentVerificationRequiredTitle => 'مطلوب تحقق من ولي الأمر';

  @override
  String get logoutParentCredentialsMessage =>
      'لتسجيل الخروج، يرجى إدخال بيانات اعتماد ولي الأمر.';

  @override
  String get parentEmailLabel => 'البريد الإلكتروني لولي الأمر';

  @override
  String get parentPasswordLabel => 'كلمة مرور ولي الأمر';

  @override
  String get verifyAndLogOutButton => 'تحقق وتسجيل الخروج';

  @override
  String xpRewardLabel(int xp) {
    return '+$xp خبرة';
  }

  @override
  String notifLevelUpTitle(int level) {
    return 'لقد وصلت إلى المستوى $level! 🎓';
  }

  @override
  String get notifLevelUpBody =>
      'أحسنت! المزيد من المكافآت في انتظارك بالمستوى التالي.';

  @override
  String notifParentLevelUpTitle(String studentName, int level) {
    return '$studentName وصل إلى المستوى $level! 🎓';
  }

  @override
  String get notifParentLevelUpBody => 'لقد كان مجتهدًا. تابع تقدمه الآن.';

  @override
  String notifStreakMilestoneTitle(int streak) {
    return 'سلسلة $streak يوم متتالية! 🔥';
  }

  @override
  String notifStreakMilestoneBody(int streak) {
    return 'لقد ذاكرت $streak يوم متتالي. حافظ على حماسك!';
  }

  @override
  String get notifNearMilestoneTitle => 'يوم واحد فقط! 🔥';

  @override
  String notifNearMilestoneBody(int nextMilestone) {
    return 'استمر — مكافأة سلسلة $nextMilestone يوم في انتظارك غدًا.';
  }

  @override
  String get notifStreakReminderTitle => 'لا تكسر سلسلتك! 🔥';

  @override
  String notifStreakReminderBody(int streak) {
    return 'اختبار واحد فقط يحافظ على سلسلتك من $streak يوم.';
  }

  @override
  String get notifStartStreakTitle => 'ابدأ سلسلة جديدة اليوم!';

  @override
  String get notifStartStreakBody =>
      'أنجز اختبارًا سريعًا وابدأ سلسلة مذاكرتك.';

  @override
  String notifParentStreakBrokenTitle(String studentName) {
    return 'انتهت سلسلة $studentName';
  }

  @override
  String notifParentStreakBrokenBody(int previousStreak) {
    return 'انقطعت سلسلته البالغة $previousStreak يوم. قد يساعده القليل من التشجيع.';
  }

  @override
  String notifGardenNudgeTitle(String subject) {
    return 'نبتة $subject بحاجة إليك 🌱';
  }

  @override
  String notifGardenNudgeBody(String subject) {
    return 'مرت أيام قليلة — تعال واسقِ حديقة $subject!';
  }

  @override
  String notifInactivityTitle(String studentName) {
    return '$studentName لم يحل أي اختبار منذ 3 أيام';
  }

  @override
  String get notifInactivityBody =>
      'قد يساعده القليل من التشجيع على العودة إلى المسار الصحيح.';

  @override
  String notifParentStreakMilestoneTitle(String studentName, int streak) {
    return '$studentName وصل إلى سلسلة $streak يوم! 🔥';
  }

  @override
  String get notifParentStreakMilestoneBody =>
      'إنهم في حالة رائعة — استمر في التشجيع!';

  @override
  String get parentNotifPerStudentSection => 'الطلاب';

  @override
  String get parentStudentNotifAllLabel => 'جميع إشعارات هذا الطالب';

  @override
  String get parentNotifNoStudentsLinked => 'لا يوجد طلاب مرتبطون بعد.';

  @override
  String get managePreferencesButton => 'إدارة التفضيلات';

  @override
  String get parentPreferencesTitle => 'التفضيلات';

  @override
  String get parentNotificationsSection => 'الإشعارات';

  @override
  String get parentNotifProgressLabel => 'تنبيهات تقدم الطفل';

  @override
  String get parentNotifProgressSubtitle => 'الترقيات وإنجازات الشارات';

  @override
  String get parentNotifStreakLabel => 'تنبيهات السلاسل';

  @override
  String get parentNotifStreakSubtitle => 'إنجازات السلاسل وانقطاعها';

  @override
  String get parentNotifInactivityLabel => 'تذكيرات عدم النشاط';

  @override
  String get parentNotifInactivitySubtitle =>
      'تنبيهات عندما لا يدرس الطفل لمدة 3 أيام أو أكثر';

  @override
  String get errInvalidCredentials =>
      'البريد الإلكتروني أو كلمة المرور غير صحيحة. يرجى المحاولة مرة أخرى.';

  @override
  String get errNetworkError => 'خطأ في الشبكة. تحقق من اتصالك.';

  @override
  String get errNetworkErrorRetry =>
      'خطأ في الشبكة. تحقق من اتصالك وحاول مرة أخرى.';

  @override
  String get errWeakPassword => 'كلمة المرور ضعيفة جدًا.';

  @override
  String get errWeakPasswordDetailed =>
      'كلمة المرور ضعيفة جدًا. يرجى استخدام 6 أحرف على الأقل.';

  @override
  String get errEmailAlreadyInUse =>
      'هذا البريد الإلكتروني مسجل بالفعل. يرجى استخدام عنوان آخر.';

  @override
  String get errInvalidEmailFormat =>
      'هذا البريد الإلكتروني لا يبدو صحيحًا. يرجى التحقق منه.';

  @override
  String get errSessionExpired =>
      'انتهت جلستك. يرجى تسجيل الخروج وإعادة تسجيل الدخول.';

  @override
  String get errTooManyAttempts =>
      'محاولات كثيرة جدًا. يرجى الانتظار قليلاً والمحاولة مرة أخرى.';

  @override
  String get errRegistrationFailed => 'فشل التسجيل. يرجى المحاولة مرة أخرى.';

  @override
  String get errNoSignedInAccount =>
      'لم يتم العثور على حساب مسجل. يرجى تسجيل الدخول مرة أخرى.';

  @override
  String get errVerificationEmailFailed =>
      'تعذر إرسال بريد التحقق. يرجى المحاولة مرة أخرى.';

  @override
  String get errWrongCurrentPassword => 'كلمة المرور الحالية غير صحيحة.';

  @override
  String get errNewPasswordTooWeak =>
      'كلمة المرور الجديدة ضعيفة. استخدم 6 أحرف على الأقل.';

  @override
  String get errEmailAlreadyInUseOther =>
      'هذا البريد الإلكتروني مستخدم من قِبل حساب آخر.';

  @override
  String get errUpdateFailed => 'فشل التحديث. يرجى المحاولة مرة أخرى.';

  @override
  String get errUploadFailed => 'فشل الرفع. يرجى المحاولة مرة أخرى.';

  @override
  String get errSubjectStillProcessing =>
      'لا يزال مستند هذه المادة قيد التجهيز. يرجى الانتظار حتى ينتهي قبل رفع مستند آخر.';

  @override
  String get subjectPreparingLabel => 'جارٍ تجهيز المادة…';

  @override
  String get subjectStageParsing => 'جارٍ قراءة المستند…';

  @override
  String get subjectStageAnalyzing => 'جارٍ تحليل المحتوى…';

  @override
  String get subjectStageBuildingSkills => 'جارٍ بناء شجرة المهارات…';

  @override
  String get subjectPreparingPracticeDisabled => 'جارٍ التجهيز…';

  @override
  String get subjectIngestFailed =>
      'تعذر معالجة هذا المستند. يرجى محاولة رفعه مرة أخرى.';

  @override
  String get quizSubjectStillPreparing =>
      'لا تزال هذه المادة قيد التجهيز. يرجى المحاولة بعد قليل.';

  @override
  String get errDeleteAccountFailed =>
      'تعذر حذف الحساب. يرجى المحاولة مرة أخرى.';

  @override
  String get errStudentSessionExpired =>
      'انتهت جلستك. يرجى تسجيل الخروج وإعادة تسجيل الدخول قبل إضافة طالب.';

  @override
  String get errStudentEmailAlreadyRegistered =>
      'هذا البريد الإلكتروني مسجل بالفعل. جرّب تسجيل الدخول أو إعادة تعيين كلمة المرور.';

  @override
  String get errStudentWeakPassword =>
      'كلمة المرور المُدخلة ضعيفة جدًا. يرجى استخدام 6 أحرف على الأقل.';

  @override
  String get errStudentInvalidEmail => 'صيغة البريد الإلكتروني غير صحيحة.';

  @override
  String get errUnexpected => 'حدث خطأ غير متوقع. يرجى المحاولة مرة أخرى.';

  @override
  String get shopItemPurchasedMessage => 'تمت عملية الشراء بنجاح! 🎉';

  @override
  String get errPurchaseFailed => 'فشلت عملية الشراء. يرجى المحاولة مرة أخرى.';
}
