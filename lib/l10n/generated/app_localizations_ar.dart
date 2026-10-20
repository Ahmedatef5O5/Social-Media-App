// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get settingsTitle => 'الإعدادات';

  @override
  String get settingsSubtitle => 'إدارة تفضيلاتك';

  @override
  String get settingsSectionAccount => 'الحساب';

  @override
  String get settingsSectionNotifications => 'الإشعارات';

  @override
  String get settingsSectionPrivacy => 'الخصوصية';

  @override
  String get settingsSectionAi => 'الذكاء الاصطناعي';

  @override
  String get settingsSectionAppearance => 'المظهر';

  @override
  String get settingsSectionSupport => 'الدعم';

  @override
  String get settingsEditProfile => 'تعديل الملف الشخصي';

  @override
  String get settingsEditProfileSubtitle => 'حدّث بياناتك وصورتك';

  @override
  String get settingsChangePassword => 'تغيير كلمة المرور';

  @override
  String get settingsChangePasswordSubtitle => 'حدّث كلمة مرور حسابك';

  @override
  String get settingsEmailAddress => 'البريد الإلكتروني';

  @override
  String get settingsEmailAddressSubtitle => 'إدارة البريد الإلكتروني المرتبط';

  @override
  String get settingsPushNotifications => 'الإشعارات الفورية';

  @override
  String get settingsPushNotificationsSubtitle => 'تفعيل جميع الإشعارات';

  @override
  String get settingsMessagePreviews => 'معاينة الرسائل';

  @override
  String get settingsMessagePreviewsSubtitle => 'إظهار المحتوى في الإشعارات';

  @override
  String get settingsCallNotifications => 'إشعارات المكالمات';

  @override
  String get settingsCallNotificationsSubtitle => 'تنبيهات المكالمات الواردة';

  @override
  String get settingsReadReceipts => 'مؤشرات قراءة الرسائل';

  @override
  String get settingsReadReceiptsSubtitle => 'أظهر للآخرين أنك قرأت رسائلهم';

  @override
  String get settingsOnlineStatus => 'حالة الاتصال';

  @override
  String get settingsOnlineStatusSubtitle =>
      'دع الآخرين يعرفون متى تكون متصلاً';

  @override
  String get settingsOnlineStatusVisibility => 'ظهور حالة الاتصال';

  @override
  String get presenceEveryone => 'الجميع';

  @override
  String get presenceFriends => 'أصدقائي';

  @override
  String get presenceSpecific => 'أشخاص محددون';

  @override
  String get presenceNobody => 'لا أحد';

  @override
  String get settingsAppLock => 'قفل التطبيق';

  @override
  String get settingsAppLockSubtitle =>
      'اطلب بصمة الإصبع أو Face ID لفتح التطبيق';

  @override
  String get settingsTwoFactor => 'المصادقة الثنائية';

  @override
  String get settingsTwoFactorOffSubtitle => 'طبقة أمان إضافية';

  @override
  String get settingsTwoFactorOnAuthenticator => 'مفعّلة • تطبيق المصادقة';

  @override
  String settingsTwoFactorOnRecoveryCodes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'متبقٍ $count رمز استرداد',
      many: 'متبقٍ $count رمز استرداد',
      few: 'متبقٍ $count رموز استرداد',
      two: 'متبقٍ رمزا استرداد',
      one: 'متبقٍ رمز استرداد واحد',
      zero: 'لا توجد رموز استرداد متبقية',
    );
    return 'مفعّلة • $_temp0';
  }

  @override
  String get settingsBlockedUsers => 'المستخدمون المحظورون';

  @override
  String get settingsBlockedUsersSubtitle => 'إدارة الحسابات المحظورة';

  @override
  String get settingsAiSettings => 'إعدادات الذكاء الاصطناعي';

  @override
  String get settingsAiSettingsSubtitle =>
      'خصّص تجربتك المدعومة بالذكاء الاصطناعي';

  @override
  String get settingsTheme => 'السمة';

  @override
  String get settingsThemeSubtitle => 'خصّص ألوان تطبيقك';

  @override
  String get language => 'اللغة';

  @override
  String get languageSheetSubtitle => 'اختر اللغة المستخدمة في التطبيق';

  @override
  String get settingsAboutUs => 'من نحن';

  @override
  String get settingsAboutUsSubtitle => 'قصتنا ورسالتنا';

  @override
  String get settingsHelpFaq => 'المساعدة والأسئلة الشائعة';

  @override
  String get settingsHelpFaqSubtitle => 'احصل على إجابات للأسئلة الشائعة';

  @override
  String get settingsSendFeedback => 'إرسال ملاحظة';

  @override
  String get settingsSendFeedbackSubtitle => 'شاركنا رأيك';

  @override
  String get settingsPrivacyPolicy => 'سياسة الخصوصية';

  @override
  String get settingsPrivacyPolicySubtitle => 'كيف نتعامل مع بياناتك';

  @override
  String get settingsTermsOfService => 'شروط الخدمة';

  @override
  String get settingsTermsOfServiceSubtitle => 'قواعد المنصة وإرشادات المجتمع';

  @override
  String get dangerZone => 'منطقة الخطر';

  @override
  String get logOut => 'تسجيل الخروج';

  @override
  String get logOutSubtitle => 'تسجيل الخروج من حسابك';

  @override
  String get loggedOutSuccessfully => 'تم تسجيل الخروج بنجاح';

  @override
  String get deleteAccount => 'حذف الحساب';

  @override
  String get deleteAccountSubtitle => 'حذف حسابك نهائيًا';

  @override
  String get deleteAccountConfirmation =>
      'هل أنت متأكد أنك تريد حذف حسابك؟ هذا الإجراء نهائي ولا يمكن التراجع عنه.';

  @override
  String get cancel => 'إلغاء';

  @override
  String get settingsErrorPrivacyUpdate => 'تعذّر تحديث إعداد الخصوصية.';

  @override
  String get settingsErrorVisibilityUpdate => 'تعذّر تحديث قائمة الظهور.';

  @override
  String get settingsErrorIdentityNotVerified =>
      'لم يتم التحقق من هويتك، يُرجى المحاولة مرة أخرى.';

  @override
  String get settingsErrorBiometricNoHardware =>
      'لا يحتوي هذا الجهاز على مستشعر بصمة أو Face ID، لذا فإن قفل التطبيق غير متاح.';

  @override
  String get settingsErrorBiometricNotEnrolled =>
      'لم يتم إعداد بصمة أو Face ID على هذا الجهاز بعد. أضف واحدة من إعدادات الجهاز ثم حاول مجددًا.';

  @override
  String get settingsErrorBiometricLockedOut =>
      'محاولات فاشلة كثيرة. يُرجى الانتظار قليلًا قبل المحاولة مجددًا.';

  @override
  String get settingsErrorBiometricPermanentlyLockedOut =>
      'المصادقة الحيوية مقفلة. افتح قفل جهازك أولًا باستخدام PIN أو النمط أو كلمة المرور.';

  @override
  String get settingsErrorBiometricPasscodeNotSet =>
      'عيّن قفل شاشة (PIN أو نمط أو كلمة مرور) على جهازك قبل تفعيل قفل التطبيق.';

  @override
  String get settingsErrorBiometricUnknown =>
      'تعذّر التحقق من إعدادات المصادقة الحيوية على جهازك. يُرجى المحاولة مرة أخرى.';

  @override
  String get themesTitle => 'المظهر';

  @override
  String get themesSubtitle =>
      'اختر مظهرًا يعبّر عنك. تُطبَّق التغييرات فورًا.';

  @override
  String get themeNameOcean => 'المحيط';

  @override
  String get themeNameSunset => 'الغروب';

  @override
  String get themeNameForest => 'الغابة';

  @override
  String get themeNameMidnight => 'منتصف الليل';

  @override
  String get themeNameGold => 'ذهبي';

  @override
  String get themeNameGlass => 'زجاجي';

  @override
  String get themeNameLavender => 'الخزامى';

  @override
  String get themeNameCarbon => 'الكربون';

  @override
  String get themeNameEmerald => 'الزمرد';

  @override
  String get themeNameNordic => 'الشمال';

  @override
  String get themeNameGrape => 'العنب';

  @override
  String get themeNameSahara => 'الصحراء';

  @override
  String get connectivityOffline => 'لا يوجد اتصال بالإنترنت';

  @override
  String get connectivityRestored => 'عاد الاتصال بالإنترنت';

  @override
  String get callOngoingTitle => 'مكالمة جارية';

  @override
  String get callReturnHint => 'اضغط للعودة إلى المكالمة';

  @override
  String get gallery => 'المعرض';

  @override
  String get video => 'فيديو';

  @override
  String get file => 'ملف';

  @override
  String get voice => 'صوت';

  @override
  String get sticker => 'ملصق';

  @override
  String get camera => 'الكاميرا';

  @override
  String get resume => 'استئناف';

  @override
  String get slideToCancel => 'اسحب للإلغاء';

  @override
  String get archivedChats => 'المحادثات المؤرشفة';

  @override
  String get noArchivedChats => 'لا توجد محادثات مؤرشفة.';

  @override
  String get messageInfo => 'معلومات الرسالة';

  @override
  String get voiceNote => 'رسالة صوتية';

  @override
  String get reportMessage => 'الإبلاغ عن الرسالة';

  @override
  String get reportSpamAbusiveContent =>
      'أبلغ عن الرسائل المزعجة أو المسيئة أو غير اللائقة';

  @override
  String get growYourNetwork => 'وسّع شبكتك';

  @override
  String get youHaventAddedAny =>
      'لم تضف أي جهات اتصال بعد.\nاكتشف أشخاصًا بالقرب منك أو تصفّح الحسابات المقترحة لتبدأ المحادثة.';

  @override
  String get discoverPeople => 'اكتشف أشخاصًا';

  @override
  String get newChat => 'محادثة جديدة';

  @override
  String get searchFriendsGroups => 'ابحث عن الأصدقاء والمجموعات...';

  @override
  String get sharedMedia => 'الوسائط المشتركة';

  @override
  String get starredMessages => 'الرسائل المميزة بنجمة';

  @override
  String get searchMessages => 'البحث في الرسائل';

  @override
  String get couldntOpenThatFile => 'تعذّر فتح هذا الملف.';

  @override
  String get noLinksSharedYet => 'لا توجد روابط مشتركة بعد';

  @override
  String get group => 'مجموعة';

  @override
  String get selected => 'محدد';

  @override
  String get mediaLinksAndDocs => 'الوسائط والروابط والمستندات';

  @override
  String get seeAll => 'عرض الكل';

  @override
  String get previewNotAvailable => 'المعاينة غير متاحة';

  @override
  String get couldNotTrimThis => 'تعذّر قص هذا الفيديو. حاول مرة أخرى.';

  @override
  String get trimVideo => 'قص الفيديو';

  @override
  String get done => 'تم';

  @override
  String get trimming => 'جارٍ القص…';

  @override
  String get couldNotLoadThis => 'تعذّر تحميل هذا الفيديو.';

  @override
  String get searching => 'جارٍ البحث...';

  @override
  String get noUsersFound => 'لم يتم العثور على مستخدمين';

  @override
  String get whoCanSeeYour => 'من يمكنه رؤية حالة اتصالك';

  @override
  String get thisControlsYourGreen =>
      'يتحكم هذا في النقطة الخضراء و“آخر ظهور” في كل أنحاء التطبيق.';

  @override
  String get lastSeenRecently => 'آخر ظهور منذ قليل';

  @override
  String get online => 'متصل';

  @override
  String get yourProfileIsStill =>
      'ملفك الشخصي ما زال قيد التحميل، حاول بعد لحظات.';

  @override
  String get storiesDontSupportDocuments => 'القصص لا تدعم المستندات بعد.';

  @override
  String get aiDoesntSupportVideo => 'الذكاء الاصطناعي لا يدعم الفيديو بعد';

  @override
  String get shareToStory => 'المشاركة في القصة';

  @override
  String get createPost => 'إنشاء منشور';

  @override
  String get askSyncraAi => 'اسأل Syncra AI';

  @override
  String get recentChats => 'المحادثات الأخيرة';

  @override
  String get noConversationsYet => 'لا توجد محادثات بعد';

  @override
  String get sendTo => 'إرسال إلى...';

  @override
  String get linkCopied => 'تم نسخ الرابط';

  @override
  String get failedToForwardTry => 'تعذّرت إعادة التوجيه. حاول مرة أخرى.';

  @override
  String get copyLink => 'نسخ الرابط';

  @override
  String get forwardToChat => 'إعادة التوجيه إلى محادثة';

  @override
  String get shareVia => 'المشاركة عبر...';

  @override
  String get pleaseEndYourCurrent =>
      'يرجى إنهاء مكالمتك الحالية قبل بدء مكالمة أخرى.';

  @override
  String get areYouSureYou => 'هل أنت متأكد أنك تريد الخروج؟';

  @override
  String get edit => 'تعديل';

  @override
  String get saveToGallery => 'الحفظ في المعرض';

  @override
  String get whatWeOffer => 'ما نقدّمه';

  @override
  String get builtMaintainedBy => 'تطوير وصيانة';

  @override
  String get connectWithUs => 'تواصل معنا';

  @override
  String get connectingPeopleBuildingCommunities =>
      'نربط الناس ونبني المجتمعات';

  @override
  String get ourMission => 'مهمتنا';

  @override
  String get weBelieveMeaningfulConnections =>
      'نؤمن بأن العلاقات الحقيقية تغيّر الحياة. بُنيت منصتنا لتقرّب الناس من بعضهم — عبر المحادثات واللحظات المشتركة وتجارب مباشرة تعني الكثير.';

  @override
  String get website => 'الموقع الإلكتروني';

  @override
  String get portfolio => 'الأعمال';

  @override
  String get email => 'البريد الإلكتروني';

  @override
  String get version100 => 'الإصدار 1.0.0  •  صُنع بحب ❤️';

  @override
  String get theSmartReplyTo =>
      'خدمة الرد الذكي على الصور مشغولة حاليًا. حاول لاحقًا أو اكتب ردك يدويًا.';

  @override
  String get anErrorOccurredWith =>
      'حدث خطأ في اقتراح الذكاء الاصطناعي. حاول مرة أخرى.';

  @override
  String get copiedSuccessfully => 'تم النسخ بنجاح';

  @override
  String get copy => 'نسخ';

  @override
  String get todaysAiUsage => 'استخدام الذكاء الاصطناعي اليوم';

  @override
  String get estimated => 'تقديري';

  @override
  String get failedToDeleteThis => 'تعذّر حذف هذه المحادثة. حاول مرة أخرى.';

  @override
  String get failedToForwardPlease => 'تعذّرت إعادة التوجيه. حاول مرة أخرى.';

  @override
  String get theresNoTextTo => 'لا يوجد نص لمشاركته في هذا التحديد.';

  @override
  String get copiedToClipboard => 'تم النسخ إلى الحافظة';

  @override
  String get image => 'صورة';

  @override
  String get translate => 'ترجمة';

  @override
  String get audioChat => 'محادثة صوتية';

  @override
  String get chatFiles => 'ملفات المحادثة';

  @override
  String get stillGettingSyncraReady =>
      'ما زلنا نجهّز Syncra — حاول بعد لحظات.';

  @override
  String get failedToSendYour => 'تعذّر إرسال رسالتك. حاول مرة أخرى.';

  @override
  String get couldntLoadThatPhoto => 'تعذّر تحميل هذه الصورة. حاول مرة أخرى.';

  @override
  String get addACaption => 'أضف شرحًا توضيحيًا...';

  @override
  String get howCanIHelp => 'كيف يمكنني مساعدتك؟';

  @override
  String get voiceDictationIsntAvailable =>
      'الإملاء الصوتي غير متاح على هذا الجهاز.';

  @override
  String get messageSyncra => 'راسل Syncra...';

  @override
  String get failedToShareThis => 'تعذّرت مشاركة هذه المحادثة. حاول مرة أخرى.';

  @override
  String get loadMore => 'تحميل المزيد';

  @override
  String get chooseAModel => 'اختر نموذجًا';

  @override
  String get backToLogin => 'العودة لتسجيل الدخول';

  @override
  String get aLinkWasJust =>
      'تم إرسال رابط إلى هذا العنوان للتو. يرجى الانتظار.';

  @override
  String get forgotPassword => 'هل نسيت كلمة المرور؟';

  @override
  String get enterYourRegisteredEmail =>
      'أدخل بريدك الإلكتروني المسجّل وسنرسل لك رابط الاستعادة.';

  @override
  String get changeEmail => 'تغيير البريد الإلكتروني';

  @override
  String get enterYourEmail => 'أدخل بريدك الإلكتروني';

  @override
  String get ifAnAccountExists =>
      'إذا كان هناك حساب مرتبط بهذا البريد، فقد أرسلنا لك رابط إعادة تعيين كلمة المرور.';

  @override
  String get returnToLogin => 'العودة إلى تسجيل الدخول';

  @override
  String get theRecoverySessionIs =>
      'جلسة الاستعادة غير صالحة أو منتهية. يرجى طلب رابط جديد.';

  @override
  String get createNewPassword => 'إنشاء كلمة مرور جديدة';

  @override
  String get yourNewPasswordMust =>
      'يجب ألا تقل كلمة المرور الجديدة عن 6 أحرف.';

  @override
  String get newPassword => 'كلمة المرور الجديدة';

  @override
  String get enterNewPassword => 'أدخل كلمة المرور الجديدة';

  @override
  String get confirmPassword => 'تأكيد كلمة المرور';

  @override
  String get reEnterYourPassword => 'أعد إدخال كلمة المرور';

  @override
  String get passwordUpdatedSuccessfully => 'تم تحديث كلمة المرور بنجاح';

  @override
  String get enterEmail => 'أدخل البريد الإلكتروني';

  @override
  String get password => 'كلمة المرور';

  @override
  String get enterPassword => 'أدخل كلمة المرور';

  @override
  String get loginSuccessfully => 'تم تسجيل الدخول بنجاح';

  @override
  String get orSignInWith => 'أو سجّل الدخول باستخدام';

  @override
  String get fullName => 'الاسم الكامل';

  @override
  String get yourFullName => 'اسمك الكامل';

  @override
  String get enterNewEmail => 'أدخل البريد الإلكتروني الجديد';

  @override
  String get typeYourPassword => 'اكتب كلمة المرور';

  @override
  String get retypeYourPassword => 'أعد كتابة كلمة المرور';

  @override
  String get signUpSuccessfully => 'تم إنشاء الحساب بنجاح';

  @override
  String get orSignUpWith => 'أو أنشئ حسابًا باستخدام';

  @override
  String get facebookLogInIs =>
      'تسجيل الدخول عبر Facebook في وضع التطوير (لحسابات الاختبار والمسؤولين فقط). هل تريد المتابعة؟';

  @override
  String get continueLabel => 'متابعة';

  @override
  String get unblockUser => 'إلغاء حظر المستخدم';

  @override
  String get unblock => 'إلغاء الحظر';

  @override
  String get manageTheAccountsYouve => 'إدارة الحسابات التي حظرتها';

  @override
  String get blocked => 'محظور';

  @override
  String get searchPeopleOrGroups => 'ابحث عن أشخاص أو مجموعات...';

  @override
  String get askTheAiAssistant => 'اسأل المساعد الذكي عن هذا';

  @override
  String get editingComment => 'تعديل التعليق';

  @override
  String get voice2 => '🎤 رسالة صوتية';

  @override
  String get photo => 'صورة';

  @override
  String get close => 'إغلاق';

  @override
  String get recordingVoiceMessage => 'جارٍ تسجيل رسالة صوتية';

  @override
  String get delete => 'حذف';

  @override
  String get report => 'إبلاغ';

  @override
  String get deleteThisComment => 'هل تريد حذف هذا التعليق؟';

  @override
  String get commentDeletedSuccessfully => 'تم حذف التعليق بنجاح';

  @override
  String get youMentionedYourselfIn => 'لقد أشرت إلى نفسك في هذا التعليق';

  @override
  String get edited => '· تم التعديل';

  @override
  String get reply => 'رد';

  @override
  String get comments => 'التعليقات';

  @override
  String get noCommentsYet => 'لا توجد تعليقات بعد.';

  @override
  String get searchPeople => 'ابحث عن أشخاص...';

  @override
  String get tryADifferentName => 'جرّب اسمًا أو اسم مستخدم مختلفًا';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get peopleYouMayKnow => 'أشخاص قد تعرفهم';

  @override
  String get somethingWentWrongPlease => 'حدث خطأ ما. حاول مرة أخرى.';

  @override
  String get accept => 'قبول';

  @override
  String get friends => 'الأصدقاء';

  @override
  String get followsYou => 'يتابعك';

  @override
  String get couldNotLoadThe => 'تعذّر تحميل الصورة.';

  @override
  String get responseWithin24Hours => 'الرد خلال 24 ساعة (بحد أقصى 3 أيام).';

  @override
  String get yourMessage => 'رسالتك';

  @override
  String get ourTeamHasReviewed =>
      'راجع فريقنا هذه الملاحظة. شكرًا لمساعدتك في تحسيننا!';

  @override
  String get weAreWorkingOn => 'نعمل على هذا الأمر. سيصلك إشعار عندما نرد.';

  @override
  String get socialMateSupport => 'دعم Social Mate';

  @override
  String get official => 'رسمي';

  @override
  String get myFeedbacks => 'ملاحظاتي';

  @override
  String get trackTheStatusOf => 'تتبّع حالة ما أرسلته';

  @override
  String get couldNotLoadYour => 'تعذّر تحميل ملاحظاتك';

  @override
  String get noFeedbackYet => 'لا توجد ملاحظات بعد';

  @override
  String get anythingYouSendUs => 'كل ما ترسله لنا سيظهر هنا مع حالته.';

  @override
  String get replyReceived => 'تم استلام الرد';

  @override
  String get responseWithin24Hours2 => 'الرد خلال 24 ساعة (بحد أقصى 3 أيام)';

  @override
  String get imageIsTooLarge => 'الصورة كبيرة جدًا (الحد الأقصى 10 MB).';

  @override
  String get couldNotOpenYour => 'تعذّر فتح المعرض.';

  @override
  String get editedImageIsToo =>
      'الصورة المعدّلة كبيرة جدًا (الحد الأقصى 10 MB).';

  @override
  String get feedbackSubmittedSuccessfully => 'تم إرسال الملاحظة بنجاح';

  @override
  String get underReview => 'قيد المراجعة';

  @override
  String get ourTeamTypicallyResponds =>
      'يرد فريقنا عادةً خلال 24 ساعة (وحتى 3 أيام عمل).';

  @override
  String get feedbackSupport => 'الملاحظات والدعم';

  @override
  String get helpUsImproveSocial => 'ساعدنا في تحسين Social Mate';

  @override
  String get emailOrPhoneNumber => 'البريد الإلكتروني أو رقم الهاتف';

  @override
  String get responseTime => 'مدة الرد';

  @override
  String get myFeedbacks2 => 'ملاحظاتي';

  @override
  String get attachAScreenshot => 'أرفق لقطة شاشة';

  @override
  String get microphonePermissionIsRequired => 'إذن الميكروفون مطلوب للتسجيل.';

  @override
  String get couldNotStartRecording => 'تعذّر بدء التسجيل.';

  @override
  String get recordingWasTooShort => 'التسجيل قصير جدًا.';

  @override
  String get deleteVoiceNote => 'حذف الرسالة الصوتية';

  @override
  String get stop => 'إيقاف';

  @override
  String get noGifsFound => 'لم يتم العثور على GIF';

  @override
  String get searchGifs => 'ابحث عن GIF...';

  @override
  String get decline => 'رفض';

  @override
  String get ongoingGroupCall => 'مكالمة جماعية جارية';

  @override
  String get theCallCouldNot => 'تعذّر بدء المكالمة.';

  @override
  String get back => 'رجوع';

  @override
  String get flip => 'قلب';

  @override
  String get end => 'إنهاء';

  @override
  String get groupMembers => 'أعضاء المجموعة';

  @override
  String get admin => 'مشرف';

  @override
  String get inCall => 'في المكالمة';

  @override
  String get syncraCantReadMedia =>
      'لا يستطيع Syncra قراءة رسائل الوسائط بعد — جرّب رسالة نصية.';

  @override
  String get deleteForMe => 'حذف لدي';

  @override
  String get deleteForEveryone => 'حذف للجميع';

  @override
  String get failedToAddMembers => 'تعذّرت إضافة الأعضاء. حاول مرة أخرى.';

  @override
  String get addMembers => 'إضافة أعضاء';

  @override
  String get noNewConnectionsTo => 'لا توجد جهات اتصال جديدة للإضافة';

  @override
  String get noPeopleFound => 'لم يتم العثور على أشخاص';

  @override
  String get buildYourCommunity => 'ابنِ مجتمعك';

  @override
  String get youHaventAddedAny2 =>
      'لم تضف أي جهات اتصال بعد.\nاكتشف أشخاصًا بالقرب منك أو تصفّح الحسابات المقترحة لإنشاء مجموعتك الأولى.';

  @override
  String get newGroup => 'مجموعة جديدة';

  @override
  String get fileSent => 'تم إرسال الملف';

  @override
  String get failedToUpdateGroup => 'تعذّر تحديث صورة المجموعة';

  @override
  String get removeMember => 'إزالة العضو';

  @override
  String get remove => 'إزالة';

  @override
  String get failedToLoadMembers => 'تعذّر تحميل الأعضاء';

  @override
  String get groupNameUpdated => 'تم تحديث اسم المجموعة';

  @override
  String get groupTitleUpdated => 'تم تحديث عنوان المجموعة';

  @override
  String get removeGroupPhoto => 'إزالة صورة المجموعة';

  @override
  String get groupPhotoRemoved => 'تمت إزالة صورة المجموعة';

  @override
  String get leaveGroup => 'مغادرة المجموعة';

  @override
  String get blockGroup => 'حظر المجموعة';

  @override
  String get deleteGroup => 'حذف المجموعة';

  @override
  String get groupSettings => 'إعدادات المجموعة';

  @override
  String get tapToJoin => 'اضغط للانضمام';

  @override
  String get search => 'بحث';

  @override
  String get groupInfo => 'معلومات المجموعة';

  @override
  String get pleaseEndYourCurrent2 =>
      'يرجى إنهاء مكالمتك الحالية قبل الانضمام إلى مكالمة أخرى.';

  @override
  String get join => 'انضمام';

  @override
  String get voiceCall => 'مكالمة صوتية';

  @override
  String get videoCall => 'مكالمة فيديو';

  @override
  String get youAreNoLonger => 'لم تعد عضوًا في هذه المجموعة';

  @override
  String get editingMessage => 'تعديل الرسالة';

  @override
  String get enterGroupName => 'أدخل اسم المجموعة';

  @override
  String get members => 'الأعضاء';

  @override
  String get online2 => 'متصل الآن';

  @override
  String get owner => 'المالك';

  @override
  String get message => 'رسالة';

  @override
  String get call => 'اتصال';

  @override
  String get typeAMessage => 'اكتب رسالة...';

  @override
  String get thisGroupIsNo => 'هذه المجموعة لم تعد متاحة';

  @override
  String get failedToOpenGroup => 'تعذّر فتح محادثة المجموعة';

  @override
  String get linkExpiration => 'انتهاء صلاحية الرابط';

  @override
  String get neverExpires => 'لا تنتهي أبدًا';

  @override
  String get t24Hours => '24 ساعة';

  @override
  String get t2Days => 'يومان';

  @override
  String get t1Week => 'أسبوع';

  @override
  String get revokeInviteLink => 'إلغاء رابط الدعوة';

  @override
  String get inviteLinkCopied => 'تم نسخ رابط الدعوة';

  @override
  String get createALinkTo =>
      'أنشئ رابطًا لتتيح للآخرين الانضمام إلى هذه المجموعة.';

  @override
  String get generate => 'إنشاء';

  @override
  String get forward => 'إعادة توجيه';

  @override
  String get revokeLink => 'إلغاء الرابط';

  @override
  String get inviteLink => 'رابط الدعوة';

  @override
  String get addACaption2 => 'أضف شرحًا توضيحيًا…';

  @override
  String get add => 'إضافة';

  @override
  String get noMessagesYet => 'لا توجد رسائل بعد.';

  @override
  String get groupName => 'اسم المجموعة';

  @override
  String get groupName2 => 'اسم المجموعة';

  @override
  String get saveName => 'حفظ الاسم';

  @override
  String get groupTitle => 'عنوان المجموعة';

  @override
  String get addATitleFor => 'أضف عنوانًا لهذه المجموعة';

  @override
  String get saveTitle => 'حفظ العنوان';

  @override
  String get groupOwner => 'مالك المجموعة';

  @override
  String get groupAdmins => 'مشرفو المجموعة';

  @override
  String get removeAdmin => 'إزالة الإشراف';

  @override
  String get removeFromGroup => 'إزالة من المجموعة';

  @override
  String get youMentionedAllGroup => 'لقد أشرت إلى جميع أعضاء المجموعة';

  @override
  String get youMentionedYourselfIn2 => 'لقد أشرت إلى نفسك في هذه الرسالة';

  @override
  String get searchPeople2 => 'البحث عن أشخاص';

  @override
  String get edited2 => 'تم التعديل';

  @override
  String get loadingMorePosts => 'جارٍ تحميل المزيد من المنشورات...';

  @override
  String get markRead => 'تحديد كمقروء';

  @override
  String get reject => 'رفض';

  @override
  String get markAllRead => 'تحديد الكل كمقروء';

  @override
  String get thisPostIsNo => 'هذا المنشور لم يعد متاحًا.';

  @override
  String get uploadCanceled => 'تم إلغاء الرفع';

  @override
  String get postPublishedSuccessfully => 'تم نشر المنشور بنجاح';

  @override
  String get writeSomethingOrAttach =>
      'اكتب شيئًا أو أرفق ملفًا لمشاركة منشورك.';

  @override
  String get contentNotAvailable => 'المحتوى غير متاح';

  @override
  String get backgroundColor => 'لون الخلفية';

  @override
  String get savedPosts => 'المنشورات المحفوظة';

  @override
  String get thisFeatureIsComing => 'هذه الميزة ستتوفر قريبًا';

  @override
  String get noSavedPostsYet => 'لا توجد منشورات محفوظة بعد';

  @override
  String get tapTheBookmarkIcon =>
      'اضغط على أيقونة الإشارة المرجعية في أي منشور لحفظه هنا لاحقًا.';

  @override
  String get backgroundColorIsComing => 'لون الخلفية سيتوفر قريبًا';

  @override
  String get addGifIsComing => 'إضافة GIF ستتوفر قريبًا';

  @override
  String get liveVideoIsComing => 'البث المباشر سيتوفر قريبًا';

  @override
  String get createAPost => 'إنشاء منشور';

  @override
  String get post => 'نشر';

  @override
  String get whatsOnYourHead => 'ما الذي يدور في ذهنك؟';

  @override
  String get pinnedPost => 'منشور مثبّت';

  @override
  String get reportPost => 'الإبلاغ عن المنشور';

  @override
  String get postPinnedToYour => 'تم تثبيت المنشور في ملفك الشخصي';

  @override
  String get postUnpinned => 'تم إلغاء تثبيت المنشور';

  @override
  String get openOriginalPost => 'فتح المنشور الأصلي';

  @override
  String get suggestedForYou => 'مقترحات لك';

  @override
  String get failedToLoadReactions => 'تعذّر تحميل التفاعلات.';

  @override
  String get noReactionsYet => 'لا توجد تفاعلات بعد.';

  @override
  String get youMentionedYourselfIn3 => 'لقد أشرت إلى نفسك في هذا المنشور';

  @override
  String get videoUnavailableOffline => 'الفيديو غير متاح دون اتصال';

  @override
  String get videoIsStillProcessing => 'الفيديو قيد المعالجة…';

  @override
  String get couldntLoadVideo => 'تعذّر تحميل الفيديو';

  @override
  String get whatsOnYourMind => 'ما الذي يدور في ذهنك؟';

  @override
  String get noPostsAvailable => 'لا توجد منشورات متاحة.';

  @override
  String get openPostDetails => 'فتح تفاصيل المنشور';

  @override
  String get profileUpdatedSuccessfully => 'تم تحديث الملف الشخصي بنجاح';

  @override
  String get youHaveUnsavedChanges =>
      'لديك تغييرات غير محفوظة. هل تريد تجاهلها؟';

  @override
  String get discard => 'تجاهل';

  @override
  String get deletedAccount => 'حساب محذوف';

  @override
  String get name => 'الاسم';

  @override
  String get enterNewName => 'أدخل الاسم الجديد';

  @override
  String get username => 'اسم المستخدم';

  @override
  String get enterNewUsername => 'أدخل اسم المستخدم الجديد';

  @override
  String get title => 'اللقب';

  @override
  String get enterNewTitle => 'أدخل اللقب الجديد';

  @override
  String get bio => 'النبذة';

  @override
  String get enterNewBio => 'أدخل النبذة الجديدة';

  @override
  String get socialMedia => 'وسائل التواصل الاجتماعي';

  @override
  String get chooseFromGallery => 'اختيار من المعرض';

  @override
  String get takeAPhoto => 'التقاط صورة';

  @override
  String get cropEdit => 'قص وتعديل';

  @override
  String get removePhoto => 'إزالة الصورة';

  @override
  String get stories => 'القصص';

  @override
  String get friendsList => 'قائمة الأصدقاء';

  @override
  String get declineRequest => 'رفض الطلب';

  @override
  String get sendMessage => 'إرسال رسالة';

  @override
  String get reportProfile => 'الإبلاغ عن الملف الشخصي';

  @override
  String get posts => 'المنشورات';

  @override
  String get media => 'الوسائط';

  @override
  String get followers => 'المتابعون';

  @override
  String get following => 'يتابع';

  @override
  String get linkedinProfile => 'ملف LinkedIn الشخصي';

  @override
  String get status => 'الحالة';

  @override
  String get aShortQuoteMood => 'عبارة قصيرة أو مزاج أو إيموجي';

  @override
  String get thisAccountHasBeen => 'تم حذف هذا الحساب';

  @override
  String get reactions => 'التفاعلات';

  @override
  String get tapToRemove => 'اضغط للإزالة';

  @override
  String get whatDoYouLike => 'ما الذي يعجبك؟';

  @override
  String get chooseTheTopicsThat =>
      'اختر المواضيع التي تهمك لنخصّص تجربة الريلز لك.';

  @override
  String get skipForNow => 'تخطي الآن';

  @override
  String get shareRemoved => 'تمت إزالة المشاركة';

  @override
  String get reelSharedToYour => 'تمت مشاركة الريل في خلاصتك';

  @override
  String get couldNotShareThis => 'تعذّرت مشاركة هذا الريل. حاول مرة أخرى.';

  @override
  String get linkCopiedToClipboard => 'تم نسخ الرابط إلى الحافظة';

  @override
  String get couldNotShareThis2 => 'تعذّرت مشاركة هذا الرابط. حاول مرة أخرى.';

  @override
  String get reshare => 'إعادة مشاركة';

  @override
  String get learnHowToPlay => 'تعرّف على طريقة تشغيل هذا الفيديو';

  @override
  String get openOnYoutube => 'فتح في YouTube';

  @override
  String get reels => 'الريلز';

  @override
  String get thanksForReportingOur => 'شكرًا على إبلاغك. سيراجعه فريقنا.';

  @override
  String get whyAreYouReporting => 'لماذا تبلّغ عن هذا؟ بلاغك سري.';

  @override
  String get reelsForYou => 'ريلز لك';

  @override
  String get peopleYouAddAs => 'الأشخاص الذين تضيفهم كأصدقاء سيظهرون هنا.';

  @override
  String get searchAccountsPostsReels => 'ابحث عن حسابات ومنشورات وريلز...';

  @override
  String get featuresLanguageUsage => 'الميزات واللغة والاستخدام';

  @override
  String get aiFeatures => 'ميزات الذكاء الاصطناعي';

  @override
  String get aiAutoComplete => 'الإكمال التلقائي بالذكاء الاصطناعي';

  @override
  String get tapTheAiIcon =>
      'اضغط على أيقونة الذكاء الاصطناعي لإنشاء الشروحات والردود';

  @override
  String get aiAutoDetect => 'الكشف التلقائي بالذكاء الاصطناعي';

  @override
  String get automaticSpellingSuggestionsWhile =>
      'اقتراحات إملائية تلقائية أثناء الكتابة';

  @override
  String get aiCommentSuggestions => 'اقتراحات التعليقات بالذكاء الاصطناعي';

  @override
  String get quickAiSuggestedReplies =>
      'ردود سريعة مقترحة بالذكاء الاصطناعي أسفل المنشورات';

  @override
  String get autoCompleteLanguage => 'لغة الإكمال التلقائي';

  @override
  String get replyTone => 'نبرة الرد';

  @override
  String get replyLength => 'طول الرد';

  @override
  String get sendResetLink => 'هل تريد إرسال رابط إعادة التعيين؟';

  @override
  String get sendLink => 'إرسال الرابط';

  @override
  String get passwordChangedSuccessfully => 'تم تغيير كلمة المرور بنجاح';

  @override
  String get updateYourAccountPassword => 'حدّث كلمة مرور حسابك بأمان';

  @override
  String get pleaseSignInAgain => 'يرجى تسجيل الدخول مجددًا للمتابعة.';

  @override
  String get currentPassword => 'كلمة المرور الحالية';

  @override
  String get enterYourCurrentPassword => 'أدخل كلمة المرور الحالية';

  @override
  String get confirmNewPassword => 'تأكيد كلمة المرور الجديدة';

  @override
  String get reEnterNewPassword => 'أعد إدخال كلمة المرور الجديدة';

  @override
  String get yourEmailAddressWas => 'تم تحديث بريدك الإلكتروني';

  @override
  String get emailVerified => 'تم التحقق من البريد الإلكتروني';

  @override
  String get confirmationLinkSent => 'تم إرسال رابط التأكيد';

  @override
  String get confirmationLinkSentAgain => 'تم إرسال رابط التأكيد مرة أخرى';

  @override
  String get emailChangeCancelled => 'تم إلغاء تغيير البريد الإلكتروني';

  @override
  String get verificationEmailSent => 'تم إرسال رسالة التحقق';

  @override
  String get keep => 'إبقاء';

  @override
  String get cancelEmailChange => 'هل تريد إلغاء تغيير البريد الإلكتروني؟';

  @override
  String get manageAndUpdateYour =>
      'أدِر عنوان بريدك الإلكتروني المرتبط وحدّثه';

  @override
  String get setAPasswordFirst => 'عيّن كلمة مرور أولًا';

  @override
  String get changeEmailAddress => 'تغيير عنوان البريد الإلكتروني';

  @override
  String get enterYourPassword => 'أدخل كلمة المرور';

  @override
  String get newEmailAddress => 'عنوان البريد الإلكتروني الجديد';

  @override
  String get enterYourNewEmail => 'أدخل بريدك الإلكتروني الجديد';

  @override
  String get whichLanguageShouldAi =>
      'ما اللغة التي يجب أن يستخدمها الذكاء الاصطناعي في الشروحات والردود والتصحيحات؟';

  @override
  String get howLongShouldAi =>
      'ما الطول المناسب للشروحات والردود التي ينشئها الذكاء الاصطناعي؟';

  @override
  String get whatToneShouldAi =>
      'ما النبرة التي يجب أن يستخدمها الذكاء الاصطناعي في الشروحات والردود؟';

  @override
  String get theAppIsLocked => 'التطبيق مقفل.';

  @override
  String get useYourFingerprintOr =>
      'استخدم بصمة إصبعك أو Face ID لفتح التطبيق.';

  @override
  String get openTheApp => 'فتح التطبيق';

  @override
  String get searchProfile => 'البحث في الملفات الشخصية';

  @override
  String get yourChats => 'محادثاتك';

  @override
  String get yourThemes => 'سماتك';

  @override
  String get logOutSuccessfully => 'تم تسجيل الخروج بنجاح';

  @override
  String get isCallingYou => 'يتصل بك...';

  @override
  String get returnToCall => 'العودة إلى المكالمة';

  @override
  String get sharedGroups => 'المجموعات المشتركة';

  @override
  String get addAnOptionalCaption => 'أضف شرحًا توضيحيًا اختياريًا...';

  @override
  String get editMessage => 'تعديل الرسالة';

  @override
  String get deleteMessage => 'حذف الرسالة';

  @override
  String get youCannotSendMessages => 'لا يمكنك إرسال رسائل إلى حساب محذوف.';

  @override
  String get t5Sec => '-5 ث';

  @override
  String get t5Sec2 => '+5 ث';

  @override
  String get messages => 'الرسائل';

  @override
  String get archivedChats2 => 'المحادثات المؤرشفة';

  @override
  String get createGroup => 'إنشاء مجموعة';

  @override
  String get repliedToStory => 'ردّ على قصة';

  @override
  String get selectPeople => 'اختيار الأشخاص';

  @override
  String get searchFriends => 'ابحث عن أصدقاء...';

  @override
  String get noFriendsYet => 'لا يوجد أصدقاء بعد';

  @override
  String get couldntLoadMoreTap => 'تعذّر تحميل المزيد · اضغط لإعادة المحاولة';

  @override
  String get unfriend => 'إلغاء الصداقة';

  @override
  String get skip => 'تخطي';

  @override
  String get signIn => 'تسجيل الدخول';

  @override
  String get packName => 'اسم الحزمة';

  @override
  String get createStickerPack => 'إنشاء حزمة ملصقات';

  @override
  String get noStickersYet => 'لا توجد ملصقات بعد';

  @override
  String get discoverAndDownloadAmazing =>
      'اكتشف حزم الملصقات الرائعة من المكتبة وحمّلها للتعبير عن نفسك.';

  @override
  String get exploreLibrary => 'استكشاف المكتبة';

  @override
  String get stickerLibrary => 'مكتبة الملصقات';

  @override
  String get createPack => 'إنشاء حزمة';

  @override
  String get createYourOwnSticker => 'أنشئ حزمة\nملصقاتك الخاصة';

  @override
  String get privacyAudience => 'الخصوصية والجمهور';

  @override
  String get tapToChangeAudience => 'اضغط لتغيير الجمهور';

  @override
  String get stickers => 'الملصقات';

  @override
  String get nameYourPack => 'اختر اسمًا لحزمتك...';

  @override
  String get download => 'تنزيل';

  @override
  String get noFriendsFound => 'لم يتم العثور على أصدقاء.';

  @override
  String get browseLibrary => 'تصفّح المكتبة';

  @override
  String get share => 'مشاركة';

  @override
  String get couldNotLoadVideo => 'تعذّر تحميل الفيديو';

  @override
  String get storyAddedSuccessfully => 'تمت إضافة القصة بنجاح';

  @override
  String get thisStoryIsNo => 'هذه القصة لم تعد متاحة';

  @override
  String get replySent => 'تم إرسال الرد ✓';

  @override
  String get youMentionedYourselfIn4 => 'لقد أشرت إلى نفسك في هذه القصة';

  @override
  String get couldNotLoadStories => 'تعذّر تحميل القصص';

  @override
  String get noStoriesYet => 'لا توجد قصص بعد';

  @override
  String get createStory => 'إنشاء\nقصة';

  @override
  String get shareStory => 'مشاركة القصة';

  @override
  String get deleteStory => 'حذف القصة';

  @override
  String get reportStory => 'الإبلاغ عن القصة';

  @override
  String get addToStory => 'إضافة إلى القصة';

  @override
  String get textStory => 'قصة نصية';

  @override
  String get photoFromGallery => 'صورة من المعرض';

  @override
  String get videoFromGallery => 'فيديو من المعرض';

  @override
  String get max60Seconds => '60 ثانية كحد أقصى';

  @override
  String get recordAVideo => 'تسجيل فيديو';

  @override
  String get yourStory => 'قصتك';

  @override
  String get writeYourThoughtWith => 'شارك أفكارك مع الآخرين';

  @override
  String get couldntLoadViews => 'تعذّر تحميل المشاهدات.';

  @override
  String get noViewsYet => 'لا توجد مشاهدات بعد';

  @override
  String get weCouldntLoadThis => 'تعذّر تحميل هذا المحتوى. حاول لاحقًا.';

  @override
  String get searchForAQuestion => 'ابحث عن سؤال…';

  @override
  String get tableOfContents => 'جدول المحتويات';

  @override
  String get stillNeedHelpContact => 'ما زلت بحاجة إلى مساعدة؟ تواصل مع الدعم';

  @override
  String get twoFactorWasTurned =>
      'تم إيقاف المصادقة الثنائية بعد استخدامك رمز استرداد.';

  @override
  String get twoStepVerification => 'التحقق بخطوتين';

  @override
  String get pasteCode => 'لصق الرمز';

  @override
  String get notYouSignOut => 'لست أنت؟ سجّل الخروج';

  @override
  String get leaveWithoutSaving => 'المغادرة دون حفظ؟';

  @override
  String get stay => 'البقاء';

  @override
  String get leave => 'مغادرة';

  @override
  String get saveYourRecoveryCodes => 'احفظ رموز الاسترداد';

  @override
  String get codesCopiedClipboardClears =>
      'تم نسخ الرموز. ستُمسح الحافظة خلال 60 ثانية.';

  @override
  String get copyAll => 'نسخ الكل';

  @override
  String get saveShare => 'حفظ / مشاركة';

  @override
  String get iSavedTheseCodes => 'حفظت هذه الرموز في مكان آمن';

  @override
  String get twoFactorAuthenticationIs => 'المصادقة الثنائية متوقفة';

  @override
  String get turnOffTwoFactor => 'هل تريد إيقاف المصادقة الثنائية؟';

  @override
  String get currentPassword2 => 'كلمة المرور الحالية';

  @override
  String get protectYourAccount => 'احمِ حسابك';

  @override
  String get noAuthenticatorAppFound =>
      'لم يتم العثور على تطبيق مصادقة. انسخ المفتاح السري بدلًا من ذلك.';

  @override
  String get scanThisQrCode => 'امسح رمز QR هذا';

  @override
  String get openYourAuthenticatorApp =>
      'افتح تطبيق المصادقة، وأضف حسابًا جديدًا، ثم امسح الرمز.';

  @override
  String get cantScanEnterThis => 'لا تستطيع المسح؟ أدخل هذا المفتاح يدويًا';

  @override
  String get copySecret => 'نسخ المفتاح السري';

  @override
  String get secretCopiedItWill =>
      'تم نسخ المفتاح السري. سيُمسح خلال 60 ثانية.';

  @override
  String get openInAuthenticatorApp => 'فتح في تطبيق المصادقة';

  @override
  String get enterThe6Digit => 'أدخل الرمز المكوّن من 6 أرقام';

  @override
  String get backToQrCode => 'العودة إلى رمز QR';

  @override
  String get thisClearsTheChat =>
      'يمسح هذا سجل المحادثة على هذا الجهاز فقط. يحتفظ المشاركون الآخرون بنسختهم الخاصة.';

  @override
  String get openThisFromA => 'افتح هذا من داخل محادثة للانتقال إلى الرسالة';

  @override
  String get failedToDeleteMessage => 'تعذّر حذف الرسالة';

  @override
  String readBy(Object length) {
    return 'قرأها ($length)';
  }

  @override
  String get noGroupMembersHave =>
      'لم يقرأ أي من أعضاء المجموعة هذه الرسالة بعد';

  @override
  String get delivered => 'تم التسليم';

  @override
  String get deliveredToGroupMembers => 'تم التسليم إلى أعضاء المجموعة';

  @override
  String get sent => 'تم الإرسال';

  @override
  String get sentToServer => 'أُرسلت إلى الخادم';

  @override
  String get read => 'تمت القراءة';

  @override
  String get model => 'النموذج';

  @override
  String get aiEngine => 'محرك الذكاء الاصطناعي';

  @override
  String noResultsFoundFor(Object searchQuery) {
    return 'لا توجد نتائج لـ “$searchQuery”';
  }

  @override
  String get noStarredMessages => 'لا توجد رسائل مميزة بنجمة';

  @override
  String get tapAndHoldOn =>
      'اضغط مطوّلًا على أي رسالة لتمييزها بنجمة، لتجدها هنا لاحقًا.';

  @override
  String noSharedYet(Object tab) {
    return 'لا توجد عناصر مشتركة في $tab بعد';
  }

  @override
  String get showInChat => 'عرض في المحادثة';

  @override
  String sStory(Object authorName) {
    return 'قصة $authorName';
  }

  @override
  String get imageFileNotFound => 'لم يتم العثور على ملف الصورة.';

  @override
  String get couldNotSaveYour => 'تعذّر حفظ تعديلك. حاول مرة أخرى.';

  @override
  String get videoFileNotFound => 'لم يتم العثور على ملف الفيديو.';

  @override
  String selected2(Object selectedMs) {
    return 'المحدد $selectedMs';
  }

  @override
  String total(Object totalMs) {
    return 'الإجمالي $totalMs';
  }

  @override
  String maxLengthIs(Object maxMs) {
    return 'أقصى مدة هي $maxMs';
  }

  @override
  String get thisCallHasAlready => 'انتهت هذه المكالمة بالفعل';

  @override
  String get failedToOpenStory => 'تعذّر فتح القصة';

  @override
  String lastSeen(Object lastSeenStr) {
    return 'آخر ظهور $lastSeenStr';
  }

  @override
  String get navigationError => 'خطأ في التنقل';

  @override
  String route(Object name) {
    return 'المسار: $name';
  }

  @override
  String get savedToGallerySuccessfully => 'تم الحفظ في المعرض بنجاح! ✅';

  @override
  String get pleaseAllowStorageAccess =>
      'يرجى السماح بالوصول إلى التخزين من الإعدادات ⚙️';

  @override
  String failedToSave(Object e) {
    return 'فشل الحفظ: $e ❌';
  }

  @override
  String get enableMicrophoneCameraAccess =>
      'فعّل الوصول إلى الميكروفون والكاميرا من الإعدادات لإجراء المكالمات';

  @override
  String get permissionRequired => 'الإذن مطلوب';

  @override
  String accessIsTurnedOff(Object what) {
    return 'الوصول إلى $what متوقف لهذا التطبيق. فعّله من الإعدادات لإجراء المكالمات أو الانضمام إليها.';
  }

  @override
  String get notNow => 'ليس الآن';

  @override
  String get openSettings => 'فتح الإعدادات';

  @override
  String forwardedToChatS(Object length) {
    return 'تمت إعادة التوجيه إلى $length من المحادثات';
  }

  @override
  String isBusyOnAnother(Object receiverName) {
    return '$receiverName مشغول في مكالمة أخرى';
  }

  @override
  String socialAppAllRights(Object year) {
    return '© $year Social App. جميع الحقوق محفوظة.';
  }

  @override
  String resetsAt(Object resetTimeLabel) {
    return 'يُعاد التعيين في $resetTimeLabel';
  }

  @override
  String bonus(Object bonus) {
    return '~$bonus إضافي';
  }

  @override
  String get sharingThisWithSyncra => 'المشاركة مع Syncra ستتوفر قريبًا.';

  @override
  String get imageFileNotFound2 =>
      'لم يتم العثور على ملف الصورة. حاول اختيارها مرة أخرى.';

  @override
  String get fileNotFoundPlease =>
      'لم يتم العثور على الملف. حاول اختياره مرة أخرى.';

  @override
  String get filesLargerThan20mb => 'الملفات الأكبر من 20 MB غير مدعومة بعد.';

  @override
  String get voiceMessageNotFound =>
      'لم يتم العثور على الرسالة الصوتية. حاول تسجيلها مرة أخرى.';

  @override
  String get failedToSendThe => 'تعذّر إرسال الرسالة الصوتية. حاول مرة أخرى.';

  @override
  String get failedToSendThe2 => 'تعذّر إرسال الملف. حاول مرة أخرى.';

  @override
  String get failedToUploadPlease => 'فشل الرفع. حاول مرة أخرى.';

  @override
  String get failedToSendThe3 => 'تعذّر إرسال الصورة. حاول مرة أخرى.';

  @override
  String get couldntLoadThatFile => 'تعذّر تحميل هذا الملف. حاول مرة أخرى.';

  @override
  String couldntLoadThisConversation(Object message) {
    return 'تعذّر تحميل هذه المحادثة.\n$message';
  }

  @override
  String get deleteThisChat => 'هل تريد حذف هذه المحادثة؟';

  @override
  String deleteThisPermanentlyRemoves(Object title) {
    return 'هل تريد حذف “$title”؟ سيتم إزالتها نهائيًا من Syncra ولا يمكن التراجع.';
  }

  @override
  String hi(Object userName) {
    return 'مرحبًا، $userName!';
  }

  @override
  String get open => 'فتح';

  @override
  String bonus2(Object bonusGranted) {
    return '+~$bonusGranted إضافي';
  }

  @override
  String usedOfYourDaily(
    Object percentLabel,
    Object effectiveUserLimit,
    Object usedLabel,
  ) {
    return 'استخدمت $percentLabel من حدّك اليومي البالغ $effectiveUserLimit طلبًا ($usedLabel)';
  }

  @override
  String get yourAccountHasBeen => 'تم حذف حسابك بنجاح.';

  @override
  String get noConnectionCheckYour =>
      'لا يوجد اتصال. تحقق من الإنترنت ثم اضغط على الرابط في البريد مرة أخرى.';

  @override
  String get somethingWentWrongPlease2 => 'حدث خطأ ما. يرجى طلب رابط جديد.';

  @override
  String unblockTheyWillBe(Object name) {
    return 'هل تريد إلغاء حظر $name؟ سيتمكن من مراسلتك مجددًا.';
  }

  @override
  String get noBlockedUsers => 'لا يوجد مستخدمون محظورون';

  @override
  String get accountsYouBlockWill =>
      'ستظهر الحسابات التي تحظرها هنا لتديرها في أي وقت.';

  @override
  String selected3(Object totalSelected) {
    return 'تم تحديد $totalSelected';
  }

  @override
  String get noResultsFound => 'لم يتم العثور على نتائج.';

  @override
  String get nowhereToForwardYet => 'لا توجد جهات لإعادة التوجيه بعد';

  @override
  String get addFriendsFollowPeople =>
      'أضف أصدقاء أو تابع أشخاصًا أو انضم إلى مجموعة أولًا.';

  @override
  String mentionedYouInThis(Object authorName) {
    return '$authorName أشار إليك في هذا التعليق';
  }

  @override
  String mutualFriends(Object mutualFriendsCount) {
    return '$mutualFriendsCount أصدقاء مشتركين';
  }

  @override
  String friends2(Object totalFriendsCount) {
    return '$totalFriendsCount من الأصدقاء';
  }

  @override
  String mutualGroups(Object mutualGroupsCount) {
    return '$mutualGroupsCount مجموعات مشتركة';
  }

  @override
  String mutual(Object mutualFriendsCount) {
    return '$mutualFriendsCount مشترك';
  }

  @override
  String mutual2(Object totalMutualCount) {
    return '$totalMutualCount مشترك';
  }

  @override
  String sent2(Object createdAt) {
    return 'أُرسلت $createdAt';
  }

  @override
  String recordAVoiceNote(Object maxSeconds) {
    return 'سجّل رسالة صوتية (حتى $maxSeconds دقيقة)';
  }

  @override
  String isCalling(Object initiatorName) {
    return '$initiatorName يتصل بك...';
  }

  @override
  String isComingSoon(Object feature) {
    return '$feature ستتوفر قريبًا';
  }

  @override
  String selected4(Object length) {
    return 'تم تحديد $length';
  }

  @override
  String noResultsFoundFor2(Object query) {
    return 'لا توجد نتائج لـ “$query”';
  }

  @override
  String membersSelected(Object length) {
    return 'تم تحديد $length أعضاء';
  }

  @override
  String removeFromTheGroup(Object userName) {
    return 'هل تريد إزالة $userName من المجموعة؟';
  }

  @override
  String isNowAnAdmin(Object userName) {
    return '$userName أصبح مشرفًا الآن';
  }

  @override
  String isNoLongerAn(Object userName) {
    return '$userName لم يعد مشرفًا';
  }

  @override
  String removedFromTheGroup(Object userName) {
    return 'تمت إزالة $userName من المجموعة';
  }

  @override
  String get ongoing => 'جارٍ';

  @override
  String get save => 'حفظ';

  @override
  String get makeAdmin => 'تعيين كمشرف';

  @override
  String joinedViaThisLink(Object joinCount) {
    return 'انضم $joinCount عبر هذا الرابط';
  }

  @override
  String members2(Object count) {
    return '$count أعضاء';
  }

  @override
  String mentionedAllGroupMembers(Object senderName) {
    return '$senderName أشار إلى جميع أعضاء المجموعة';
  }

  @override
  String mentionedYouInThis2(Object senderName) {
    return '$senderName أشار إليك في هذه الرسالة';
  }

  @override
  String get tapToOpenGroup => 'اضغط لفتح محادثة المجموعة';

  @override
  String selected5(Object selectedCount) {
    return 'تم تحديد $selectedCount';
  }

  @override
  String selected6(Object count) {
    return 'تم تحديد $count';
  }

  @override
  String get youreAllCaughtUp => 'لقد اطّلعت على كل شيء!';

  @override
  String get pinLimitReachedUnpin =>
      'تم بلوغ حد التثبيت. ألغِ تثبيت منشور أولًا.';

  @override
  String get couldNotUpdateThe => 'تعذّر تحديث التثبيت. حاول مرة أخرى.';

  @override
  String reactions2(Object length) {
    return '$length تفاعلات';
  }

  @override
  String mentionedYouInThis3(Object authorName) {
    return '$authorName أشار إليك في هذا المنشور';
  }

  @override
  String get thisAccountHasBeen2 =>
      'تم حذف هذا الحساب ولم يعد ملفه الشخصي متاحًا.';

  @override
  String couldNotOpenLink(Object label) {
    return 'تعذّر فتح رابط $label';
  }

  @override
  String get viewProfessionalProfileOn => 'عرض الملف المهني على LinkedIn';

  @override
  String get yourStatusWillBe =>
      'ستبقى حالتك مخفية عن ملفك الشخصي حتى تعيد تفعيلها.';

  @override
  String get tooManyReportsIn => 'بلاغات كثيرة في وقت قصير. حاول لاحقًا.';

  @override
  String get thisContentIsNo => 'هذا المحتوى لم يعد متاحًا.';

  @override
  String get youCantReportThis => 'لا يمكنك الإبلاغ عن هذا المحتوى.';

  @override
  String report2(Object label) {
    return 'الإبلاغ عن $label';
  }

  @override
  String get thisFeatureChecksYour =>
      'تفحص هذه الميزة كتابتك باستمرار، لذا قد تستهلك حصتك اليومية من الذكاء الاصطناعي بشكل أسرع.';

  @override
  String sendAPasswordReset(Object email) {
    return 'هل تريد إرسال رابط إعادة تعيين كلمة المرور إلى $email؟\n\nستبقى مسجّلًا دخولك على هذا الجهاز.';
  }

  @override
  String resetLinkSentTo(Object email) {
    return 'تم إرسال رابط إعادة التعيين إلى $email. تحقق من بريدك الوارد.';
  }

  @override
  String linkedTo(Object oauthLabel) {
    return 'مرتبط بـ $oauthLabel';
  }

  @override
  String yourAccountIsLinked(Object oauthLabel) {
    return 'حسابك مرتبط بـ $oauthLabel. يمكنك تعيين كلمة مرور لتفعيل الدخول بالبريد الإلكتروني.';
  }

  @override
  String get youWillStaySigned =>
      'ستبقى مسجّلًا دخولك على هذا الجهاز، وسيتم تسجيل خروجك من الأجهزة الأخرى.';

  @override
  String yourEmailStaysThe(Object currentEmail, Object pendingEmail) {
    return 'يبقى بريدك الإلكتروني $currentEmail. لن يعمل الرابط المرسل إلى $pendingEmail بعد الآن.';
  }

  @override
  String get forYourSecurityWe =>
      'لحمايتك، سنطلب كلمة مرورك قبل تغيير بريدك الإلكتروني.';

  @override
  String get toChangeYourEmail =>
      'لتغيير بريدك الإلكتروني تحتاج أولًا إلى كلمة مرور لهذا الحساب، لنتأكد أنك أنت.';

  @override
  String get currentEmail => 'البريد الإلكتروني الحالي';

  @override
  String get verified => 'موثّق';

  @override
  String get unverified => 'غير موثّق';

  @override
  String get verifyThisAddressSo =>
      'وثّق هذا العنوان لتتمكن من استعادة حسابك وتلقي الإشعارات المهمة.';

  @override
  String get signInMethod => 'طريقة تسجيل الدخول';

  @override
  String get confirmYourNewEmail => 'أكّد بريدك الإلكتروني الجديد';

  @override
  String confirmationLinkSentTo(Object pendingEmail) {
    return 'تم إرسال رابط التأكيد إلى $pendingEmail. اضغط عليه لتأكيد عنوانك الجديد. يبقى بريدك الحالي فعّالًا إلى حين التأكيد.';
  }

  @override
  String get cannotFindItCheck =>
      'لا تجده؟ تحقق من مجلد الرسائل غير المرغوب فيها. وقد يُطلب منك الموافقة على التغيير من بريدك الحالي.';

  @override
  String get cancelRequest => 'إلغاء الطلب';

  @override
  String get enterYourPasswordAnd =>
      'أدخل كلمة مرورك والعنوان الجديد. سنرسل رابط تأكيد، ويبقى بريدك الحالي فعّالًا حتى تؤكد.';

  @override
  String get yourProfileWillBe =>
      'سيتم إخفاء هوية ملفك الشخصي باسم “حساب محذوف” وتسجيل خروجك من جميع الأجهزة. ستبقى منشوراتك وتعليقاتك ورسائلك ظاهرة للآخرين بهذا الاسم. لا يمكن التراجع عن هذا الإجراء.';

  @override
  String get thisAccountHasBeen3 => 'تم حذف هذا الحساب.';

  @override
  String get noConnectionsYet => 'لا توجد جهات اتصال بعد';

  @override
  String get addSomeFriendsOr =>
      'أضف بعض الأصدقاء أو المتابعين أولًا لتتمكن من مشاركة المنشورات الخاصة معهم.';

  @override
  String get noUsersFound2 => 'لم يتم العثور على مستخدمين.';

  @override
  String get public => 'عام';

  @override
  String get anyoneOnTheApp => 'يمكن لأي شخص في التطبيق رؤية هذا';

  @override
  String get onlyYourFriendsCan => 'يمكن لأصدقائك فقط رؤية هذا';

  @override
  String get specificPeople => 'أشخاص محددون';

  @override
  String get onlySpecificPeopleYou => 'أشخاص محددون تختارهم أنت فقط';

  @override
  String removeFromYourFriends(Object friendName) {
    return 'هل تريد إزالة $friendName من أصدقائك؟';
  }

  @override
  String get couldNotDeleteThe => 'تعذّر حذف الحزمة، حاول مرة أخرى.';

  @override
  String get couldNotOpenThe => 'تعذّر فتح المعرض، حاول مرة أخرى.';

  @override
  String thisPackAlreadyHas(Object maxStickers) {
    return 'وصلت هذه الحزمة إلى الحد الأقصى وهو $maxStickers ملصقًا.';
  }

  @override
  String onlyTheFirstImage(Object remainingSlots, Object maxStickers) {
    return 'أُضيفت أول $remainingSlots صور فقط — تتسع الحزمة لـ $maxStickers ملصقًا كحد أقصى.';
  }

  @override
  String get thisSelectionPushesThe =>
      'هذا التحديد يتجاوز حد 25 MB للحزمة — اختر صورًا أقل أو أصغر.';

  @override
  String get giveYourPackA => 'أعطِ حزمتك اسمًا أولًا.';

  @override
  String get addAtLeastOne => 'أضف ملصقًا واحدًا على الأقل.';

  @override
  String get pickAtLeastOne =>
      'اختر صديقًا واحدًا على الأقل، أو غيّر إعداد الخصوصية.';

  @override
  String get couldNotVerifyYour => 'تعذّر التحقق من حصة الحزم، حاول مرة أخرى.';

  @override
  String get uploadCancelled => 'تم إلغاء الرفع.';

  @override
  String get couldNotCreateThe => 'تعذّر إنشاء الحزمة، حاول مرة أخرى.';

  @override
  String get youAlreadyOwn3 =>
      'تمتلك بالفعل 3 حزم ملصقات — وهو الحد الأقصى. احذف واحدة أدناه لإنشاء حزمة جديدة.';

  @override
  String stickers2(Object stickerCount) {
    return '$stickerCount ملصقات';
  }

  @override
  String uploading(Object label) {
    return 'جارٍ الرفع  •  $label';
  }

  @override
  String packCreated(Object title) {
    return 'تم إنشاء الحزمة “$title”!';
  }

  @override
  String t25Mb(Object length, Object maxStickers, Object sizeMb) {
    return '$length/$maxStickers  •  $sizeMb/25 MB';
  }

  @override
  String defaultStoryPrivacySet(Object label) {
    return 'تم ضبط خصوصية القصة الافتراضية على $label';
  }

  @override
  String mentionedYouInThis4(Object authorName) {
    return '$authorName أشار إليك في هذه القصة';
  }

  @override
  String error(Object message) {
    return 'خطأ: $message';
  }

  @override
  String failedToSendReply(Object message) {
    return 'تعذّر إرسال الرد: $message';
  }

  @override
  String replyToSStory(Object authorName) {
    return 'الرد على قصة $authorName…';
  }

  @override
  String views(Object count) {
    return '$count مشاهدات';
  }

  @override
  String get couldNotOpenYour2 => 'تعذّر فتح تطبيق البريد الإلكتروني.';

  @override
  String noResultsFor(Object query) {
    return 'لا توجد نتائج لـ “$query”';
  }

  @override
  String tooManyAttemptsTry(Object lockRemaining) {
    return 'محاولات كثيرة. حاول مجددًا بعد $lockRemaining.';
  }

  @override
  String get stillNotWorkingMake =>
      'ما زال لا يعمل؟ تأكد من ضبط التاريخ والوقت في هاتفك على الوضع التلقائي من إعدادات الجهاز.';

  @override
  String get yourRecoveryCodesWill =>
      'لن تُعرض رموز الاسترداد مرة أخرى. ستبقى المصادقة الثنائية مفعّلة، ويمكنك إنشاء رموز جديدة لاحقًا من الإعدادات.';

  @override
  String stepOf4(Object step) {
    return 'الخطوة $step من 4';
  }

  @override
  String get twoFactorAuthenticationIs2 => 'المصادقة الثنائية مفعّلة';

  @override
  String get couldNotStartSetup => 'تعذّر بدء الإعداد';

  @override
  String get twoFactorIsOn =>
      'المصادقة الثنائية مفعّلة، لكن تعذّر إنشاء الرموز';

  @override
  String yourAccountIsAlready(Object generated) {
    return '$generated\n\nحسابك محمي بالفعل. أعد المحاولة الآن أو أنشئ الرموز لاحقًا من الإعدادات.';
  }

  @override
  String get keepTheseCodesIn =>
      'احتفظ بهذه الرموز في مكان آمن لاستعادة حسابك إن فقدت هاتفك. يعمل كل رمز مرة واحدة ولن تُعرض مرة أخرى.';

  @override
  String get yourAccountWillBe =>
      'سيُحمى حسابك بكلمة المرور فقط، وسيتم حذف رموز الاسترداد. أكّد أنك أنت للمتابعة.';

  @override
  String get evenIfSomeoneLearns =>
      'حتى لو عرف شخص ما كلمة مرورك، لا يمكنه تسجيل الدخول دون رمز من هاتفك.';

  @override
  String get typeTheCodeYour =>
      'اكتب الرمز الذي يعرضه تطبيق المصادقة لـ Social Mate للتأكد من ربطه.';

  @override
  String mutualFriendsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count صديقًا مشتركًا',
      many: '$count صديقًا مشتركًا',
      few: '$count أصدقاء مشتركين',
      two: 'صديقان مشتركان',
      one: 'صديق مشترك واحد',
    );
    return '$_temp0';
  }

  @override
  String mutualGroupsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count مجموعة مشتركة',
      many: '$count مجموعة مشتركة',
      few: '$count مجموعات مشتركة',
      two: 'مجموعتان مشتركتان',
      one: 'مجموعة مشتركة واحدة',
    );
    return '$_temp0';
  }

  @override
  String newPostsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count منشورًا جديدًا',
      many: '$count منشورًا جديدًا',
      few: '$count منشورات جديدة',
      two: 'منشوران جديدان',
      one: 'منشور جديد واحد',
    );
    return '$_temp0';
  }

  @override
  String starsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count نجمة',
      many: '$count نجمة',
      few: '$count نجوم',
      two: 'نجمتان',
      one: 'نجمة واحدة',
    );
    return '$_temp0';
  }

  @override
  String forwardNMessages(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count رسالة',
      many: '$count رسالة',
      few: '$count رسائل',
      two: 'الرسالتين',
      one: 'الرسالة',
    );
    return 'إعادة توجيه $_temp0';
  }

  @override
  String videoIsSMax(Object inSeconds, Object inSeconds2) {
    return 'مدة الفيديو $inSeconds ثانية — الحد الأقصى المسموح $inSeconds2 ثانية.';
  }

  @override
  String deleteNChats(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count محادثة',
      many: '$count محادثة',
      few: '$count محادثات',
      two: 'محادثتين',
      one: 'محادثة واحدة',
    );
    return 'حذف $_temp0؟';
  }

  @override
  String deleteNMessages(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count رسالة',
      many: '$count رسالة',
      few: '$count رسائل',
      two: 'رسالتين',
      one: 'رسالة واحدة',
    );
    return 'حذف $_temp0؟';
  }

  @override
  String membersCountPlural(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count عضوًا',
      many: '$count عضوًا',
      few: '$count أعضاء',
      two: 'عضوان',
      one: 'عضو واحد',
    );
    return '$_temp0';
  }

  @override
  String get onboardingOneTitle => 'اعثر على أصدقاء واستلهم';

  @override
  String get onboardingOneSubtitle =>
      'اكتشف محتوى إبداعيًا، واستكشف أفكارًا جديدة، وتواصل مع مجتمع عالمي يشاركك اهتماماتك.';

  @override
  String get onboardingTwoTitle => 'تعرّف على أشخاص رائعين واستمتع';

  @override
  String get onboardingTwoSubtitle =>
      'وسّع شبكتك الاجتماعية، وشارك في حوارات ذات معنى، وشارك لحظاتك المفضلة مع الآخرين.';

  @override
  String get onboardingThreeTitle => 'اقضِ وقتك مع الأصدقاء';

  @override
  String get onboardingThreeSubtitle =>
      'ابقَ قريبًا من أحبائك عبر محادثات فيديو وصوت ونصوص سلسة أينما كنت.';

  @override
  String get deletedForEveryone => 'تم الحذف للجميع';

  @override
  String get deletedForYou => 'تم الحذف لديك';

  @override
  String get photo2 => '📷 صورة';

  @override
  String get video2 => '🎥 فيديو';

  @override
  String get voiceMessage => '🎤 رسالة صوتية';

  @override
  String get gif => '🖼️ GIF';

  @override
  String get sticker2 => '🏷️ ملصق';

  @override
  String get call2 => '📞 مكالمة';

  @override
  String get attachment => '📎 مرفق';

  @override
  String reactWithTo(Object actor, Object emoji, Object snippet) {
    return '$actor تفاعل بـ $emoji على $snippet';
  }

  @override
  String reactWithTo2(Object actor, Object emoji, Object snippet) {
    return '$actor تفاعل بـ $emoji على “$snippet”';
  }

  @override
  String seenBy(Object receiverName) {
    return 'شاهدها $receiverName';
  }

  @override
  String get notReadYet => 'لم تُقرأ بعد';

  @override
  String deliveredTo(Object receiverName) {
    return 'وصلت إلى $receiverName';
  }

  @override
  String get deliveredToAi => 'وصلت إلى الذكاء الاصطناعي';

  @override
  String get responseCreated => 'تم إنشاء الرد';

  @override
  String get noConversationsYet2 => 'لا توجد محادثات بعد.';

  @override
  String get noChatsYet => 'لا توجد محادثات فردية بعد.';

  @override
  String get noGroupsYet => 'لا توجد مجموعات بعد.';

  @override
  String get noFavoriteChatsYet => 'لا توجد محادثات مفضلة بعد.';

  @override
  String get noUnreadChats => 'لا توجد محادثات غير مقروءة.';

  @override
  String get bringYourFriendsTogether =>
      'اجمع أصدقاءك معًا.\nأنشئ مساحة لمشاركة اللحظات.';

  @override
  String get yourInboxIsWaiting =>
      'صندوق رسائلك بانتظارك.\nابدأ محادثة واستكشف علاقات جديدة.';

  @override
  String get startChat => 'بدء محادثة';

  @override
  String get voiceMessages => 'الرسائل الصوتية';

  @override
  String get viewPhoto => 'عرض الصورة';

  @override
  String get playVideo => 'تشغيل الفيديو';

  @override
  String get playVoiceMessage => 'تشغيل الرسالة الصوتية';

  @override
  String get mixedSelection => 'تحديد متنوع';

  @override
  String get deleteThisMessageFor => 'هل تريد حذف هذه الرسالة للجميع؟';

  @override
  String get deleteThisMessageFor2 => 'هل تريد حذف هذه الرسالة لديك؟';

  @override
  String get deleteFromMe => 'حذف لدي';

  @override
  String get justNow => 'الآن';

  @override
  String min(Object inMinutes) {
    return '$inMinutes د';
  }

  @override
  String todayAt(Object time) {
    return 'اليوم الساعة $time';
  }

  @override
  String yesterdayAt(Object time) {
    return 'أمس الساعة $time';
  }

  @override
  String get allAllMembers => 'الكل (@جميع الأعضاء)';

  @override
  String get readMore => 'عرض المزيد...';

  @override
  String get showLess => 'عرض أقل';

  @override
  String get youHaveReachedThe =>
      'لقد وصلت إلى الحد اليومي لاستخدام الذكاء الاصطناعي المجاني. حاول مرة أخرى غدًا.';

  @override
  String get youHaveUsedUp =>
      'لقد استنفدت حصتك اليومية من اقتراحات الذكاء الاصطناعي. ستتجدد غدًا.';

  @override
  String get spellingCorrection => 'التصحيح الإملائي';

  @override
  String get smartReplyToImages => 'الرد الذكي على الصور غير متاح حاليًا';

  @override
  String get aiSuggestion => 'اقتراح الذكاء الاصطناعي';

  @override
  String get chatSummary => 'ملخص المحادثة';

  @override
  String get detailedSummary => 'ملخص مفصّل';

  @override
  String get whatIsTheTopic => 'ما موضوع المحادثة؟';

  @override
  String get thereArentEnoughMessages =>
      'لا توجد رسائل كافية في المحادثة لتلخيصها.';

  @override
  String get youHaveUsedUp2 =>
      'لقد استنفدت حصتك اليومية من الذكاء الاصطناعي. حاول مرة أخرى غدًا.';

  @override
  String get anErrorOccurredPlease => 'حدث خطأ. حاول مرة أخرى لاحقًا.';

  @override
  String usedOfYourDaily2(Object dailyLimit) {
    return 'مستخدم من حدّك اليومي البالغ $dailyLimit طلبًا';
  }

  @override
  String get forwardedFile => 'ملف معاد توجيهه';

  @override
  String get youveReachedTodaysSyncra =>
      'لقد وصلت إلى حد Syncra اليومي — حاول غدًا.';

  @override
  String get syncraIsABit => 'Syncra مشغول قليلًا الآن — حاول بعد قليل.';

  @override
  String get syncraCouldntReachAny =>
      'تعذّر على Syncra الوصول إلى أي مزوّد ذكاء اصطناعي — حاول مرة أخرى.';

  @override
  String get voiceMessage2 => 'رسالة صوتية';

  @override
  String voiceMessage3(Object seconds) {
    return 'رسالة صوتية · $seconds';
  }

  @override
  String get couldntLoadYourConversations => 'تعذّر تحميل محادثاتك.';

  @override
  String get noConversationsYetStart =>
      'لا توجد محادثات بعد — ابدأ واحدة من الأعلى.';

  @override
  String get thisLinkWasAlready => 'تم استخدام هذا الرابط من قبل';

  @override
  String get thisLinkIsNo => 'هذا الرابط لم يعد صالحًا';

  @override
  String get yourPasswordWasAlready =>
      'تم تحديث كلمة مرورك بالفعل وأنت مسجّل الدخول.';

  @override
  String get thisLinkHasExpired =>
      'انتهت صلاحية هذا الرابط أو تم استخدامه من قبل. يرجى طلب رابط جديد.';

  @override
  String get goToHome => 'الذهاب إلى الرئيسية';

  @override
  String get requestNewLink => 'طلب رابط جديد';

  @override
  String get signIn2 => 'تسجيل الدخول';

  @override
  String get signUp => 'إنشاء حساب';

  @override
  String resendInS(Object secondsRemaining) {
    return 'إعادة الإرسال خلال $secondsRemaining ث';
  }

  @override
  String get sendResetLink2 => 'إرسال رابط إعادة التعيين';

  @override
  String get failedToLoadYour => 'تعذّر تحميل محادثاتك.';

  @override
  String send(Object totalSelected) {
    return 'إرسال ($totalSelected)';
  }

  @override
  String get forwardedFrom => 'تمت إعادة التوجيه من ';

  @override
  String get replyingTo => 'رد على ';

  @override
  String and(Object name, Object name2) {
    return '$name و$name2';
  }

  @override
  String andOthers(Object name, Object length) {
    return '$name و$length آخرين';
  }

  @override
  String get isWritingAComment => ' يكتب تعليقًا...';

  @override
  String get areWritingAComment => ' يكتبون تعليقًا...';

  @override
  String get microphonePermissionDenied => 'تم رفض إذن الميكروفون';

  @override
  String get couldNotStartRecording2 => 'تعذّر بدء التسجيل';

  @override
  String get hideReplies => 'إخفاء الردود';

  @override
  String get stickerReadyToSend => 'الملصق جاهز للإرسال';

  @override
  String replyTo(Object replyingToAuthorName) {
    return 'الرد على @$replyingToAuthorName...';
  }

  @override
  String get writeAComment => 'اكتب تعليقًا...';

  @override
  String get noSuggestionsRightNow => 'لا توجد اقتراحات الآن';

  @override
  String feedback(Object shortId) {
    return 'ملاحظة رقم $shortId';
  }

  @override
  String get supportConversation => 'محادثة الدعم';

  @override
  String get couldNotLoadThis2 => 'تعذّر تحميل هذه الملاحظة.';

  @override
  String get thisFeedbackIsNo => 'هذه الملاحظة لم تعد متاحة.';

  @override
  String get pleaseTellUsWhat => 'يرجى إخبارنا بما يدور في ذهنك.';

  @override
  String pleaseWriteAtLeast(Object minMessageLength) {
    return 'يرجى كتابة $minMessageLength أحرف على الأقل.';
  }

  @override
  String get enterAValidEmail => 'أدخل بريدًا إلكترونيًا أو رقم هاتف صالحًا.';

  @override
  String get yourRating => 'تقييمك *';

  @override
  String get yourRatingOptional => 'تقييمك (اختياري)';

  @override
  String get dailyLimitReached => 'تم بلوغ الحد اليومي';

  @override
  String get submitFeedback => 'إرسال الملاحظة';

  @override
  String get whatWentWrongWhat =>
      'ما الذي حدث بشكل خاطئ؟ وماذا كنت تتوقع أن يحدث؟';

  @override
  String get describeTheFeatureYou => 'صِف الميزة التي تتمنى رؤيتها…';

  @override
  String get whatWouldYouLike => 'ماذا تود أن تعرف؟';

  @override
  String get shareYourExperienceWith => 'شاركنا تجربتك مع Social Mate…';

  @override
  String get tellUsWhatYou => 'أخبرنا بما يعجبك!';

  @override
  String get writeYourMessageHere => 'اكتب رسالتك هنا…';

  @override
  String dailyLimitReachedNext(Object left) {
    return 'تم بلوغ الحد اليومي · الملاحظة التالية بعد $left';
  }

  @override
  String ofFeedbacksLeftToday(Object remaining, Object limit) {
    return 'تبقّى $remaining من $limit ملاحظات اليوم';
  }

  @override
  String get couldNotLoadGifs => 'تعذّر تحميل ملفات GIF';

  @override
  String get incomingGroupVideo => 'مكالمة فيديو جماعية واردة';

  @override
  String get incomingGroupVoice => 'مكالمة صوتية جماعية واردة';

  @override
  String get tapToReturnTo => 'اضغط للعودة إلى المكالمة الجماعية';

  @override
  String get groupVideoCall => 'مكالمة فيديو جماعية';

  @override
  String get groupVoiceCall => 'مكالمة صوتية جماعية';

  @override
  String get callingGroupVideo => 'جارٍ الاتصال بالمجموعة (فيديو)...';

  @override
  String get callingGroupAudio => 'جارٍ الاتصال بالمجموعة (صوت)...';

  @override
  String get inTheCall => 'في المكالمة';

  @override
  String get notInTheCall => 'ليس في المكالمة';

  @override
  String get ringing => 'جارٍ الرنين…';

  @override
  String added(Object actor, Object target) {
    return '$actor أضاف $target';
  }

  @override
  String removed(Object actor, Object target) {
    return '$actor أزال $target';
  }

  @override
  String leftTheGroup(Object actor) {
    return '$actor غادر المجموعة';
  }

  @override
  String get noMessagesYet2 => 'لا توجد رسائل بعد';

  @override
  String photo3(Object senderName) {
    return '$senderName: 📷 صورة';
  }

  @override
  String video3(Object senderName) {
    return '$senderName: 🎬 فيديو';
  }

  @override
  String gif2(Object senderName) {
    return '$senderName: 🎞️ GIF';
  }

  @override
  String sticker3(Object senderName) {
    return '$senderName: 😊 ملصق';
  }

  @override
  String voiceMessage4(Object senderName) {
    return '$senderName: 🎤 رسالة صوتية';
  }

  @override
  String groupCall(Object senderName) {
    return '$senderName: 📞 مكالمة جماعية';
  }

  @override
  String addedOnePersonIsnt(Object length) {
    return 'تمت إضافة $length. شخص واحد غير متاح للانضمام حاليًا.';
  }

  @override
  String addedPeopleArentAvailable(Object length, Object length2) {
    return 'تمت إضافة $length. $length2 أشخاص غير متاحين للانضمام حاليًا.';
  }

  @override
  String get thisPersonIsntAvailable =>
      'هذا الشخص غير متاح للانضمام إلى المجموعة حاليًا.';

  @override
  String get thesePeopleArentAvailable =>
      'هؤلاء الأشخاص غير متاحين للانضمام إلى المجموعة حاليًا.';

  @override
  String addMembers2(Object length) {
    return 'إضافة $length أعضاء';
  }

  @override
  String createGroup2(Object length) {
    return 'إنشاء مجموعة ($length)';
  }

  @override
  String youWillLeaveThe(Object name) {
    return 'ستغادر “$name”، وسيتم مسح سجل المحادثة على هذا الجهاز، ولن تتمكن من إعادة إضافتك إلى هذه المجموعة. هل تريد المتابعة؟';
  }

  @override
  String get theChatHistoryOn =>
      'سيتم مسح سجل المحادثة على هذا الجهاز، ولن تتمكن من إعادة إضافتك إلى هذه المجموعة. هل تريد المتابعة؟';

  @override
  String get missedVoiceCall => 'مكالمة صوتية فائتة';

  @override
  String get missedVideoCall => 'مكالمة فيديو فائتة';

  @override
  String get endedCall => 'مكالمة منتهية';

  @override
  String get groupVoiceCall2 => 'مكالمة صوتية جماعية';

  @override
  String get groupVideoCall2 => 'مكالمة فيديو جماعية';

  @override
  String get missedCall => 'مكالمة فائتة';

  @override
  String get ongoingTapToJoin => 'جارية • اضغط للانضمام';

  @override
  String ended(Object duration) {
    return 'انتهت • $duration';
  }

  @override
  String get thisInviteLinkIs => 'رابط الدعوة هذا لم يعد صالحًا';

  @override
  String get openChat => 'فتح المحادثة';

  @override
  String get joinGroup => 'انضمام إلى المجموعة';

  @override
  String joinOnSocialMedia(Object groupName, Object hash) {
    return 'انضم إلى “$groupName” على Social Media App: $hash';
  }

  @override
  String expiresInDH(Object inDays, Object remainder) {
    return 'تنتهي بعد $inDays ي $remainder س';
  }

  @override
  String expiresInHM(Object inHours, Object remainder) {
    return 'تنتهي بعد $inHours س $remainder د';
  }

  @override
  String expiresInM(Object inMinutes) {
    return 'تنتهي بعد $inMinutes د';
  }

  @override
  String recordingAudio(Object userName) {
    return '$userName يسجّل رسالة صوتية...';
  }

  @override
  String peopleRecordingAudio(Object length) {
    return '$length أشخاص يسجّلون رسائل صوتية...';
  }

  @override
  String get noNotificationsYet => 'لا توجد إشعارات بعد';

  @override
  String noNotifications(Object name) {
    return 'لا توجد إشعارات $name';
  }

  @override
  String get followBack => 'متابعة بالمثل';

  @override
  String get sharedSuccessfully => 'تمت المشاركة بنجاح';

  @override
  String get postRemovedFromSaves => 'تمت إزالة المنشور من المحفوظات';

  @override
  String get postSavedSuccessfully => 'تم حفظ المنشور بنجاح';

  @override
  String get publishingPost => 'جارٍ نشر المنشور...';

  @override
  String get unpinPost => 'إلغاء تثبيت المنشور';

  @override
  String get pinPost => 'تثبيت المنشور';

  @override
  String get removeShare => 'إزالة المشاركة';

  @override
  String get removeThisShareFrom =>
      'هل تريد إزالة هذه المشاركة من ملفك الشخصي؟';

  @override
  String get areYouSureYou2 => 'هل أنت متأكد أنك تريد حذف هذا المنشور؟';

  @override
  String get postDeletedSuccessfully => 'تم حذف المنشور بنجاح';

  @override
  String get reshareRemoved => 'تمت إزالة إعادة المشاركة';

  @override
  String get resharedSuccessfully => 'تمت إعادة المشاركة بنجاح';

  @override
  String get aReel => 'ريل';

  @override
  String get aPost => 'منشورًا';

  @override
  String get unknownUser => 'مستخدم غير معروف';

  @override
  String shared(Object contentLabel) {
    return '  شارك $contentLabel';
  }

  @override
  String get editProfilePicture => 'تعديل صورة الملف الشخصي';

  @override
  String get editCoverPhoto => 'تعديل صورة الغلاف';

  @override
  String get optionalShownAsRich =>
      'اختياري — يظهر كبطاقات غنية في ملفك الشخصي.';

  @override
  String noProvidedYet(Object title) {
    return 'لم يتم تقديم $title بعد.';
  }

  @override
  String isFriendsWithBoth(Object names) {
    return '$names صديق لكما معًا';
  }

  @override
  String andAreFriendsWith(Object names, Object second) {
    return '$names و$second صديقان لكما معًا';
  }

  @override
  String andOthersAreFriends(Object names, Object others) {
    return '$names و$others آخرين أصدقاء لكما معًا';
  }

  @override
  String get noPostsToShow => 'لا توجد منشورات لعرضها بعد';

  @override
  String get noPostsYet => 'لا توجد منشورات بعد';

  @override
  String get shareYourThoughtsWith => 'شارك أفكارك مع أصدقائك.';

  @override
  String get thisPersonHasntShared => 'لم يشارك هذا الشخص أي شيء بعد.';

  @override
  String get addAStatus => 'أضف حالة ✨';

  @override
  String get showOnProfile => 'إظهار في الملف الشخصي';

  @override
  String get hideFromProfile => 'إخفاء من الملف الشخصي';

  @override
  String doneSelected(Object length) {
    return 'تم ($length محدد)';
  }

  @override
  String get tellUsWhatIs => 'أخبرنا بما حدث (مطلوب)';

  @override
  String get addDetailsOptional => 'أضف تفاصيل (اختياري)';

  @override
  String get submitReport => 'إرسال البلاغ';

  @override
  String get noAccountsToDiscover => 'لا توجد حسابات لاكتشافها بعد';

  @override
  String noAccountsFoundFor(Object query) {
    return 'لم يتم العثور على حسابات لـ “$query”';
  }

  @override
  String get nothingToShowYet => 'لا يوجد ما يُعرض بعد';

  @override
  String noFriendsFoundFor(Object query) {
    return 'لم يتم العثور على أصدقاء لـ “$query”';
  }

  @override
  String get youHaventJoinedAny => 'لم تنضم إلى أي مجموعة بعد';

  @override
  String get searchForGroups => 'ابحث عن مجموعات';

  @override
  String noGroupsFoundFor(Object query) {
    return 'لم يتم العثور على مجموعات لـ “$query”';
  }

  @override
  String get noReelsAvailable => 'لا توجد ريلز متاحة';

  @override
  String noReelsFoundFor(Object query) {
    return 'لم يتم العثور على ريلز لـ “$query”';
  }

  @override
  String get currentPasswordIsRequired => 'كلمة المرور الحالية مطلوبة';

  @override
  String resetLinkSentResend(Object secs) {
    return 'تم إرسال رابط إعادة التعيين · أعد الإرسال خلال $secs ث';
  }

  @override
  String get forgotYourCurrentPassword => 'هل نسيت كلمة مرورك الحالية؟';

  @override
  String get newPasswordMustBe => 'يجب أن تختلف كلمة المرور الجديدة عن الحالية';

  @override
  String get updatePassword => 'تحديث كلمة المرور';

  @override
  String get setPassword => 'تعيين كلمة المرور';

  @override
  String get noEmailOnFile => 'لا يوجد بريد إلكتروني مسجّل';

  @override
  String isAlsoLinkedTo(Object oauthLabel, Object oauthLabel2) {
    return '$oauthLabel مرتبط أيضًا بهذا الحساب. تغيير بريدك هنا لا يغيّر حساب $oauthLabel2 الخاص بك.';
  }

  @override
  String yourPrimarySignIn(Object oauthLabel) {
    return 'تسجيل دخولك الأساسي مُدار عبر $oauthLabel. بريدك الإلكتروني مرتبط بهذا المزوّد.';
  }

  @override
  String resendInS2(Object secs) {
    return 'إعادة الإرسال خلال $secs ث';
  }

  @override
  String get resendVerification => 'إعادة إرسال التوثيق';

  @override
  String get resendLink => 'إعادة إرسال الرابط';

  @override
  String get passwordIsRequired => 'كلمة المرور مطلوبة';

  @override
  String get newEmailMustBe => 'يجب أن يختلف البريد الجديد عن بريدك الحالي';

  @override
  String get confirmYourPassword => 'أكّد كلمة مرورك';

  @override
  String get oneLastConfirmation => 'تأكيد أخير';

  @override
  String typeToConfirm(Object confirmationWord) {
    return 'اكتب $confirmationWord للتأكيد';
  }

  @override
  String get videoCall2 => 'مكالمة فيديو';

  @override
  String get voiceCall2 => 'مكالمة صوتية';

  @override
  String get callingVideo => 'جارٍ الاتصال (فيديو)...';

  @override
  String get callingAudio => 'جارٍ الاتصال (صوت)...';

  @override
  String get incomingVideoCall => 'مكالمة فيديو واردة';

  @override
  String get incomingVoiceCall => 'مكالمة صوتية واردة';

  @override
  String youCantMessageUntil(Object name) {
    return 'لا يمكنك مراسلة $name حتى تلغي حظره.';
  }

  @override
  String get youCantReplyTo => 'لا يمكنك الرد على هذه المحادثة.';

  @override
  String youBlocked(Object otherUserName) {
    return 'لقد حظرت $otherUserName';
  }

  @override
  String blockedYou(Object otherUserName) {
    return '$otherUserName حظرك';
  }

  @override
  String youUnblocked(Object otherUserName) {
    return 'لقد ألغيت حظر $otherUserName';
  }

  @override
  String unblockedYou(Object otherUserName) {
    return '$otherUserName ألغى حظرك';
  }

  @override
  String sentYouAMessage(Object receiverUser) {
    return '$receiverUser أرسل لك طلب مراسلة. ردّ للقبول أو ارفض.';
  }

  @override
  String get youAreNotFriends =>
      'أنتما لستما أصدقاء أو متابعين. إرسال رسالة سيرسل طلب مراسلة.';

  @override
  String get recordingAudio2 => 'يسجّل رسالة صوتية...';

  @override
  String unblock2(Object name) {
    return 'إلغاء حظر $name';
  }

  @override
  String block(Object name) {
    return 'حظر $name';
  }

  @override
  String get calling => 'جارٍ الاتصال…';

  @override
  String get videoCalling => 'جارٍ مكالمة الفيديو…';

  @override
  String youBlocked2(Object name) {
    return 'لقد حظرت $name';
  }

  @override
  String blockedYou2(Object name) {
    return '$name حظرك';
  }

  @override
  String youUnblocked2(Object name) {
    return 'لقد ألغيت حظر $name';
  }

  @override
  String unblockedYou2(Object name) {
    return '$name ألغى حظرك';
  }

  @override
  String get textStatus => 'حالة نصية';

  @override
  String get failedToLoadYour2 => 'تعذّر تحميل جهات اتصالك.';

  @override
  String done2(Object length) {
    return 'تم ($length)';
  }

  @override
  String get whoCanSeeThis => 'من يمكنه رؤية هذه الحزمة؟';

  @override
  String get whoCanSeeThis2 => 'من يمكنه رؤية هذا؟';

  @override
  String get chooseYourAudienceFor => 'اختر جمهور حزمة الملصقات هذه';

  @override
  String get chooseYourAudienceFor2 => 'اختر جمهور هذه القصة';

  @override
  String get chooseYourAudienceFor3 => 'اختر جمهور هذا المنشور';

  @override
  String stickers3(Object stickerCount, Object asReadableSize) {
    return '$stickerCount ملصقات  •  $asReadableSize';
  }

  @override
  String stickers4(Object stickerCount) {
    return '$stickerCount ملصقات';
  }

  @override
  String mbStickers(
    Object toStringAsFixed,
    Object toStringAsFixed2,
    Object stickerCount,
  ) {
    return '$toStringAsFixed/$toStringAsFixed2 MB  •  $stickerCount ملصقات';
  }

  @override
  String get noFriendsSelected => 'لم يتم اختيار أصدقاء';

  @override
  String friendSSelected(Object length) {
    return 'تم اختيار $length من الأصدقاء';
  }

  @override
  String stickers5(Object stickerCount, Object asReadableSize) {
    return '$stickerCount ملصقات  •  $asReadableSize';
  }

  @override
  String get videoPreview => 'معاينة الفيديو';

  @override
  String get photoPreview => 'معاينة الصورة';

  @override
  String get myStories => 'قصصي';

  @override
  String sStories(Object authorName) {
    return 'قصص $authorName';
  }

  @override
  String get textStory2 => 'قصة نصية';

  @override
  String get videoStory => 'قصة فيديو';

  @override
  String get photoStory => 'قصة صورة';

  @override
  String deleteStories(Object count) {
    return 'هل تريد حذف $count من القصص؟';
  }

  @override
  String get deleteThisStory => 'هل تريد حذف هذه القصة؟';

  @override
  String get gifAnimation => 'صورة GIF متحركة';

  @override
  String get enterThe6Digit2 =>
      'أدخل الرمز المكوّن من 6 أرقام من تطبيق المصادقة.';

  @override
  String get enterOneOfThe =>
      'أدخل أحد رموز الاسترداد التي حفظتها. استخدامه يوقف المصادقة الثنائية.';

  @override
  String get useABackupCode => 'استخدم رمز احتياطي';

  @override
  String get useAuthenticatorCode => 'استخدم رمز المصادقة';

  @override
  String get preparingYourSecureKey => 'جارٍ تجهيز مفتاحك الآمن...';

  @override
  String get generatingRecoveryCodes => 'جارٍ إنشاء رموز الاسترداد...';

  @override
  String get pleaseTryAgain => 'يرجى المحاولة مرة أخرى.';

  @override
  String get recoveryCodesCouldNot => 'تعذّر إنشاء رموز الاسترداد.';

  @override
  String get codeAboutToChange => 'الرمز على وشك التغيّر، انتظر الرمز التالي';

  @override
  String codeUpdatesInS(Object remaining) {
    return 'يتغيّر الرمز خلال $remaining ث';
  }

  @override
  String get useAnAuthenticatorCode => 'استخدم رمز المصادقة بدلًا من ذلك';

  @override
  String get useMyPasswordInstead => 'استخدم كلمة مروري بدلًا من ذلك';

  @override
  String get preparing => 'جارٍ التجهيز...';

  @override
  String get joining => 'جارٍ الانضمام...';

  @override
  String get connecting => 'جارٍ الاتصال...';

  @override
  String get ringing2 => 'جارٍ الرنين...';

  @override
  String get you => 'أنت';

  @override
  String get someone => 'شخص ما';

  @override
  String get today => 'اليوم';

  @override
  String get yesterday => 'أمس';

  @override
  String get unavailable => 'غير متاح';

  @override
  String get summary => 'الملخص';

  @override
  String get weak => 'ضعيفة';

  @override
  String get fair => 'مقبولة';

  @override
  String get good => 'جيدة';

  @override
  String get strong => 'قوية';

  @override
  String get send2 => 'إرسال';

  @override
  String get unknown => 'غير معروف';

  @override
  String get feedback2 => 'ملاحظة';

  @override
  String get mute => 'كتم';

  @override
  String get unmute => 'إلغاء الكتم';

  @override
  String get off => 'متوقف';

  @override
  String get member => 'عضو';

  @override
  String get ring => 'رنين';

  @override
  String get ended2 => 'انتهت';

  @override
  String get expired => 'منتهي';

  @override
  String get trim => 'قص';

  @override
  String get posted => 'تم النشر';

  @override
  String get details => 'التفاصيل';

  @override
  String get attachment2 => 'مرفق';
}
