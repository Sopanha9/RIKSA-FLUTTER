// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Khmer Central Khmer (`km`).
class AppLocalizationsKm extends AppLocalizations {
  AppLocalizationsKm([String locale = 'km']) : super(locale);

  @override
  String get appName => 'Riksa';

  @override
  String get welcomeBack => 'សួស្ដី​ម្ដង​ទៀត';

  @override
  String get loginSubtitle => 'ចូលប្រើប្រាស់ដើម្បីបន្តការសិក្សារបស់អ្នក';

  @override
  String get authReasonSaveProgress =>
      'ចូលគណនី ដើម្បីរក្សាទុកវឌ្ឍនភាពមេរៀន និងការរៀនជាប់គ្នា។';

  @override
  String get authReasonSaveLesson =>
      'ចូលគណនី ដើម្បីរក្សាទុកមេរៀននេះក្នុងបណ្ណាល័យរបស់អ្នក។';

  @override
  String get authReasonPost =>
      'ចូលគណនី ដើម្បីចែករំលែកប្រកាសជាមួយសហគមន៍របស់អ្នក។';

  @override
  String get loginEyebrow => 'កន្លែងសិក្សារបស់អ្នក';

  @override
  String get registerTitle => 'បង្កើត​គណនី';

  @override
  String get registerSubtitle => 'បង្កើតគណនីរបស់អ្នក និងចាប់ផ្ដើមសិក្សាថ្ងៃនេះ';

  @override
  String get registerEyebrow => 'ចាប់ផ្ដើមការសិក្សាបន្តបន្ទាប់';

  @override
  String get accountBasics => 'ព័ត៌មានគណនី';

  @override
  String get secureYourAccount => 'ការពារគណនីរបស់អ្នក';

  @override
  String stepOfTwo(int step) {
    return 'ជំហានទី $step នៃ ២';
  }

  @override
  String get username => 'ឈ្មោះ​អ្នក​ប្រើ';

  @override
  String get usernameHint => 'បញ្ចូលឈ្មោះអ្នកប្រើ';

  @override
  String get emailOrUsername => 'អ៊ីមែល ឬឈ្មោះអ្នកប្រើ';

  @override
  String get emailOrUsernameHint => 'បញ្ចូលអ៊ីមែល ឬឈ្មោះអ្នកប្រើរបស់អ្នក';

  @override
  String get password => 'ពាក្យ​សម្ងាត់';

  @override
  String get passwordHint => 'បញ្ចូលពាក្យសម្ងាត់';

  @override
  String get confirmPassword => 'បញ្ជាក់​ពាក្យ​សម្ងាត់';

  @override
  String get confirmPasswordHint => 'បញ្ចូលពាក្យសម្ងាត់ម្ដងទៀត';

  @override
  String get showPassword => 'បង្ហាញពាក្យសម្ងាត់';

  @override
  String get hidePassword => 'លាក់ពាក្យសម្ងាត់';

  @override
  String get passwordEightCharacters => '៨ តួអក្សរឡើងទៅ';

  @override
  String get passwordUppercase => 'អក្សរធំ';

  @override
  String get passwordLowercase => 'អក្សរតូច';

  @override
  String get passwordNumber => 'លេខ';

  @override
  String get email => 'អ៊ីមែល';

  @override
  String get emailHint => 'you@example.com';

  @override
  String get displayName => 'ឈ្មោះ​បង្ហាញ';

  @override
  String get displayNameHint => 'ឈ្មោះរបស់អ្នកដែលបង្ហាញដល់អ្នកដទៃ';

  @override
  String get phoneNumber => 'លេខ​ទូរស័ព្ទ';

  @override
  String get phoneNumberHint => 'ស្រេចចិត្ត';

  @override
  String get login => 'ចូល';

  @override
  String get register => 'ចុះ​ឈ្មោះ';

  @override
  String get continueLabel => 'បន្ត';

  @override
  String get back => 'ត្រឡប់ក្រោយ';

  @override
  String get tryAgain => 'ព្យាយាមម្ដងទៀត';

  @override
  String get useAnotherAccount => 'ប្រើគណនីផ្សេង';

  @override
  String get readyToLearn => 'ត្រៀមរៀន';

  @override
  String get preparingYourSpace => 'កំពុងរៀបចំកន្លែងសិក្សា';

  @override
  String get orContinueWith => 'ឬ​បន្ត​ជាមួយ';

  @override
  String get orLabel => 'ឬ';

  @override
  String get signInWithGoogle => 'បន្ត​ជាមួយ Google';

  @override
  String get signInWithTelegram => 'បន្ត​ជាមួយ Telegram';

  @override
  String get verify => 'ផ្ទៀង​ផ្ទាត់';

  @override
  String get noAccount => 'មិន​មាន​គណនី​ឬ?';

  @override
  String get haveAccount => 'មាន​គណនី​រួច​ហើយ​ឬ?';

  @override
  String get signUpNow => 'ចុះ​ឈ្មោះ';

  @override
  String get signInNow => 'ចូល';

  @override
  String get forgotPassword => 'ភ្លេច​ពាក្យ​សម្ងាត់?';

  @override
  String get passwordRecoveryUnavailable =>
      'មុខងារសង្គ្រោះពាក្យសម្ងាត់មិនទាន់មាននៅឡើយទេ។';

  @override
  String get requiredField => 'ចន្លោះ​នេះ​ត្រូវ​ការ';

  @override
  String get invalidUsername =>
      'ឈ្មោះ​អ្នក​ប្រើ​ត្រូវ​មាន​យ៉ាង​ហោច​ណាស់ ៣ តួ​អក្សរ';

  @override
  String get invalidEmail => 'បញ្ចូល​អ៊ីមែល​ត្រឹម​ត្រូវ';

  @override
  String get weakPassword =>
      'ពាក្យ​សម្ងាត់​ត្រូវ​មាន ៨ តួ​អក្សរ​ឡើង​ទៅ​មាន​អក្សរ​ធំ អក្សរ​តូច និង​លេខ';

  @override
  String get passwordsDoNotMatch => 'ពាក្យសម្ងាត់មិនត្រូវគ្នា';

  @override
  String get displayNameTooLong => 'ឈ្មោះបង្ហាញត្រូវមានមិនលើសពី ១០០ តួអក្សរ';

  @override
  String get usernameTooLong => 'ឈ្មោះអ្នកប្រើត្រូវមានពី ៣ ដល់ ៥០ តួអក្សរ';

  @override
  String get signInSecureNote =>
      'សម័យចូលប្រើរបស់អ្នកត្រូវបានការពារ និងបន្តដោយស្វ័យប្រវត្តិ។';

  @override
  String get registerEmailNote =>
      'អ្នកអាចផ្ទៀងផ្ទាត់អ៊ីមែលពេលក្រោយក្នុងប្រវត្តិរូប។';

  @override
  String get loginFailed => 'ការ​ចូល​បរាជ័យ។ ពិនិត្យ​ព័ត៌មាន​របស់​អ្នក។';

  @override
  String get registerFailed => 'ការ​ចុះ​ឈ្មោះ​បរាជ័យ។ សូម​ព្យាយាម​ម្ដង​ទៀត។';

  @override
  String get googleFailed => 'ការ​ចូល​តាម Google បរាជ័យ';

  @override
  String get googleNotConfigured =>
      'ការ​ចូល​តាម Google មិន​ទាន់​បាន​កំណត់​សម្រាប់​កំណែ​នេះ​ទេ។';

  @override
  String get googleUnsupported =>
      'ប្រើ​ប៊ូតុង Google ដែល​កម្មវិធី​រុករក​ផ្តល់​ឱ្យ​ដើម្បី​បន្ត។';

  @override
  String get telegramEyebrow => 'មិនត្រូវការពាក្យសម្ងាត់';

  @override
  String get telegramAuthTitle => 'បន្ត​ជាមួយ Telegram';

  @override
  String get telegramAuthSubtitle =>
      'មិនចាំបាច់ចាំលេខសម្គាល់ Telegram ទេ។ ជ្រើសរើសវិធីចូល។ ថ្មីនៅ Riksa? ជម្រើសទាំងពីរនឹងបង្កើតគណនីឱ្យអ្នក។';

  @override
  String get telegramAuthorize => 'បើក Telegram';

  @override
  String get telegramAuthorizeHint =>
      'លឿនបំផុត៖ ចុច Confirm នៅក្នុងបូត Riksa ហើយត្រឡប់មកវិញភ្លាម។';

  @override
  String get telegramUseCode => 'ចូលដោយប្រើកូដ';

  @override
  String get telegramUseCodeHint =>
      'Telegram នៅលើឧបករណ៍ផ្សេង? យកកូដពីបូត ហើយបិទភ្ជាប់នៅទីនេះ។';

  @override
  String get telegramTheBot => 'បូត Riksa';

  @override
  String get telegramCodeTitle => 'ចូលដោយប្រើកូដ';

  @override
  String telegramCodeSubtitle(String bot) {
    return 'បិទភ្ជាប់កូដពី $bot ដើម្បីចូល។';
  }

  @override
  String telegramCodeStepOpen(String bot) {
    return 'បើក $bot ហើយចុច Start ឬផ្ញើ /⁠code';
  }

  @override
  String get telegramCodeStepCopy => 'ចម្លងកូដ ៨ តួអក្សរដែលវាផ្ញើមក';

  @override
  String get telegramCodeStepPaste => 'បិទភ្ជាប់វានៅខាងក្រោម';

  @override
  String telegramOpenBot(String bot) {
    return 'បើក $bot';
  }

  @override
  String get telegramCodeLabel => 'កូដចូល';

  @override
  String get telegramCodeHint => 'ឧ. VE9BLZ8J';

  @override
  String get telegramPasteCode => 'បិទភ្ជាប់កូដ';

  @override
  String get telegramCodeInvalidFormat => 'បញ្ចូលកូដ ៨ តួអក្សរពីបូត';

  @override
  String get telegramCodeRejected =>
      'កូដនេះមិនត្រឹមត្រូវ ឬផុតកំណត់។ ផ្ញើ /code ទៅបូតដើម្បីទទួលកូដថ្មី។';

  @override
  String get telegramNoCodeInClipboard =>
      'រកមិនឃើញកូដចូលក្នុងក្ដារតម្បៀតខ្ទាស់ទេ។';

  @override
  String get telegramSignIn => 'ចូល';

  @override
  String get telegramUseOpenInstead => 'ប្រើ បើក Telegram ជំនួសវិញ';

  @override
  String get telegramSwitchToCode => 'មានបញ្ហា? ចូលដោយប្រើកូដ';

  @override
  String get telegramPrivacyNote =>
      'Riksa ទទួលបានតែឈ្មោះ និងឈ្មោះអ្នកប្រើសាធារណៈ Telegram របស់អ្នកប៉ុណ្ណោះ។ មិនដែលទទួលលេខទូរស័ព្ទ ឬការជជែករបស់អ្នកទេ។';

  @override
  String get telegramWaitingTitle => 'កំពុងរង់ចាំ Telegram';

  @override
  String get telegramWaitingSubtitle =>
      'បញ្ជាក់សំណើនៅក្នុងបូត Riksa រួចត្រឡប់មកអេក្រង់នេះវិញ។';

  @override
  String telegramExpiresIn(String time) {
    return 'សំណើផុតកំណត់ក្នុងរយៈពេល $time';
  }

  @override
  String get telegramOpenAgain => 'បើក Telegram ម្ដងទៀត';

  @override
  String get telegramCopyLink => 'ចម្លងតំណ';

  @override
  String get telegramLinkCopied =>
      'បានចម្លងតំណ។ បើកវានៅលើឧបករណ៍ណាដែលមាន Telegram។';

  @override
  String get telegramOpenFailed =>
      'មិនអាចបើក Telegram បានទេ។ សូមដំឡើង Telegram ឬចម្លងតំណហើយបើកនៅលើឧបករណ៍ផ្សេង។';

  @override
  String get telegramStartFailed =>
      'មិនអាចចាប់ផ្ដើមការអនុញ្ញាតតាម Telegram បានទេ។ សូមព្យាយាមម្ដងទៀត។';

  @override
  String get telegramExpired =>
      'សំណើនេះបានផុតកំណត់។ សូមចាប់ផ្ដើមម្ដងទៀតដើម្បីទទួលតំណថ្មី។';

  @override
  String get telegramDenied => 'សំណើត្រូវបានបដិសេធនៅក្នុង Telegram។';

  @override
  String get telegramSignupExpired =>
      'ការអនុញ្ញាតតាម Telegram បានផុតកំណត់មុនពេលបង្កើតគណនី។ សូមអនុញ្ញាតម្ដងទៀត។';

  @override
  String get telegramProfileEyebrow => 'បានភ្ជាប់ Telegram';

  @override
  String get telegramProfileTitle => 'រៀបចំប្រវត្តិរូប Riksa របស់អ្នក';

  @override
  String get telegramProfileSubtitle =>
      'ជ្រើសរើសរបៀបដែលអ្នករៀនផ្សេងទៀតឃើញអ្នក។ អ្នកអាចប្ដូរឈ្មោះបង្ហាញពេលក្រោយបាន។';

  @override
  String telegramConnectedAs(String name) {
    return 'បានភ្ជាប់ជា $name';
  }

  @override
  String get telegramCreateAccount => 'បង្កើតគណនី';

  @override
  String get telegramUseAnotherAccount => 'ប្រើគណនី Telegram ផ្សេង';

  @override
  String get languageEn => 'English';

  @override
  String get languageKm => 'ខ្មែរ';

  @override
  String get community => 'សហគមន៍';

  @override
  String get myFeed => 'មតិព័ត៌មានរបស់ខ្ញុំ';

  @override
  String streakDays(int count) {
    return '$count ថ្ងៃ';
  }

  @override
  String get streakTitle => 'ការសិក្សាបន្ត';

  @override
  String get streakSubtitle =>
      'រៀនរាល់ថ្ងៃ ដើម្បីបន្តការសិក្សារបស់អ្នកឱ្យកាន់តែប្រសើរ។';

  @override
  String get heatmapLess => 'តិច';

  @override
  String get heatmapMore => 'ច្រើន';

  @override
  String get bestStreak => 'ការសិក្សាបន្តល្អបំផុត';

  @override
  String get lastTracked => 'បានកត់ត្រាចុងក្រោយ';

  @override
  String get noTrackedDate => 'មិនទាន់មានសកម្មភាពសិក្សាដែលបានកត់ត្រាទេ។';

  @override
  String get activityCalendar => 'ប្រតិទិនសកម្មភាព';

  @override
  String get createCommunityContent => 'បង្កើតក្នុងសហគមន៍';

  @override
  String get startConversation => 'ចាប់ផ្តើមការសន្ទនា';

  @override
  String get startConversationHint => 'ចែករំលែកអ្វីមួយជាមួយ RIKSA...';

  @override
  String get createPost => 'បង្កើតការបង្ហោះ';

  @override
  String get createPostSubtitle => 'ចែករំលែកគំនិត មេរៀន ឬធនធានមានប្រយោជន៍។';

  @override
  String get askCommunity => 'សួរសហគមន៍';

  @override
  String get askCommunitySubtitle => 'សុំជំនួយពីអ្នកសិក្សាផ្សេងទៀត។';

  @override
  String get writeArticle => 'សរសេរអត្ថបទ';

  @override
  String get writeArticleSubtitle =>
      'អត្ថបទវែងសម្រាប់ប្លុក ដែលត្រូវពិនិត្យមុនបង្ហាញ។';

  @override
  String get yourArticles => 'អត្ថបទរបស់អ្នក';

  @override
  String articlesInReview(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count កំពុងពិនិត្យ',
    );
    return '$_temp0';
  }

  @override
  String get communityComposerPrompt => 'តើអ្នកមានចម្ងល់អ្វី?';

  @override
  String get chooseCommunity => 'ជ្រើសរើសសហគមន៍';

  @override
  String get postTitleLabel => 'ចំណងជើងការបង្ហោះ';

  @override
  String get questionTitleLabel => 'តើអ្នកចង់សួរអ្វី?';

  @override
  String get detailsLabel => 'បន្ថែមព័ត៌មានលម្អិត';

  @override
  String get addPhoto => 'បន្ថែមរូបភាព';

  @override
  String get changePhoto => 'ប្ដូររូបភាព';

  @override
  String get removePhoto => 'លុបរូបភាព';

  @override
  String get photoUploading => 'កំពុងផ្ទុករូបភាព…';

  @override
  String get photoFailed => 'មិនអាចផ្ទុករូបភាពនេះបានទេ។ សូមជ្រើសរើសរូបផ្សេង។';

  @override
  String get photoTooLarge => 'រូបភាពនេះធំពេក។ សូមជ្រើសរើសរូបតូចជាង 2MB។';

  @override
  String get photoFromGallery => 'ជ្រើសរើសពីវិចិត្រសាល';

  @override
  String get photoFromCamera => 'ថតរូប';

  @override
  String get publish => 'បោះពុម្ពផ្សាយ';

  @override
  String get publishFailed =>
      'យើងមិនអាចបោះពុម្ពផ្សាយបានទេ។ សូមពិនិត្យខ្លឹមសារ ហើយព្យាយាមម្ដងទៀត។';

  @override
  String get noCommunities => 'មិនទាន់មានសហគមន៍ទេ។';

  @override
  String get blogEmptyMessage => 'អត្ថបទថ្មីៗពីសហគមន៍ RIKSA នឹងបង្ហាញនៅទីនេះ។';

  @override
  String get communityHeadline => 'រៀនជាមួយគ្នា។ ចែករំលែកអ្វីដែលអ្នកយល់។';

  @override
  String get communitySubtitle =>
      'សួរសំណួរ ចែករំលែកគំនិតមានប្រយោជន៍ និងអបអរវឌ្ឍនភាពជាមួយអ្នកសិក្សា RIKSA។';

  @override
  String get forYou => 'សម្រាប់អ្នក';

  @override
  String get official => 'ផ្លូវការ';

  @override
  String get topLearnersThisWeek => 'អ្នកសិក្សាឆ្នើមប្រចាំសប្តាហ៍';

  @override
  String get viewAll => 'មើលទាំងអស់';

  @override
  String upvotesCount(int count) {
    return 'ការគាំទ្រ $count';
  }

  @override
  String get popularCommunities => 'សហគមន៍ពេញនិយម';

  @override
  String membersLabel(int count) {
    return 'សមាជិក $count នាក់';
  }

  @override
  String get join => 'ចូលរួម';

  @override
  String get joined => 'បានចូលរួម';

  @override
  String get feedEmptyTitle => 'មតិព័ត៌មានសហគមន៍របស់អ្នករួចរាល់';

  @override
  String get feedEmptyMessage =>
      'ការបង្ហោះពីសហគមន៍នេះនឹងបង្ហាញនៅទីនេះ ពេលអ្នកសិក្សាចាប់ផ្ដើមចែករំលែក។';

  @override
  String get feedErrorTitle => 'យើងមិនអាចផ្ទុកសហគមន៍បានទេ';

  @override
  String get loadMore => 'ផ្ទុកបន្ថែម';

  @override
  String get copiedLink => 'បានចម្លងតំណការបង្ហោះ';

  @override
  String get actionFailed => 'សកម្មភាពនេះមិនបានសម្រេចទេ។ សូមព្យាយាមម្ដងទៀត។';

  @override
  String get postDetail => 'ព័ត៌មានលម្អិតនៃការបង្ហោះ';

  @override
  String get editPost => 'កែសម្រួលការបង្ហោះ';

  @override
  String get deletePost => 'លុបការបង្ហោះ';

  @override
  String get postOptions => 'ជម្រើសការបង្ហោះ';

  @override
  String get deletePostTitle => 'លុបការបង្ហោះនេះមែនទេ?';

  @override
  String get deletePostMessage =>
      'ការបង្ហោះ និងមតិយោបល់របស់វា នឹងត្រូវលុបចេញសម្រាប់អ្នកទាំងអស់គ្នា។ សកម្មភាពនេះមិនអាចត្រឡប់វិញបានទេ។';

  @override
  String get keepPost => 'រក្សាទុកការបង្ហោះ';

  @override
  String get delete => 'លុប';

  @override
  String get postUpdated => 'បានរក្សាទុកការផ្លាស់ប្ដូរ';

  @override
  String get postDeleted => 'បានលុបការបង្ហោះ';

  @override
  String get saveFailed =>
      'យើងមិនអាចរក្សាទុកការផ្លាស់ប្ដូរបានទេ។ សូមព្យាយាមម្ដងទៀត។';

  @override
  String get deleteFailed =>
      'យើងមិនអាចលុបការបង្ហោះនេះបានទេ។ សូមព្យាយាមម្ដងទៀត។';

  @override
  String get editPostSubtitle =>
      'ធ្វើបច្ចុប្បន្នភាពអ្វីដែលអ្នកបានចែករំលែកជាមួយសហគមន៍។';

  @override
  String get discussion => 'ការពិភាក្សា';

  @override
  String get addComment => 'ចូលរួមក្នុងការពិភាក្សា';

  @override
  String get sendComment => 'ផ្ញើមតិយោបល់';

  @override
  String get reply => 'ឆ្លើយតប';

  @override
  String get replyingTo => 'កំពុងឆ្លើយតបទៅកាន់';

  @override
  String get commentFailed =>
      'យើងមិនអាចបន្ថែមមតិយោបល់របស់អ្នកបានទេ។ សូមព្យាយាមម្ដងទៀត។';

  @override
  String get noComments => 'មិនទាន់មានមតិយោបល់ទេ។ ចាប់ផ្ដើមការសន្ទនា។';

  @override
  String get postUnavailable => 'មិនអាចមើលការបង្ហោះបាន';

  @override
  String get postUnavailableMessage =>
      'ការបង្ហោះនេះអាចត្រូវបានលុប ឬលែងអាចមើលឃើញ។';

  @override
  String get profile => 'ប្រវត្តិរូប';

  @override
  String get shareProfile => 'ចែករំលែកប្រវត្តិរូប';

  @override
  String get profileLinkCopied => 'បានចម្លងតំណប្រវត្តិរូប';

  @override
  String get blog => 'ប្លុក';

  @override
  String get setUpProfile => 'រៀបចំប្រវត្តិរូប';

  @override
  String get onboardingLearningBody =>
      'មេរៀន គ្រូបង្វឹក AI និងមិត្តភក្តិដែលពន្យល់តាមរបៀបរបស់គេ។ ការរៀនស្រាលជាងមុន ពេលមានគ្នា។';

  @override
  String get onboardingAchievementBody =>
      'រក្សាការសិក្សាបន្ត ឡើងតារាងចំណាត់ថ្នាក់ ហើយឱ្យដៃគូរបស់អ្នកអបអរគ្រប់ជោគជ័យ។';

  @override
  String get onboardingCommunityBody =>
      'ចូលរួមសហគមន៍ ចែករំលែកអ្វីដែលអ្នកកំពុងធ្វើ និងសួរអ្វីក៏បាន។ តែងតែមានគេនៅក្បែរអ្នក។';

  @override
  String get onboardingLearningTitle => 'រៀនជាមួយគ្នា មិនមែនម្នាក់ឯង';

  @override
  String get onboardingAchievementTitle => 'រីកចម្រើនជាមួយដៃគូរបស់អ្នក';

  @override
  String get onboardingCommunityTitle => 'មិត្តភក្តិរបស់អ្នកនៅទីនេះ';

  @override
  String get onboardingReturningAccount => 'ខ្ញុំមានគណនីរួចហើយ';

  @override
  String get onboardingGetStarted => 'ចាប់ផ្តើម';

  @override
  String onboardingPageLabel(int page, int count) {
    return 'ទំព័រ $page ក្នុងចំណោម $count ទំព័រ';
  }

  @override
  String get selectProvinceTitle => 'ជ្រើសរើសខេត្តរបស់អ្នក';

  @override
  String get selectProvinceSubtitle =>
      'ខេត្តរបស់អ្នកជួយកំណត់សហគមន៍ក្នុងតំបន់ និងចំណាត់ថ្នាក់តាមខេត្ត។ ព័ត៌មាននេះនឹងត្រូវរក្សាទុកដោយសុវត្ថិភាពក្នុងប្រវត្តិរូប បន្ទាប់ពីអ្នកចូលគណនី។';

  @override
  String get searchProvince => 'ស្វែងរកខេត្ត';

  @override
  String get searchCommunity => 'ស្វែងរក';

  @override
  String get searchCommunityHint => 'សាកល្បងពាក្យគន្លឹះផ្សេង។';

  @override
  String get noSearchResults => 'រកមិនឃើញលទ្ធផលដែលត្រូវគ្នា';

  @override
  String get noProvinceResults => 'រកមិនឃើញខេត្តដែលត្រូវនឹងការស្វែងរកទេ។';

  @override
  String get provinceLoadFailed => 'យើងមិនអាចផ្ទុកបញ្ជីខេត្តបានទេ។';

  @override
  String get provinceSaveFailed =>
      'យើងមិនអាចរក្សាទុកខេត្តរបស់អ្នកបានទេ។ សូមព្យាយាមម្ដងទៀត។';

  @override
  String get home => 'ទំព័រ​ដើម';

  @override
  String get learn => 'រៀន';

  @override
  String get learningTitle => 'ការសិក្សា';

  @override
  String get continueLearning => 'បន្តការសិក្សា';

  @override
  String get searchLessons => 'ស្វែងរកមេរៀន';

  @override
  String get leaderboard => 'តារាងចំណាត់ថ្នាក់';

  @override
  String get ranksTab => 'ចំណាត់ថ្នាក់';

  @override
  String get logout => 'ចេញ';

  @override
  String get loading => 'កំពុង​ផ្ទុក...';

  @override
  String get learningHeadline => 'ស្វែងរកមេរៀនបន្ទាប់របស់អ្នក';

  @override
  String get learningSubtitle =>
      'ជ្រើសរើសថ្នាក់ មុខវិជ្ជា និងកម្រិត ដើម្បីរៀនតាមល្បឿនរបស់អ្នក។';

  @override
  String get learningHeaderSubtitle => 'រៀនបន្តិចម្តងៗ រាល់ថ្ងៃ';

  @override
  String get dailyMissionEyebrow => 'បេសកកម្មថ្ងៃនេះ';

  @override
  String get dailyMissionBody =>
      'មេរៀនខ្លីមួយ ដែលបានជ្រើសសម្រាប់ល្បឿនរបស់អ្នក។';

  @override
  String get startDailyMission => 'ចាប់ផ្តើមមេរៀន';

  @override
  String get filters => 'តម្រង';

  @override
  String get filterLessons => 'តម្រងមេរៀន';

  @override
  String get applyFilters => 'បង្ហាញមេរៀន';

  @override
  String get resetFilters => 'កំណត់ឡើងវិញ';

  @override
  String removeFilter(String filter) {
    return 'ដកតម្រង $filter';
  }

  @override
  String minutesShort(int minutes) {
    return '$minutes នាទី';
  }

  @override
  String get gradeFilter => 'ថ្នាក់';

  @override
  String get subjectFilter => 'មុខវិជ្ជា';

  @override
  String get difficultyFilter => 'កម្រិត';

  @override
  String get allGrades => 'គ្រប់ថ្នាក់';

  @override
  String gradeNumber(int grade) {
    return 'ថ្នាក់ទី $grade';
  }

  @override
  String gradeDataPending(int grade) {
    return 'បានជ្រើសរើសថ្នាក់ទី $grade។ រហូតដល់ API បន្ថែមស្លាកថ្នាក់ យើងនៅតែបង្ហាញមេរៀនដែលមិនទាន់កំណត់ថ្នាក់។';
  }

  @override
  String get allSubjects => 'គ្រប់មុខវិជ្ជា';

  @override
  String get allLevels => 'គ្រប់កម្រិត';

  @override
  String get recommendedLessons => 'មេរៀនដែលណែនាំ';

  @override
  String get doneLabel => 'រួច';

  @override
  String get completedLabel => 'បានបញ្ចប់';

  @override
  String get roadmapCompletedEarlier => 'បានបញ្ចប់ពីមុន · ផ្នែកនេះនៅតែបើក';

  @override
  String get generalSubject => 'ទូទៅ';

  @override
  String get difficultyEasy => 'ងាយ';

  @override
  String get difficultyMedium => 'មធ្យម';

  @override
  String get difficultyHard => 'ពិបាក';

  @override
  String get difficultyDifficult => 'កម្រិតខ្ពស់';

  @override
  String get contentTypeLesson => 'មេរៀន';

  @override
  String get contentTypeChallenge => 'ការប្រកួតប្រជែង';

  @override
  String get contentTypeRoadmap => 'ផែនទីសិក្សា';

  @override
  String exerciseCount(int count) {
    return 'លំហាត់ $count';
  }

  @override
  String baseXpLabel(int xp) {
    return '$xp XP មូលដ្ឋាន';
  }

  @override
  String greetingNamed(String name) {
    return 'សួស្តី $name';
  }

  @override
  String get gradeStemLabel => 'ថ្នាក់ទី១២ · STEM';

  @override
  String get yourSubjects => 'មុខវិជ្ជារបស់អ្នក';

  @override
  String get mathematicsSubjectDescription =>
      'ពង្រឹងជំនាញលេខ និងការដោះស្រាយបញ្ហា';

  @override
  String get physicsSubjectDescription => 'ស្វែងយល់ពីចលនា កម្លាំង និងសកលលោក';

  @override
  String get chemistrySubjectDescription =>
      'ស្វែងយល់ពីសារធាតុ ប្រតិកម្ម និងការប្រែប្រួល';

  @override
  String get biologySubjectDescription =>
      'ស្វែងយល់ពីប្រព័ន្ធរស់ និងវិទ្យាសាស្ត្រជីវិត';

  @override
  String get technologySubjectDescription =>
      'អនុវត្តកុំព្យូទ័រ និងបច្ចេកវិទ្យាឌីជីថល';

  @override
  String get generalSubjectDescription => 'ស្វែងយល់ពីមុខវិជ្ជា និងមេរៀននេះ';

  @override
  String get continueReading => 'បន្តអាន';

  @override
  String xpRewardAmount(int xp) {
    return '+$xp XP';
  }

  @override
  String lessonsDoneOfTotal(int done, int total) {
    return 'មេរៀន $done ក្នុងចំណោម $total';
  }

  @override
  String subjectCountShort(int done, int total) {
    return '$done / $total';
  }

  @override
  String get examDestination => 'បាក់ឌុប · ថ្នាក់ទី១២';

  @override
  String daysRemaining(int days) {
    return '$days ថ្ងៃ';
  }

  @override
  String get subjectUnavailable => 'មិនអាចផ្ទុកបាន';

  @override
  String get noSubjectsYet => 'មិនទាន់មានមុខវិជ្ជា STEM';

  @override
  String get noSubjectsYetBody =>
      'មុខវិជ្ជាថ្នាក់ទី១២ នឹងបង្ហាញនៅទីនេះ ពេលបានផ្សព្វផ្សាយ។';

  @override
  String get everySubjectFinished => 'អ្នកបានបញ្ចប់គ្រប់មុខវិជ្ជា';

  @override
  String get everySubjectFinishedBody =>
      'អ្នកបានរៀនកម្មវិធីសិក្សា STEM ថ្នាក់ទី១២ ទាំងមូលហើយ។';

  @override
  String unitOfTotal(int current, int total) {
    return 'ជំពូកទី $current ក្នុងចំណោម $total';
  }

  @override
  String wholeSyllabusSummary(int units, int lessons) {
    return 'ជំពូក $units, មេរៀន $lessons';
  }

  @override
  String unitProgressShort(int done, int total) {
    return 'រួច $done ក្នុងចំណោម $total';
  }

  @override
  String get youAreHere => 'អ្នកនៅទីនេះ';

  @override
  String opensAfterUnit(int number) {
    return 'បើកបន្ទាប់ពីជំពូកទី $number';
  }

  @override
  String get lessonLockedShort => 'ជាប់សោ';

  @override
  String lessonCountLabel(int count) {
    return 'មេរៀន $count';
  }

  @override
  String get readyForExam => 'ត្រៀមរួចសម្រាប់បាក់ឌុប';

  @override
  String get roadmapLoadFailed => 'យើងមិនអាចផ្ទុកផែនទីសិក្សានេះបានទេ';

  @override
  String get roadmapEmpty => 'មុខវិជ្ជានេះមិនទាន់មានមេរៀន';

  @override
  String get roadmapEmptyBody => 'មេរៀននឹងបង្ហាញនៅទីនេះ ពេលបានផ្សព្វផ្សាយ។';

  @override
  String get lessonLocked => 'សូមបញ្ចប់មេរៀនមុន ដើម្បីបើកមេរៀននេះ';

  @override
  String get lessonLoadFailed => 'យើងមិនអាចផ្ទុកមេរៀនបានទេ';

  @override
  String get noLessonsFound => 'រកមិនឃើញមេរៀន';

  @override
  String get noLessonsForFilters =>
      'សាកល្បងជ្រើសរើសថ្នាក់ មុខវិជ្ជា ឬកម្រិតផ្សេង។';

  @override
  String get lessonPreviewHeading => 'ត្រៀមខ្លួនហើយឬនៅ';

  @override
  String get lessonPreviewBody =>
      'រៀនម្តងមួយជំហាន។ វឌ្ឍនភាពរបស់អ្នកនឹងត្រូវបានរក្សាទុក។';

  @override
  String get beginLesson => 'ចាប់ផ្តើមរៀន';

  @override
  String get lessonContentUnavailable =>
      'សកម្មភាពមេរៀននឹងបង្ហាញ នៅពេលសេវាកម្មសិក្សាផ្តល់ព័ត៌មានលម្អិត។';

  @override
  String get backToLessons => 'ត្រឡប់ទៅមេរៀន';

  @override
  String get accountSettings => 'ការកំណត់គណនី';

  @override
  String get riksaLearner => 'អ្នកសិក្សា RIKSA';

  @override
  String memberSince(String date) {
    return 'សមាជិកតាំងពី $date';
  }

  @override
  String get verified => 'បានផ្ទៀងផ្ទាត់';

  @override
  String get notVerified => 'មិនទាន់ផ្ទៀងផ្ទាត់';

  @override
  String get accountRole => 'តួនាទីគណនី';

  @override
  String get totalXp => 'XP សរុប';

  @override
  String get currentStreak => 'ការសិក្សាបន្ត';

  @override
  String get achievements => 'សមិទ្ធផល';

  @override
  String get currentRank => 'ចំណាត់ថ្នាក់បច្ចុប្បន្ន';

  @override
  String get startingTier => 'កម្រិតចាប់ផ្តើម';

  @override
  String get highestRankReached => 'អ្នកបានឈានដល់ចំណាត់ថ្នាក់ខ្ពស់បំផុត។';

  @override
  String xpUntilNextRank(int xp, String tier) {
    return 'ត្រូវការ $xp XP ទៀតដើម្បីឡើងទៅ $tier';
  }

  @override
  String tierBandProgress(String earned, String total) {
    return '$earned / $total XP';
  }

  @override
  String xpUntilFinalRank(int xp, String tier) {
    return 'នៅ $xp XP ទៀតដល់ $tier ដែលជាឋានៈចុងក្រោយ';
  }

  @override
  String tierPosition(int position, int total) {
    return 'ឋានៈទី $position ក្នុងចំណោម $total';
  }

  @override
  String get earned => 'ទទួលបាន';

  @override
  String get recentActivity => 'សកម្មភាពថ្មីៗ';

  @override
  String get noAchievements => 'សមិទ្ធផល និងវឌ្ឍនភាពរបស់អ្នកនឹងបង្ហាញនៅទីនេះ។';

  @override
  String get noRecentActivity =>
      'សកម្មភាព XP របស់អ្នកនឹងបង្ហាញនៅទីនេះពេលអ្នកសិក្សា។';

  @override
  String get profileLoadFailed => 'យើងមិនអាចផ្ទុកប្រវត្តិសិក្សារបស់អ្នកបានទេ។';

  @override
  String get lessonCompletionReward => 'បានបញ្ចប់មេរៀន';

  @override
  String get achievementReward => 'រង្វាន់សមិទ្ធផល';

  @override
  String get streakReward => 'រង្វាន់ការសិក្សាបន្ត';

  @override
  String get rankReward => 'រង្វាន់ចំណាត់ថ្នាក់';

  @override
  String get welcomeBonus => 'រង្វាន់ស្វាគមន៍';

  @override
  String get xpReward => 'រង្វាន់ XP';

  @override
  String get myPosts => 'ការបង្ហោះរបស់ខ្ញុំ';

  @override
  String get profileArticlesTab => 'អត្ថបទ';

  @override
  String get profileBadgesTab => 'សមិទ្ធផល';

  @override
  String get profileRankTab => 'ចំណាត់ថ្នាក់';

  @override
  String get leaderboardRank => 'ចំណាត់ថ្នាក់តារាងពិន្ទុ';

  @override
  String get noPostsYet => 'ការបង្ហោះក្នុងសហគមន៍របស់អ្នកនឹងបង្ហាញនៅទីនេះ។';

  @override
  String get profileComposerPrompt => 'ចែករំលែកអ្វីដែលអ្នកកំពុងរៀន';

  @override
  String profilePostCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ការបង្ហោះ $count',
      one: 'ការបង្ហោះ ១',
      zero: 'មិនទាន់មានការបង្ហោះ',
    );
    return '$_temp0';
  }

  @override
  String get writeFirstPost => 'សរសេរការបង្ហោះដំបូងរបស់អ្នក';

  @override
  String get managePost => 'គ្រប់គ្រងការបង្ហោះ';

  @override
  String get countryRank => 'ចំណាត់ថ្នាក់កម្ពុជា';

  @override
  String get provinceRank => 'ចំណាត់ថ្នាក់ខេត្ត';

  @override
  String get unranked => 'មិនទាន់មានចំណាត់ថ្នាក់';

  @override
  String get settings => 'ការកំណត់';

  @override
  String get openProfileMenu => 'បើកម៉ឺនុយប្រវត្តិរូប';

  @override
  String get communitiesMenu => 'សហគមន៍';

  @override
  String get progressHistory => 'វឌ្ឍនភាព';

  @override
  String get editProfile => 'កែប្រែប្រវត្តិរូប';

  @override
  String get notificationPreferences => 'ការជូនដំណឹង';

  @override
  String get notificationPreferencesHint => 'រំលឹកអំពីការសិក្សា និងសហគមន៍';

  @override
  String get learningSounds => 'សំឡេងសម្រាប់ការរៀន';

  @override
  String get learningSoundsHint =>
      'បន្លឺសំឡេងពេលឆ្លើយត្រូវ ខុស និងពេលបញ្ចប់មេរៀន។';

  @override
  String get darkMode => 'មុខងារងងឹត';

  @override
  String get darkModeHint => 'ប្រើរូបរាងងងឹតរបស់ RIKSA';

  @override
  String get language => 'ភាសា';

  @override
  String get helpAndLegal => 'ជំនួយ និងច្បាប់';

  @override
  String get faq => 'សំណួរញឹកញាប់';

  @override
  String get termsOfService => 'លក្ខខណ្ឌប្រើប្រាស់';

  @override
  String get privacyPolicy => 'គោលការណ៍ឯកជនភាព';

  @override
  String get fullName => 'ឈ្មោះពេញ';

  @override
  String get bio => 'ប្រវត្តិខ្លី';

  @override
  String get gender => 'ភេទ';

  @override
  String get genderUnspecified => 'មិនចង់បញ្ជាក់';

  @override
  String get saveChanges => 'រក្សាទុកការផ្លាស់ប្តូរ';

  @override
  String get changesSaved => 'ប្រវត្តិរូបរបស់អ្នកត្រូវបានកែប្រែ។';

  @override
  String get profileSaveFailed =>
      'យើងមិនអាចរក្សាទុកប្រវត្តិរូបបានទេ។ សូមព្យាយាមម្ដងទៀត។';

  @override
  String get deleteAccount => 'លុបគណនី';

  @override
  String get deleteAccountTitle => 'លុបគណនី RIKSA របស់អ្នកមែនទេ?';

  @override
  String get deleteAccountConfirmation =>
      'វានឹងលុបប្រវត្តិសិក្សា XP សមិទ្ធផល និងការបង្ហោះរបស់អ្នកជាអចិន្ត្រៃយ៍។ បន្តទេ?';

  @override
  String get cancel => 'បោះបង់';

  @override
  String get deleteUnavailable =>
      'API មិនទាន់គាំទ្រការលុបគណនីទេ។ សូមទាក់ទងក្រុមគាំទ្រ RIKSA។';

  @override
  String get accountIdentifiersReadOnly =>
      'អ៊ីមែល លេខទូរស័ព្ទ និងឈ្មោះអ្នកប្រើ គឺជាព័ត៌មានសុវត្ថិភាពដែលមិនអាចកែប្រែនៅទីនេះបានទេ។';

  @override
  String get chooseAvatar => 'ជ្រើសរើសរូបតំណាង';

  @override
  String get humationAvatarSubtitle =>
      'ជ្រើសរើសតួអង្គគូរដោយដៃសម្រាប់ប្រវត្តិរូប RIKSA របស់អ្នក។';

  @override
  String get editCover => 'កែរូបគម្រប';

  @override
  String get chooseProfileCover => 'ជ្រើសរើសរូបគម្របប្រវត្តិរូប';

  @override
  String get profileCoverSubtitle => 'ជ្រើសរើសពណ៌ និងលំនាំដែលបង្ហាញពីអ្នក។';

  @override
  String get chooseFromPhotos => 'ជ្រើសរើសពីរូបថត';

  @override
  String get imageSelectionFailed =>
      'យើងមិនអាចប្រើរូបភាពនោះបានទេ។ សូមសាកល្បងរូបភាពផ្សេង។';

  @override
  String get notProvided => 'មិនបានផ្តល់';

  @override
  String get supportDocumentUnavailable =>
      'ឯកសារនេះនឹងមាននៅទីនេះ បន្ទាប់ពីខ្លឹមសារជំនួយ RIKSA ត្រូវបានផ្សព្វផ្សាយ។';

  @override
  String get aiTutor => 'គ្រូ AI';

  @override
  String get aiTutorComingSoon => 'គ្រូ AI របស់ RIKSA នឹងមកដល់ឆាប់ៗនេះ។';

  @override
  String get publicProfile => 'ប្រវត្តិរូបសាធារណៈ';

  @override
  String get posts => 'ការបង្ហោះ';

  @override
  String get publicProfileUnavailable => 'មិនអាចមើលប្រវត្តិរូបបាន';

  @override
  String get publicProfileUnavailableMessage =>
      'អ្នកនេះប្រហែលជាបានលុបគណនី ត្រូវបានផ្អាក ឬបានកំណត់ការចូលមើលប្រវត្តិរូប។';

  @override
  String get publicProfileLoadFailed =>
      'យើងមិនអាចផ្ទុកប្រវត្តិរូបសាធារណៈនេះបានទេ។ សូមព្យាយាមម្ដងទៀត។';

  @override
  String get publicPostsLoadFailed =>
      'យើងមិនអាចផ្ទុកការបង្ហោះរបស់អ្នកនេះបានទេ។';

  @override
  String get noPublicPosts =>
      'អ្នកនេះមិនទាន់បានចែករំលែកការបង្ហោះក្នុងសហគមន៍ទេ។';

  @override
  String get noPublicAchievements =>
      'មិនទាន់មានសមិទ្ធផលដែលទទួលបានសម្រាប់បង្ហាញទេ។';

  @override
  String get noPublicRank => 'មិនទាន់មានចំណាត់ថ្នាក់សាធារណៈសម្រាប់បង្ហាញទេ។';

  @override
  String get aiTutorSubtitle => 'សួរអ្វីក៏បាន ពីមេរៀនរបស់អ្នក';

  @override
  String get aiAskNewQuestion => 'សួរសំណួរថ្មី';

  @override
  String get aiChatsToday => 'ថ្ងៃនេះ';

  @override
  String get aiChatsThisWeek => 'សប្ដាហ៍នេះ';

  @override
  String get aiChatsEarlier => 'មុននេះ';

  @override
  String get aiChatOptions => 'ជម្រើសនៃការសន្ទនា';

  @override
  String get aiDeleteChat => 'លុបការសន្ទនា';

  @override
  String get aiChatDeleted => 'បានលុបការសន្ទនា';

  @override
  String get aiUndo => 'មិនធ្វើវិញ';

  @override
  String get aiChatDeleteFailed => 'មិនអាចលុបការសន្ទនានេះបានទេ។';

  @override
  String get aiChatsEmptyTitle => 'សួរអំពីអ្វីដែលអ្នកកំពុងរៀន';

  @override
  String get aiChatsEmptyBody =>
      'ចាប់ផ្ដើមការសន្ទនាឯកជនជាភាសាខ្មែរ ឬអង់គ្លេស អំពីមេរៀនណាមួយ។';

  @override
  String get aiStartChat => 'ចាប់ផ្ដើមសន្ទនា';

  @override
  String get aiTutorUnavailableTitle => 'មិនអាចភ្ជាប់គ្រូ AI បានទេ';

  @override
  String get aiTutorUnavailableBody =>
      'សូមពិនិត្យការតភ្ជាប់ រួចព្យាយាមម្ដងទៀត។';

  @override
  String get aiSearchChats => 'ស្វែងរកការសន្ទនា';

  @override
  String get aiNoChatMatches => 'គ្មានការសន្ទនាត្រូវនឹងពាក្យនេះទេ។';

  @override
  String get aiChatFallbackTitle => 'ការសន្ទនាសិក្សា';

  @override
  String get aiComposerHint => 'វាយសំណួររបស់អ្នក...';

  @override
  String get aiSendMessage => 'ផ្ញើសារ';

  @override
  String get aiThinking => 'RIKSA កំពុងគិត';

  @override
  String get aiMessageNotSent => 'មិនបានផ្ញើ';

  @override
  String get aiRetryMessage => 'ផ្ញើម្ដងទៀត';

  @override
  String get aiChatOpener => 'ថ្ងៃនេះ អ្នកចង់យល់អំពីអ្វី?';

  @override
  String get aiAskAboutLesson => 'សួរអំពីមេរៀននេះ';

  @override
  String aiLessonContext(String lesson) {
    return 'អំពី $lesson';
  }

  @override
  String get aiStarterExplainAgain => 'សូមពន្យល់ម្ដងទៀត ឲ្យយឺតជាងមុន';

  @override
  String get aiStarterStillUnsure => 'ខ្ញុំនៅមិនទាន់ច្បាស់ចំណុចមួយ';

  @override
  String get aiStarterWorkedExample => 'សូមឧទាហរណ៍ដោះស្រាយជាជំហានៗ';

  @override
  String get aiChatLoadFailed => 'មិនអាចផ្ទុកការសន្ទនានេះបានទេ។';

  @override
  String get aiReplyFailed => 'គ្រូ AI មិនអាចឆ្លើយបានទេ។ សូមព្យាយាមម្ដងទៀត។';

  @override
  String get aiContinueChat => 'បន្ត';

  @override
  String get aiTimeNow => 'ឥឡូវ';

  @override
  String aiTimeMinutes(int count) {
    return '$count នាទី';
  }

  @override
  String aiTimeHours(int count) {
    return '$count ម៉ោង';
  }

  @override
  String aiTimeDays(int count) {
    return '$count ថ្ងៃ';
  }

  @override
  String get lessonRead => 'អាន';

  @override
  String get lessonRespond => 'ឆ្លើយ';

  @override
  String get lessonReflect => 'សរសេរការយល់ដឹង';

  @override
  String lessonSectionCounter(int current, int total) {
    return 'ផ្នែកទី $current នៃ $total';
  }

  @override
  String get lessonTrySection => 'សាកល្បងដោយខ្លួនឯង';

  @override
  String get lessonReflectAction => 'សរសេរការយល់ដឹងពីមេរៀន';

  @override
  String get lessonCheckAnswer => 'ពិនិត្យចម្លើយ';

  @override
  String get lessonCompareAnswers => 'ប្រៀបធៀបចម្លើយ';

  @override
  String get lessonShowChoices => 'បង្ហាញជម្រើសចម្លើយ';

  @override
  String get lessonWorkedOnPaper => 'ខ្ញុំបានដោះស្រាយលើក្រដាសរួចហើយ';

  @override
  String get lessonAddWorkingOptional => 'បន្ថែមវិធីដោះស្រាយ (មិនចាំបាច់)';

  @override
  String get lessonWorkFirst => 'សាកល្បងដោះស្រាយជាមុន';

  @override
  String get lessonWorkHint =>
      'សរសេរចម្លើយ និងរបៀបដែលអ្នករកបាន។ បន្ទាប់មកប្រៀបធៀបជាមួយជម្រើស។';

  @override
  String get lessonAnswerHint => 'សរសេរចម្លើយរបស់អ្នក';

  @override
  String get lessonYourWork => 'វិធីដោះស្រាយរបស់អ្នក';

  @override
  String get lessonChooseAnswer =>
      'ប្រៀបធៀបវិធីដោះស្រាយរបស់អ្នក ហើយជ្រើសរើសចម្លើយ។';

  @override
  String lessonExerciseNumber(int number) {
    return 'លំហាត់ទី $number';
  }

  @override
  String lessonResponseProgress(int done, int total) {
    return 'បានពិនិត្យចម្លើយ $done ក្នុងចំណោម $total';
  }

  @override
  String get lessonSectionComplete => 'បានបញ្ចប់ផ្នែកនេះ';

  @override
  String get lessonUpNext => 'បន្ទាប់មក';

  @override
  String get lessonReflectionTitle => 'តើអ្នកបានយល់អ្វីខ្លះ?';

  @override
  String get lessonReflectionBody =>
      'សរសេរគំនិតមួយជាពាក្យរបស់អ្នកផ្ទាល់។ កត់ត្រាចំណុចដែលអ្នកចង់រំលឹកឡើងវិញ។';

  @override
  String get lessonReflectionHint =>
      'ខ្ញុំបានយល់ថា… ខ្ញុំនៅចង់សិក្សាបន្ថែមអំពី…';

  @override
  String get lessonReflectionOptionalHint =>
      'មិនចាំបាច់៖ សរសេរកំណត់ចំណាំសម្រាប់ពេលក្រោយ';

  @override
  String get lessonConfidencePrompt => 'តើអ្នកយល់មេរៀននេះកម្រិតណា?';

  @override
  String get lessonConfident => 'ខ្ញុំអាចពន្យល់បាន';

  @override
  String get lessonNeedsReview => 'ខ្ញុំចង់រំលឹកឡើងវិញ';

  @override
  String get lessonFinishAction => 'បញ្ចប់មេរៀន';

  @override
  String get lessonReflectionAddOptional => 'បន្ថែមកំណត់ចំណាំ (មិនចាំបាច់)';

  @override
  String get guestSaveProgressTitle => 'រក្សាទុកវឌ្ឍនភាពរបស់អ្នក';

  @override
  String get guestSaveProgressBody =>
      'ចូលគណនីដើម្បីរក្សាចម្លើយ និងបញ្ចប់មេរៀននេះ។';

  @override
  String get guestSaveProgressBuddyLine =>
      'មិត្តតូចរបស់អ្នកកំពុងលើកទឹកចិត្ត។ ចូលគណនីដើម្បីរក្សាវឌ្ឍនភាពសិក្សារបស់អ្នក។';

  @override
  String get guestSaveProgressSignIn => 'ចូលគណនី';

  @override
  String get guestSaveProgressLater => 'បន្តរៀនក្នុងនាមជាភ្ញៀវ';

  @override
  String get lessonSavedReflection => 'ការយល់ដឹងរបស់អ្នក';

  @override
  String get lessonCompletedBody =>
      'អ្នកបានបោះជំហានមួយទៀតក្នុងកម្មវិធីសិក្សា។ សម្រាក ឬបន្តពេលអ្នករួចរាល់។';

  @override
  String get lessonRestoredProgress =>
      'មេរៀននេះបានបញ្ចប់ពីមុន — វឌ្ឍនភាពរបស់អ្នកត្រូវបានស្ដារឡើងវិញ។';

  @override
  String get lessonRevisitTitle => 'ចំណុចដែលត្រូវរំលឹកឡើងវិញ';

  @override
  String get lessonRevisitBody =>
      'អ្នកបានសម្គាល់ថាចង់រំលឹកមេរៀននេះ។ អ្នកអាចបើកវាម្ដងទៀតពីផែនទីសិក្សា។';

  @override
  String get lessonNextAction => 'ចាប់ផ្តើមមេរៀនបន្ទាប់';

  @override
  String get lessonRoadmapAction => 'ត្រឡប់ទៅផែនទីសិក្សា';

  @override
  String get lessonFinishSession => 'បញ្ចប់ត្រឹមនេះសិន';

  @override
  String get lessonResumeAction => 'បន្តមេរៀន';

  @override
  String get lessonStartAction => 'ចាប់ផ្តើមមេរៀន';

  @override
  String get startHere => 'ចាប់ផ្តើមទីនេះ';

  @override
  String get lessonOptions => 'ជម្រើសមេរៀន';

  @override
  String get lessonSections => 'ផ្នែកមេរៀន';

  @override
  String get lessonSave => 'រក្សាទុកមេរៀន';

  @override
  String get lessonUnsave => 'ដកចេញពីមេរៀនរក្សាទុក';

  @override
  String get lessonMute => 'បិទសំឡេង';

  @override
  String get lessonUnmute => 'បើកសំឡេង';

  @override
  String get lessonExitBody =>
      'ចម្លើយដែលបានពិនិត្យត្រូវបានរក្សាទុក។ សំណេរដែលមិនទាន់បានរក្សាទុកនឹងបាត់បង់ ប្រសិនបើអ្នកចាកចេញ។';

  @override
  String get lessonExitTitle => 'ចាកចេញពីមេរៀន?';

  @override
  String get lessonKeepLearning => 'បន្តរៀន';

  @override
  String get lessonLeaveAction => 'ចាកចេញ';

  @override
  String get lessonAiHint => 'ទទួលតម្រុយ';

  @override
  String get lessonExplainAnswer => 'ពន្យល់ជាមួយ AI';

  @override
  String get lessonWhy => 'សេចក្តីពន្យល់';

  @override
  String get lessonHint => 'តម្រុយ';

  @override
  String get lessonEditWorking => 'កែសម្រួលវិធីដោះស្រាយ';

  @override
  String get lessonWorkingStatus => 'សូមរង់ចាំបន្តិច…';

  @override
  String get lessonAnswerSuccess => 'ត្រឹមត្រូវហើយ។ បន្តពេលអ្នករួចរាល់។';

  @override
  String get lessonAnswerRetry => 'មិនទាន់ត្រឹមត្រូវទេ។ សាកល្បងវិធីផ្សេងទៀត។';

  @override
  String get learningLoadErrorBody =>
      'មេរៀនរបស់អ្នកមិនអាចផ្ទុកបាននៅពេលនេះ។ សូមព្យាយាមម្ដងទៀត។';

  @override
  String get savedLessonsEmptyTitle => 'រក្សាគំនិតល្អទុកសម្រាប់ពេលក្រោយ';

  @override
  String get savedLessonsLabel => 'មេរៀនបានរក្សាទុក';

  @override
  String get savedLessonsEmptyBody =>
      'បានឃើញរូបមន្តដែលគួររំលឹកឡើងវិញ? រក្សាទុកមេរៀនពីម៉ឺនុយរបស់វា។ អ្នកនឹងរកឃើញវានៅទីនេះ។';

  @override
  String get splashTagline => 'រៀនថ្ងៃនេះ កសាងថ្ងៃស្អែក';

  @override
  String get splashDescription =>
      'ដៃគូសិក្សា STEM ថ្នាក់ទី១២ របស់អ្នក ដើម្បីកម្ពុជាដ៏ភ្លឺស្វាង។';

  @override
  String get mascotSelectTitle => 'ជ្រើសរើសដៃគូសិក្សារបស់អ្នក';

  @override
  String get mascotSelectSubtitle =>
      'គេនឹងលើកទឹកចិត្ត និងអបអរជោគជ័យជាមួយអ្នកគ្រប់ពេល។';

  @override
  String get mascotCrocodile => 'ក្រពើ';

  @override
  String get mascotCapybara => 'កាពីបារ៉ា';

  @override
  String get mascotCrocodileTraits => 'គួរឱ្យស្រលាញ់ · រួសរាយ · ឆ្លាតវៃ';

  @override
  String get mascotCapybaraTraits => 'ស្ងប់ស្ងាត់ · ចិត្តល្អ · ឧស្សាហ៍';

  @override
  String get mascotNameLabel => 'ដាក់ឈ្មោះដៃគូរបស់អ្នក';

  @override
  String get mascotTapHint => 'ចុចដើម្បីនិយាយសួស្តី';

  @override
  String mascotSemantic(String name) {
    return '$name ដៃគូសិក្សារបស់អ្នក';
  }

  @override
  String languageSelectTitle(String name) {
    return 'តើ $name គួរនិយាយភាសាអ្វី?';
  }

  @override
  String languageSelectSubtitle(String name) {
    return '$name នឹងប្រើភាសានេះក្នុងមេរៀន ការរំលឹក និងការជជែក។ អ្នកអាចប្ដូរវាបានគ្រប់ពេល។';
  }

  @override
  String languageMascotGreeting(String name) {
    return 'សួស្តី! ខ្ញុំឈ្មោះ $name។ តោះរៀនជាមួយគ្នា!';
  }

  @override
  String get skipLabel => 'រំលង';

  @override
  String get nextLabel => 'បន្ទាប់';

  @override
  String homeGreeting(String name) {
    return 'សួស្តី $name!';
  }

  @override
  String get homeSubtitle => 'បន្តទៀត! ចំណេះដឹងកសាងអនាគតរបស់អ្នក។';

  @override
  String get homeSearchHint => 'ស្វែងរកការបង្ហោះ ប្រធានបទ ឬមេរៀន...';

  @override
  String get homeLessons => 'មេរៀន';

  @override
  String get homeLessonsCaption => 'បន្តរៀន';

  @override
  String get homeCommunityCaption => 'ចូលរួម និងចែករំលែក';

  @override
  String get homeAiCaption => 'សួរអ្វីក៏បាន';

  @override
  String get homeLeaderboardCaption => 'មើលចំណាត់ថ្នាក់';

  @override
  String get todaysLearning => 'ការសិក្សាថ្ងៃនេះ';

  @override
  String get communityFeed => 'ព័ត៌មានសហគមន៍';

  @override
  String get viewAllShort => 'មើលទាំងអស់';

  @override
  String get feedFilterAll => 'ទាំងអស់';

  @override
  String get aiCoachTitle => 'គ្រូជំនួយ AI';

  @override
  String get aiCoachGreeting =>
      'សួស្តី! ខ្ញុំជាគ្រូជំនួយ AI របស់អ្នក។ សួរខ្ញុំអំពីមេរៀនអ្វីក៏បាន ខ្ញុំនឹងជួយអ្នករៀនម្តងមួយជំហាន!';

  @override
  String get aiCoachSectionTitle => 'គ្រូជំនួយតាមមុខវិជ្ជា';

  @override
  String get aiCoachMathTitle => 'គ្រូគណិតវិទ្យា';

  @override
  String get aiCoachMathSubtitle =>
      'ដោះស្រាយពិជគណិត កាល់គុល និងធរណីមាត្រម្តងមួយជំហាន';

  @override
  String get aiCoachScienceTitle => 'គ្រូពន្យល់វិទ្យាសាស្ត្រ';

  @override
  String get aiCoachScienceSubtitle =>
      'ពន្យល់ច្បាប់រូបវិទ្យា រូបមន្តគីមី និងជីវវិទ្យាឱ្យងាយយល់';

  @override
  String get aiCoachKhmerTitle => 'គ្រូភាសាខ្មែរ';

  @override
  String get aiCoachKhmerSubtitle =>
      'អក្ខរាវិរុទ្ធ វេយ្យាករណ៍ ភាសាគួរសម និងតែងសេចក្តីបុរាណ';

  @override
  String get aiCoachEnglishTitle => 'អនុវត្តភាសាអង់គ្លេស';

  @override
  String get aiCoachEnglishSubtitle =>
      'ដៃគូសន្ទនា ជាមួយការកែវេយ្យាករណ៍យ៉ាងទន់ភ្លន់';

  @override
  String get aiCoachBakiiTitle => 'ត្រៀមប្រឡងបាក់ឌុបថ្នាក់ទី១២';

  @override
  String get aiCoachBakiiSubtitle => 'សំណួរប្រឡងជាតិ និងវិធីសាស្ត្ររំឭកមេរៀន';

  @override
  String get aiTryAskingAbout => 'សាកសួរអំពី៖';

  @override
  String get menuMyProgress => 'វឌ្ឍនភាពរបស់ខ្ញុំ';

  @override
  String get menuSavedLessons => 'មេរៀនដែលបានរក្សាទុក';

  @override
  String get menuCommunities => 'សហគមន៍';

  @override
  String get communitiesDiscover => 'ស្វែងរក';

  @override
  String get communitiesMine => 'សហគមន៍របស់ខ្ញុំ';

  @override
  String get communitiesSearchHint => 'ស្វែងរកសហគមន៍...';

  @override
  String get communityJoin => 'ចូលរួម';

  @override
  String get communityJoined => 'បានចូលរួម';

  @override
  String get communitiesUnavailable => 'មិនអាចបង្ហាញសហគមន៍';

  @override
  String get communitiesLoadFailed => 'មិនអាចផ្ទុកសហគមន៍បានទេ។';

  @override
  String get communitiesNoneJoined => 'អ្នកមិនទាន់បានចូលរួមសហគមន៍ណាមួយនៅឡើយទេ។';

  @override
  String communityMembers(String count) {
    return 'សមាជិក $count នាក់';
  }

  @override
  String get communityCreatePost => 'បង្កើតការបង្ហោះ';

  @override
  String get communityShare => 'ចែករំលែកសហគមន៍';

  @override
  String get communitySeeMore => 'មើលបន្ថែម';

  @override
  String get communitySeeLess => 'មើលតិច';

  @override
  String get communitySortBy => 'តម្រៀបការបង្ហោះតាម';

  @override
  String get communitySortHot => 'ពេញនិយម';

  @override
  String get communitySortNew => 'ថ្មីៗ';

  @override
  String get communitySortTop => 'កំពូល';

  @override
  String get communityNoPostsTitle => 'មិនទាន់មានការបង្ហោះ';

  @override
  String get communityNoPostsBody =>
      'ក្លាយជាអ្នកដំបូងដែលចាប់ផ្តើមការពិភាក្សានៅទីនេះ។';

  @override
  String get communityNotFound => 'រកមិនឃើញសហគមន៍នេះទេ។';

  @override
  String get communityLinkCopied => 'បានចម្លងតំណសហគមន៍';

  @override
  String communityMemberCount(int count, String label) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'សមាជិក $label នាក់',
      zero: 'មិនទាន់មានសមាជិក',
    );
    return '$_temp0';
  }

  @override
  String get composeJoinFirst => 'សូមចូលរួមសហគមន៍ជាមុនសិន ដើម្បីបង្ហោះ។';

  @override
  String get composeBrowseCommunities => 'ស្វែងរកសហគមន៍';

  @override
  String get communitiesYours => 'សហគមន៍របស់អ្នក';

  @override
  String get communitiesSeeAll => 'មើលទាំងអស់';

  @override
  String get communitiesFeatured => 'ពិសេស';

  @override
  String get communitiesCantFind => 'រកមិនឃើញសហគមន៍របស់អ្នក?';

  @override
  String get communitiesCreate => 'បង្កើតសហគមន៍';

  @override
  String get communitiesFilterAll => 'ទាំងអស់';

  @override
  String get communitiesFilterScience => 'វិទ្យាសាស្ត្រ';

  @override
  String get communitiesFilterLanguages => 'ភាសា';

  @override
  String get communitiesFilterHistory => 'ប្រវត្តិសាស្ត្រ និងវប្បធម៌';

  @override
  String get communitiesFilterTech => 'បច្ចេកវិទ្យា';

  @override
  String get communitiesFilterGeneral => 'ទូទៅ';

  @override
  String get createCommunityIcon => 'រូបតំណាងសហគមន៍';

  @override
  String get createCommunityIconHint => 'ស្រេចចិត្ត។ រូបភាពរាងការ៉េល្អបំផុត។';

  @override
  String get createCommunityName => 'ឈ្មោះសហគមន៍';

  @override
  String get createCommunityNameHint => 'ឧ. ក្លឹបរ៉ូបូត';

  @override
  String get createCommunityNameLength => 'ប្រើពី ៣ ដល់ ៥០ តួអក្សរ។';

  @override
  String get createCommunityNameChars =>
      'ប្រើតែអក្សរ លេខ ដកឃ្លា និង & \' . , ( ) + # -';

  @override
  String get createCommunityNameLetters => 'ឈ្មោះត្រូវមានអក្សរយ៉ាងហោចណាស់មួយ។';

  @override
  String get createCommunityNameReserved =>
      'ឈ្មោះនេះត្រូវបានបម្រុងទុក។ សូមសាកល្បងឈ្មោះផ្សេង។';

  @override
  String get createCommunityDescription => 'តើវានិយាយអំពីអ្វី?';

  @override
  String get createCommunityDescriptionHint =>
      'ប្រាប់អ្នកដទៃពីអ្វីដែលពួកគេនឹងរៀន ឬពិភាក្សានៅទីនេះ។';

  @override
  String get createCommunityRulesTitle => 'មុនពេលបង្កើត';

  @override
  String get createCommunityRulePublic =>
      'អ្នកប្រើ RIKSA ទាំងអស់អាចស្វែងរក ចូលរួម និងបង្ហោះក្នុងសហគមន៍របស់អ្នក។';

  @override
  String get createCommunityRuleOwner =>
      'អ្នកក្លាយជាម្ចាស់ ហើយនៅជាសមាជិកដរាបណាអ្នកជាម្ចាស់។';

  @override
  String get createCommunityRuleConduct =>
      'សូមរក្សាភាពសុភាព សុវត្ថិភាព និងនិយាយតាមប្រធានបទ។ សហគមន៍ដែលបំពានច្បាប់នឹងត្រូវលុប។';

  @override
  String get createCommunityRuleLimit =>
      'អ្នកត្រូវមានគណនីដែលបានផ្ទៀងផ្ទាត់។ អាចបង្កើតបាន ៣ ក្នុងមួយថ្ងៃ និងជាម្ចាស់បានរហូតដល់ ៥។';

  @override
  String get createCommunityCreated => 'សហគមន៍របស់អ្នករួចរាល់ហើយ';

  @override
  String aiAskCoachAbout(String query) {
    return 'សួរគ្រូជំនួយ AI៖ «$query»';
  }

  @override
  String get aiChatLoadFailedBody =>
      'សូមពិនិត្យការតភ្ជាប់ ហើយព្យាយាមម្ដងទៀត។ គ្មានអ្វីក្នុងការសន្ទនានេះបាត់បង់ទេ។';

  @override
  String get discardChangesTitle => 'បោះបង់ការកែប្រែរបស់អ្នក?';

  @override
  String get discardChangesBody => 'អ្វីដែលអ្នកបានសរសេរនៅទីនេះនឹងបាត់បង់។';

  @override
  String get keepEditing => 'បន្តកែសម្រួល';

  @override
  String get discardAction => 'បោះបង់';

  @override
  String get notNow => 'ពេលក្រោយ';

  @override
  String get lessonDetailLoadFailed => 'យើងមិនអាចបើកមេរៀននេះបានទេ';

  @override
  String get loadFailedCheckConnection =>
      'សូមពិនិត្យការតភ្ជាប់ ហើយព្យាយាមម្ដងទៀត។';

  @override
  String get backToSubjects => 'ត្រឡប់ទៅមុខវិជ្ជា';

  @override
  String get savedLessonsLoadFailed =>
      'យើងមិនអាចផ្ទុកមេរៀនដែលអ្នករក្សាទុកបានទេ';

  @override
  String get savedLessonsSomeFailed =>
      'មេរៀនដែលរក្សាទុកមួយចំនួនមិនអាចផ្ទុកបានទេ។';

  @override
  String get savedLessonsUnavailableTitle => 'មេរៀនទាំងនេះលែងមានទៀតហើយ';

  @override
  String get savedLessonsUnavailableBody =>
      'ពួកវាប្រហែលជាត្រូវបានដកចេញពីវគ្គសិក្សា។';

  @override
  String get savedLessonsClear => 'សម្អាតមេរៀនដែលរក្សាទុក';

  @override
  String get browseLessons => 'រុករកមេរៀន';

  @override
  String get removeFromSaved => 'ដកចេញពីមេរៀនរក្សាទុក';

  @override
  String get composeLoadingCommunities => 'កំពុងផ្ទុកសហគមន៍របស់អ្នក…';

  @override
  String get composeCommunitiesFailed =>
      'យើងមិនអាចផ្ទុកសហគមន៍របស់អ្នកបានទេ។ អត្ថបទរបស់អ្នកនៅដដែល។';

  @override
  String get blogChooseTopicRequired => 'ជ្រើសរើសប្រធានបទ (ចាំបាច់)';

  @override
  String get blogTopicsLoading =>
      'ប្រធានបទកំពុងផ្ទុក។ សូមព្យាយាមម្ដងទៀតបន្តិចទៀត។';

  @override
  String get blogTopicsFailed => 'យើងមិនអាចផ្ទុកប្រធានបទបានទេ។';

  @override
  String get blogTopicsEmpty => 'មិនទាន់មានប្រធានបទនៅឡើយទេ។';

  @override
  String get recoveryErrorNetwork =>
      'យើងមិនអាចតភ្ជាប់ទៅ Riksa បានទេ។ សូមពិនិត្យអ៊ីនធឺណិត ហើយព្យាយាមម្ដងទៀត។';

  @override
  String get recoveryErrorRateLimited =>
      'អ្នកបានព្យាយាមច្រើនដងហើយ! សូមសម្រាកបន្តិច រួចព្យាយាមម្ដងទៀត។';

  @override
  String get recoveryErrorServer =>
      'មានបញ្ហាខាងយើង។ សូមព្យាយាមម្ដងទៀតបន្តិចទៀត។';

  @override
  String get recoveryErrorPassword =>
      'ជិតរួចហើយ! ពាក្យសម្ងាត់ត្រូវមានយ៉ាងតិច ៨ តួ រួមមានអក្សរធំ អក្សរតូច និងលេខ។';

  @override
  String get recoveryErrorCode =>
      'លេខកូដនេះមិនដំណើរការទេ។ វាប្រហែលជាផុតកំណត់ សូមស្នើលេខកូដថ្មី ហើយព្យាយាមម្ដងទៀត។';

  @override
  String get recoveryErrorAccount =>
      'យើងរកគណនីនេះមិនឃើញទេ។ សូមពិនិត្យអក្ខរាវិរុទ្ធ ហើយព្យាយាមម្ដងទៀត។';

  @override
  String get recoveryErrorDetails =>
      'មិនបានសម្រេចទេ។ សូមពិនិត្យព័ត៌មានរបស់អ្នក ហើយព្យាយាមម្ដងទៀត។';

  @override
  String get recoveryErrorGeneric => 'មានបញ្ហាកើតឡើង។ សូមព្យាយាមម្ដងទៀត។';

  @override
  String get recoveryNeedIdentifier =>
      'សូមប្រាប់ឈ្មោះអ្នកប្រើ អ៊ីមែល ឬ Telegram ID របស់អ្នក ដើម្បីយើងដឹងថាជួយគណនីណា។';

  @override
  String get recoveryCodeLength =>
      'លេខកូដមាន ៦ ខ្ទង់។ សូមពិនិត្យសាររបស់អ្នក ហើយព្យាយាមម្ដងទៀត។';

  @override
  String get recoveryChecklistIncomplete =>
      'ជិតរួចហើយ! ពាក្យសម្ងាត់ត្រូវបំពេញគ្រប់លក្ខខណ្ឌក្នុងបញ្ជី។';

  @override
  String get recoveryPasswordsDiffer =>
      'ពាក្យសម្ងាត់ទាំងពីរមិនដូចគ្នាទេ។ សូមវាយបញ្ចូលម្ដងទៀត។';

  @override
  String get recoveryPasswordSaved =>
      'រួចរាល់! សូមចូលដោយប្រើពាក្យសម្ងាត់ថ្មីរបស់អ្នក។';

  @override
  String get recoveryStepIdentifierTitle => 'ភ្លេចពាក្យសម្ងាត់មែនទេ?';

  @override
  String get recoveryStepIdentifierSubtitle =>
      'កុំបារម្ភ វាកើតឡើងចំពោះគ្រប់គ្នា។ ប្រាប់យើងថាអ្នកជានរណា យើងនឹងផ្ញើលេខកូដទៅ។';

  @override
  String get recoveryStepCodeTitle => 'ពិនិត្យសាររបស់អ្នក';

  @override
  String get recoveryStepCodeSubtitle =>
      'យើងបានផ្ញើលេខកូដ ៦ ខ្ទង់ទៅអ៊ីមែល ឬ Telegram របស់អ្នក។ សូមបញ្ចូលវាខាងក្រោម។';

  @override
  String get recoveryStepPasswordTitle => 'បង្កើតពាក្យសម្ងាត់ថ្មី';

  @override
  String get recoveryStepPasswordSubtitle =>
      'ជ្រើសរើសអ្វីដែលអ្នកចាំបាន តែអ្នកដទៃទាយមិនឃើញ។';

  @override
  String get recoveryIdentifierLabel => 'ឈ្មោះអ្នកប្រើ អ៊ីមែល ឬ Telegram ID';

  @override
  String get recoveryNewPasswordLabel => 'ពាក្យសម្ងាត់ថ្មី';

  @override
  String get recoveryConfirmPasswordLabel => 'វាយម្ដងទៀត';

  @override
  String get recoverySendCode => 'ផ្ញើលេខកូដមកខ្ញុំ';

  @override
  String get recoveryVerifyCode => 'ផ្ទៀងផ្ទាត់លេខកូដ';

  @override
  String get recoverySavePassword => 'រក្សាទុកពាក្យសម្ងាត់ថ្មី';

  @override
  String get recoveryResend => 'មិនបានទទួលមែនទេ? ផ្ញើលេខកូដថ្មី';

  @override
  String get recoveryResendSent => 'លេខកូដថ្មីកំពុងផ្ញើទៅ។';

  @override
  String get recoveryBackToSignIn => 'ខ្ញុំចាំហើយ — ត្រឡប់ទៅចូលគណនី';

  @override
  String recoveryIllustrationLabel(int step) {
    return 'ការសង្គ្រោះគណនី ជំហានទី $step';
  }

  @override
  String recoveryStepProgress(int step, int total) {
    return 'ជំហានទី $step ក្នុងចំណោម $total';
  }

  @override
  String get passwordRuleLength => 'យ៉ាងតិច ៨ តួ';

  @override
  String get passwordRuleUppercase => 'អក្សរធំមួយ (A–Z)';

  @override
  String get passwordRuleLowercase => 'អក្សរតូចមួយ (a–z)';

  @override
  String get passwordRuleDigit => 'លេខមួយ (0–9)';

  @override
  String get passwordRuleMatch => 'ពាក្យសម្ងាត់ទាំងពីរដូចគ្នា';

  @override
  String checklistItemDone(String item) {
    return '$item រួចរាល់';
  }

  @override
  String checklistItemPending(String item) {
    return '$item មិនទាន់';
  }

  @override
  String get emailVerifiedTitle => 'អ៊ីមែលបានផ្ទៀងផ្ទាត់';

  @override
  String get emailVerifiedBody => 'អ៊ីមែលគណនី Riksa របស់អ្នកបានផ្ទៀងផ្ទាត់ហើយ។';

  @override
  String get emailVerifyFailedTitle => 'ការផ្ទៀងផ្ទាត់បរាជ័យ';

  @override
  String get emailVerifyFailedBody =>
      'តំណផ្ទៀងផ្ទាត់នេះមិនត្រឹមត្រូវ ឬផុតកំណត់។';

  @override
  String socialLikeLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ចូលចិត្តការបង្ហោះនេះ មាន $count ចូលចិត្ត',
      zero: 'ចូលចិត្តការបង្ហោះនេះ',
    );
    return '$_temp0';
  }

  @override
  String socialCommentLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'មើលមតិ $count',
      zero: 'ផ្ដល់មតិលើការបង្ហោះនេះ',
    );
    return '$_temp0';
  }

  @override
  String socialShareLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ចែករំលែកការបង្ហោះនេះ បានចែករំលែក $count ដង',
      zero: 'ចែករំលែកការបង្ហោះនេះ',
    );
    return '$_temp0';
  }

  @override
  String socialOpenProfile(String name) {
    return 'បើកប្រវត្តិរូបរបស់ $name';
  }

  @override
  String socialReplyTo(String name) {
    return 'ឆ្លើយតបទៅ $name';
  }

  @override
  String get socialDeleteComment => 'លុបមតិនេះ';

  @override
  String get socialCancelReply => 'បោះបង់ការឆ្លើយតប';

  @override
  String get genderFemale => 'ស្រី';

  @override
  String get genderMale => 'ប្រុស';

  @override
  String get genderOther => 'ផ្សេងទៀត';

  @override
  String get loadingProvincesTitle => 'កំពុងផ្ទុកខេត្ត';

  @override
  String get loadingProvincesBody => 'កំពុងរៀបចំជម្រើសសិក្សាក្នុងតំបន់។';

  @override
  String get leaderboardNational => 'ទូទាំងប្រទេស';

  @override
  String get leaderboardProvince => 'ខេត្ត';

  @override
  String get leaderboardRankings => 'ចំណាត់ថ្នាក់';

  @override
  String get leaderboardYourRank => 'ចំណាត់ថ្នាក់របស់អ្នក';

  @override
  String leaderboardRowLabel(int rank, String name, int xp) {
    return 'ចំណាត់ថ្នាក់ទី $rank, $name, $xp XP';
  }

  @override
  String leaderboardYourRankLabel(
    int rank,
    String name,
    String scope,
    String tier,
    int xp,
  ) {
    return 'ចំណាត់ថ្នាក់របស់អ្នកគឺទី $rank។ $name, $scope, $tier, $xp XP។';
  }

  @override
  String get progressHistoryTitle => 'ប្រវត្តិវឌ្ឍនភាព';

  @override
  String get progressHistoryXpTab => 'សកម្មភាព XP';

  @override
  String get progressHistoryRankTab => 'ការប្ដូរចំណាត់ថ្នាក់';

  @override
  String get progressHistoryXpFailed =>
      'យើងមិនអាចផ្ទុកប្រវត្តិ XP របស់អ្នកបានទេ';

  @override
  String get progressHistoryRankFailed =>
      'យើងមិនអាចផ្ទុកប្រវត្តិចំណាត់ថ្នាក់របស់អ្នកបានទេ';

  @override
  String get progressHistoryXpEmptyTitle => 'មិនទាន់មាន XP ទេ';

  @override
  String get progressHistoryXpEmptyBody =>
      'បញ្ចប់មេរៀនមួយ ដើម្បីចាប់ផ្ដើមប្រវត្តិរបស់អ្នក។';

  @override
  String get progressHistoryRankEmptyTitle =>
      'មិនទាន់មានការប្ដូរចំណាត់ថ្នាក់ទេ';

  @override
  String get progressHistoryRankEmptyBody =>
      'បន្តរកបាន XP ដើម្បីឡើងចំណាត់ថ្នាក់។';

  @override
  String progressHistoryRankRow(String scope) {
    return 'ចំណាត់ថ្នាក់$scope';
  }

  @override
  String xpAmount(int amount) {
    return '+$amount XP';
  }

  @override
  String get xpSourceLesson => 'បានបញ្ចប់មេរៀន';

  @override
  String get xpSourceExercise => 'បានឆ្លើយលំហាត់';

  @override
  String get xpSourceAchievement => 'បានទទួលសមិទ្ធផល';

  @override
  String get xpSourceStreak => 'ប្រាក់រង្វាន់ជាប់ៗគ្នា';

  @override
  String get xpSourceReward => 'រង្វាន់';

  @override
  String get profileSetupTitle => 'រៀបចំប្រវត្តិរូបរបស់អ្នក';

  @override
  String get profileSetupSubtitle =>
      'ព័ត៌មានខ្លីៗជួយឱ្យមិត្តរួមថ្នាក់ស្គាល់អ្នក និងរក្សាវឌ្ឍនភាពជារបស់អ្នក។';

  @override
  String get profileSetupCta => 'រៀបចំប្រវត្តិរូប';

  @override
  String get profileSetupStepPhotoTitle => 'បន្ថែមរូបភាព';

  @override
  String get profileSetupStepPhotoBody =>
      'ជ្រើសរើសរូបតំណាង ឬបញ្ចូលរូបភាពផ្ទាល់ខ្លួន។';

  @override
  String get profileSetupStepNameTitle => 'ឈ្មោះរបស់អ្នក';

  @override
  String get profileSetupStepNameBody =>
      'ឈ្មោះដែលមិត្តរួមថ្នាក់ឃើញលើការបង្ហោះ និងចំណាត់ថ្នាក់។';

  @override
  String get profileSetupStepBioTitle => 'ប្រវត្តិរូបខ្លី';

  @override
  String get profileSetupStepBioBody =>
      'និយាយពីអ្វីដែលអ្នកកំពុងរៀន ក្នុងមួយ ឬពីរបន្ទាត់។';

  @override
  String get profileSetupStepProvinceTitle => 'ខេត្តរបស់អ្នក';

  @override
  String get profileSetupStepProvinceBody =>
      'ប្រើសម្រាប់ចំណាត់ថ្នាក់ខេត្ត និងសហគមន៍ក្នុងតំបន់។';

  @override
  String get supportDocumentComingSoon => 'នឹងមានឆាប់ៗ';

  @override
  String get ok => 'យល់ព្រម';

  @override
  String get blogTitle => 'ប្លុក';

  @override
  String get blogWritePost => 'សរសេរអត្ថបទ';

  @override
  String get blogYourPosts => 'អត្ថបទរបស់ខ្ញុំ';

  @override
  String get blogFeedFailedTitle => 'អត្ថបទកំពុងសម្រាក';

  @override
  String get blogFeedEmptyTitle => 'មិនទាន់មានអត្ថបទទេ';

  @override
  String get blogFeedEmptyBody =>
      'ក្លាយជាសិស្សដំបូងដែលចែករំលែកអ្វីមានប្រយោជន៍ជាមួយសហគមន៍ Riksa។';

  @override
  String get blogPostDeleted => 'បានលុបអត្ថបទ';

  @override
  String blogLikeLabel(int count) {
    return 'ចូលចិត្ត, $count ចូលចិត្ត';
  }

  @override
  String blogUnlikeLabel(int count) {
    return 'ឈប់ចូលចិត្ត, $count ចូលចិត្ត';
  }

  @override
  String get blogMyPostsFailed => 'មិនអាចផ្ទុកអត្ថបទរបស់អ្នកបានទេ';

  @override
  String get blogMyPostsEmptyTitle => 'មិនទាន់មានអត្ថបទទេ';

  @override
  String get blogMyPostsEmptyBody =>
      'អ្វីគ្រប់យ៉ាងដែលអ្នកសរសេរនឹងបង្ហាញនៅទីនេះ ជាមួយស្ថានភាពត្រួតពិនិត្យ។';

  @override
  String get blogMyPostsFilteredTitle => 'គ្មានអ្វីនៅទីនេះ';

  @override
  String get blogMyPostsFilteredBody => 'អ្នកមិនមានអត្ថបទដែលមានស្ថានភាពនេះទេ។';

  @override
  String get blogStatusPending => 'កំពុងត្រួតពិនិត្យ';

  @override
  String get blogStatusApproved => 'បានផ្សាយ';

  @override
  String get blogStatusRejected => 'ត្រូវបានបដិសេធ';

  @override
  String get blogEditPost => 'កែអត្ថបទ';

  @override
  String get blogDeletePost => 'លុបអត្ថបទ';

  @override
  String get blogDeleteConfirmTitle => 'លុបអត្ថបទនេះ?';

  @override
  String get blogDeleteConfirmBody =>
      'អត្ថបទ រួមទាំងចំនួនចូលចិត្ត និងចំនួនមើល នឹងត្រូវលុបចោលសម្រាប់គ្រប់គ្នា។ មិនអាចត្រឡប់វិញបានទេ។';

  @override
  String get blogKeepPost => 'រក្សាអត្ថបទ';

  @override
  String get blogPostOptions => 'ជម្រើសអត្ថបទ';

  @override
  String get blogVerified => 'បានផ្ទៀងផ្ទាត់';

  @override
  String get blogUnknownAuthor => 'អ្នកសរសេរ Riksa';

  @override
  String get blogOwnerEditFailed => 'អ្នកអាចកែបានតែអត្ថបទរបស់អ្នកប៉ុណ្ណោះ';

  @override
  String get blogOwnerDeleteFailed => 'អ្នកអាចលុបបានតែអត្ថបទរបស់អ្នកប៉ុណ្ណោះ';

  @override
  String get blogPostGone => 'អត្ថបទនេះលែងមានទៀតហើយ';

  @override
  String get blogReviewPendingTitle => 'កំពុងត្រួតពិនិត្យ';

  @override
  String get blogReviewBackTitle => 'ត្រឡប់ទៅត្រួតពិនិត្យវិញ';

  @override
  String get blogReviewBackBody =>
      'ការកែប្រែរបស់អ្នកបានរក្សាទុក។ អត្ថបទនឹងត្រឡប់ទៅប្លុកវិញ នៅពេលអ្នកត្រួតពិនិត្យអនុម័តកំណែនេះ។';

  @override
  String get blogReviewSubmittedBody =>
      'អត្ថបទរបស់អ្នកបានដាក់ស្នើ។ វានឹងបង្ហាញក្នុងប្លុក នៅពេលអ្នកត្រួតពិនិត្យអនុម័ត ហើយអ្នកអាចតាមដានស្ថានភាពនៅក្នុង អត្ថបទរបស់អ្នក។';

  @override
  String get blogDone => 'រួចរាល់';

  @override
  String get blogSave => 'រក្សាទុក';

  @override
  String get blogPublish => 'បង្ហោះ';

  @override
  String get blogNothingToPreview => 'មិនទាន់មានអ្វីសម្រាប់មើលជាមុនទេ។';

  @override
  String get blogTitleHint => 'ចំណងជើង';

  @override
  String get blogBodyHint =>
      'ចែករំលែកអ្វីដែលអ្នករៀនបាន។ Markdown ប្រើបាននៅទីនេះ។';

  @override
  String get blogCoverUrlLabel => 'តំណរូបភាពគម្រប (ជាជម្រើស)';

  @override
  String get blogRemoveCover => 'ដករូបភាពគម្រប';

  @override
  String get blogCoverImage => 'រូបភាពគម្រប';

  @override
  String get blogPreview => 'មើលជាមុន';

  @override
  String get blogBackToWriting => 'ត្រឡប់ទៅសរសេរវិញ';

  @override
  String get blogOpenForEditFailed => 'មិនអាចបើកអត្ថបទនេះដើម្បីកែបានទេ';

  @override
  String get blogPostUnavailableTitle => 'អត្ថបទមិនអាចប្រើបាន';

  @override
  String get blogPostUnavailableBody => 'អត្ថបទនេះមិនអាចផ្ទុកបានទេ។';

  @override
  String get blogLoadPostFailed => 'មិនអាចផ្ទុកអត្ថបទនេះបានទេ';

  @override
  String get blogLikeFailed => 'មិនអាចធ្វើបច្ចុប្បន្នភាពការចូលចិត្តបានទេ';

  @override
  String get blogOpenPostFailedTitle => 'អត្ថបទនេះមិនអាចបើកបានទេ';

  @override
  String get blogTextSizeTooltip => 'កែទំហំអក្សរ';

  @override
  String get blogTextSizeDefault => 'ទំហំអក្សរ៖ ធម្មតា (1.0x)';

  @override
  String get blogTextSizeLarge => 'ទំហំអក្សរ៖ ធំ (1.18x)';

  @override
  String get blogTextSizeExtraLarge => 'ទំហំអក្សរ៖ ធំបំផុត (1.35x)';

  @override
  String get blogProfile => 'ប្រវត្តិរូប';

  @override
  String get blogSomethingWentWrong => 'មានបញ្ហាកើតឡើង';

  @override
  String get markdownBold => 'អក្សរដិត';

  @override
  String get markdownItalic => 'អក្សរទ្រេត';

  @override
  String get markdownHeading => 'ចំណងជើងរង';

  @override
  String get markdownQuote => 'សម្រង់';

  @override
  String get markdownBulletList => 'បញ្ជីចំណុច';

  @override
  String get markdownNumberedList => 'បញ្ជីលេខរៀង';

  @override
  String get markdownCode => 'កូដ';

  @override
  String get markdownLink => 'តំណ';

  @override
  String authBuddyWelcome(String name) {
    return 'ស្វាគមន៍មកវិញ $name! ខ្ញុំនឹកអ្នក។';
  }

  @override
  String get authBuddyRegister => 'អ្នកថ្មីមែនទេ? តោះបង្កើតគណនី!';

  @override
  String get authBuddyPasswordHidden => 'ខ្ញុំមិនមើលទេ!';

  @override
  String get authBuddyPasswordShown => 'អូ! ឥឡូវខ្ញុំអាចមើលឃើញហើយ។';

  @override
  String get authBuddyChecking => 'កំពុងពិនិត្យ…';

  @override
  String authBuddyError(String message) {
    return 'អូ ទេ! $message';
  }

  @override
  String get authBuddyValidationHint => 'អូ! សូមពិនិត្យកន្លែងដែលបានបន្លិច។';

  @override
  String get authBuddyForgotHint => 'នៅតែមិនបាន? សាកភ្លេចពាក្យសម្ងាត់។';

  @override
  String get authBuddySuccess => 'យេ! អ្នកបានចូលហើយ!';

  @override
  String get buddyHomeGreeting => 'ត្រៀមបោះជំហានបន្ទាប់ហើយឬនៅ?';

  @override
  String get buddyWelcomeBack => 'សូមស្វាគមន៍មកវិញ។ បន្តពីកន្លែងដែលអ្នកបានឈប់។';

  @override
  String get buddyLessonCompleted => 'អ្នកសម្រេចបានហើយ!';

  @override
  String buddyCareTitle(String name) {
    return 'ថ្ងៃនេះជាមួយ $name';
  }

  @override
  String get buddyCareLesson => 'បញ្ចប់មេរៀនមួយ';

  @override
  String get buddyCareRead => 'អានរឿងមួយ';

  @override
  String get buddyCareShare => 'ចែករំលែកជាមួយសហគមន៍';

  @override
  String get buddyChooseAction => 'ជ្រើសរើសមិត្តតូចម្នាក់';

  @override
  String buddyCareProgress(int count) {
    return 'បានបញ្ចប់ $count ក្នុងចំណោម 1';
  }

  @override
  String buddyEnergyLively(String name) {
    return '$name មានថាមពលពេញលេញ។';
  }

  @override
  String buddyEnergySteady(String name) {
    return 'មេរៀនមួយជួយឱ្យ $name បន្តមានថាមពល។';
  }

  @override
  String buddyEnergySleepy(String name) {
    return '$name កំពុងចាប់ផ្តើមងងុយគេង។';
  }

  @override
  String buddyEnergyNapping(String name) {
    return '$name កំពុងគេងថ្ងៃ។ មេរៀនមួយអាចជួយដាស់ $name។';
  }

  @override
  String buddyLessonEnergyLine(String name) {
    return '+35 ថាមពល · $name មានថាមពលពេញលេញ';
  }

  @override
  String buddyReadEnjoyed(String name) {
    return '$name រីករាយនឹងរឿងនោះ';
  }

  @override
  String get buddyRankImproved =>
      'វឌ្ឍនភាពរបស់អ្នកបានធ្វើឱ្យចំណាត់ថ្នាក់កើនឡើង។';

  @override
  String get buddyCommunityJoined => 'សូមស្វាគមន៍មកកាន់សហគមន៍ថ្មីរបស់អ្នក!';

  @override
  String homeStreakDays(int count) {
    return '$count ថ្ងៃ';
  }

  @override
  String get homeTodaysStudy => 'ការសិក្សាថ្ងៃនេះ';

  @override
  String get homeStartHere => 'ចាប់ផ្តើមទីនេះ';

  @override
  String get homeStartHereBody =>
      'ជ្រើសរើសមេរៀនដំបូង ហើយចាប់ផ្តើមម្តងមួយជំហាន។';

  @override
  String homeLessonMinutes(int minutes) {
    return '$minutes នាទី';
  }

  @override
  String get homeContinue => 'បន្ត';

  @override
  String get homeProvinceSquad => 'ក្រុមសិក្សាខេត្តរបស់អ្នក';

  @override
  String get homeProvinceMissing =>
      'ជ្រើសរើសខេត្តដើម្បីមើលក្រុមសិក្សារបស់អ្នក។';

  @override
  String get homeSelectProvince => 'ជ្រើសរើសខេត្ត';

  @override
  String homeProvinceRank(int rank) {
    return 'អ្នកស្ថិតនៅលេខ #$rank សប្តាហ៍នេះ';
  }

  @override
  String homeNearbyLearner(int rank, String name) {
    return '#$rank $name';
  }

  @override
  String get homeYou => 'អ្នក';

  @override
  String get homeViewProvinceRanks => 'មើលចំណាត់ថ្នាក់ខេត្ត';

  @override
  String get homeFromCommunities => 'ពីសហគមន៍របស់អ្នក';

  @override
  String homeCommunityPostMeta(String community, String author, int count) {
    return '$community · $author · មតិ $count';
  }

  @override
  String get homeSeeCommunityFeed => 'មើលព័ត៌មានសហគមន៍';

  @override
  String get lessonShareLearning => 'ចែករំលែកអ្វីដែលខ្ញុំបានរៀន';

  @override
  String get resumeLearningTitle => 'បន្តការរៀន';

  @override
  String get resumeLearningEmptyTitle => 'មិនមានមេរៀនកំពុងរៀនទេ';

  @override
  String get resumeLearningEmptyBody =>
      'ជ្រើសរើសមេរៀនដើម្បីចាប់ផ្តើមជំហានសិក្សាបន្ទាប់។';

  @override
  String get leaderboardNearbyLearners => 'អ្នកសិក្សានៅជិតចំណាត់ថ្នាក់របស់អ្នក';

  @override
  String get leaderboardSearchLearners => 'ស្វែងរកអ្នកសិក្សា';

  @override
  String get buddyReactions => 'ប្រតិកម្មរបស់មិត្តសិក្សា';

  @override
  String get buddyReactionsHint => 'អនុញ្ញាតឱ្យមិត្តសិក្សាបង្ហាញចលនា និងនិយាយ';

  @override
  String get profileStudyBuddy => 'មិត្តសិក្សា';

  @override
  String profileBuddyNamed(String name) {
    return '$name មិត្តសិក្សារបស់អ្នក';
  }

  @override
  String get aiBuddyHandoff =>
      'មិត្តសិក្សារបស់អ្នកអាចជួយចាប់ផ្តើម ហើយគ្រូ AI នឹងពន្យល់សំណួរ។';

  @override
  String homeProvinceSquadNamed(String province) {
    return 'ក្រុមសិក្សា $province';
  }

  @override
  String get streakReminderTitle => '🔥 រក្សាខ្សែពិន្ទុបន្តរបស់អ្នក!';

  @override
  String get streakReminderBody =>
      'ចំណាយពេល ៥ នាទីយប់នេះដើម្បីរៀន និងរក្សាការសិក្សាបន្តរបស់អ្នក។';

  @override
  String get reminderPermissionTitle => 'តើអ្នកចង់បានការរំលឹកនៅម៉ោង ៨ យប់ទេ?';

  @override
  String reminderPermissionBody(String buddyName) {
    return '$buddyName៖ តើខ្ញុំអាចរំលឹកអ្នក ដើម្បីកុំឱ្យស្ទ្រីករបស់អ្នកដាច់បានទេ?';
  }

  @override
  String get reminderPermissionAllow => 'បើកការរំលឹក';

  @override
  String reminderNotificationTitle(String buddyName, int streakDays) {
    return '$buddyName៖ ស្ទ្រីក $streakDays ថ្ងៃរបស់អ្នកនឹងដាច់នៅយប់នេះ 😢';
  }

  @override
  String reminderNotificationTitleNoStreak(String buddyName) {
    return '$buddyName៖ ចំណាយពេលរៀនមេរៀនមួយនៅយប់នេះ';
  }

  @override
  String get reminderNotificationBody =>
      'បញ្ចប់មេរៀនមួយនៅយប់នេះ ដើម្បីបន្តស្ទ្រីករបស់អ្នក។';

  @override
  String get drawerGeneral => 'ទូទៅ';

  @override
  String get drawerAbout => 'អំពី';

  @override
  String get drawerUserAgreement => 'កិច្ចព្រមព្រៀងអ្នកប្រើប្រាស់';

  @override
  String get drawerPrivacyCenter => 'មជ្ឈមណ្ឌលឯកជនភាព';

  @override
  String get aiCopyAnswer => 'ចម្លងចម្លើយ';

  @override
  String get aiCopiedClipboard => 'បានចម្លងទៅក្តារតម្កល់';

  @override
  String get aiCopy => 'ចម្លង';

  @override
  String get aiLoginRequired => 'សូមចូលគណនីដើម្បីជជែកជាមួយគ្រូ AI។';

  @override
  String get buddyHeadOpenSemantics => 'បើកកិច្ចការថ្ងៃនេះ';

  @override
  String get buddyHeadTodayTitle => 'កិច្ចការថ្ងៃនេះ';

  @override
  String buddyHeadGreeting(String name) {
    return '$name៖ តោះធ្វើឱ្យថ្ងៃនេះមានន័យ!';
  }

  @override
  String get buddyHeadCurrentStreak => 'ស្ទ្រីកបច្ចុប្បន្នរបស់អ្នក';

  @override
  String buddyHeadStreakDays(int count) {
    return '$count ថ្ងៃ';
  }

  @override
  String buddyHeadProgress(int progress, int target) {
    return '$progress ក្នុងចំណោម $target';
  }

  @override
  String buddyHeadProgressShort(int progress, int target) {
    return '$progress/$target';
  }

  @override
  String get buddyHeadStartLesson => 'ចាប់ផ្តើមមេរៀន';

  @override
  String get buddyHeadGuestPrompt => 'រក្សាស្ទ្រីករបស់អ្នក — ចូលគណនី';

  @override
  String get buddyHeadSignIn => 'ចូលគណនី';

  @override
  String get buddyHeadHideTitle => 'លាក់មិត្តសិក្សារហូតដល់ថ្ងៃស្អែក?';

  @override
  String get buddyHeadHideBody =>
      'មិត្តសិក្សារបស់អ្នកនឹងត្រឡប់មកវិញនៅថ្ងៃស្អែក។';

  @override
  String get buddyHeadHideAction => 'លាក់ថ្ងៃនេះ';

  @override
  String buddyPanelClaimable(String name) {
    return '$name សូមទទួល XP របស់អ្នក!';
  }

  @override
  String buddyPanelStreakAtRisk(String name) {
    return '$name នៅសល់មេរៀន ១ ទៀត ហើយស្ទ្រីករបស់អ្នកនឹងមានសុវត្ថិភាព។';
  }

  @override
  String buddyPanelAllDone(String name) {
    return 'ធ្វើរួចទាំងអស់ហើយ — ជួបគ្នាថ្ងៃស្អែក $name។';
  }

  @override
  String buddyPanelGreeting(String name) {
    return '$name ត្រៀមរៀនពេលអ្នករួចរាល់។';
  }

  @override
  String get buddyPanelToday => 'ថ្ងៃនេះ';

  @override
  String get buddyPanelThisWeek => 'សប្តាហ៍នេះ';

  @override
  String get buddyPanelStreak => 'ស្ទ្រីក';

  @override
  String buddyPanelDays(int count) {
    return '$count ថ្ងៃ';
  }

  @override
  String get buddyPanelWeeklyChest => 'ទ្រូងរង្វាន់ប្រចាំសប្តាហ៍';

  @override
  String buddyPanelProgress(int progress, int target, int xp) {
    return '$progress/$target · +$xp XP';
  }

  @override
  String buddyPanelResetsIn(int hours, int minutes) {
    return 'កំណត់ឡើងវិញក្នុងរយៈពេល $hours ម៉ោង $minutes នាទី';
  }

  @override
  String get buddyPanelGuestPrompt =>
      'ចូលគណនីដើម្បីរក្សាស្ទ្រីក និងរង្វាន់របស់អ្នក។';

  @override
  String get buddyPanelClose => 'បិទផ្ទាំងកិច្ចការ';

  @override
  String buddyPanelDailyBonus(int xp) {
    return 'ប្រាក់រង្វាន់ប្រចាំថ្ងៃ +$xp XP';
  }

  @override
  String get buddyPanelGo => 'ទៅ →';

  @override
  String get buddyPanelStartLesson => 'ចាប់ផ្តើមមេរៀន';

  @override
  String get buddyPanelSignIn => 'ចូលគណនី';

  @override
  String get weeklyPreviewLessons => 'បញ្ចប់មេរៀន ៥';

  @override
  String get weeklyPreviewAnswers => 'ឆ្លើយត្រូវ ១៥ សំណួរ';

  @override
  String get weeklyPreviewActiveDays => 'រៀន ៥ ថ្ងៃ';

  @override
  String get weeklyPreviewSocial => 'ធ្វើសកម្មភាពសង្គម ៣ ដង';

  @override
  String get chestOpen => 'បើក';

  @override
  String chestProgress(int points, int target) {
    return '$points/$target ពិន្ទុ';
  }

  @override
  String chestOpenedXp(int xp) {
    return 'ទទួលបាន +$xp XP';
  }

  @override
  String get chestOpenFailed =>
      'មិនអាចបើកទ្រូងរង្វាន់បានទេ។ សូមព្យាយាមម្តងទៀត។';

  @override
  String get weeklyLoadFailed => 'មិនអាចផ្ទុកកិច្ចការសប្តាហ៍នេះបានទេ។';

  @override
  String get questPreviewLesson => 'បញ្ចប់មេរៀន ១';

  @override
  String get questPreviewAnswers => 'ឆ្លើយត្រូវ ៣ សំណួរ';

  @override
  String get questPreviewSocial => 'ប្រតិកម្ម ឬបញ្ចេញមតិលើប្រកាស';

  @override
  String get questClaim => 'ទទួលរង្វាន់';

  @override
  String get questClaimed => 'បានទទួលហើយ';

  @override
  String get questSignInToClaim => 'ចូលគណនីដើម្បីទទួលរង្វាន់';

  @override
  String get questClaimFailed =>
      'មិនអាចទទួលកិច្ចការនេះបានទេ។ សូមព្យាយាមម្តងទៀត។';

  @override
  String get questLoadFailed => 'មិនអាចផ្ទុកកិច្ចការថ្ងៃនេះបានទេ។';

  @override
  String get questPreviewStreak => 'មើលកិច្ចការថ្ងៃនេះ';

  @override
  String get questRetry => 'ព្យាយាមម្តងទៀត';

  @override
  String get resourceSectionTitle => 'ធនធានសិក្សា';

  @override
  String resourceEntryCount(int count) {
    return 'ធនធាន ($count)';
  }

  @override
  String get resourceShareAction => 'ចែករំលែកធនធាន';

  @override
  String get resourceLoadFailed => 'មិនអាចផ្ទុកធនធានបានទេ។ សូមព្យាយាមម្តងទៀត។';

  @override
  String get resourceSaveFailed => 'មិនអាចកែប្រែធនធានដែលបានរក្សាទុកបានទេ។';

  @override
  String get resourceOpenFailed => 'មិនអាចបើកតំណនេះបានទេ។';

  @override
  String get resourceEmptyTitle => 'មិត្តរៀនរបស់អ្នកកំពុងរង់ចាំធនធានល្អមួយ';

  @override
  String get resourceEmptyBody =>
      'ចែករំលែកតំណ វីដេអូ ឬឯកសារ PDF ដែលមានប្រយោជន៍សម្រាប់មេរៀននេះ។';

  @override
  String resourceSaveCount(int count) {
    return 'បានរក្សាទុក $count ដង';
  }

  @override
  String get resourceUnsaveAction => 'ដកធនធានចេញពីធនធានដែលបានរក្សាទុក';

  @override
  String get resourceSaveAction => 'រក្សាទុកធនធាន';

  @override
  String get resourceDeleteAction => 'លុបធនធាន';

  @override
  String get resourceDeleteConfirm => 'លុបធនធាននេះសម្រាប់អ្នករាល់គ្នាមែនទេ?';

  @override
  String get resourceDeleteFailed => 'មិនអាចលុបធនធាននេះបានទេ។';

  @override
  String get resourceReportAction => 'រាយការណ៍ធនធាន';

  @override
  String get resourceReportConfirm => 'រាយការណ៍ធនធាននេះដើម្បីពិនិត្យមែនទេ?';

  @override
  String get resourceReportSent => 'បានផ្ញើរបាយការណ៍ដើម្បីពិនិត្យហើយ។';

  @override
  String get resourceReportFailed => 'មិនអាចរាយការណ៍ធនធាននេះបានទេ។';

  @override
  String get resourceShareTitle => 'ចែករំលែកធនធានសិក្សា';

  @override
  String get resourceTitleLabel => 'ចំណងជើង';

  @override
  String get resourceTitleError => 'ប្រើចំណងជើងដែលមានពី ៣ ដល់ ១២០ តួអក្សរ។';

  @override
  String get resourceUrlLabel => 'អាសយដ្ឋានគេហទំព័រ';

  @override
  String get resourceUrlError => 'បញ្ចូលអាសយដ្ឋាន http ឬ https ដែលត្រឹមត្រូវ។';

  @override
  String get resourceKindLabel => 'ប្រភេទ';

  @override
  String get resourceKindLink => 'តំណ';

  @override
  String get resourceKindPdf => 'PDF';

  @override
  String get resourceKindVideo => 'វីដេអូ';

  @override
  String get resourceRateLimit =>
      'អ្នកអាចចែករំលែកធនធានបានរហូតដល់ ១០ ក្នុងមួយថ្ងៃ។';

  @override
  String get resourceShareFailed =>
      'មិនអាចចែករំលែកធនធាននេះបានទេ។ សូមព្យាយាមម្តងទៀត។';

  @override
  String get resourceConfirm => 'បញ្ជាក់';

  @override
  String get milestoneCelebrationLabel => 'សម្រេចបានចំណុចសំខាន់';

  @override
  String milestoneStreakMessage(String name, int days) {
    return '$name រៀនជាប់គ្នាបាន $days ថ្ងៃ!';
  }

  @override
  String milestoneRankMessage(String name, String rank) {
    return '$name ឡើងដល់ថ្នាក់ $rank!';
  }

  @override
  String milestoneUnitMessage(String name, String unit) {
    return '$name បានបញ្ចប់ $unit!';
  }

  @override
  String get milestoneShareTitle => 'ចែករំលែកចំណុចសំខាន់ៗរបស់ខ្ញុំ';

  @override
  String get milestoneShareHint =>
      'ឲ្យមិត្តភក្តិអបអរស្ទ្រីក ថ្នាក់ និងឯកតាមេរៀនដែលអ្នកបានបញ្ចប់។';

  @override
  String get postOpenPhoto => 'បើករូបភាព';

  @override
  String get photoViewerClose => 'បិទរូបភាព';

  @override
  String get postPhotosAdd => 'បន្ថែមរូបភាព';

  @override
  String get postPhotosRemove => 'លុបរូបភាព';

  @override
  String get postPhotosRetry => 'ព្យាយាមម្ដងទៀត';

  @override
  String get postPhotosReorder => 'រៀបលំដាប់រូបភាព';

  @override
  String get postPhotosUploadFailed => 'បង្ហោះរូបភាពមិនបានទេ';

  @override
  String postPhotosUploading(int progress) {
    return 'កំពុងបង្ហោះ $progress%';
  }

  @override
  String get postPhotosLimitReached =>
      'អ្នកអាចបន្ថែមរូបភាពបានរហូតដល់ ៤ ប៉ុណ្ណោះ។';

  @override
  String get postPhotosBodyRequired =>
      'សូមបន្ថែមព័ត៌មាន ឬភ្ជាប់រូបភាព មុនពេលបង្ហោះ។';

  @override
  String postPhotosPageIndicator(int current, int total) {
    return '$current / $total';
  }

  @override
  String get composerWrite => 'សរសេរ';

  @override
  String get composerPreview => 'មើលជាមុន';
}
