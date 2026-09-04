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
  String get telegramChatId => 'លេខ​សម្គាល់​ផ្ទាល់​ Telegram';

  @override
  String get telegramChatIdHint =>
      'ចាប់ផ្ដើម bot របស់​យើង​ហើយ​បិទ​ភ្ជាប់​លេខ​សម្គាល់​ផ្ទាល់​របស់​អ្នក';

  @override
  String get telegramOtpInstructions =>
      'យើង​បាន​ផ្ញើ​កូដ​ទៅ​ Telegram របស់​អ្នក។ បញ្ចូល​វា​ខាង​ក្រោម។';

  @override
  String get otpCode => 'កូដ OTP';

  @override
  String get otpCodeHint => 'កូដ ៦ ខ្ទង់';

  @override
  String get sendCode => 'ផ្ញើ​កូដ';

  @override
  String get verify => 'ផ្ទៀង​ផ្ទាត់';

  @override
  String get resendCode => 'ផ្ញើ​កូដ​ម្ដង​ទៀត';

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
  String get otpSendFailed => 'មិន​អាច​ផ្ញើ​កូដ OTP បាន';

  @override
  String get otpVerifyFailed => 'កូដ​មិន​ត្រឹម​ត្រូវ ឬ​ផុត​កំណត់';

  @override
  String get otpSendSuccess => 'កូដ​បាន​ផ្ញើ​ទៅ Telegram របស់​អ្នក';

  @override
  String get telegramEyebrow => 'ចូលប្រើរហ័សដោយគ្មានពាក្យសម្ងាត់';

  @override
  String get telegramLoginTitle => 'ចូលជាមួយ Telegram';

  @override
  String get telegramLoginSubtitle =>
      'បញ្ចូលលេខសម្គាល់ការជជែកពី Riksa bot ហើយយើងនឹងផ្ញើកូដប្រើតែម្តង។';

  @override
  String get telegramRegisterTitle => 'ចុះឈ្មោះជាមួយ Telegram';

  @override
  String get telegramRegisterSubtitle =>
      'ជ្រើសរើសឈ្មោះ Riksa របស់អ្នក រួចផ្ទៀងផ្ទាត់គណនី Telegram ដោយកូដប្រើតែម្តង។';

  @override
  String get enterTelegramCode => 'បញ្ចូលកូដ Telegram របស់អ្នក';

  @override
  String get invalidTelegramChatId =>
      'បញ្ចូលលេខសម្គាល់ការជជែក Telegram ជាលេខត្រឹមត្រូវ';

  @override
  String get invalidOtpCode => 'បញ្ចូលកូដ ៦ ខ្ទង់';

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
  String get discussion => 'ការពិភាក្សា';

  @override
  String get addComment => 'ចូលរួមក្នុងការពិភាក្សា';

  @override
  String get sendComment => 'ផ្ញើមតិយោបល់';

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
  String get onboardingTitle => 'កសាងអនាគតដ៏ប្រសើរជាមួយសហគមន៍អ្នកសិក្សា';

  @override
  String get onboardingLearningBody =>
      'ស្វែងយល់ពីការអប់រំប្រកបដោយគុណភាព បទពិសោធន៍សិក្សាទំនើប និងចំណេះដឹងដែលរីកចម្រើនជាមួយអ្នក។';

  @override
  String get onboardingAchievementBody =>
      'បន្តការសិក្សាប្រចាំថ្ងៃ អបអរវឌ្ឍនភាព និងប្រែក្លាយជ័យជម្នះតូចៗទៅជាកម្លាំងចលករ។';

  @override
  String get onboardingCommunityBody =>
      'រៀនជាមួយសហគមន៍ដែលគាំទ្រ ចែករំលែកគំនិត ឆ្លើយសំណួរ និងរីកចម្រើនជាមួយគ្នា។';

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
  String get leaderboardRank => 'ចំណាត់ថ្នាក់តារាងពិន្ទុ';

  @override
  String get noPostsYet => 'ការបង្ហោះក្នុងសហគមន៍របស់អ្នកនឹងបង្ហាញនៅទីនេះ។';

  @override
  String get countryRank => 'ចំណាត់ថ្នាក់កម្ពុជា';

  @override
  String get provinceRank => 'ចំណាត់ថ្នាក់ខេត្ត';

  @override
  String get unranked => 'មិនទាន់មានចំណាត់ថ្នាក់';

  @override
  String get settings => 'ការកំណត់';

  @override
  String get editProfile => 'កែប្រែប្រវត្តិរូប';

  @override
  String get notificationPreferences => 'ការជូនដំណឹង';

  @override
  String get notificationPreferencesHint => 'រំលឹកអំពីការសិក្សា និងសហគមន៍';

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
}
