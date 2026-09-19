// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Riksa';

  @override
  String get welcomeBack => 'Welcome back!';

  @override
  String get loginSubtitle => 'Sign in to continue your learning journey.';

  @override
  String get loginEyebrow => 'Your learning space';

  @override
  String get registerTitle => 'Create Account';

  @override
  String get registerSubtitle => 'Create your account and start learning today';

  @override
  String get registerEyebrow => 'Start your streak';

  @override
  String get accountBasics => 'Account basics';

  @override
  String get secureYourAccount => 'Secure your account';

  @override
  String stepOfTwo(int step) {
    return 'Step $step of 2';
  }

  @override
  String get username => 'Username';

  @override
  String get usernameHint => 'Enter your username';

  @override
  String get emailOrUsername => 'Email or username';

  @override
  String get emailOrUsernameHint => 'Enter your email or username';

  @override
  String get password => 'Password';

  @override
  String get passwordHint => 'Enter your password';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get confirmPasswordHint => 'Enter your password again';

  @override
  String get showPassword => 'Show password';

  @override
  String get hidePassword => 'Hide password';

  @override
  String get passwordEightCharacters => '8+ characters';

  @override
  String get passwordUppercase => 'Uppercase';

  @override
  String get passwordLowercase => 'Lowercase';

  @override
  String get passwordNumber => 'Number';

  @override
  String get email => 'Email';

  @override
  String get emailHint => 'you@example.com';

  @override
  String get displayName => 'Display Name';

  @override
  String get displayNameHint => 'Your name as shown to others';

  @override
  String get phoneNumber => 'Phone Number';

  @override
  String get phoneNumberHint => 'Optional';

  @override
  String get login => 'Log in';

  @override
  String get register => 'Register';

  @override
  String get continueLabel => 'Continue';

  @override
  String get back => 'Back';

  @override
  String get tryAgain => 'Try again';

  @override
  String get useAnotherAccount => 'Use another account';

  @override
  String get readyToLearn => 'Ready to learn';

  @override
  String get preparingYourSpace => 'Preparing your space';

  @override
  String get orContinueWith => 'or continue with';

  @override
  String get orLabel => 'OR';

  @override
  String get signInWithGoogle => 'Continue with Google';

  @override
  String get signInWithTelegram => 'Continue with Telegram';

  @override
  String get verify => 'Verify';

  @override
  String get noAccount => 'Don\'t have an account?';

  @override
  String get haveAccount => 'Already have an account?';

  @override
  String get signUpNow => 'Sign up';

  @override
  String get signInNow => 'Sign in';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get passwordRecoveryUnavailable =>
      'Password recovery is not available yet.';

  @override
  String get requiredField => 'This field is required';

  @override
  String get invalidUsername => 'Username must be at least 3 characters';

  @override
  String get invalidEmail => 'Enter a valid email address';

  @override
  String get weakPassword =>
      'Password must be 8+ chars with upper, lower, and digit';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get displayNameTooLong =>
      'Display name must be 100 characters or fewer';

  @override
  String get usernameTooLong => 'Username must be between 3 and 50 characters';

  @override
  String get signInSecureNote =>
      'Your session stays protected and refreshes automatically.';

  @override
  String get registerEmailNote =>
      'You can verify your email later from your profile.';

  @override
  String get loginFailed => 'Login failed. Check your credentials.';

  @override
  String get registerFailed => 'Registration failed. Please try again.';

  @override
  String get googleFailed => 'Google sign-in failed';

  @override
  String get googleNotConfigured =>
      'Google sign-in is not configured for this build yet.';

  @override
  String get googleUnsupported =>
      'Use the Google button provided by your browser to continue.';

  @override
  String get telegramEyebrow => 'No password needed';

  @override
  String get telegramAuthTitle => 'Continue with Telegram';

  @override
  String get telegramAuthSubtitle =>
      'No Telegram ID to remember. Pick a way to sign in. New to Riksa? Both options create your account.';

  @override
  String get telegramAuthorize => 'Open Telegram';

  @override
  String get telegramAuthorizeHint =>
      'Fastest: tap Confirm in the Riksa bot and come straight back.';

  @override
  String get telegramUseCode => 'Log in with code';

  @override
  String get telegramUseCodeHint =>
      'Telegram on another device? Get a code from the bot and paste it here.';

  @override
  String get telegramTheBot => 'the Riksa bot';

  @override
  String get telegramCodeTitle => 'Log in with code';

  @override
  String telegramCodeSubtitle(String bot) {
    return 'Paste the code from $bot to sign in.';
  }

  @override
  String telegramCodeStepOpen(String bot) {
    return 'Open $bot and tap Start, or send /code';
  }

  @override
  String get telegramCodeStepCopy => 'Copy the 8-character code it sends you';

  @override
  String get telegramCodeStepPaste => 'Paste it below';

  @override
  String telegramOpenBot(String bot) {
    return 'Open $bot';
  }

  @override
  String get telegramCodeLabel => 'Sign-in code';

  @override
  String get telegramCodeHint => 'e.g. VE9BLZ8J';

  @override
  String get telegramPasteCode => 'Paste code';

  @override
  String get telegramCodeInvalidFormat =>
      'Enter the 8-character code from the bot';

  @override
  String get telegramCodeRejected =>
      'This code is invalid or expired. Send /code to the bot for a new one.';

  @override
  String get telegramNoCodeInClipboard =>
      'No sign-in code found in your clipboard.';

  @override
  String get telegramSignIn => 'Sign in';

  @override
  String get telegramUseOpenInstead => 'Use Open Telegram instead';

  @override
  String get telegramSwitchToCode => 'Having trouble? Log in with code';

  @override
  String get telegramPrivacyNote =>
      'Riksa only receives your public Telegram name and username. Never your phone number or chats.';

  @override
  String get telegramWaitingTitle => 'Waiting for Telegram';

  @override
  String get telegramWaitingSubtitle =>
      'Confirm the request in the Riksa bot, then return to this screen.';

  @override
  String telegramExpiresIn(String time) {
    return 'Request expires in $time';
  }

  @override
  String get telegramOpenAgain => 'Open Telegram again';

  @override
  String get telegramCopyLink => 'Copy link';

  @override
  String get telegramLinkCopied =>
      'Link copied. Open it on any device with Telegram.';

  @override
  String get telegramOpenFailed =>
      'Couldn\'t open Telegram. Install Telegram, or copy the link and open it on another device.';

  @override
  String get telegramStartFailed =>
      'Couldn\'t start Telegram authorization. Please try again.';

  @override
  String get telegramExpired =>
      'This request expired. Start again to get a fresh link.';

  @override
  String get telegramDenied => 'The request was declined in Telegram.';

  @override
  String get telegramSignupExpired =>
      'Your Telegram approval expired before the account was created. Please authorize again.';

  @override
  String get telegramProfileEyebrow => 'Telegram connected';

  @override
  String get telegramProfileTitle => 'Set up your Riksa profile';

  @override
  String get telegramProfileSubtitle =>
      'Choose how other learners will see you. You can change your display name later.';

  @override
  String telegramConnectedAs(String name) {
    return 'Connected as $name';
  }

  @override
  String get telegramCreateAccount => 'Create account';

  @override
  String get telegramUseAnotherAccount => 'Use a different Telegram account';

  @override
  String get languageEn => 'English';

  @override
  String get languageKm => 'ខ្មែរ';

  @override
  String get community => 'Community';

  @override
  String get myFeed => 'My Feed';

  @override
  String streakDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
      zero: '0 days',
    );
    return '$_temp0';
  }

  @override
  String get streakTitle => 'Streak';

  @override
  String get streakSubtitle => 'Learn every day to keep your streak growing.';

  @override
  String get bestStreak => 'Best streak';

  @override
  String get lastTracked => 'Last tracked';

  @override
  String get noTrackedDate => 'No learning activity has been recorded yet.';

  @override
  String get activityCalendar => 'Activity calendar';

  @override
  String get createCommunityContent => 'Create in Community';

  @override
  String get startConversation => 'Start a conversation';

  @override
  String get startConversationHint => 'Share something with RIKSA...';

  @override
  String get createPost => 'Create a post';

  @override
  String get createPostSubtitle => 'Share an idea, lesson, or useful resource.';

  @override
  String get askCommunity => 'Ask the community';

  @override
  String get askCommunitySubtitle =>
      'Get help from learners who have been there.';

  @override
  String get writeArticle => 'Write an article';

  @override
  String get writeArticleSubtitle =>
      'A longer piece for the blog, reviewed before it appears.';

  @override
  String get yourArticles => 'Your articles';

  @override
  String articlesInReview(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count in review',
      one: '1 in review',
    );
    return '$_temp0';
  }

  @override
  String get communityComposerPrompt => 'What are your doubts?';

  @override
  String get chooseCommunity => 'Choose a community';

  @override
  String get postTitleLabel => 'Post title';

  @override
  String get questionTitleLabel => 'What do you want to ask?';

  @override
  String get detailsLabel => 'Add details';

  @override
  String get addPhoto => 'Add a photo';

  @override
  String get changePhoto => 'Change photo';

  @override
  String get removePhoto => 'Remove photo';

  @override
  String get photoUploading => 'Uploading photo…';

  @override
  String get photoFailed => 'That photo couldn’t be uploaded. Try another one.';

  @override
  String get photoTooLarge => 'That photo is too large. Pick one under 2MB.';

  @override
  String get photoFromGallery => 'Choose from gallery';

  @override
  String get photoFromCamera => 'Take a photo';

  @override
  String get publish => 'Publish';

  @override
  String get publishFailed =>
      'We couldn’t publish this yet. Check your content and try again.';

  @override
  String get noCommunities => 'Communities are not available yet.';

  @override
  String get blogEmptyMessage =>
      'Fresh stories from the RIKSA community will appear here.';

  @override
  String get communityHeadline => 'Learn together. Share what clicks.';

  @override
  String get communitySubtitle =>
      'Ask questions, swap useful ideas, and celebrate progress with learners across RIKSA.';

  @override
  String get forYou => 'For you';

  @override
  String get official => 'Official';

  @override
  String get topLearnersThisWeek => 'Top Learners This Week';

  @override
  String get viewAll => 'View All';

  @override
  String upvotesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count upvotes',
      one: '1 upvote',
      zero: '0 upvotes',
    );
    return '$_temp0';
  }

  @override
  String get popularCommunities => 'Popular communities';

  @override
  String membersLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count members',
      one: '1 member',
      zero: 'No members',
    );
    return '$_temp0';
  }

  @override
  String get join => 'Join';

  @override
  String get joined => 'Joined';

  @override
  String get feedEmptyTitle => 'Your community feed is ready';

  @override
  String get feedEmptyMessage =>
      'Posts from this community will appear here as learners start sharing.';

  @override
  String get feedErrorTitle => 'We couldn’t load the community';

  @override
  String get loadMore => 'Load more';

  @override
  String get copiedLink => 'Post link copied';

  @override
  String get actionFailed => 'That action didn’t go through. Try again.';

  @override
  String get postDetail => 'Post detail';

  @override
  String get editPost => 'Edit post';

  @override
  String get deletePost => 'Delete post';

  @override
  String get postOptions => 'Post options';

  @override
  String get deletePostTitle => 'Delete this post?';

  @override
  String get deletePostMessage =>
      'The post and its replies are removed for everyone. This cannot be undone.';

  @override
  String get keepPost => 'Keep post';

  @override
  String get delete => 'Delete';

  @override
  String get postUpdated => 'Changes saved';

  @override
  String get postDeleted => 'Post deleted';

  @override
  String get saveFailed => 'We couldn’t save your changes. Try again.';

  @override
  String get deleteFailed => 'We couldn’t delete this post. Try again.';

  @override
  String get editPostSubtitle => 'Update what you shared with the community.';

  @override
  String get discussion => 'Discussion';

  @override
  String get addComment => 'Add to the discussion';

  @override
  String get sendComment => 'Send comment';

  @override
  String get reply => 'Reply';

  @override
  String get replyingTo => 'Replying to';

  @override
  String get commentFailed => 'We couldn’t add your comment. Please try again.';

  @override
  String get noComments => 'No comments yet. Start the conversation.';

  @override
  String get postUnavailable => 'Post unavailable';

  @override
  String get postUnavailableMessage =>
      'This post may have been removed or is no longer visible.';

  @override
  String get profile => 'Profile';

  @override
  String get shareProfile => 'Share profile';

  @override
  String get profileLinkCopied => 'Profile link copied';

  @override
  String get blog => 'Blog';

  @override
  String get setUpProfile => 'Set up profile';

  @override
  String get onboardingLearningBody =>
      'Discover quality education, modern learning experiences, and knowledge that grows with you.';

  @override
  String get onboardingAchievementBody =>
      'Keep your streak alive, celebrate progress, and turn every small win into momentum.';

  @override
  String get onboardingCommunityBody =>
      'Learn with a supportive community that shares ideas, answers questions, and grows together.';

  @override
  String get onboardingLearningTitle => 'Learn Without Limits';

  @override
  String get onboardingAchievementTitle => 'Progress You Can See';

  @override
  String get onboardingCommunityTitle => 'Never Study Alone';

  @override
  String get onboardingGetStarted => 'Get started';

  @override
  String get selectProvinceTitle => 'Select your province';

  @override
  String get selectProvinceSubtitle =>
      'Your province personalizes local communities and provincial rankings. It will be saved securely to your profile after you sign in.';

  @override
  String get searchProvince => 'Search provinces';

  @override
  String get searchCommunity => 'Search';

  @override
  String get searchCommunityHint => 'Try a different keyword.';

  @override
  String get noSearchResults => 'No matching results';

  @override
  String get noProvinceResults => 'No provinces match your search.';

  @override
  String get provinceLoadFailed => 'We couldn’t load the provinces.';

  @override
  String get provinceSaveFailed =>
      'We couldn’t save your province. Please try again.';

  @override
  String get home => 'Home';

  @override
  String get learn => 'Learn';

  @override
  String get learningTitle => 'Learning';

  @override
  String get continueLearning => 'Continue learning';

  @override
  String get searchLessons => 'Search lessons';

  @override
  String get leaderboard => 'Leaderboard';

  @override
  String get ranksTab => 'Ranks';

  @override
  String get logout => 'Log Out';

  @override
  String get loading => 'Loading...';

  @override
  String get learningHeadline => 'Find your next lesson';

  @override
  String get learningSubtitle =>
      'Choose your grade, subject, and level to learn at your pace.';

  @override
  String get learningHeaderSubtitle => 'A little progress, every day';

  @override
  String get dailyMissionEyebrow => 'Today\'s mission';

  @override
  String get dailyMissionBody => 'A focused lesson picked for your pace.';

  @override
  String get startDailyMission => 'Start lesson';

  @override
  String get filters => 'Filters';

  @override
  String get filterLessons => 'Filter lessons';

  @override
  String get applyFilters => 'Show lessons';

  @override
  String get resetFilters => 'Reset';

  @override
  String removeFilter(String filter) {
    return 'Remove $filter filter';
  }

  @override
  String minutesShort(int minutes) {
    return '$minutes min';
  }

  @override
  String get gradeFilter => 'Grade';

  @override
  String get subjectFilter => 'Subject';

  @override
  String get difficultyFilter => 'Difficulty';

  @override
  String get allGrades => 'All grades';

  @override
  String gradeNumber(int grade) {
    return 'Grade $grade';
  }

  @override
  String gradeDataPending(int grade) {
    return 'Grade $grade is selected. Until lessons receive grade tags from the API, ungraded lessons remain visible.';
  }

  @override
  String get allSubjects => 'All subjects';

  @override
  String get allLevels => 'All levels';

  @override
  String get recommendedLessons => 'Recommended lessons';

  @override
  String get doneLabel => 'done';

  @override
  String get completedLabel => 'Completed';

  @override
  String get generalSubject => 'General';

  @override
  String get difficultyEasy => 'Easy';

  @override
  String get difficultyMedium => 'Medium';

  @override
  String get difficultyHard => 'Hard';

  @override
  String get difficultyDifficult => 'Advanced';

  @override
  String get contentTypeLesson => 'Lesson';

  @override
  String get contentTypeChallenge => 'Challenge';

  @override
  String get contentTypeRoadmap => 'Roadmap';

  @override
  String exerciseCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count exercises',
      one: '1 exercise',
      zero: 'No exercises',
    );
    return '$_temp0';
  }

  @override
  String baseXpLabel(int xp) {
    return 'Base $xp XP';
  }

  @override
  String greetingNamed(String name) {
    return 'Hi, $name';
  }

  @override
  String get gradeStemLabel => 'Grade 12 · STEM';

  @override
  String get yourSubjects => 'Your subjects';

  @override
  String get mathematicsSubjectDescription =>
      'Build confidence with numbers and problem solving';

  @override
  String get physicsSubjectDescription =>
      'Understand motion, forces, and the universe';

  @override
  String get chemistrySubjectDescription =>
      'Discover matter, reactions, and change';

  @override
  String get biologySubjectDescription =>
      'Explore living systems and life science';

  @override
  String get technologySubjectDescription =>
      'Practice computing and digital technology';

  @override
  String get generalSubjectDescription =>
      'Explore this subject and its lessons';

  @override
  String get continueReading => 'Continue reading';

  @override
  String xpRewardAmount(int xp) {
    return '+$xp XP';
  }

  @override
  String lessonsDoneOfTotal(int done, int total) {
    return '$done of $total lessons';
  }

  @override
  String subjectCountShort(int done, int total) {
    return '$done / $total';
  }

  @override
  String get examDestination => 'Bac II · Grade 12';

  @override
  String daysRemaining(int days) {
    return '${days}d';
  }

  @override
  String get subjectUnavailable => 'Could not load';

  @override
  String get noSubjectsYet => 'No STEM subjects yet';

  @override
  String get noSubjectsYetBody =>
      'Grade 12 subjects appear here as soon as they are published.';

  @override
  String get everySubjectFinished => 'Every subject is finished';

  @override
  String get everySubjectFinishedBody =>
      'You have worked through the whole Grade 12 STEM syllabus.';

  @override
  String unitOfTotal(int current, int total) {
    return 'Unit $current of $total';
  }

  @override
  String wholeSyllabusSummary(int units, int lessons) {
    String _temp0 = intl.Intl.pluralLogic(
      units,
      locale: localeName,
      other: '$units units',
      one: '1 unit',
    );
    String _temp1 = intl.Intl.pluralLogic(
      lessons,
      locale: localeName,
      other: '$lessons lessons',
      one: '1 lesson',
    );
    return '$_temp0, $_temp1';
  }

  @override
  String unitProgressShort(int done, int total) {
    return '$done of $total done';
  }

  @override
  String get youAreHere => 'You are here';

  @override
  String opensAfterUnit(int number) {
    return 'Opens after Unit $number';
  }

  @override
  String get lessonLockedShort => 'Locked';

  @override
  String lessonCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lessons',
      one: '1 lesson',
    );
    return '$_temp0';
  }

  @override
  String get readyForExam => 'Ready for Bac II';

  @override
  String get roadmapLoadFailed => 'We couldn’t load this roadmap';

  @override
  String get roadmapEmpty => 'This subject has no lessons yet';

  @override
  String get roadmapEmptyBody =>
      'Lessons appear here as soon as they are published.';

  @override
  String get lessonLocked => 'Finish the lessons before this one to unlock it';

  @override
  String get lessonLoadFailed => 'We couldn’t load lessons';

  @override
  String get noLessonsFound => 'No lessons found';

  @override
  String get noLessonsForFilters =>
      'Try another grade, subject, or difficulty.';

  @override
  String get lessonPreviewHeading => 'Ready when you are';

  @override
  String get lessonPreviewBody =>
      'Take it one step at a time. Your progress is saved along the way.';

  @override
  String get beginLesson => 'Begin lesson';

  @override
  String get lessonContentUnavailable =>
      'Lesson activities will appear when the learning service provides the lesson detail.';

  @override
  String get backToLessons => 'Back to lessons';

  @override
  String get accountSettings => 'Account settings';

  @override
  String get riksaLearner => 'RIKSA Learner';

  @override
  String memberSince(String date) {
    return 'Member since $date';
  }

  @override
  String get verified => 'Verified';

  @override
  String get notVerified => 'Not verified';

  @override
  String get accountRole => 'Account role';

  @override
  String get totalXp => 'Total XP';

  @override
  String get currentStreak => 'Current streak';

  @override
  String get achievements => 'Achievements';

  @override
  String get currentRank => 'Current rank';

  @override
  String get startingTier => 'Starting tier';

  @override
  String get highestRankReached => 'You’ve reached the highest available rank.';

  @override
  String xpUntilNextRank(int xp, String tier) {
    return '$xp XP until $tier';
  }

  @override
  String tierBandProgress(String earned, String total) {
    return '$earned / $total XP';
  }

  @override
  String xpUntilFinalRank(int xp, String tier) {
    return '$xp XP to $tier, the final rank';
  }

  @override
  String tierPosition(int position, int total) {
    return 'Rank $position of $total';
  }

  @override
  String get earned => 'Earned';

  @override
  String get recentActivity => 'Recent activity';

  @override
  String get noAchievements =>
      'Achievements and their progress will appear here.';

  @override
  String get noRecentActivity =>
      'Your XP activity will appear here as you learn.';

  @override
  String get profileLoadFailed => 'We couldn’t load your learning profile.';

  @override
  String get lessonCompletionReward => 'Lesson completed';

  @override
  String get achievementReward => 'Achievement reward';

  @override
  String get streakReward => 'Streak reward';

  @override
  String get rankReward => 'Rank reward';

  @override
  String get welcomeBonus => 'Welcome bonus';

  @override
  String get xpReward => 'XP reward';

  @override
  String get myPosts => 'My Posts';

  @override
  String get leaderboardRank => 'Leaderboard Rank';

  @override
  String get noPostsYet => 'Your community posts will appear here.';

  @override
  String get profileComposerPrompt => 'Share what you are learning';

  @override
  String profilePostCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count posts',
      one: '1 post',
      zero: 'No posts yet',
    );
    return '$_temp0';
  }

  @override
  String get writeFirstPost => 'Write your first post';

  @override
  String get managePost => 'Manage post';

  @override
  String get countryRank => 'Cambodia rank';

  @override
  String get provinceRank => 'Province rank';

  @override
  String get unranked => 'Not ranked yet';

  @override
  String get settings => 'Settings';

  @override
  String get openProfileMenu => 'Open profile menu';

  @override
  String get communitiesMenu => 'Communities';

  @override
  String get progressHistory => 'Progress';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get notificationPreferences => 'Notification preferences';

  @override
  String get notificationPreferencesHint => 'Learning and community reminders';

  @override
  String get learningSounds => 'Learning sounds';

  @override
  String get learningSoundsHint =>
      'Play a sound for correct answers, mistakes and finished lessons.';

  @override
  String get darkMode => 'Dark mode';

  @override
  String get darkModeHint => 'Use RIKSA\'s dark appearance';

  @override
  String get language => 'Language';

  @override
  String get helpAndLegal => 'Help & legal';

  @override
  String get faq => 'FAQ';

  @override
  String get termsOfService => 'Terms of Service';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get fullName => 'Full name';

  @override
  String get bio => 'Bio';

  @override
  String get gender => 'Gender';

  @override
  String get genderUnspecified => 'Prefer not to say';

  @override
  String get saveChanges => 'Save Changes';

  @override
  String get changesSaved => 'Your profile was updated.';

  @override
  String get profileSaveFailed =>
      'We couldn’t save your profile. Please try again.';

  @override
  String get deleteAccount => 'Delete Account';

  @override
  String get deleteAccountTitle => 'Delete your RIKSA account?';

  @override
  String get deleteAccountConfirmation =>
      'This would permanently remove your learning history, XP, achievements, and posts. Continue?';

  @override
  String get cancel => 'Cancel';

  @override
  String get deleteUnavailable =>
      'Account deletion is not available from the API yet. Contact RIKSA support for help.';

  @override
  String get accountIdentifiersReadOnly =>
      'Email, phone, and username are secured account identifiers and cannot currently be changed here.';

  @override
  String get chooseAvatar => 'Choose an avatar';

  @override
  String get humationAvatarSubtitle =>
      'Pick a hand-drawn character for your RIKSA profile.';

  @override
  String get editCover => 'Edit cover';

  @override
  String get chooseProfileCover => 'Choose a profile cover';

  @override
  String get profileCoverSubtitle =>
      'Pick a color and pattern that feels like you.';

  @override
  String get chooseFromPhotos => 'Choose from photos';

  @override
  String get imageSelectionFailed =>
      'We couldn’t use that image. Please try another one.';

  @override
  String get notProvided => 'Not provided';

  @override
  String get supportDocumentUnavailable =>
      'This document will be available here after the RIKSA support content is published.';

  @override
  String get aiTutor => 'AI Tutor';

  @override
  String get aiTutorComingSoon => 'RIKSA AI Tutor is coming soon.';

  @override
  String get publicProfile => 'Public profile';

  @override
  String get posts => 'Posts';

  @override
  String get publicProfileUnavailable => 'Profile unavailable';

  @override
  String get publicProfileUnavailableMessage =>
      'This person may have deleted their account, been suspended, or limited access to their profile.';

  @override
  String get publicProfileLoadFailed =>
      'We couldn’t load this public profile. Please try again.';

  @override
  String get publicPostsLoadFailed => 'We couldn’t load this person’s posts.';

  @override
  String get noPublicPosts =>
      'This person hasn’t shared any community posts yet.';

  @override
  String get noPublicAchievements =>
      'No earned achievements are available yet.';

  @override
  String get noPublicRank => 'No public ranking is available yet.';

  @override
  String get aiTutorSubtitle => 'Ask anything from your lessons';

  @override
  String get aiAskNewQuestion => 'Ask a new question';

  @override
  String get aiChatsToday => 'Today';

  @override
  String get aiChatsThisWeek => 'This week';

  @override
  String get aiChatsEarlier => 'Earlier';

  @override
  String get aiChatOptions => 'Chat options';

  @override
  String get aiDeleteChat => 'Delete chat';

  @override
  String get aiChatDeleted => 'Chat deleted';

  @override
  String get aiUndo => 'Undo';

  @override
  String get aiChatDeleteFailed => 'That chat could not be deleted.';

  @override
  String get aiChatsEmptyTitle => 'Ask anything you are learning';

  @override
  String get aiChatsEmptyBody =>
      'Start a private conversation in Khmer or English about any lesson.';

  @override
  String get aiStartChat => 'Start a chat';

  @override
  String get aiTutorUnavailableTitle => 'Tutor unavailable';

  @override
  String get aiTutorUnavailableBody => 'Check your connection and try again.';

  @override
  String get aiSearchChats => 'Search your chats';

  @override
  String get aiNoChatMatches => 'No chat matches that.';

  @override
  String get aiChatFallbackTitle => 'Learning chat';

  @override
  String get aiComposerHint => 'Type your question...';

  @override
  String get aiSendMessage => 'Send message';

  @override
  String get aiThinking => 'Riksa is thinking';

  @override
  String get aiMessageNotSent => 'Not sent';

  @override
  String get aiRetryMessage => 'Send again';

  @override
  String get aiChatOpener => 'What would you like to understand today?';

  @override
  String get aiAskAboutLesson => 'Ask about this lesson';

  @override
  String aiLessonContext(String lesson) {
    return 'About $lesson';
  }

  @override
  String get aiStarterExplainAgain => 'Explain this again, more slowly';

  @override
  String get aiStarterStillUnsure => 'I am still unsure about one part';

  @override
  String get aiStarterWorkedExample => 'Give me a worked example';

  @override
  String get aiChatLoadFailed => 'Could not load this chat.';

  @override
  String get aiReplyFailed => 'The tutor could not answer. Please try again.';

  @override
  String get aiContinueChat => 'Continue';

  @override
  String get aiTimeNow => 'now';

  @override
  String aiTimeMinutes(int count) {
    return '${count}m';
  }

  @override
  String aiTimeHours(int count) {
    return '${count}h';
  }

  @override
  String aiTimeDays(int count) {
    return '${count}d';
  }

  @override
  String get lessonRead => 'Read';

  @override
  String get lessonRespond => 'Respond';

  @override
  String get lessonReflect => 'Reflect';

  @override
  String lessonSectionCounter(int current, int total) {
    return 'Section $current of $total';
  }

  @override
  String get lessonTrySection => 'Try it yourself';

  @override
  String get lessonReflectAction => 'Reflect on this lesson';

  @override
  String get lessonCheckAnswer => 'Check answer';

  @override
  String get lessonCompareAnswers => 'Compare answers';

  @override
  String get lessonWorkFirst => 'Work it out first';

  @override
  String get lessonWorkHint =>
      'Write your answer and how you got there. Then compare it with the choices.';

  @override
  String get lessonAnswerHint => 'Write your answer';

  @override
  String get lessonYourWork => 'Your working';

  @override
  String get lessonChooseAnswer => 'Compare your working and choose an answer.';

  @override
  String lessonExerciseNumber(int number) {
    return 'Exercise $number';
  }

  @override
  String lessonResponseProgress(int done, int total) {
    return '$done of $total responses checked';
  }

  @override
  String get lessonSectionComplete => 'Section complete';

  @override
  String get lessonUpNext => 'Up next';

  @override
  String get lessonReflectionTitle => 'What will you take away?';

  @override
  String get lessonReflectionBody =>
      'Put one idea into your own words. Note anything you want to revisit.';

  @override
  String get lessonReflectionHint => 'I understood… I still want to work on…';

  @override
  String get lessonConfidencePrompt => 'How do you feel about this lesson?';

  @override
  String get lessonConfident => 'I can explain it';

  @override
  String get lessonNeedsReview => 'I want to revisit it';

  @override
  String get lessonSaveReflection => 'Save and finish';

  @override
  String get lessonReflectionRequired =>
      'Write a short reflection to finish this lesson.';

  @override
  String get lessonSavedReflection => 'Your reflection';

  @override
  String get lessonCompletedBody =>
      'One more step through your syllabus. Take a break or continue when you are ready.';

  @override
  String get lessonRevisitTitle => 'Worth another look';

  @override
  String get lessonRevisitBody =>
      'You marked this lesson for another look. You can reopen it from your roadmap.';

  @override
  String get lessonNextAction => 'Start next lesson';

  @override
  String get lessonRoadmapAction => 'Back to roadmap';

  @override
  String get lessonFinishSession => 'Finish for now';

  @override
  String get lessonResumeAction => 'Resume lesson';

  @override
  String get lessonStartAction => 'Start lesson';

  @override
  String get lessonOptions => 'Lesson options';

  @override
  String get lessonSections => 'Lesson sections';

  @override
  String get lessonSave => 'Save lesson';

  @override
  String get lessonUnsave => 'Remove from saved';

  @override
  String get lessonMute => 'Mute sound';

  @override
  String get lessonUnmute => 'Unmute sound';

  @override
  String get lessonExitBody =>
      'Checked answers are saved. Your unfinished writing will be lost if you leave.';

  @override
  String get lessonAiHint => 'Get a hint';

  @override
  String get lessonExplainAnswer => 'Explain with AI';

  @override
  String get lessonWhy => 'Explanation';

  @override
  String get lessonHint => 'Hint';

  @override
  String get lessonEditWorking => 'Edit working';

  @override
  String get lessonWorkingStatus => 'One moment…';

  @override
  String get lessonAnswerSuccess => 'That’s it. Keep going when you’re ready.';

  @override
  String get lessonAnswerRetry => 'Not quite yet. Try another approach.';

  @override
  String get learningLoadErrorBody =>
      'Your lessons couldn’t load this time. Give it another try.';

  @override
  String get savedLessonsEmptyTitle => 'Keep a good idea for later';

  @override
  String get savedLessonsEmptyBody =>
      'Found a formula worth revisiting? Save the lesson from its menu. It will be waiting here.';

  @override
  String get splashTagline => 'Learn Today, Build Tomorrow';

  @override
  String get splashDescription =>
      'Your Grade 12 STEM learning companion for a brighter Cambodia.';

  @override
  String get skipLabel => 'Skip';

  @override
  String get nextLabel => 'Next';

  @override
  String homeGreeting(String name) {
    return 'Hello, $name!';
  }

  @override
  String get homeSubtitle => 'Keep going! Knowledge builds your future.';

  @override
  String get homeSearchHint => 'Search posts, topics, or lessons...';

  @override
  String get homeLessons => 'Lessons';

  @override
  String get homeLessonsCaption => 'Continue';

  @override
  String get homeCommunityCaption => 'Join & share';

  @override
  String get homeAiCaption => 'Ask anything';

  @override
  String get homeLeaderboardCaption => 'See rankings';

  @override
  String get todaysLearning => 'Today\'s learning';

  @override
  String get communityFeed => 'Community Feed';

  @override
  String get viewAllShort => 'View all';

  @override
  String get feedFilterAll => 'All';

  @override
  String get aiCoachTitle => 'AI Study Coach';

  @override
  String get aiCoachGreeting =>
      'Hi! I\'m your AI Study Coach. Ask me anything about your lessons, and I\'ll help you learn step by step!';

  @override
  String get aiTryAskingAbout => 'Try asking about:';

  @override
  String get menuMyProgress => 'My Progress';

  @override
  String get menuSavedLessons => 'Saved Lessons';

  @override
  String get menuCommunities => 'Communities';

  @override
  String get communitiesDiscover => 'Discover';

  @override
  String get communitiesMine => 'My Communities';

  @override
  String get communitiesSearchHint => 'Search communities...';

  @override
  String get communityJoin => 'Join';

  @override
  String get communityJoined => 'Joined';

  @override
  String get communitiesUnavailable => 'Communities unavailable';

  @override
  String get communitiesLoadFailed => 'Could not load communities.';

  @override
  String get communitiesNoneJoined => 'You haven\'t joined a community yet.';

  @override
  String communityMembers(String count) {
    return '$count members';
  }
}
