import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_km.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
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
    Locale('km'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Riksa'**
  String get appName;

  /// Login screen heading
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get welcomeBack;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue your learning journey'**
  String get loginSubtitle;

  /// No description provided for @loginEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Your learning space'**
  String get loginEyebrow;

  /// No description provided for @registerTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get registerTitle;

  /// No description provided for @registerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Join Riksa and start learning today'**
  String get registerSubtitle;

  /// No description provided for @registerEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Start your streak'**
  String get registerEyebrow;

  /// No description provided for @accountBasics.
  ///
  /// In en, this message translates to:
  /// **'Account basics'**
  String get accountBasics;

  /// No description provided for @secureYourAccount.
  ///
  /// In en, this message translates to:
  /// **'Secure your account'**
  String get secureYourAccount;

  /// No description provided for @stepOfTwo.
  ///
  /// In en, this message translates to:
  /// **'Step {step} of 2'**
  String stepOfTwo(int step);

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// No description provided for @usernameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your username'**
  String get usernameHint;

  /// No description provided for @emailOrUsername.
  ///
  /// In en, this message translates to:
  /// **'Email or username'**
  String get emailOrUsername;

  /// No description provided for @emailOrUsernameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your email or username'**
  String get emailOrUsernameHint;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @passwordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get passwordHint;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @confirmPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your password again'**
  String get confirmPasswordHint;

  /// No description provided for @showPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get showPassword;

  /// No description provided for @hidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get hidePassword;

  /// No description provided for @passwordEightCharacters.
  ///
  /// In en, this message translates to:
  /// **'8+ characters'**
  String get passwordEightCharacters;

  /// No description provided for @passwordUppercase.
  ///
  /// In en, this message translates to:
  /// **'Uppercase'**
  String get passwordUppercase;

  /// No description provided for @passwordLowercase.
  ///
  /// In en, this message translates to:
  /// **'Lowercase'**
  String get passwordLowercase;

  /// No description provided for @passwordNumber.
  ///
  /// In en, this message translates to:
  /// **'Number'**
  String get passwordNumber;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @emailHint.
  ///
  /// In en, this message translates to:
  /// **'you@example.com'**
  String get emailHint;

  /// No description provided for @displayName.
  ///
  /// In en, this message translates to:
  /// **'Display Name'**
  String get displayName;

  /// No description provided for @displayNameHint.
  ///
  /// In en, this message translates to:
  /// **'Your name as shown to others'**
  String get displayNameHint;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @phoneNumberHint.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get phoneNumberHint;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Log In'**
  String get login;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// No description provided for @continueLabel.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueLabel;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @useAnotherAccount.
  ///
  /// In en, this message translates to:
  /// **'Use another account'**
  String get useAnotherAccount;

  /// No description provided for @readyToLearn.
  ///
  /// In en, this message translates to:
  /// **'Ready to learn'**
  String get readyToLearn;

  /// No description provided for @preparingYourSpace.
  ///
  /// In en, this message translates to:
  /// **'Preparing your space'**
  String get preparingYourSpace;

  /// No description provided for @orContinueWith.
  ///
  /// In en, this message translates to:
  /// **'or continue with'**
  String get orContinueWith;

  /// No description provided for @orLabel.
  ///
  /// In en, this message translates to:
  /// **'OR'**
  String get orLabel;

  /// No description provided for @signInWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get signInWithGoogle;

  /// No description provided for @signInWithTelegram.
  ///
  /// In en, this message translates to:
  /// **'Continue with Telegram'**
  String get signInWithTelegram;

  /// No description provided for @telegramChatId.
  ///
  /// In en, this message translates to:
  /// **'Telegram Chat ID'**
  String get telegramChatId;

  /// No description provided for @telegramChatIdHint.
  ///
  /// In en, this message translates to:
  /// **'Start our bot and paste your chat ID'**
  String get telegramChatIdHint;

  /// No description provided for @telegramOtpInstructions.
  ///
  /// In en, this message translates to:
  /// **'We sent a code to your Telegram. Enter it below.'**
  String get telegramOtpInstructions;

  /// No description provided for @otpCode.
  ///
  /// In en, this message translates to:
  /// **'OTP Code'**
  String get otpCode;

  /// No description provided for @otpCodeHint.
  ///
  /// In en, this message translates to:
  /// **'6-digit code'**
  String get otpCodeHint;

  /// No description provided for @sendCode.
  ///
  /// In en, this message translates to:
  /// **'Send Code'**
  String get sendCode;

  /// No description provided for @verify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verify;

  /// No description provided for @resendCode.
  ///
  /// In en, this message translates to:
  /// **'Resend code'**
  String get resendCode;

  /// No description provided for @noAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get noAccount;

  /// No description provided for @haveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get haveAccount;

  /// No description provided for @signUpNow.
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get signUpNow;

  /// No description provided for @signInNow.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signInNow;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @passwordRecoveryUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Password recovery is not available yet.'**
  String get passwordRecoveryUnavailable;

  /// No description provided for @requiredField.
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get requiredField;

  /// No description provided for @invalidUsername.
  ///
  /// In en, this message translates to:
  /// **'Username must be at least 3 characters'**
  String get invalidUsername;

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address'**
  String get invalidEmail;

  /// No description provided for @weakPassword.
  ///
  /// In en, this message translates to:
  /// **'Password must be 8+ chars with upper, lower, and digit'**
  String get weakPassword;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @displayNameTooLong.
  ///
  /// In en, this message translates to:
  /// **'Display name must be 100 characters or fewer'**
  String get displayNameTooLong;

  /// No description provided for @usernameTooLong.
  ///
  /// In en, this message translates to:
  /// **'Username must be between 3 and 50 characters'**
  String get usernameTooLong;

  /// No description provided for @signInSecureNote.
  ///
  /// In en, this message translates to:
  /// **'Your session stays protected and refreshes automatically.'**
  String get signInSecureNote;

  /// No description provided for @registerEmailNote.
  ///
  /// In en, this message translates to:
  /// **'You can verify your email later from your profile.'**
  String get registerEmailNote;

  /// No description provided for @loginFailed.
  ///
  /// In en, this message translates to:
  /// **'Login failed. Check your credentials.'**
  String get loginFailed;

  /// No description provided for @registerFailed.
  ///
  /// In en, this message translates to:
  /// **'Registration failed. Please try again.'**
  String get registerFailed;

  /// No description provided for @googleFailed.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in failed'**
  String get googleFailed;

  /// No description provided for @googleNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in is not configured for this build yet.'**
  String get googleNotConfigured;

  /// No description provided for @googleUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Use the Google button provided by your browser to continue.'**
  String get googleUnsupported;

  /// No description provided for @otpSendFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to send OTP code'**
  String get otpSendFailed;

  /// No description provided for @otpVerifyFailed.
  ///
  /// In en, this message translates to:
  /// **'Invalid or expired code'**
  String get otpVerifyFailed;

  /// No description provided for @otpSendSuccess.
  ///
  /// In en, this message translates to:
  /// **'Code sent to your Telegram'**
  String get otpSendSuccess;

  /// No description provided for @telegramEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Fast passwordless access'**
  String get telegramEyebrow;

  /// No description provided for @telegramLoginTitle.
  ///
  /// In en, this message translates to:
  /// **'Log in with Telegram'**
  String get telegramLoginTitle;

  /// No description provided for @telegramLoginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter the chat ID from the Riksa bot and we’ll send a one-time code.'**
  String get telegramLoginSubtitle;

  /// No description provided for @telegramRegisterTitle.
  ///
  /// In en, this message translates to:
  /// **'Register with Telegram'**
  String get telegramRegisterTitle;

  /// No description provided for @telegramRegisterSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose your Riksa name, then verify your Telegram account with a one-time code.'**
  String get telegramRegisterSubtitle;

  /// No description provided for @enterTelegramCode.
  ///
  /// In en, this message translates to:
  /// **'Enter your Telegram code'**
  String get enterTelegramCode;

  /// No description provided for @invalidTelegramChatId.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid numeric Telegram chat ID'**
  String get invalidTelegramChatId;

  /// No description provided for @invalidOtpCode.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code'**
  String get invalidOtpCode;

  /// No description provided for @languageEn.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEn;

  /// No description provided for @languageKm.
  ///
  /// In en, this message translates to:
  /// **'ខ្មែរ'**
  String get languageKm;

  /// No description provided for @community.
  ///
  /// In en, this message translates to:
  /// **'Community'**
  String get community;

  /// No description provided for @myFeed.
  ///
  /// In en, this message translates to:
  /// **'My Feed'**
  String get myFeed;

  /// No description provided for @streakDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0 {0 days} =1 {1 day} other {{count} days}}'**
  String streakDays(int count);

  /// No description provided for @streakTitle.
  ///
  /// In en, this message translates to:
  /// **'Streak'**
  String get streakTitle;

  /// No description provided for @streakSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Learn every day to keep your streak growing.'**
  String get streakSubtitle;

  /// No description provided for @bestStreak.
  ///
  /// In en, this message translates to:
  /// **'Best streak'**
  String get bestStreak;

  /// No description provided for @lastTracked.
  ///
  /// In en, this message translates to:
  /// **'Last tracked'**
  String get lastTracked;

  /// No description provided for @noTrackedDate.
  ///
  /// In en, this message translates to:
  /// **'No learning activity has been recorded yet.'**
  String get noTrackedDate;

  /// No description provided for @activityCalendar.
  ///
  /// In en, this message translates to:
  /// **'Activity calendar'**
  String get activityCalendar;

  /// No description provided for @createCommunityContent.
  ///
  /// In en, this message translates to:
  /// **'Create in Community'**
  String get createCommunityContent;

  /// No description provided for @createPost.
  ///
  /// In en, this message translates to:
  /// **'Create a post'**
  String get createPost;

  /// No description provided for @createPostSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Share an idea, lesson, or useful resource.'**
  String get createPostSubtitle;

  /// No description provided for @askCommunity.
  ///
  /// In en, this message translates to:
  /// **'Ask the community'**
  String get askCommunity;

  /// No description provided for @askCommunitySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Get help from learners who have been there.'**
  String get askCommunitySubtitle;

  /// No description provided for @chooseCommunity.
  ///
  /// In en, this message translates to:
  /// **'Choose a community'**
  String get chooseCommunity;

  /// No description provided for @postTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Post title'**
  String get postTitleLabel;

  /// No description provided for @questionTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'What do you want to ask?'**
  String get questionTitleLabel;

  /// No description provided for @detailsLabel.
  ///
  /// In en, this message translates to:
  /// **'Add details'**
  String get detailsLabel;

  /// No description provided for @publish.
  ///
  /// In en, this message translates to:
  /// **'Publish'**
  String get publish;

  /// No description provided for @publishFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn’t publish this yet. Check your content and try again.'**
  String get publishFailed;

  /// No description provided for @noCommunities.
  ///
  /// In en, this message translates to:
  /// **'Communities are not available yet.'**
  String get noCommunities;

  /// No description provided for @blogEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Fresh stories from the RIKSA community will appear here.'**
  String get blogEmptyMessage;

  /// No description provided for @communityHeadline.
  ///
  /// In en, this message translates to:
  /// **'Learn together. Share what clicks.'**
  String get communityHeadline;

  /// No description provided for @communitySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Ask questions, swap useful ideas, and celebrate progress with learners across RIKSA.'**
  String get communitySubtitle;

  /// No description provided for @forYou.
  ///
  /// In en, this message translates to:
  /// **'For you'**
  String get forYou;

  /// No description provided for @official.
  ///
  /// In en, this message translates to:
  /// **'Official'**
  String get official;

  /// No description provided for @topLearnersThisWeek.
  ///
  /// In en, this message translates to:
  /// **'Top Learners This Week'**
  String get topLearnersThisWeek;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get viewAll;

  /// No description provided for @upvotesCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0 {0 upvotes} =1 {1 upvote} other {{count} upvotes}}'**
  String upvotesCount(int count);

  /// No description provided for @popularCommunities.
  ///
  /// In en, this message translates to:
  /// **'Popular communities'**
  String get popularCommunities;

  /// No description provided for @membersLabel.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0 {No members} =1 {1 member} other {{count} members}}'**
  String membersLabel(int count);

  /// No description provided for @join.
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get join;

  /// No description provided for @joined.
  ///
  /// In en, this message translates to:
  /// **'Joined'**
  String get joined;

  /// No description provided for @feedEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Your community feed is ready'**
  String get feedEmptyTitle;

  /// No description provided for @feedEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Posts from this community will appear here as learners start sharing.'**
  String get feedEmptyMessage;

  /// No description provided for @feedErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'We couldn’t load the community'**
  String get feedErrorTitle;

  /// No description provided for @loadMore.
  ///
  /// In en, this message translates to:
  /// **'Load more'**
  String get loadMore;

  /// No description provided for @copiedLink.
  ///
  /// In en, this message translates to:
  /// **'Post link copied'**
  String get copiedLink;

  /// No description provided for @actionFailed.
  ///
  /// In en, this message translates to:
  /// **'That action didn’t go through. Try again.'**
  String get actionFailed;

  /// No description provided for @postDetail.
  ///
  /// In en, this message translates to:
  /// **'Post detail'**
  String get postDetail;

  /// No description provided for @discussion.
  ///
  /// In en, this message translates to:
  /// **'Discussion'**
  String get discussion;

  /// No description provided for @addComment.
  ///
  /// In en, this message translates to:
  /// **'Add to the discussion'**
  String get addComment;

  /// No description provided for @sendComment.
  ///
  /// In en, this message translates to:
  /// **'Send comment'**
  String get sendComment;

  /// No description provided for @commentFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn’t add your comment. Please try again.'**
  String get commentFailed;

  /// No description provided for @noComments.
  ///
  /// In en, this message translates to:
  /// **'No comments yet. Start the conversation.'**
  String get noComments;

  /// No description provided for @postUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Post unavailable'**
  String get postUnavailable;

  /// No description provided for @postUnavailableMessage.
  ///
  /// In en, this message translates to:
  /// **'This post may have been removed or is no longer visible.'**
  String get postUnavailableMessage;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @blog.
  ///
  /// In en, this message translates to:
  /// **'Blog'**
  String get blog;

  /// No description provided for @setUpProfile.
  ///
  /// In en, this message translates to:
  /// **'Set up profile'**
  String get setUpProfile;

  /// No description provided for @onboardingTitle.
  ///
  /// In en, this message translates to:
  /// **'Build a Better Future with a Community of Learners'**
  String get onboardingTitle;

  /// No description provided for @onboardingLearningBody.
  ///
  /// In en, this message translates to:
  /// **'Discover quality education, modern learning experiences, and knowledge that grows with you.'**
  String get onboardingLearningBody;

  /// No description provided for @onboardingAchievementBody.
  ///
  /// In en, this message translates to:
  /// **'Keep your streak alive, celebrate progress, and turn every small win into momentum.'**
  String get onboardingAchievementBody;

  /// No description provided for @onboardingCommunityBody.
  ///
  /// In en, this message translates to:
  /// **'Learn with a supportive community that shares ideas, answers questions, and grows together.'**
  String get onboardingCommunityBody;

  /// No description provided for @selectProvinceTitle.
  ///
  /// In en, this message translates to:
  /// **'Select your province'**
  String get selectProvinceTitle;

  /// No description provided for @selectProvinceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your province personalizes local communities and provincial rankings. It will be saved securely to your profile after you sign in.'**
  String get selectProvinceSubtitle;

  /// No description provided for @searchProvince.
  ///
  /// In en, this message translates to:
  /// **'Search provinces'**
  String get searchProvince;

  /// No description provided for @noProvinceResults.
  ///
  /// In en, this message translates to:
  /// **'No provinces match your search.'**
  String get noProvinceResults;

  /// No description provided for @provinceLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn’t load the provinces.'**
  String get provinceLoadFailed;

  /// No description provided for @provinceSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn’t save your province. Please try again.'**
  String get provinceSaveFailed;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @learn.
  ///
  /// In en, this message translates to:
  /// **'Learn'**
  String get learn;

  /// No description provided for @leaderboard.
  ///
  /// In en, this message translates to:
  /// **'Leaderboard'**
  String get leaderboard;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get logout;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @learningHeadline.
  ///
  /// In en, this message translates to:
  /// **'Find your next lesson'**
  String get learningHeadline;

  /// No description provided for @learningSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose your grade, subject, and level to learn at your pace.'**
  String get learningSubtitle;

  /// No description provided for @learningHeaderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A little progress, every day'**
  String get learningHeaderSubtitle;

  /// No description provided for @dailyMissionEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Today\'s mission'**
  String get dailyMissionEyebrow;

  /// No description provided for @dailyMissionBody.
  ///
  /// In en, this message translates to:
  /// **'A focused lesson picked for your pace.'**
  String get dailyMissionBody;

  /// No description provided for @startDailyMission.
  ///
  /// In en, this message translates to:
  /// **'Start lesson'**
  String get startDailyMission;

  /// No description provided for @filters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get filters;

  /// No description provided for @filterLessons.
  ///
  /// In en, this message translates to:
  /// **'Filter lessons'**
  String get filterLessons;

  /// No description provided for @applyFilters.
  ///
  /// In en, this message translates to:
  /// **'Show lessons'**
  String get applyFilters;

  /// No description provided for @resetFilters.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get resetFilters;

  /// No description provided for @removeFilter.
  ///
  /// In en, this message translates to:
  /// **'Remove {filter} filter'**
  String removeFilter(String filter);

  /// No description provided for @minutesShort.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String minutesShort(int minutes);

  /// No description provided for @gradeFilter.
  ///
  /// In en, this message translates to:
  /// **'Grade'**
  String get gradeFilter;

  /// No description provided for @subjectFilter.
  ///
  /// In en, this message translates to:
  /// **'Subject'**
  String get subjectFilter;

  /// No description provided for @difficultyFilter.
  ///
  /// In en, this message translates to:
  /// **'Difficulty'**
  String get difficultyFilter;

  /// No description provided for @allGrades.
  ///
  /// In en, this message translates to:
  /// **'All grades'**
  String get allGrades;

  /// No description provided for @gradeNumber.
  ///
  /// In en, this message translates to:
  /// **'Grade {grade}'**
  String gradeNumber(int grade);

  /// No description provided for @gradeDataPending.
  ///
  /// In en, this message translates to:
  /// **'Grade {grade} is selected. Until lessons receive grade tags from the API, ungraded lessons remain visible.'**
  String gradeDataPending(int grade);

  /// No description provided for @allSubjects.
  ///
  /// In en, this message translates to:
  /// **'All subjects'**
  String get allSubjects;

  /// No description provided for @allLevels.
  ///
  /// In en, this message translates to:
  /// **'All levels'**
  String get allLevels;

  /// No description provided for @recommendedLessons.
  ///
  /// In en, this message translates to:
  /// **'Recommended lessons'**
  String get recommendedLessons;

  /// No description provided for @doneLabel.
  ///
  /// In en, this message translates to:
  /// **'done'**
  String get doneLabel;

  /// No description provided for @completedLabel.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completedLabel;

  /// No description provided for @generalSubject.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get generalSubject;

  /// No description provided for @difficultyEasy.
  ///
  /// In en, this message translates to:
  /// **'Easy'**
  String get difficultyEasy;

  /// No description provided for @difficultyMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get difficultyMedium;

  /// No description provided for @difficultyHard.
  ///
  /// In en, this message translates to:
  /// **'Hard'**
  String get difficultyHard;

  /// No description provided for @difficultyDifficult.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get difficultyDifficult;

  /// No description provided for @exerciseCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0 {No exercises} =1 {1 exercise} other {{count} exercises}}'**
  String exerciseCount(int count);

  /// No description provided for @baseXpLabel.
  ///
  /// In en, this message translates to:
  /// **'Base {xp} XP'**
  String baseXpLabel(int xp);

  /// No description provided for @lessonLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn’t load lessons'**
  String get lessonLoadFailed;

  /// No description provided for @noLessonsFound.
  ///
  /// In en, this message translates to:
  /// **'No lessons found'**
  String get noLessonsFound;

  /// No description provided for @noLessonsForFilters.
  ///
  /// In en, this message translates to:
  /// **'Try another grade, subject, or difficulty.'**
  String get noLessonsForFilters;

  /// No description provided for @lessonPreviewHeading.
  ///
  /// In en, this message translates to:
  /// **'Ready when you are'**
  String get lessonPreviewHeading;

  /// No description provided for @lessonPreviewBody.
  ///
  /// In en, this message translates to:
  /// **'Take it one step at a time. Your progress is saved along the way.'**
  String get lessonPreviewBody;

  /// No description provided for @beginLesson.
  ///
  /// In en, this message translates to:
  /// **'Begin lesson'**
  String get beginLesson;

  /// No description provided for @lessonContentUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Lesson activities will appear when the learning service provides the lesson detail.'**
  String get lessonContentUnavailable;

  /// No description provided for @backToLessons.
  ///
  /// In en, this message translates to:
  /// **'Back to lessons'**
  String get backToLessons;

  /// No description provided for @accountSettings.
  ///
  /// In en, this message translates to:
  /// **'Account settings'**
  String get accountSettings;

  /// No description provided for @riksaLearner.
  ///
  /// In en, this message translates to:
  /// **'RIKSA Learner'**
  String get riksaLearner;

  /// No description provided for @memberSince.
  ///
  /// In en, this message translates to:
  /// **'Member since {date}'**
  String memberSince(String date);

  /// No description provided for @verified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get verified;

  /// No description provided for @notVerified.
  ///
  /// In en, this message translates to:
  /// **'Not verified'**
  String get notVerified;

  /// No description provided for @accountRole.
  ///
  /// In en, this message translates to:
  /// **'Account role'**
  String get accountRole;

  /// No description provided for @totalXp.
  ///
  /// In en, this message translates to:
  /// **'Total XP'**
  String get totalXp;

  /// No description provided for @currentStreak.
  ///
  /// In en, this message translates to:
  /// **'Current streak'**
  String get currentStreak;

  /// No description provided for @achievements.
  ///
  /// In en, this message translates to:
  /// **'Achievements'**
  String get achievements;

  /// No description provided for @currentRank.
  ///
  /// In en, this message translates to:
  /// **'Current rank'**
  String get currentRank;

  /// No description provided for @startingTier.
  ///
  /// In en, this message translates to:
  /// **'Starting tier'**
  String get startingTier;

  /// No description provided for @highestRankReached.
  ///
  /// In en, this message translates to:
  /// **'You’ve reached the highest available rank.'**
  String get highestRankReached;

  /// No description provided for @xpUntilNextRank.
  ///
  /// In en, this message translates to:
  /// **'{xp} XP until {tier}'**
  String xpUntilNextRank(int xp, String tier);

  /// No description provided for @earned.
  ///
  /// In en, this message translates to:
  /// **'Earned'**
  String get earned;

  /// No description provided for @recentActivity.
  ///
  /// In en, this message translates to:
  /// **'Recent activity'**
  String get recentActivity;

  /// No description provided for @noAchievements.
  ///
  /// In en, this message translates to:
  /// **'Achievements and their progress will appear here.'**
  String get noAchievements;

  /// No description provided for @noRecentActivity.
  ///
  /// In en, this message translates to:
  /// **'Your XP activity will appear here as you learn.'**
  String get noRecentActivity;

  /// No description provided for @profileLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn’t load your learning profile.'**
  String get profileLoadFailed;

  /// No description provided for @lessonCompletionReward.
  ///
  /// In en, this message translates to:
  /// **'Lesson completed'**
  String get lessonCompletionReward;

  /// No description provided for @achievementReward.
  ///
  /// In en, this message translates to:
  /// **'Achievement reward'**
  String get achievementReward;

  /// No description provided for @streakReward.
  ///
  /// In en, this message translates to:
  /// **'Streak reward'**
  String get streakReward;

  /// No description provided for @rankReward.
  ///
  /// In en, this message translates to:
  /// **'Rank reward'**
  String get rankReward;

  /// No description provided for @welcomeBonus.
  ///
  /// In en, this message translates to:
  /// **'Welcome bonus'**
  String get welcomeBonus;

  /// No description provided for @xpReward.
  ///
  /// In en, this message translates to:
  /// **'XP reward'**
  String get xpReward;

  /// No description provided for @myPosts.
  ///
  /// In en, this message translates to:
  /// **'My Posts'**
  String get myPosts;

  /// No description provided for @leaderboardRank.
  ///
  /// In en, this message translates to:
  /// **'Leaderboard Rank'**
  String get leaderboardRank;

  /// No description provided for @noPostsYet.
  ///
  /// In en, this message translates to:
  /// **'Your community posts will appear here.'**
  String get noPostsYet;

  /// No description provided for @countryRank.
  ///
  /// In en, this message translates to:
  /// **'Cambodia rank'**
  String get countryRank;

  /// No description provided for @provinceRank.
  ///
  /// In en, this message translates to:
  /// **'Province rank'**
  String get provinceRank;

  /// No description provided for @unranked.
  ///
  /// In en, this message translates to:
  /// **'Not ranked yet'**
  String get unranked;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @notificationPreferences.
  ///
  /// In en, this message translates to:
  /// **'Notification preferences'**
  String get notificationPreferences;

  /// No description provided for @notificationPreferencesHint.
  ///
  /// In en, this message translates to:
  /// **'Learning and community reminders'**
  String get notificationPreferencesHint;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark mode'**
  String get darkMode;

  /// No description provided for @darkModeHint.
  ///
  /// In en, this message translates to:
  /// **'Use RIKSA\'s dark appearance'**
  String get darkModeHint;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @helpAndLegal.
  ///
  /// In en, this message translates to:
  /// **'Help & legal'**
  String get helpAndLegal;

  /// No description provided for @faq.
  ///
  /// In en, this message translates to:
  /// **'FAQ'**
  String get faq;

  /// No description provided for @termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get fullName;

  /// No description provided for @bio.
  ///
  /// In en, this message translates to:
  /// **'Bio'**
  String get bio;

  /// No description provided for @gender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get gender;

  /// No description provided for @genderUnspecified.
  ///
  /// In en, this message translates to:
  /// **'Prefer not to say'**
  String get genderUnspecified;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @changesSaved.
  ///
  /// In en, this message translates to:
  /// **'Your profile was updated.'**
  String get changesSaved;

  /// No description provided for @profileSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn’t save your profile. Please try again.'**
  String get profileSaveFailed;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccount;

  /// No description provided for @deleteAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete your RIKSA account?'**
  String get deleteAccountTitle;

  /// No description provided for @deleteAccountConfirmation.
  ///
  /// In en, this message translates to:
  /// **'This would permanently remove your learning history, XP, achievements, and posts. Continue?'**
  String get deleteAccountConfirmation;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @deleteUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Account deletion is not available from the API yet. Contact RIKSA support for help.'**
  String get deleteUnavailable;

  /// No description provided for @accountIdentifiersReadOnly.
  ///
  /// In en, this message translates to:
  /// **'Email, phone, and username are secured account identifiers and cannot currently be changed here.'**
  String get accountIdentifiersReadOnly;

  /// No description provided for @chooseAvatar.
  ///
  /// In en, this message translates to:
  /// **'Choose an avatar'**
  String get chooseAvatar;

  /// No description provided for @humationAvatarSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pick a hand-drawn character for your RIKSA profile.'**
  String get humationAvatarSubtitle;

  /// No description provided for @editCover.
  ///
  /// In en, this message translates to:
  /// **'Edit cover'**
  String get editCover;

  /// No description provided for @chooseProfileCover.
  ///
  /// In en, this message translates to:
  /// **'Choose a profile cover'**
  String get chooseProfileCover;

  /// No description provided for @profileCoverSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pick a color and pattern that feels like you.'**
  String get profileCoverSubtitle;

  /// No description provided for @chooseFromPhotos.
  ///
  /// In en, this message translates to:
  /// **'Choose from photos'**
  String get chooseFromPhotos;

  /// No description provided for @imageSelectionFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn’t use that image. Please try another one.'**
  String get imageSelectionFailed;

  /// No description provided for @notProvided.
  ///
  /// In en, this message translates to:
  /// **'Not provided'**
  String get notProvided;

  /// No description provided for @supportDocumentUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This document will be available here after the RIKSA support content is published.'**
  String get supportDocumentUnavailable;

  /// No description provided for @aiTutor.
  ///
  /// In en, this message translates to:
  /// **'AI Tutor'**
  String get aiTutor;

  /// No description provided for @aiTutorComingSoon.
  ///
  /// In en, this message translates to:
  /// **'RIKSA AI Tutor is coming soon.'**
  String get aiTutorComingSoon;
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
      <String>['en', 'km'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'km':
      return AppLocalizationsKm();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
