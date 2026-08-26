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
  String get welcomeBack => 'Welcome Back';

  @override
  String get loginSubtitle => 'Sign in to continue your learning journey';

  @override
  String get loginEyebrow => 'Your learning space';

  @override
  String get registerTitle => 'Create Account';

  @override
  String get registerSubtitle => 'Join Riksa and start learning today';

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
  String get login => 'Log In';

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
  String get telegramChatId => 'Telegram Chat ID';

  @override
  String get telegramChatIdHint => 'Start our bot and paste your chat ID';

  @override
  String get telegramOtpInstructions =>
      'We sent a code to your Telegram. Enter it below.';

  @override
  String get otpCode => 'OTP Code';

  @override
  String get otpCodeHint => '6-digit code';

  @override
  String get sendCode => 'Send Code';

  @override
  String get verify => 'Verify';

  @override
  String get resendCode => 'Resend code';

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
  String get otpSendFailed => 'Failed to send OTP code';

  @override
  String get otpVerifyFailed => 'Invalid or expired code';

  @override
  String get otpSendSuccess => 'Code sent to your Telegram';

  @override
  String get telegramEyebrow => 'Fast passwordless access';

  @override
  String get telegramLoginTitle => 'Log in with Telegram';

  @override
  String get telegramLoginSubtitle =>
      'Enter the chat ID from the Riksa bot and we’ll send a one-time code.';

  @override
  String get telegramRegisterTitle => 'Register with Telegram';

  @override
  String get telegramRegisterSubtitle =>
      'Choose your Riksa name, then verify your Telegram account with a one-time code.';

  @override
  String get enterTelegramCode => 'Enter your Telegram code';

  @override
  String get invalidTelegramChatId => 'Enter a valid numeric Telegram chat ID';

  @override
  String get invalidOtpCode => 'Enter the 6-digit code';

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
  String get chooseCommunity => 'Choose a community';

  @override
  String get postTitleLabel => 'Post title';

  @override
  String get questionTitleLabel => 'What do you want to ask?';

  @override
  String get detailsLabel => 'Add details';

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
  String get discussion => 'Discussion';

  @override
  String get addComment => 'Add to the discussion';

  @override
  String get sendComment => 'Send comment';

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
  String get onboardingTitle =>
      'Build a Better Future with a Community of Learners';

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
  String get countryRank => 'Cambodia rank';

  @override
  String get provinceRank => 'Province rank';

  @override
  String get unranked => 'Not ranked yet';

  @override
  String get settings => 'Settings';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get notificationPreferences => 'Notification preferences';

  @override
  String get notificationPreferencesHint => 'Learning and community reminders';

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
}
