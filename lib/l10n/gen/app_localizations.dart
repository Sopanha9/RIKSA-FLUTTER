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
  /// **'Welcome back!'**
  String get welcomeBack;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue your learning journey.'**
  String get loginSubtitle;

  /// No description provided for @authReasonSaveProgress.
  ///
  /// In en, this message translates to:
  /// **'Sign in to save your lesson progress and streak.'**
  String get authReasonSaveProgress;

  /// No description provided for @authReasonSaveLesson.
  ///
  /// In en, this message translates to:
  /// **'Sign in to save this lesson to your library.'**
  String get authReasonSaveLesson;

  /// No description provided for @authReasonPost.
  ///
  /// In en, this message translates to:
  /// **'Sign in to share a post with your community.'**
  String get authReasonPost;

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
  /// **'Create your account and start learning today'**
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
  /// **'Log in'**
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

  /// No description provided for @verify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verify;

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

  /// No description provided for @telegramEyebrow.
  ///
  /// In en, this message translates to:
  /// **'No password needed'**
  String get telegramEyebrow;

  /// No description provided for @telegramAuthTitle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Telegram'**
  String get telegramAuthTitle;

  /// No description provided for @telegramAuthSubtitle.
  ///
  /// In en, this message translates to:
  /// **'No Telegram ID to remember. Pick a way to sign in. New to Riksa? Both options create your account.'**
  String get telegramAuthSubtitle;

  /// No description provided for @telegramAuthorize.
  ///
  /// In en, this message translates to:
  /// **'Open Telegram'**
  String get telegramAuthorize;

  /// No description provided for @telegramAuthorizeHint.
  ///
  /// In en, this message translates to:
  /// **'Fastest: tap Confirm in the Riksa bot and come straight back.'**
  String get telegramAuthorizeHint;

  /// No description provided for @telegramUseCode.
  ///
  /// In en, this message translates to:
  /// **'Log in with code'**
  String get telegramUseCode;

  /// No description provided for @telegramUseCodeHint.
  ///
  /// In en, this message translates to:
  /// **'Telegram on another device? Get a code from the bot and paste it here.'**
  String get telegramUseCodeHint;

  /// No description provided for @telegramTheBot.
  ///
  /// In en, this message translates to:
  /// **'the Riksa bot'**
  String get telegramTheBot;

  /// No description provided for @telegramCodeTitle.
  ///
  /// In en, this message translates to:
  /// **'Log in with code'**
  String get telegramCodeTitle;

  /// No description provided for @telegramCodeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Paste the code from {bot} to sign in.'**
  String telegramCodeSubtitle(String bot);

  /// No description provided for @telegramCodeStepOpen.
  ///
  /// In en, this message translates to:
  /// **'Open {bot} and tap Start, or send /code'**
  String telegramCodeStepOpen(String bot);

  /// No description provided for @telegramCodeStepCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy the 8-character code it sends you'**
  String get telegramCodeStepCopy;

  /// No description provided for @telegramCodeStepPaste.
  ///
  /// In en, this message translates to:
  /// **'Paste it below'**
  String get telegramCodeStepPaste;

  /// No description provided for @telegramOpenBot.
  ///
  /// In en, this message translates to:
  /// **'Open {bot}'**
  String telegramOpenBot(String bot);

  /// No description provided for @telegramCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Sign-in code'**
  String get telegramCodeLabel;

  /// No description provided for @telegramCodeHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. VE9BLZ8J'**
  String get telegramCodeHint;

  /// No description provided for @telegramPasteCode.
  ///
  /// In en, this message translates to:
  /// **'Paste code'**
  String get telegramPasteCode;

  /// No description provided for @telegramCodeInvalidFormat.
  ///
  /// In en, this message translates to:
  /// **'Enter the 8-character code from the bot'**
  String get telegramCodeInvalidFormat;

  /// No description provided for @telegramCodeRejected.
  ///
  /// In en, this message translates to:
  /// **'This code is invalid or expired. Send /code to the bot for a new one.'**
  String get telegramCodeRejected;

  /// No description provided for @telegramNoCodeInClipboard.
  ///
  /// In en, this message translates to:
  /// **'No sign-in code found in your clipboard.'**
  String get telegramNoCodeInClipboard;

  /// No description provided for @telegramSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get telegramSignIn;

  /// No description provided for @telegramUseOpenInstead.
  ///
  /// In en, this message translates to:
  /// **'Use Open Telegram instead'**
  String get telegramUseOpenInstead;

  /// No description provided for @telegramSwitchToCode.
  ///
  /// In en, this message translates to:
  /// **'Having trouble? Log in with code'**
  String get telegramSwitchToCode;

  /// No description provided for @telegramPrivacyNote.
  ///
  /// In en, this message translates to:
  /// **'Riksa only receives your public Telegram name and username. Never your phone number or chats.'**
  String get telegramPrivacyNote;

  /// No description provided for @telegramWaitingTitle.
  ///
  /// In en, this message translates to:
  /// **'Waiting for Telegram'**
  String get telegramWaitingTitle;

  /// No description provided for @telegramWaitingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm the request in the Riksa bot, then return to this screen.'**
  String get telegramWaitingSubtitle;

  /// No description provided for @telegramExpiresIn.
  ///
  /// In en, this message translates to:
  /// **'Request expires in {time}'**
  String telegramExpiresIn(String time);

  /// No description provided for @telegramOpenAgain.
  ///
  /// In en, this message translates to:
  /// **'Open Telegram again'**
  String get telegramOpenAgain;

  /// No description provided for @telegramCopyLink.
  ///
  /// In en, this message translates to:
  /// **'Copy link'**
  String get telegramCopyLink;

  /// No description provided for @telegramLinkCopied.
  ///
  /// In en, this message translates to:
  /// **'Link copied. Open it on any device with Telegram.'**
  String get telegramLinkCopied;

  /// No description provided for @telegramOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open Telegram. Install Telegram, or copy the link and open it on another device.'**
  String get telegramOpenFailed;

  /// No description provided for @telegramStartFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t start Telegram authorization. Please try again.'**
  String get telegramStartFailed;

  /// No description provided for @telegramExpired.
  ///
  /// In en, this message translates to:
  /// **'This request expired. Start again to get a fresh link.'**
  String get telegramExpired;

  /// No description provided for @telegramDenied.
  ///
  /// In en, this message translates to:
  /// **'The request was declined in Telegram.'**
  String get telegramDenied;

  /// No description provided for @telegramSignupExpired.
  ///
  /// In en, this message translates to:
  /// **'Your Telegram approval expired before the account was created. Please authorize again.'**
  String get telegramSignupExpired;

  /// No description provided for @telegramProfileEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Telegram connected'**
  String get telegramProfileEyebrow;

  /// No description provided for @telegramProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Set up your Riksa profile'**
  String get telegramProfileTitle;

  /// No description provided for @telegramProfileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose how other learners will see you. You can change your display name later.'**
  String get telegramProfileSubtitle;

  /// No description provided for @telegramConnectedAs.
  ///
  /// In en, this message translates to:
  /// **'Connected as {name}'**
  String telegramConnectedAs(String name);

  /// No description provided for @telegramCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get telegramCreateAccount;

  /// No description provided for @telegramUseAnotherAccount.
  ///
  /// In en, this message translates to:
  /// **'Use a different Telegram account'**
  String get telegramUseAnotherAccount;

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

  /// No description provided for @startConversation.
  ///
  /// In en, this message translates to:
  /// **'Start a conversation'**
  String get startConversation;

  /// No description provided for @startConversationHint.
  ///
  /// In en, this message translates to:
  /// **'Share something with RIKSA...'**
  String get startConversationHint;

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

  /// No description provided for @writeArticle.
  ///
  /// In en, this message translates to:
  /// **'Write an article'**
  String get writeArticle;

  /// No description provided for @writeArticleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A longer piece for the blog, reviewed before it appears.'**
  String get writeArticleSubtitle;

  /// No description provided for @yourArticles.
  ///
  /// In en, this message translates to:
  /// **'Your articles'**
  String get yourArticles;

  /// No description provided for @articlesInReview.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 in review} other{{count} in review}}'**
  String articlesInReview(int count);

  /// No description provided for @communityComposerPrompt.
  ///
  /// In en, this message translates to:
  /// **'What are your doubts?'**
  String get communityComposerPrompt;

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

  /// No description provided for @addPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add a photo'**
  String get addPhoto;

  /// No description provided for @changePhoto.
  ///
  /// In en, this message translates to:
  /// **'Change photo'**
  String get changePhoto;

  /// No description provided for @removePhoto.
  ///
  /// In en, this message translates to:
  /// **'Remove photo'**
  String get removePhoto;

  /// No description provided for @photoUploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading photo…'**
  String get photoUploading;

  /// No description provided for @photoFailed.
  ///
  /// In en, this message translates to:
  /// **'That photo couldn’t be uploaded. Try another one.'**
  String get photoFailed;

  /// No description provided for @photoTooLarge.
  ///
  /// In en, this message translates to:
  /// **'That photo is too large. Pick one under 2MB.'**
  String get photoTooLarge;

  /// No description provided for @photoFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get photoFromGallery;

  /// No description provided for @photoFromCamera.
  ///
  /// In en, this message translates to:
  /// **'Take a photo'**
  String get photoFromCamera;

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

  /// No description provided for @editPost.
  ///
  /// In en, this message translates to:
  /// **'Edit post'**
  String get editPost;

  /// No description provided for @deletePost.
  ///
  /// In en, this message translates to:
  /// **'Delete post'**
  String get deletePost;

  /// No description provided for @postOptions.
  ///
  /// In en, this message translates to:
  /// **'Post options'**
  String get postOptions;

  /// No description provided for @deletePostTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this post?'**
  String get deletePostTitle;

  /// No description provided for @deletePostMessage.
  ///
  /// In en, this message translates to:
  /// **'The post and its replies are removed for everyone. This cannot be undone.'**
  String get deletePostMessage;

  /// No description provided for @keepPost.
  ///
  /// In en, this message translates to:
  /// **'Keep post'**
  String get keepPost;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @postUpdated.
  ///
  /// In en, this message translates to:
  /// **'Changes saved'**
  String get postUpdated;

  /// No description provided for @postDeleted.
  ///
  /// In en, this message translates to:
  /// **'Post deleted'**
  String get postDeleted;

  /// No description provided for @saveFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn’t save your changes. Try again.'**
  String get saveFailed;

  /// No description provided for @deleteFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn’t delete this post. Try again.'**
  String get deleteFailed;

  /// No description provided for @editPostSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Update what you shared with the community.'**
  String get editPostSubtitle;

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

  /// No description provided for @reply.
  ///
  /// In en, this message translates to:
  /// **'Reply'**
  String get reply;

  /// No description provided for @replyingTo.
  ///
  /// In en, this message translates to:
  /// **'Replying to'**
  String get replyingTo;

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

  /// No description provided for @shareProfile.
  ///
  /// In en, this message translates to:
  /// **'Share profile'**
  String get shareProfile;

  /// No description provided for @profileLinkCopied.
  ///
  /// In en, this message translates to:
  /// **'Profile link copied'**
  String get profileLinkCopied;

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

  /// No description provided for @onboardingLearningBody.
  ///
  /// In en, this message translates to:
  /// **'Lessons, an AI coach, and friends who explain things their way. Studying feels lighter with company.'**
  String get onboardingLearningBody;

  /// No description provided for @onboardingAchievementBody.
  ///
  /// In en, this message translates to:
  /// **'Keep your streak, climb the leaderboard, and let your buddy cheer every win.'**
  String get onboardingAchievementBody;

  /// No description provided for @onboardingCommunityBody.
  ///
  /// In en, this message translates to:
  /// **'Join communities, share what you are working on, and ask anything. Someone always has your back.'**
  String get onboardingCommunityBody;

  /// Onboarding page 2 headline (learning together).
  ///
  /// In en, this message translates to:
  /// **'Learn together, not alone'**
  String get onboardingLearningTitle;

  /// Onboarding page 3 headline (progress with the buddy).
  ///
  /// In en, this message translates to:
  /// **'Grow with your buddy'**
  String get onboardingAchievementTitle;

  /// Onboarding page 1 headline (the community).
  ///
  /// In en, this message translates to:
  /// **'Your people are here'**
  String get onboardingCommunityTitle;

  /// Primary action on the last onboarding page.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get onboardingGetStarted;

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

  /// No description provided for @searchCommunity.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get searchCommunity;

  /// No description provided for @searchCommunityHint.
  ///
  /// In en, this message translates to:
  /// **'Try a different keyword.'**
  String get searchCommunityHint;

  /// No description provided for @noSearchResults.
  ///
  /// In en, this message translates to:
  /// **'No matching results'**
  String get noSearchResults;

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

  /// No description provided for @learningTitle.
  ///
  /// In en, this message translates to:
  /// **'Learning'**
  String get learningTitle;

  /// No description provided for @continueLearning.
  ///
  /// In en, this message translates to:
  /// **'Continue learning'**
  String get continueLearning;

  /// No description provided for @searchLessons.
  ///
  /// In en, this message translates to:
  /// **'Search lessons'**
  String get searchLessons;

  /// No description provided for @leaderboard.
  ///
  /// In en, this message translates to:
  /// **'Leaderboard'**
  String get leaderboard;

  /// Short leaderboard label for the bottom navigation bar.
  ///
  /// In en, this message translates to:
  /// **'Ranks'**
  String get ranksTab;

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

  /// No description provided for @roadmapCompletedEarlier.
  ///
  /// In en, this message translates to:
  /// **'Completed earlier · this unit stays open'**
  String get roadmapCompletedEarlier;

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

  /// No description provided for @contentTypeLesson.
  ///
  /// In en, this message translates to:
  /// **'Lesson'**
  String get contentTypeLesson;

  /// No description provided for @contentTypeChallenge.
  ///
  /// In en, this message translates to:
  /// **'Challenge'**
  String get contentTypeChallenge;

  /// No description provided for @contentTypeRoadmap.
  ///
  /// In en, this message translates to:
  /// **'Roadmap'**
  String get contentTypeRoadmap;

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

  /// Learning home greeting
  ///
  /// In en, this message translates to:
  /// **'Hi, {name}'**
  String greetingNamed(String name);

  /// No description provided for @gradeStemLabel.
  ///
  /// In en, this message translates to:
  /// **'Grade 12 · STEM'**
  String get gradeStemLabel;

  /// No description provided for @yourSubjects.
  ///
  /// In en, this message translates to:
  /// **'Your subjects'**
  String get yourSubjects;

  /// No description provided for @mathematicsSubjectDescription.
  ///
  /// In en, this message translates to:
  /// **'Build confidence with numbers and problem solving'**
  String get mathematicsSubjectDescription;

  /// No description provided for @physicsSubjectDescription.
  ///
  /// In en, this message translates to:
  /// **'Understand motion, forces, and the universe'**
  String get physicsSubjectDescription;

  /// No description provided for @chemistrySubjectDescription.
  ///
  /// In en, this message translates to:
  /// **'Discover matter, reactions, and change'**
  String get chemistrySubjectDescription;

  /// No description provided for @biologySubjectDescription.
  ///
  /// In en, this message translates to:
  /// **'Explore living systems and life science'**
  String get biologySubjectDescription;

  /// No description provided for @technologySubjectDescription.
  ///
  /// In en, this message translates to:
  /// **'Practice computing and digital technology'**
  String get technologySubjectDescription;

  /// No description provided for @generalSubjectDescription.
  ///
  /// In en, this message translates to:
  /// **'Explore this subject and its lessons'**
  String get generalSubjectDescription;

  /// No description provided for @continueReading.
  ///
  /// In en, this message translates to:
  /// **'Continue reading'**
  String get continueReading;

  /// XP a lesson awards, shown on a pill
  ///
  /// In en, this message translates to:
  /// **'+{xp} XP'**
  String xpRewardAmount(int xp);

  /// No description provided for @lessonsDoneOfTotal.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} lessons'**
  String lessonsDoneOfTotal(int done, int total);

  /// Compact progress on a subject tile
  ///
  /// In en, this message translates to:
  /// **'{done} / {total}'**
  String subjectCountShort(int done, int total);

  /// No description provided for @examDestination.
  ///
  /// In en, this message translates to:
  /// **'Bac II · Grade 12'**
  String get examDestination;

  /// Compact days-until-exam badge
  ///
  /// In en, this message translates to:
  /// **'{days}d'**
  String daysRemaining(int days);

  /// No description provided for @subjectUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Could not load'**
  String get subjectUnavailable;

  /// No description provided for @noSubjectsYet.
  ///
  /// In en, this message translates to:
  /// **'No STEM subjects yet'**
  String get noSubjectsYet;

  /// No description provided for @noSubjectsYetBody.
  ///
  /// In en, this message translates to:
  /// **'Grade 12 subjects appear here as soon as they are published.'**
  String get noSubjectsYetBody;

  /// No description provided for @everySubjectFinished.
  ///
  /// In en, this message translates to:
  /// **'Every subject is finished'**
  String get everySubjectFinished;

  /// No description provided for @everySubjectFinishedBody.
  ///
  /// In en, this message translates to:
  /// **'You have worked through the whole Grade 12 STEM syllabus.'**
  String get everySubjectFinishedBody;

  /// No description provided for @unitOfTotal.
  ///
  /// In en, this message translates to:
  /// **'Unit {current} of {total}'**
  String unitOfTotal(int current, int total);

  /// No description provided for @wholeSyllabusSummary.
  ///
  /// In en, this message translates to:
  /// **'{units, plural, =1 {1 unit} other {{units} units}}, {lessons, plural, =1 {1 lesson} other {{lessons} lessons}}'**
  String wholeSyllabusSummary(int units, int lessons);

  /// No description provided for @unitProgressShort.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} done'**
  String unitProgressShort(int done, int total);

  /// No description provided for @youAreHere.
  ///
  /// In en, this message translates to:
  /// **'You are here'**
  String get youAreHere;

  /// No description provided for @opensAfterUnit.
  ///
  /// In en, this message translates to:
  /// **'Opens after Unit {number}'**
  String opensAfterUnit(int number);

  /// No description provided for @lessonLockedShort.
  ///
  /// In en, this message translates to:
  /// **'Locked'**
  String get lessonLockedShort;

  /// No description provided for @lessonCountLabel.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1 {1 lesson} other {{count} lessons}}'**
  String lessonCountLabel(int count);

  /// No description provided for @readyForExam.
  ///
  /// In en, this message translates to:
  /// **'Ready for Bac II'**
  String get readyForExam;

  /// No description provided for @roadmapLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn’t load this roadmap'**
  String get roadmapLoadFailed;

  /// No description provided for @roadmapEmpty.
  ///
  /// In en, this message translates to:
  /// **'This subject has no lessons yet'**
  String get roadmapEmpty;

  /// No description provided for @roadmapEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Lessons appear here as soon as they are published.'**
  String get roadmapEmptyBody;

  /// No description provided for @lessonLocked.
  ///
  /// In en, this message translates to:
  /// **'Finish the lessons before this one to unlock it'**
  String get lessonLocked;

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

  /// No description provided for @tierBandProgress.
  ///
  /// In en, this message translates to:
  /// **'{earned} / {total} XP'**
  String tierBandProgress(String earned, String total);

  /// No description provided for @xpUntilFinalRank.
  ///
  /// In en, this message translates to:
  /// **'{xp} XP to {tier}, the final rank'**
  String xpUntilFinalRank(int xp, String tier);

  /// No description provided for @tierPosition.
  ///
  /// In en, this message translates to:
  /// **'Rank {position} of {total}'**
  String tierPosition(int position, int total);

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

  /// No description provided for @profileArticlesTab.
  ///
  /// In en, this message translates to:
  /// **'Articles'**
  String get profileArticlesTab;

  /// No description provided for @profileBadgesTab.
  ///
  /// In en, this message translates to:
  /// **'Badges'**
  String get profileBadgesTab;

  /// No description provided for @profileRankTab.
  ///
  /// In en, this message translates to:
  /// **'Rank'**
  String get profileRankTab;

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

  /// No description provided for @profileComposerPrompt.
  ///
  /// In en, this message translates to:
  /// **'Share what you are learning'**
  String get profileComposerPrompt;

  /// No description provided for @profilePostCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0 {No posts yet} =1 {1 post} other {{count} posts}}'**
  String profilePostCount(int count);

  /// No description provided for @writeFirstPost.
  ///
  /// In en, this message translates to:
  /// **'Write your first post'**
  String get writeFirstPost;

  /// No description provided for @managePost.
  ///
  /// In en, this message translates to:
  /// **'Manage post'**
  String get managePost;

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

  /// Tooltip and semantics label on the avatar that opens the app drawer.
  ///
  /// In en, this message translates to:
  /// **'Open profile menu'**
  String get openProfileMenu;

  /// Drawer item leading to the list of communities.
  ///
  /// In en, this message translates to:
  /// **'Communities'**
  String get communitiesMenu;

  /// Drawer item leading to the XP activity history.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get progressHistory;

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

  /// No description provided for @learningSounds.
  ///
  /// In en, this message translates to:
  /// **'Learning sounds'**
  String get learningSounds;

  /// No description provided for @learningSoundsHint.
  ///
  /// In en, this message translates to:
  /// **'Play a sound for correct answers, mistakes and finished lessons.'**
  String get learningSoundsHint;

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

  /// No description provided for @publicProfile.
  ///
  /// In en, this message translates to:
  /// **'Public profile'**
  String get publicProfile;

  /// No description provided for @posts.
  ///
  /// In en, this message translates to:
  /// **'Posts'**
  String get posts;

  /// No description provided for @publicProfileUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Profile unavailable'**
  String get publicProfileUnavailable;

  /// No description provided for @publicProfileUnavailableMessage.
  ///
  /// In en, this message translates to:
  /// **'This person may have deleted their account, been suspended, or limited access to their profile.'**
  String get publicProfileUnavailableMessage;

  /// No description provided for @publicProfileLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn’t load this public profile. Please try again.'**
  String get publicProfileLoadFailed;

  /// No description provided for @publicPostsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn’t load this person’s posts.'**
  String get publicPostsLoadFailed;

  /// No description provided for @noPublicPosts.
  ///
  /// In en, this message translates to:
  /// **'This person hasn’t shared any community posts yet.'**
  String get noPublicPosts;

  /// No description provided for @noPublicAchievements.
  ///
  /// In en, this message translates to:
  /// **'No earned achievements are available yet.'**
  String get noPublicAchievements;

  /// No description provided for @noPublicRank.
  ///
  /// In en, this message translates to:
  /// **'No public ranking is available yet.'**
  String get noPublicRank;

  /// No description provided for @aiTutorSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Ask anything from your lessons'**
  String get aiTutorSubtitle;

  /// No description provided for @aiAskNewQuestion.
  ///
  /// In en, this message translates to:
  /// **'Ask a new question'**
  String get aiAskNewQuestion;

  /// No description provided for @aiChatsToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get aiChatsToday;

  /// No description provided for @aiChatsThisWeek.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get aiChatsThisWeek;

  /// No description provided for @aiChatsEarlier.
  ///
  /// In en, this message translates to:
  /// **'Earlier'**
  String get aiChatsEarlier;

  /// No description provided for @aiChatOptions.
  ///
  /// In en, this message translates to:
  /// **'Chat options'**
  String get aiChatOptions;

  /// No description provided for @aiDeleteChat.
  ///
  /// In en, this message translates to:
  /// **'Delete chat'**
  String get aiDeleteChat;

  /// No description provided for @aiChatDeleted.
  ///
  /// In en, this message translates to:
  /// **'Chat deleted'**
  String get aiChatDeleted;

  /// No description provided for @aiUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get aiUndo;

  /// No description provided for @aiChatDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'That chat could not be deleted.'**
  String get aiChatDeleteFailed;

  /// No description provided for @aiChatsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Ask anything you are learning'**
  String get aiChatsEmptyTitle;

  /// No description provided for @aiChatsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Start a private conversation in Khmer or English about any lesson.'**
  String get aiChatsEmptyBody;

  /// No description provided for @aiStartChat.
  ///
  /// In en, this message translates to:
  /// **'Start a chat'**
  String get aiStartChat;

  /// No description provided for @aiTutorUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Tutor unavailable'**
  String get aiTutorUnavailableTitle;

  /// No description provided for @aiTutorUnavailableBody.
  ///
  /// In en, this message translates to:
  /// **'Check your connection and try again.'**
  String get aiTutorUnavailableBody;

  /// No description provided for @aiSearchChats.
  ///
  /// In en, this message translates to:
  /// **'Search your chats'**
  String get aiSearchChats;

  /// No description provided for @aiNoChatMatches.
  ///
  /// In en, this message translates to:
  /// **'No chat matches that.'**
  String get aiNoChatMatches;

  /// No description provided for @aiChatFallbackTitle.
  ///
  /// In en, this message translates to:
  /// **'Learning chat'**
  String get aiChatFallbackTitle;

  /// No description provided for @aiComposerHint.
  ///
  /// In en, this message translates to:
  /// **'Type your question...'**
  String get aiComposerHint;

  /// No description provided for @aiSendMessage.
  ///
  /// In en, this message translates to:
  /// **'Send message'**
  String get aiSendMessage;

  /// No description provided for @aiThinking.
  ///
  /// In en, this message translates to:
  /// **'Riksa is thinking'**
  String get aiThinking;

  /// No description provided for @aiMessageNotSent.
  ///
  /// In en, this message translates to:
  /// **'Not sent'**
  String get aiMessageNotSent;

  /// No description provided for @aiRetryMessage.
  ///
  /// In en, this message translates to:
  /// **'Send again'**
  String get aiRetryMessage;

  /// No description provided for @aiChatOpener.
  ///
  /// In en, this message translates to:
  /// **'What would you like to understand today?'**
  String get aiChatOpener;

  /// No description provided for @aiAskAboutLesson.
  ///
  /// In en, this message translates to:
  /// **'Ask about this lesson'**
  String get aiAskAboutLesson;

  /// No description provided for @aiLessonContext.
  ///
  /// In en, this message translates to:
  /// **'About {lesson}'**
  String aiLessonContext(String lesson);

  /// No description provided for @aiStarterExplainAgain.
  ///
  /// In en, this message translates to:
  /// **'Explain this again, more slowly'**
  String get aiStarterExplainAgain;

  /// No description provided for @aiStarterStillUnsure.
  ///
  /// In en, this message translates to:
  /// **'I am still unsure about one part'**
  String get aiStarterStillUnsure;

  /// No description provided for @aiStarterWorkedExample.
  ///
  /// In en, this message translates to:
  /// **'Give me a worked example'**
  String get aiStarterWorkedExample;

  /// No description provided for @aiChatLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load this chat.'**
  String get aiChatLoadFailed;

  /// No description provided for @aiReplyFailed.
  ///
  /// In en, this message translates to:
  /// **'The tutor could not answer. Please try again.'**
  String get aiReplyFailed;

  /// No description provided for @aiContinueChat.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get aiContinueChat;

  /// No description provided for @aiTimeNow.
  ///
  /// In en, this message translates to:
  /// **'now'**
  String get aiTimeNow;

  /// No description provided for @aiTimeMinutes.
  ///
  /// In en, this message translates to:
  /// **'{count}m'**
  String aiTimeMinutes(int count);

  /// No description provided for @aiTimeHours.
  ///
  /// In en, this message translates to:
  /// **'{count}h'**
  String aiTimeHours(int count);

  /// No description provided for @aiTimeDays.
  ///
  /// In en, this message translates to:
  /// **'{count}d'**
  String aiTimeDays(int count);

  /// No description provided for @lessonRead.
  ///
  /// In en, this message translates to:
  /// **'Read'**
  String get lessonRead;

  /// No description provided for @lessonRespond.
  ///
  /// In en, this message translates to:
  /// **'Respond'**
  String get lessonRespond;

  /// No description provided for @lessonReflect.
  ///
  /// In en, this message translates to:
  /// **'Reflect'**
  String get lessonReflect;

  /// No description provided for @lessonSectionCounter.
  ///
  /// In en, this message translates to:
  /// **'Section {current} of {total}'**
  String lessonSectionCounter(int current, int total);

  /// No description provided for @lessonTrySection.
  ///
  /// In en, this message translates to:
  /// **'Try it yourself'**
  String get lessonTrySection;

  /// No description provided for @lessonReflectAction.
  ///
  /// In en, this message translates to:
  /// **'Reflect on this lesson'**
  String get lessonReflectAction;

  /// No description provided for @lessonCheckAnswer.
  ///
  /// In en, this message translates to:
  /// **'Check answer'**
  String get lessonCheckAnswer;

  /// No description provided for @lessonCompareAnswers.
  ///
  /// In en, this message translates to:
  /// **'Compare answers'**
  String get lessonCompareAnswers;

  /// No description provided for @lessonShowChoices.
  ///
  /// In en, this message translates to:
  /// **'Show choices'**
  String get lessonShowChoices;

  /// No description provided for @lessonWorkedOnPaper.
  ///
  /// In en, this message translates to:
  /// **'I worked it on paper'**
  String get lessonWorkedOnPaper;

  /// No description provided for @lessonAddWorkingOptional.
  ///
  /// In en, this message translates to:
  /// **'Add your working (optional)'**
  String get lessonAddWorkingOptional;

  /// No description provided for @lessonWorkFirst.
  ///
  /// In en, this message translates to:
  /// **'Work it out first'**
  String get lessonWorkFirst;

  /// No description provided for @lessonWorkHint.
  ///
  /// In en, this message translates to:
  /// **'Write your answer and how you got there. Then compare it with the choices.'**
  String get lessonWorkHint;

  /// No description provided for @lessonAnswerHint.
  ///
  /// In en, this message translates to:
  /// **'Write your answer'**
  String get lessonAnswerHint;

  /// No description provided for @lessonYourWork.
  ///
  /// In en, this message translates to:
  /// **'Your working'**
  String get lessonYourWork;

  /// No description provided for @lessonChooseAnswer.
  ///
  /// In en, this message translates to:
  /// **'Compare your working and choose an answer.'**
  String get lessonChooseAnswer;

  /// No description provided for @lessonExerciseNumber.
  ///
  /// In en, this message translates to:
  /// **'Exercise {number}'**
  String lessonExerciseNumber(int number);

  /// No description provided for @lessonResponseProgress.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} responses checked'**
  String lessonResponseProgress(int done, int total);

  /// No description provided for @lessonSectionComplete.
  ///
  /// In en, this message translates to:
  /// **'Section complete'**
  String get lessonSectionComplete;

  /// No description provided for @lessonUpNext.
  ///
  /// In en, this message translates to:
  /// **'Up next'**
  String get lessonUpNext;

  /// No description provided for @lessonReflectionTitle.
  ///
  /// In en, this message translates to:
  /// **'What will you take away?'**
  String get lessonReflectionTitle;

  /// No description provided for @lessonReflectionBody.
  ///
  /// In en, this message translates to:
  /// **'Put one idea into your own words. Note anything you want to revisit.'**
  String get lessonReflectionBody;

  /// No description provided for @lessonReflectionHint.
  ///
  /// In en, this message translates to:
  /// **'I understood… I still want to work on…'**
  String get lessonReflectionHint;

  /// No description provided for @lessonReflectionOptionalHint.
  ///
  /// In en, this message translates to:
  /// **'Optional: add a note for later'**
  String get lessonReflectionOptionalHint;

  /// No description provided for @lessonConfidencePrompt.
  ///
  /// In en, this message translates to:
  /// **'How do you feel about this lesson?'**
  String get lessonConfidencePrompt;

  /// No description provided for @lessonConfident.
  ///
  /// In en, this message translates to:
  /// **'I can explain it'**
  String get lessonConfident;

  /// No description provided for @lessonNeedsReview.
  ///
  /// In en, this message translates to:
  /// **'I want to revisit it'**
  String get lessonNeedsReview;

  /// No description provided for @lessonSaveReflection.
  ///
  /// In en, this message translates to:
  /// **'Save and finish'**
  String get lessonSaveReflection;

  /// No description provided for @lessonConfidenceRequired.
  ///
  /// In en, this message translates to:
  /// **'Tap how it went to finish'**
  String get lessonConfidenceRequired;

  /// No description provided for @lessonSavedReflection.
  ///
  /// In en, this message translates to:
  /// **'Your reflection'**
  String get lessonSavedReflection;

  /// No description provided for @lessonCompletedBody.
  ///
  /// In en, this message translates to:
  /// **'One more step through your syllabus. Take a break or continue when you are ready.'**
  String get lessonCompletedBody;

  /// No description provided for @lessonRevisitTitle.
  ///
  /// In en, this message translates to:
  /// **'Worth another look'**
  String get lessonRevisitTitle;

  /// No description provided for @lessonRevisitBody.
  ///
  /// In en, this message translates to:
  /// **'You marked this lesson for another look. You can reopen it from your roadmap.'**
  String get lessonRevisitBody;

  /// No description provided for @lessonNextAction.
  ///
  /// In en, this message translates to:
  /// **'Start next lesson'**
  String get lessonNextAction;

  /// No description provided for @lessonRoadmapAction.
  ///
  /// In en, this message translates to:
  /// **'Back to roadmap'**
  String get lessonRoadmapAction;

  /// No description provided for @lessonFinishSession.
  ///
  /// In en, this message translates to:
  /// **'Finish for now'**
  String get lessonFinishSession;

  /// No description provided for @lessonResumeAction.
  ///
  /// In en, this message translates to:
  /// **'Resume lesson'**
  String get lessonResumeAction;

  /// No description provided for @lessonStartAction.
  ///
  /// In en, this message translates to:
  /// **'Start lesson'**
  String get lessonStartAction;

  /// No description provided for @startHere.
  ///
  /// In en, this message translates to:
  /// **'Start here'**
  String get startHere;

  /// No description provided for @lessonOptions.
  ///
  /// In en, this message translates to:
  /// **'Lesson options'**
  String get lessonOptions;

  /// No description provided for @lessonSections.
  ///
  /// In en, this message translates to:
  /// **'Lesson sections'**
  String get lessonSections;

  /// No description provided for @lessonSave.
  ///
  /// In en, this message translates to:
  /// **'Save lesson'**
  String get lessonSave;

  /// No description provided for @lessonUnsave.
  ///
  /// In en, this message translates to:
  /// **'Remove from saved'**
  String get lessonUnsave;

  /// No description provided for @lessonMute.
  ///
  /// In en, this message translates to:
  /// **'Mute sound'**
  String get lessonMute;

  /// No description provided for @lessonUnmute.
  ///
  /// In en, this message translates to:
  /// **'Unmute sound'**
  String get lessonUnmute;

  /// No description provided for @lessonExitBody.
  ///
  /// In en, this message translates to:
  /// **'Checked answers are saved. Your unfinished writing will be lost if you leave.'**
  String get lessonExitBody;

  /// No description provided for @lessonExitTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave this lesson?'**
  String get lessonExitTitle;

  /// No description provided for @lessonKeepLearning.
  ///
  /// In en, this message translates to:
  /// **'Keep learning'**
  String get lessonKeepLearning;

  /// No description provided for @lessonLeaveAction.
  ///
  /// In en, this message translates to:
  /// **'Leave lesson'**
  String get lessonLeaveAction;

  /// No description provided for @lessonAiHint.
  ///
  /// In en, this message translates to:
  /// **'Get a hint'**
  String get lessonAiHint;

  /// No description provided for @lessonExplainAnswer.
  ///
  /// In en, this message translates to:
  /// **'Explain with AI'**
  String get lessonExplainAnswer;

  /// No description provided for @lessonWhy.
  ///
  /// In en, this message translates to:
  /// **'Explanation'**
  String get lessonWhy;

  /// No description provided for @lessonHint.
  ///
  /// In en, this message translates to:
  /// **'Hint'**
  String get lessonHint;

  /// No description provided for @lessonEditWorking.
  ///
  /// In en, this message translates to:
  /// **'Edit working'**
  String get lessonEditWorking;

  /// No description provided for @lessonWorkingStatus.
  ///
  /// In en, this message translates to:
  /// **'One moment…'**
  String get lessonWorkingStatus;

  /// No description provided for @lessonAnswerSuccess.
  ///
  /// In en, this message translates to:
  /// **'That’s it. Keep going when you’re ready.'**
  String get lessonAnswerSuccess;

  /// No description provided for @lessonAnswerRetry.
  ///
  /// In en, this message translates to:
  /// **'Not quite yet. Try another approach.'**
  String get lessonAnswerRetry;

  /// No description provided for @learningLoadErrorBody.
  ///
  /// In en, this message translates to:
  /// **'Your lessons couldn’t load this time. Give it another try.'**
  String get learningLoadErrorBody;

  /// No description provided for @savedLessonsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Keep a good idea for later'**
  String get savedLessonsEmptyTitle;

  /// No description provided for @savedLessonsLabel.
  ///
  /// In en, this message translates to:
  /// **'Saved lessons'**
  String get savedLessonsLabel;

  /// No description provided for @savedLessonsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Found a formula worth revisiting? Save the lesson from its menu. It will be waiting here.'**
  String get savedLessonsEmptyBody;

  /// No description provided for @splashTagline.
  ///
  /// In en, this message translates to:
  /// **'Learn Today, Build Tomorrow'**
  String get splashTagline;

  /// No description provided for @splashDescription.
  ///
  /// In en, this message translates to:
  /// **'Your Grade 12 STEM learning companion for a brighter Cambodia.'**
  String get splashDescription;

  /// Heading of the first-run mascot picker
  ///
  /// In en, this message translates to:
  /// **'Choose your study buddy'**
  String get mascotSelectTitle;

  /// No description provided for @mascotSelectSubtitle.
  ///
  /// In en, this message translates to:
  /// **'They\'ll cheer you on and celebrate every win with you.'**
  String get mascotSelectSubtitle;

  /// No description provided for @mascotCrocodile.
  ///
  /// In en, this message translates to:
  /// **'Crocodile'**
  String get mascotCrocodile;

  /// No description provided for @mascotCapybara.
  ///
  /// In en, this message translates to:
  /// **'Capybara'**
  String get mascotCapybara;

  /// No description provided for @mascotCrocodileTraits.
  ///
  /// In en, this message translates to:
  /// **'Cute · Friendly · Smart'**
  String get mascotCrocodileTraits;

  /// No description provided for @mascotCapybaraTraits.
  ///
  /// In en, this message translates to:
  /// **'Calm · Kind · Hardworking'**
  String get mascotCapybaraTraits;

  /// No description provided for @mascotNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name your buddy'**
  String get mascotNameLabel;

  /// No description provided for @mascotTapHint.
  ///
  /// In en, this message translates to:
  /// **'Tap to say hi'**
  String get mascotTapHint;

  /// No description provided for @mascotSemantic.
  ///
  /// In en, this message translates to:
  /// **'{name}, your study buddy'**
  String mascotSemantic(String name);

  /// No description provided for @languageSelectTitle.
  ///
  /// In en, this message translates to:
  /// **'Which language should {name} speak?'**
  String languageSelectTitle(String name);

  /// No description provided for @languageSelectSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{name} will use it in lessons, reminders and chats. You can change it anytime.'**
  String languageSelectSubtitle(String name);

  /// What the learner's mascot says to preview a language
  ///
  /// In en, this message translates to:
  /// **'Hi! I\'m {name}. Let\'s learn together!'**
  String languageMascotGreeting(String name);

  /// No description provided for @skipLabel.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skipLabel;

  /// No description provided for @nextLabel.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get nextLabel;

  /// No description provided for @homeGreeting.
  ///
  /// In en, this message translates to:
  /// **'Hello, {name}!'**
  String homeGreeting(String name);

  /// No description provided for @homeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Keep going! Knowledge builds your future.'**
  String get homeSubtitle;

  /// No description provided for @homeSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search posts, topics, or lessons...'**
  String get homeSearchHint;

  /// No description provided for @homeLessons.
  ///
  /// In en, this message translates to:
  /// **'Lessons'**
  String get homeLessons;

  /// No description provided for @homeLessonsCaption.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get homeLessonsCaption;

  /// No description provided for @homeCommunityCaption.
  ///
  /// In en, this message translates to:
  /// **'Join & share'**
  String get homeCommunityCaption;

  /// No description provided for @homeAiCaption.
  ///
  /// In en, this message translates to:
  /// **'Ask anything'**
  String get homeAiCaption;

  /// No description provided for @homeLeaderboardCaption.
  ///
  /// In en, this message translates to:
  /// **'See rankings'**
  String get homeLeaderboardCaption;

  /// No description provided for @todaysLearning.
  ///
  /// In en, this message translates to:
  /// **'Today\'s learning'**
  String get todaysLearning;

  /// No description provided for @communityFeed.
  ///
  /// In en, this message translates to:
  /// **'Community Feed'**
  String get communityFeed;

  /// No description provided for @viewAllShort.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get viewAllShort;

  /// No description provided for @feedFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get feedFilterAll;

  /// No description provided for @aiCoachTitle.
  ///
  /// In en, this message translates to:
  /// **'AI Study Coach'**
  String get aiCoachTitle;

  /// No description provided for @aiCoachGreeting.
  ///
  /// In en, this message translates to:
  /// **'Hi! I\'m your AI Study Coach. Ask me anything about your lessons, and I\'ll help you learn step by step!'**
  String get aiCoachGreeting;

  /// No description provided for @aiTryAskingAbout.
  ///
  /// In en, this message translates to:
  /// **'Try asking about:'**
  String get aiTryAskingAbout;

  /// No description provided for @menuMyProgress.
  ///
  /// In en, this message translates to:
  /// **'My Progress'**
  String get menuMyProgress;

  /// No description provided for @menuSavedLessons.
  ///
  /// In en, this message translates to:
  /// **'Saved Lessons'**
  String get menuSavedLessons;

  /// No description provided for @menuCommunities.
  ///
  /// In en, this message translates to:
  /// **'Communities'**
  String get menuCommunities;

  /// No description provided for @communitiesDiscover.
  ///
  /// In en, this message translates to:
  /// **'Discover'**
  String get communitiesDiscover;

  /// No description provided for @communitiesMine.
  ///
  /// In en, this message translates to:
  /// **'My Communities'**
  String get communitiesMine;

  /// No description provided for @communitiesSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search communities...'**
  String get communitiesSearchHint;

  /// No description provided for @communityJoin.
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get communityJoin;

  /// No description provided for @communityJoined.
  ///
  /// In en, this message translates to:
  /// **'Joined'**
  String get communityJoined;

  /// No description provided for @communitiesUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Communities unavailable'**
  String get communitiesUnavailable;

  /// No description provided for @communitiesLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load communities.'**
  String get communitiesLoadFailed;

  /// No description provided for @communitiesNoneJoined.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t joined a community yet.'**
  String get communitiesNoneJoined;

  /// No description provided for @communityMembers.
  ///
  /// In en, this message translates to:
  /// **'{count} members'**
  String communityMembers(String count);

  /// No description provided for @communityCreatePost.
  ///
  /// In en, this message translates to:
  /// **'Create post'**
  String get communityCreatePost;

  /// No description provided for @communityShare.
  ///
  /// In en, this message translates to:
  /// **'Share community'**
  String get communityShare;

  /// No description provided for @communitySeeMore.
  ///
  /// In en, this message translates to:
  /// **'See more'**
  String get communitySeeMore;

  /// No description provided for @communitySeeLess.
  ///
  /// In en, this message translates to:
  /// **'See less'**
  String get communitySeeLess;

  /// No description provided for @communitySortBy.
  ///
  /// In en, this message translates to:
  /// **'Sort posts by'**
  String get communitySortBy;

  /// No description provided for @communitySortHot.
  ///
  /// In en, this message translates to:
  /// **'Hot'**
  String get communitySortHot;

  /// No description provided for @communitySortNew.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get communitySortNew;

  /// No description provided for @communitySortTop.
  ///
  /// In en, this message translates to:
  /// **'Top'**
  String get communitySortTop;

  /// No description provided for @communityNoPostsTitle.
  ///
  /// In en, this message translates to:
  /// **'No posts yet'**
  String get communityNoPostsTitle;

  /// No description provided for @communityNoPostsBody.
  ///
  /// In en, this message translates to:
  /// **'Be the first to start a discussion here.'**
  String get communityNoPostsBody;

  /// No description provided for @communityNotFound.
  ///
  /// In en, this message translates to:
  /// **'This community could not be found.'**
  String get communityNotFound;

  /// No description provided for @communityLinkCopied.
  ///
  /// In en, this message translates to:
  /// **'Community link copied'**
  String get communityLinkCopied;

  /// No description provided for @communityMemberCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No members yet} =1{1 member} other{{label} members}}'**
  String communityMemberCount(int count, String label);

  /// No description provided for @composeJoinFirst.
  ///
  /// In en, this message translates to:
  /// **'Join a community first to post in it.'**
  String get composeJoinFirst;

  /// No description provided for @composeBrowseCommunities.
  ///
  /// In en, this message translates to:
  /// **'Browse communities'**
  String get composeBrowseCommunities;

  /// No description provided for @communitiesYours.
  ///
  /// In en, this message translates to:
  /// **'Your communities'**
  String get communitiesYours;

  /// No description provided for @communitiesSeeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get communitiesSeeAll;

  /// No description provided for @communitiesFeatured.
  ///
  /// In en, this message translates to:
  /// **'Featured'**
  String get communitiesFeatured;

  /// No description provided for @communitiesCantFind.
  ///
  /// In en, this message translates to:
  /// **'Can’t find your community?'**
  String get communitiesCantFind;

  /// No description provided for @communitiesCreate.
  ///
  /// In en, this message translates to:
  /// **'Create community'**
  String get communitiesCreate;

  /// No description provided for @communitiesFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get communitiesFilterAll;

  /// No description provided for @communitiesFilterScience.
  ///
  /// In en, this message translates to:
  /// **'Science'**
  String get communitiesFilterScience;

  /// No description provided for @communitiesFilterLanguages.
  ///
  /// In en, this message translates to:
  /// **'Languages'**
  String get communitiesFilterLanguages;

  /// No description provided for @communitiesFilterHistory.
  ///
  /// In en, this message translates to:
  /// **'History & Culture'**
  String get communitiesFilterHistory;

  /// No description provided for @communitiesFilterTech.
  ///
  /// In en, this message translates to:
  /// **'Tech'**
  String get communitiesFilterTech;

  /// No description provided for @communitiesFilterGeneral.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get communitiesFilterGeneral;

  /// No description provided for @createCommunityIcon.
  ///
  /// In en, this message translates to:
  /// **'Community icon'**
  String get createCommunityIcon;

  /// No description provided for @createCommunityIconHint.
  ///
  /// In en, this message translates to:
  /// **'Optional. A square picture works best.'**
  String get createCommunityIconHint;

  /// No description provided for @createCommunityName.
  ///
  /// In en, this message translates to:
  /// **'Community name'**
  String get createCommunityName;

  /// No description provided for @createCommunityNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Robotics Club'**
  String get createCommunityNameHint;

  /// No description provided for @createCommunityNameLength.
  ///
  /// In en, this message translates to:
  /// **'Use 3 to 50 characters.'**
  String get createCommunityNameLength;

  /// No description provided for @createCommunityNameChars.
  ///
  /// In en, this message translates to:
  /// **'Use only letters, numbers, spaces and & \' . , ( ) + # -'**
  String get createCommunityNameChars;

  /// No description provided for @createCommunityNameLetters.
  ///
  /// In en, this message translates to:
  /// **'The name needs at least one letter.'**
  String get createCommunityNameLetters;

  /// No description provided for @createCommunityNameReserved.
  ///
  /// In en, this message translates to:
  /// **'This name is reserved. Try another one.'**
  String get createCommunityNameReserved;

  /// No description provided for @createCommunityDescription.
  ///
  /// In en, this message translates to:
  /// **'What is it about?'**
  String get createCommunityDescription;

  /// No description provided for @createCommunityDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Tell people what they will learn or discuss here.'**
  String get createCommunityDescriptionHint;

  /// No description provided for @createCommunityRulesTitle.
  ///
  /// In en, this message translates to:
  /// **'Before you create'**
  String get createCommunityRulesTitle;

  /// No description provided for @createCommunityRulePublic.
  ///
  /// In en, this message translates to:
  /// **'Everyone on RIKSA can find, join and post in your community.'**
  String get createCommunityRulePublic;

  /// No description provided for @createCommunityRuleOwner.
  ///
  /// In en, this message translates to:
  /// **'You become its owner and stay a member while you own it.'**
  String get createCommunityRuleOwner;

  /// No description provided for @createCommunityRuleConduct.
  ///
  /// In en, this message translates to:
  /// **'Keep it kind, safe and on topic. Communities that break the rules are removed.'**
  String get createCommunityRuleConduct;

  /// No description provided for @createCommunityRuleLimit.
  ///
  /// In en, this message translates to:
  /// **'You need a verified account. You can create up to 3 a day and own up to 5.'**
  String get createCommunityRuleLimit;

  /// No description provided for @createCommunityCreated.
  ///
  /// In en, this message translates to:
  /// **'Your community is ready'**
  String get createCommunityCreated;

  /// No description provided for @aiAskCoachAbout.
  ///
  /// In en, this message translates to:
  /// **'Ask AI Study Coach: \"{query}\"'**
  String aiAskCoachAbout(String query);

  /// No description provided for @aiChatLoadFailedBody.
  ///
  /// In en, this message translates to:
  /// **'Check your connection and try again. Nothing in this chat was lost.'**
  String get aiChatLoadFailedBody;

  /// No description provided for @discardChangesTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard your changes?'**
  String get discardChangesTitle;

  /// No description provided for @discardChangesBody.
  ///
  /// In en, this message translates to:
  /// **'What you have written here will be lost.'**
  String get discardChangesBody;

  /// No description provided for @keepEditing.
  ///
  /// In en, this message translates to:
  /// **'Keep editing'**
  String get keepEditing;

  /// No description provided for @discardAction.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discardAction;

  /// No description provided for @notNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get notNow;

  /// No description provided for @lessonDetailLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn’t open this lesson'**
  String get lessonDetailLoadFailed;

  /// No description provided for @loadFailedCheckConnection.
  ///
  /// In en, this message translates to:
  /// **'Check your connection and try again.'**
  String get loadFailedCheckConnection;

  /// No description provided for @backToSubjects.
  ///
  /// In en, this message translates to:
  /// **'Back to subjects'**
  String get backToSubjects;

  /// No description provided for @savedLessonsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn’t load your saved lessons'**
  String get savedLessonsLoadFailed;

  /// No description provided for @savedLessonsSomeFailed.
  ///
  /// In en, this message translates to:
  /// **'Some saved lessons couldn’t load.'**
  String get savedLessonsSomeFailed;

  /// No description provided for @savedLessonsUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'These lessons are no longer available'**
  String get savedLessonsUnavailableTitle;

  /// No description provided for @savedLessonsUnavailableBody.
  ///
  /// In en, this message translates to:
  /// **'They may have been removed from the course.'**
  String get savedLessonsUnavailableBody;

  /// No description provided for @savedLessonsClear.
  ///
  /// In en, this message translates to:
  /// **'Clear saved lessons'**
  String get savedLessonsClear;

  /// No description provided for @browseLessons.
  ///
  /// In en, this message translates to:
  /// **'Browse lessons'**
  String get browseLessons;

  /// No description provided for @removeFromSaved.
  ///
  /// In en, this message translates to:
  /// **'Remove from saved'**
  String get removeFromSaved;

  /// No description provided for @composeLoadingCommunities.
  ///
  /// In en, this message translates to:
  /// **'Loading your communities…'**
  String get composeLoadingCommunities;

  /// No description provided for @composeCommunitiesFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn’t load your communities. Your writing is safe.'**
  String get composeCommunitiesFailed;

  /// No description provided for @blogChooseTopicRequired.
  ///
  /// In en, this message translates to:
  /// **'Choose a topic (required)'**
  String get blogChooseTopicRequired;

  /// No description provided for @blogTopicsLoading.
  ///
  /// In en, this message translates to:
  /// **'Topics are still loading. Try again in a moment.'**
  String get blogTopicsLoading;

  /// No description provided for @blogTopicsFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn’t load topics.'**
  String get blogTopicsFailed;

  /// No description provided for @blogTopicsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No topics are available yet.'**
  String get blogTopicsEmpty;

  /// No description provided for @recoveryErrorNetwork.
  ///
  /// In en, this message translates to:
  /// **'We couldn’t reach Riksa. Check your internet and try again.'**
  String get recoveryErrorNetwork;

  /// No description provided for @recoveryErrorRateLimited.
  ///
  /// In en, this message translates to:
  /// **'That’s a lot of tries! Take a short break, then try again.'**
  String get recoveryErrorRateLimited;

  /// No description provided for @recoveryErrorServer.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong on our side. Please try again in a moment.'**
  String get recoveryErrorServer;

  /// No description provided for @recoveryErrorPassword.
  ///
  /// In en, this message translates to:
  /// **'Almost there! Your password needs at least 8 characters, with an uppercase letter, a lowercase letter and a number.'**
  String get recoveryErrorPassword;

  /// No description provided for @recoveryErrorCode.
  ///
  /// In en, this message translates to:
  /// **'That code didn’t work. It may have expired, so ask for a new one and try again.'**
  String get recoveryErrorCode;

  /// No description provided for @recoveryErrorAccount.
  ///
  /// In en, this message translates to:
  /// **'We couldn’t find that account. Check the spelling and try again.'**
  String get recoveryErrorAccount;

  /// No description provided for @recoveryErrorDetails.
  ///
  /// In en, this message translates to:
  /// **'That didn’t work. Please check your details and try again.'**
  String get recoveryErrorDetails;

  /// No description provided for @recoveryErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get recoveryErrorGeneric;

  /// No description provided for @recoveryNeedIdentifier.
  ///
  /// In en, this message translates to:
  /// **'Tell us your username, email or Telegram ID so we know whose account to help with.'**
  String get recoveryNeedIdentifier;

  /// No description provided for @recoveryCodeLength.
  ///
  /// In en, this message translates to:
  /// **'The code has 6 digits. Check your message and try again.'**
  String get recoveryCodeLength;

  /// No description provided for @recoveryChecklistIncomplete.
  ///
  /// In en, this message translates to:
  /// **'Almost there! Your password just needs everything in the checklist ticked.'**
  String get recoveryChecklistIncomplete;

  /// No description provided for @recoveryPasswordsDiffer.
  ///
  /// In en, this message translates to:
  /// **'The two passwords don’t match yet. Try typing them again.'**
  String get recoveryPasswordsDiffer;

  /// No description provided for @recoveryPasswordSaved.
  ///
  /// In en, this message translates to:
  /// **'All set! Sign in with your new password.'**
  String get recoveryPasswordSaved;

  /// No description provided for @recoveryStepIdentifierTitle.
  ///
  /// In en, this message translates to:
  /// **'Forgot your password?'**
  String get recoveryStepIdentifierTitle;

  /// No description provided for @recoveryStepIdentifierSubtitle.
  ///
  /// In en, this message translates to:
  /// **'No worries, it happens to everyone. Tell us who you are and we’ll send you a code.'**
  String get recoveryStepIdentifierSubtitle;

  /// No description provided for @recoveryStepCodeTitle.
  ///
  /// In en, this message translates to:
  /// **'Check your messages'**
  String get recoveryStepCodeTitle;

  /// No description provided for @recoveryStepCodeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We sent a 6-digit code to your email or Telegram. Enter it below.'**
  String get recoveryStepCodeSubtitle;

  /// No description provided for @recoveryStepPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Create a new password'**
  String get recoveryStepPasswordTitle;

  /// No description provided for @recoveryStepPasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pick something you will remember but others can’t guess.'**
  String get recoveryStepPasswordSubtitle;

  /// No description provided for @recoveryIdentifierLabel.
  ///
  /// In en, this message translates to:
  /// **'Username, email or Telegram ID'**
  String get recoveryIdentifierLabel;

  /// No description provided for @recoveryNewPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get recoveryNewPasswordLabel;

  /// No description provided for @recoveryConfirmPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Type it again'**
  String get recoveryConfirmPasswordLabel;

  /// No description provided for @recoverySendCode.
  ///
  /// In en, this message translates to:
  /// **'Send me a code'**
  String get recoverySendCode;

  /// No description provided for @recoveryVerifyCode.
  ///
  /// In en, this message translates to:
  /// **'Verify code'**
  String get recoveryVerifyCode;

  /// No description provided for @recoverySavePassword.
  ///
  /// In en, this message translates to:
  /// **'Save new password'**
  String get recoverySavePassword;

  /// No description provided for @recoveryResend.
  ///
  /// In en, this message translates to:
  /// **'Didn’t get it? Send a new code'**
  String get recoveryResend;

  /// No description provided for @recoveryResendSent.
  ///
  /// In en, this message translates to:
  /// **'A fresh code is on its way.'**
  String get recoveryResendSent;

  /// No description provided for @recoveryBackToSignIn.
  ///
  /// In en, this message translates to:
  /// **'I remember it — back to sign in'**
  String get recoveryBackToSignIn;

  /// No description provided for @recoveryIllustrationLabel.
  ///
  /// In en, this message translates to:
  /// **'Account recovery, step {step}'**
  String recoveryIllustrationLabel(int step);

  /// No description provided for @recoveryStepProgress.
  ///
  /// In en, this message translates to:
  /// **'Step {step} of {total}'**
  String recoveryStepProgress(int step, int total);

  /// No description provided for @passwordRuleLength.
  ///
  /// In en, this message translates to:
  /// **'At least 8 characters'**
  String get passwordRuleLength;

  /// No description provided for @passwordRuleUppercase.
  ///
  /// In en, this message translates to:
  /// **'An uppercase letter (A–Z)'**
  String get passwordRuleUppercase;

  /// No description provided for @passwordRuleLowercase.
  ///
  /// In en, this message translates to:
  /// **'A lowercase letter (a–z)'**
  String get passwordRuleLowercase;

  /// No description provided for @passwordRuleDigit.
  ///
  /// In en, this message translates to:
  /// **'A number (0–9)'**
  String get passwordRuleDigit;

  /// No description provided for @passwordRuleMatch.
  ///
  /// In en, this message translates to:
  /// **'Both passwords match'**
  String get passwordRuleMatch;

  /// No description provided for @checklistItemDone.
  ///
  /// In en, this message translates to:
  /// **'{item}, done'**
  String checklistItemDone(String item);

  /// No description provided for @checklistItemPending.
  ///
  /// In en, this message translates to:
  /// **'{item}, not yet'**
  String checklistItemPending(String item);

  /// No description provided for @emailVerifiedTitle.
  ///
  /// In en, this message translates to:
  /// **'Email verified'**
  String get emailVerifiedTitle;

  /// No description provided for @emailVerifiedBody.
  ///
  /// In en, this message translates to:
  /// **'Your Riksa account email is now verified.'**
  String get emailVerifiedBody;

  /// No description provided for @emailVerifyFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Verification failed'**
  String get emailVerifyFailedTitle;

  /// No description provided for @emailVerifyFailedBody.
  ///
  /// In en, this message translates to:
  /// **'This verification link is invalid or expired.'**
  String get emailVerifyFailedBody;

  /// No description provided for @socialLikeLabel.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Like this post} =1{Like this post, 1 like} other{Like this post, {count} likes}}'**
  String socialLikeLabel(int count);

  /// No description provided for @socialCommentLabel.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Comment on this post} =1{View 1 comment} other{View {count} comments}}'**
  String socialCommentLabel(int count);

  /// No description provided for @socialShareLabel.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Share this post} other{Share this post, shared {count} times}}'**
  String socialShareLabel(int count);

  /// No description provided for @socialOpenProfile.
  ///
  /// In en, this message translates to:
  /// **'Open {name}’s profile'**
  String socialOpenProfile(String name);

  /// No description provided for @socialReplyTo.
  ///
  /// In en, this message translates to:
  /// **'Reply to {name}'**
  String socialReplyTo(String name);

  /// No description provided for @socialDeleteComment.
  ///
  /// In en, this message translates to:
  /// **'Delete this comment'**
  String get socialDeleteComment;

  /// No description provided for @socialCancelReply.
  ///
  /// In en, this message translates to:
  /// **'Cancel reply'**
  String get socialCancelReply;

  /// No description provided for @genderFemale.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get genderFemale;

  /// No description provided for @genderMale.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get genderMale;

  /// No description provided for @genderOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get genderOther;

  /// No description provided for @loadingProvincesTitle.
  ///
  /// In en, this message translates to:
  /// **'Loading provinces'**
  String get loadingProvincesTitle;

  /// No description provided for @loadingProvincesBody.
  ///
  /// In en, this message translates to:
  /// **'Preparing local learning options.'**
  String get loadingProvincesBody;

  /// No description provided for @leaderboardNational.
  ///
  /// In en, this message translates to:
  /// **'National'**
  String get leaderboardNational;

  /// No description provided for @leaderboardProvince.
  ///
  /// In en, this message translates to:
  /// **'Province'**
  String get leaderboardProvince;

  /// No description provided for @leaderboardRankings.
  ///
  /// In en, this message translates to:
  /// **'Rankings'**
  String get leaderboardRankings;

  /// No description provided for @leaderboardYourRank.
  ///
  /// In en, this message translates to:
  /// **'Your rank'**
  String get leaderboardYourRank;

  /// No description provided for @leaderboardRowLabel.
  ///
  /// In en, this message translates to:
  /// **'Rank {rank}, {name}, {xp} XP'**
  String leaderboardRowLabel(int rank, String name, int xp);

  /// No description provided for @leaderboardYourRankLabel.
  ///
  /// In en, this message translates to:
  /// **'Your rank is {rank}. {name}, {scope}, {tier}, {xp} XP.'**
  String leaderboardYourRankLabel(
    int rank,
    String name,
    String scope,
    String tier,
    int xp,
  );

  /// No description provided for @progressHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Progress history'**
  String get progressHistoryTitle;

  /// No description provided for @progressHistoryXpTab.
  ///
  /// In en, this message translates to:
  /// **'XP activity'**
  String get progressHistoryXpTab;

  /// No description provided for @progressHistoryRankTab.
  ///
  /// In en, this message translates to:
  /// **'Rank changes'**
  String get progressHistoryRankTab;

  /// No description provided for @progressHistoryXpFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn’t load your XP history'**
  String get progressHistoryXpFailed;

  /// No description provided for @progressHistoryRankFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn’t load your rank history'**
  String get progressHistoryRankFailed;

  /// No description provided for @progressHistoryXpEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No XP yet'**
  String get progressHistoryXpEmptyTitle;

  /// No description provided for @progressHistoryXpEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Complete a lesson to start your history.'**
  String get progressHistoryXpEmptyBody;

  /// No description provided for @progressHistoryRankEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No rank changes yet'**
  String get progressHistoryRankEmptyTitle;

  /// No description provided for @progressHistoryRankEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Keep earning XP to move up the leaderboard.'**
  String get progressHistoryRankEmptyBody;

  /// No description provided for @progressHistoryRankRow.
  ///
  /// In en, this message translates to:
  /// **'{scope} rank'**
  String progressHistoryRankRow(String scope);

  /// No description provided for @xpAmount.
  ///
  /// In en, this message translates to:
  /// **'+{amount} XP'**
  String xpAmount(int amount);

  /// No description provided for @xpSourceLesson.
  ///
  /// In en, this message translates to:
  /// **'Lesson completed'**
  String get xpSourceLesson;

  /// No description provided for @xpSourceExercise.
  ///
  /// In en, this message translates to:
  /// **'Exercise answered'**
  String get xpSourceExercise;

  /// No description provided for @xpSourceAchievement.
  ///
  /// In en, this message translates to:
  /// **'Achievement earned'**
  String get xpSourceAchievement;

  /// No description provided for @xpSourceStreak.
  ///
  /// In en, this message translates to:
  /// **'Streak bonus'**
  String get xpSourceStreak;

  /// No description provided for @xpSourceReward.
  ///
  /// In en, this message translates to:
  /// **'Reward'**
  String get xpSourceReward;

  /// No description provided for @profileSetupTitle.
  ///
  /// In en, this message translates to:
  /// **'Set up your profile'**
  String get profileSetupTitle;

  /// No description provided for @profileSetupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A few details help classmates recognise you and keep your progress yours.'**
  String get profileSetupSubtitle;

  /// No description provided for @profileSetupCta.
  ///
  /// In en, this message translates to:
  /// **'Set up profile'**
  String get profileSetupCta;

  /// No description provided for @profileSetupStepPhotoTitle.
  ///
  /// In en, this message translates to:
  /// **'Add a photo'**
  String get profileSetupStepPhotoTitle;

  /// No description provided for @profileSetupStepPhotoBody.
  ///
  /// In en, this message translates to:
  /// **'Pick an avatar or upload your own picture.'**
  String get profileSetupStepPhotoBody;

  /// No description provided for @profileSetupStepNameTitle.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get profileSetupStepNameTitle;

  /// No description provided for @profileSetupStepNameBody.
  ///
  /// In en, this message translates to:
  /// **'The name classmates see on posts and rankings.'**
  String get profileSetupStepNameBody;

  /// No description provided for @profileSetupStepBioTitle.
  ///
  /// In en, this message translates to:
  /// **'A short bio'**
  String get profileSetupStepBioTitle;

  /// No description provided for @profileSetupStepBioBody.
  ///
  /// In en, this message translates to:
  /// **'Say what you are studying for in a line or two.'**
  String get profileSetupStepBioBody;

  /// No description provided for @profileSetupStepProvinceTitle.
  ///
  /// In en, this message translates to:
  /// **'Your province'**
  String get profileSetupStepProvinceTitle;

  /// No description provided for @profileSetupStepProvinceBody.
  ///
  /// In en, this message translates to:
  /// **'Used for provincial rankings and local communities.'**
  String get profileSetupStepProvinceBody;

  /// No description provided for @supportDocumentComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get supportDocumentComingSoon;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @blogTitle.
  ///
  /// In en, this message translates to:
  /// **'Blog'**
  String get blogTitle;

  /// No description provided for @blogWritePost.
  ///
  /// In en, this message translates to:
  /// **'Write an article'**
  String get blogWritePost;

  /// No description provided for @blogYourPosts.
  ///
  /// In en, this message translates to:
  /// **'My Articles'**
  String get blogYourPosts;

  /// No description provided for @blogFeedFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Posts are taking a break'**
  String get blogFeedFailedTitle;

  /// No description provided for @blogFeedEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing posted yet'**
  String get blogFeedEmptyTitle;

  /// No description provided for @blogFeedEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Be the first learner to share something useful with the Riksa community.'**
  String get blogFeedEmptyBody;

  /// No description provided for @blogPostDeleted.
  ///
  /// In en, this message translates to:
  /// **'Post deleted'**
  String get blogPostDeleted;

  /// No description provided for @blogLikeLabel.
  ///
  /// In en, this message translates to:
  /// **'Like, {count} likes'**
  String blogLikeLabel(int count);

  /// No description provided for @blogUnlikeLabel.
  ///
  /// In en, this message translates to:
  /// **'Unlike, {count} likes'**
  String blogUnlikeLabel(int count);

  /// No description provided for @blogMyPostsFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load your articles'**
  String get blogMyPostsFailed;

  /// No description provided for @blogMyPostsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No articles yet'**
  String get blogMyPostsEmptyTitle;

  /// No description provided for @blogMyPostsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Articles you write appear here, including their review status.'**
  String get blogMyPostsEmptyBody;

  /// No description provided for @blogMyPostsFilteredTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing here'**
  String get blogMyPostsFilteredTitle;

  /// No description provided for @blogMyPostsFilteredBody.
  ///
  /// In en, this message translates to:
  /// **'You have no articles with this status right now.'**
  String get blogMyPostsFilteredBody;

  /// No description provided for @blogStatusPending.
  ///
  /// In en, this message translates to:
  /// **'In review'**
  String get blogStatusPending;

  /// No description provided for @blogStatusApproved.
  ///
  /// In en, this message translates to:
  /// **'Published'**
  String get blogStatusApproved;

  /// No description provided for @blogStatusRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get blogStatusRejected;

  /// No description provided for @blogEditPost.
  ///
  /// In en, this message translates to:
  /// **'Edit post'**
  String get blogEditPost;

  /// No description provided for @blogDeletePost.
  ///
  /// In en, this message translates to:
  /// **'Delete post'**
  String get blogDeletePost;

  /// No description provided for @blogDeleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this post?'**
  String get blogDeleteConfirmTitle;

  /// No description provided for @blogDeleteConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'The post and its likes and views are removed for everyone. This cannot be undone.'**
  String get blogDeleteConfirmBody;

  /// No description provided for @blogKeepPost.
  ///
  /// In en, this message translates to:
  /// **'Keep post'**
  String get blogKeepPost;

  /// No description provided for @blogPostOptions.
  ///
  /// In en, this message translates to:
  /// **'Post options'**
  String get blogPostOptions;

  /// No description provided for @blogVerified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get blogVerified;

  /// No description provided for @blogUnknownAuthor.
  ///
  /// In en, this message translates to:
  /// **'Riksa writer'**
  String get blogUnknownAuthor;

  /// No description provided for @blogOwnerEditFailed.
  ///
  /// In en, this message translates to:
  /// **'You can only edit your own posts'**
  String get blogOwnerEditFailed;

  /// No description provided for @blogOwnerDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'You can only delete your own posts'**
  String get blogOwnerDeleteFailed;

  /// No description provided for @blogPostGone.
  ///
  /// In en, this message translates to:
  /// **'This post no longer exists'**
  String get blogPostGone;

  /// No description provided for @blogReviewPendingTitle.
  ///
  /// In en, this message translates to:
  /// **'In review'**
  String get blogReviewPendingTitle;

  /// No description provided for @blogReviewBackTitle.
  ///
  /// In en, this message translates to:
  /// **'Back in review'**
  String get blogReviewBackTitle;

  /// No description provided for @blogReviewBackBody.
  ///
  /// In en, this message translates to:
  /// **'Your changes were saved. The post returns to the blog once a moderator approves this version.'**
  String get blogReviewBackBody;

  /// No description provided for @blogReviewSubmittedBody.
  ///
  /// In en, this message translates to:
  /// **'Your post was submitted. It appears in the blog once a moderator approves it, and you can follow its status under Your posts.'**
  String get blogReviewSubmittedBody;

  /// No description provided for @blogDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get blogDone;

  /// No description provided for @blogSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get blogSave;

  /// No description provided for @blogPublish.
  ///
  /// In en, this message translates to:
  /// **'Post'**
  String get blogPublish;

  /// No description provided for @blogNothingToPreview.
  ///
  /// In en, this message translates to:
  /// **'Nothing to preview yet.'**
  String get blogNothingToPreview;

  /// No description provided for @blogTitleHint.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get blogTitleHint;

  /// No description provided for @blogBodyHint.
  ///
  /// In en, this message translates to:
  /// **'Share what you learned. Markdown works here.'**
  String get blogBodyHint;

  /// No description provided for @blogCoverUrlLabel.
  ///
  /// In en, this message translates to:
  /// **'Cover image URL (optional)'**
  String get blogCoverUrlLabel;

  /// No description provided for @blogRemoveCover.
  ///
  /// In en, this message translates to:
  /// **'Remove cover'**
  String get blogRemoveCover;

  /// No description provided for @blogCoverImage.
  ///
  /// In en, this message translates to:
  /// **'Cover image'**
  String get blogCoverImage;

  /// No description provided for @blogPreview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get blogPreview;

  /// No description provided for @blogBackToWriting.
  ///
  /// In en, this message translates to:
  /// **'Back to writing'**
  String get blogBackToWriting;

  /// No description provided for @blogOpenForEditFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open this post for editing'**
  String get blogOpenForEditFailed;

  /// No description provided for @blogPostUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Post unavailable'**
  String get blogPostUnavailableTitle;

  /// No description provided for @blogPostUnavailableBody.
  ///
  /// In en, this message translates to:
  /// **'This post could not be loaded.'**
  String get blogPostUnavailableBody;

  /// No description provided for @blogLoadPostFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load this post'**
  String get blogLoadPostFailed;

  /// No description provided for @blogLikeFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not update like'**
  String get blogLikeFailed;

  /// No description provided for @blogOpenPostFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'This post would not open'**
  String get blogOpenPostFailedTitle;

  /// No description provided for @blogTextSizeTooltip.
  ///
  /// In en, this message translates to:
  /// **'Adjust text size'**
  String get blogTextSizeTooltip;

  /// No description provided for @blogTextSizeDefault.
  ///
  /// In en, this message translates to:
  /// **'Text size: Default (1.0x)'**
  String get blogTextSizeDefault;

  /// No description provided for @blogTextSizeLarge.
  ///
  /// In en, this message translates to:
  /// **'Text size: Large (1.18x)'**
  String get blogTextSizeLarge;

  /// No description provided for @blogTextSizeExtraLarge.
  ///
  /// In en, this message translates to:
  /// **'Text size: Extra Large (1.35x)'**
  String get blogTextSizeExtraLarge;

  /// No description provided for @blogProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get blogProfile;

  /// No description provided for @blogSomethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get blogSomethingWentWrong;

  /// No description provided for @markdownBold.
  ///
  /// In en, this message translates to:
  /// **'Bold'**
  String get markdownBold;

  /// No description provided for @markdownItalic.
  ///
  /// In en, this message translates to:
  /// **'Italic'**
  String get markdownItalic;

  /// No description provided for @markdownHeading.
  ///
  /// In en, this message translates to:
  /// **'Heading'**
  String get markdownHeading;

  /// No description provided for @markdownQuote.
  ///
  /// In en, this message translates to:
  /// **'Quote'**
  String get markdownQuote;

  /// No description provided for @markdownBulletList.
  ///
  /// In en, this message translates to:
  /// **'Bulleted list'**
  String get markdownBulletList;

  /// No description provided for @markdownNumberedList.
  ///
  /// In en, this message translates to:
  /// **'Numbered list'**
  String get markdownNumberedList;

  /// No description provided for @markdownCode.
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get markdownCode;

  /// No description provided for @markdownLink.
  ///
  /// In en, this message translates to:
  /// **'Link'**
  String get markdownLink;

  /// No description provided for @authBuddyWelcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome back, {name}! I missed you.'**
  String authBuddyWelcome(String name);

  /// No description provided for @authBuddyRegister.
  ///
  /// In en, this message translates to:
  /// **'New here? Let\'s make your account!'**
  String get authBuddyRegister;

  /// No description provided for @authBuddyPasswordHidden.
  ///
  /// In en, this message translates to:
  /// **'I\'m not looking!'**
  String get authBuddyPasswordHidden;

  /// No description provided for @authBuddyPasswordShown.
  ///
  /// In en, this message translates to:
  /// **'Oh! I can see it now.'**
  String get authBuddyPasswordShown;

  /// No description provided for @authBuddyChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking…'**
  String get authBuddyChecking;

  /// No description provided for @authBuddyError.
  ///
  /// In en, this message translates to:
  /// **'Oh no! {message}'**
  String authBuddyError(String message);

  /// No description provided for @authBuddyValidationHint.
  ///
  /// In en, this message translates to:
  /// **'Oops! Check the highlighted fields.'**
  String get authBuddyValidationHint;

  /// No description provided for @authBuddyForgotHint.
  ///
  /// In en, this message translates to:
  /// **'Still stuck? Try Forgot password?'**
  String get authBuddyForgotHint;

  /// No description provided for @authBuddySuccess.
  ///
  /// In en, this message translates to:
  /// **'Yay, you\'re in!'**
  String get authBuddySuccess;

  /// No description provided for @buddyHomeGreeting.
  ///
  /// In en, this message translates to:
  /// **'Ready for another step?'**
  String get buddyHomeGreeting;

  /// No description provided for @buddyWelcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back. Pick up where you left off.'**
  String get buddyWelcomeBack;

  /// No description provided for @buddyLessonCompleted.
  ///
  /// In en, this message translates to:
  /// **'You earned this!'**
  String get buddyLessonCompleted;

  /// No description provided for @buddyCareTitle.
  ///
  /// In en, this message translates to:
  /// **'Today with {name}'**
  String buddyCareTitle(String name);

  /// No description provided for @buddyCareLesson.
  ///
  /// In en, this message translates to:
  /// **'Finish a lesson'**
  String get buddyCareLesson;

  /// No description provided for @buddyCareRead.
  ///
  /// In en, this message translates to:
  /// **'Read a story'**
  String get buddyCareRead;

  /// No description provided for @buddyCareShare.
  ///
  /// In en, this message translates to:
  /// **'Share with the community'**
  String get buddyCareShare;

  /// No description provided for @buddyChooseAction.
  ///
  /// In en, this message translates to:
  /// **'Choose a buddy'**
  String get buddyChooseAction;

  /// No description provided for @buddyCareProgress.
  ///
  /// In en, this message translates to:
  /// **'{count} of 1 complete'**
  String buddyCareProgress(int count);

  /// No description provided for @buddyEnergyLively.
  ///
  /// In en, this message translates to:
  /// **'{name} is full of energy.'**
  String buddyEnergyLively(String name);

  /// No description provided for @buddyEnergySteady.
  ///
  /// In en, this message translates to:
  /// **'One lesson keeps {name} going.'**
  String buddyEnergySteady(String name);

  /// No description provided for @buddyEnergySleepy.
  ///
  /// In en, this message translates to:
  /// **'{name} is getting sleepy.'**
  String buddyEnergySleepy(String name);

  /// No description provided for @buddyEnergyNapping.
  ///
  /// In en, this message translates to:
  /// **'{name} is napping. A lesson wakes them up.'**
  String buddyEnergyNapping(String name);

  /// No description provided for @buddyLessonEnergyLine.
  ///
  /// In en, this message translates to:
  /// **'+35 energy · {name} is full of energy'**
  String buddyLessonEnergyLine(String name);

  /// No description provided for @buddyReadEnjoyed.
  ///
  /// In en, this message translates to:
  /// **'{name} enjoyed that story'**
  String buddyReadEnjoyed(String name);

  /// No description provided for @buddyRankImproved.
  ///
  /// In en, this message translates to:
  /// **'Your progress moved you up.'**
  String get buddyRankImproved;

  /// No description provided for @buddyCommunityJoined.
  ///
  /// In en, this message translates to:
  /// **'Welcome to your new community!'**
  String get buddyCommunityJoined;

  /// No description provided for @homeStreakDays.
  ///
  /// In en, this message translates to:
  /// **'{count} days'**
  String homeStreakDays(int count);

  /// No description provided for @homeTodaysStudy.
  ///
  /// In en, this message translates to:
  /// **'Today\'s study'**
  String get homeTodaysStudy;

  /// No description provided for @homeStartHere.
  ///
  /// In en, this message translates to:
  /// **'Start here'**
  String get homeStartHere;

  /// No description provided for @homeStartHereBody.
  ///
  /// In en, this message translates to:
  /// **'Choose your first lesson and begin one step at a time.'**
  String get homeStartHereBody;

  /// No description provided for @homeLessonMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String homeLessonMinutes(int minutes);

  /// No description provided for @homeContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get homeContinue;

  /// No description provided for @homeProvinceSquad.
  ///
  /// In en, this message translates to:
  /// **'Your province study squad'**
  String get homeProvinceSquad;

  /// No description provided for @homeProvinceMissing.
  ///
  /// In en, this message translates to:
  /// **'Choose your province to see your study squad.'**
  String get homeProvinceMissing;

  /// No description provided for @homeSelectProvince.
  ///
  /// In en, this message translates to:
  /// **'Choose province'**
  String get homeSelectProvince;

  /// No description provided for @homeProvinceRank.
  ///
  /// In en, this message translates to:
  /// **'You are #{rank} this week'**
  String homeProvinceRank(int rank);

  /// No description provided for @homeNearbyLearner.
  ///
  /// In en, this message translates to:
  /// **'#{rank} {name}'**
  String homeNearbyLearner(int rank, String name);

  /// No description provided for @homeYou.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get homeYou;

  /// No description provided for @homeViewProvinceRanks.
  ///
  /// In en, this message translates to:
  /// **'View province ranks'**
  String get homeViewProvinceRanks;

  /// No description provided for @homeFromCommunities.
  ///
  /// In en, this message translates to:
  /// **'From your communities'**
  String get homeFromCommunities;

  /// No description provided for @homeCommunityPostMeta.
  ///
  /// In en, this message translates to:
  /// **'{community} · {author} · {count} comments'**
  String homeCommunityPostMeta(String community, String author, int count);

  /// No description provided for @homeSeeCommunityFeed.
  ///
  /// In en, this message translates to:
  /// **'See community feed'**
  String get homeSeeCommunityFeed;

  /// No description provided for @lessonShareLearning.
  ///
  /// In en, this message translates to:
  /// **'Share what I learned'**
  String get lessonShareLearning;

  /// No description provided for @resumeLearningTitle.
  ///
  /// In en, this message translates to:
  /// **'Resume learning'**
  String get resumeLearningTitle;

  /// No description provided for @resumeLearningEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No lesson in progress'**
  String get resumeLearningEmptyTitle;

  /// No description provided for @resumeLearningEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Choose a lesson to begin your next learning step.'**
  String get resumeLearningEmptyBody;

  /// No description provided for @leaderboardNearbyLearners.
  ///
  /// In en, this message translates to:
  /// **'Learners around your rank'**
  String get leaderboardNearbyLearners;

  /// No description provided for @leaderboardSearchLearners.
  ///
  /// In en, this message translates to:
  /// **'Search learners'**
  String get leaderboardSearchLearners;

  /// No description provided for @buddyReactions.
  ///
  /// In en, this message translates to:
  /// **'Buddy reactions'**
  String get buddyReactions;

  /// No description provided for @buddyReactionsHint.
  ///
  /// In en, this message translates to:
  /// **'Allow animated and speaking buddy reactions'**
  String get buddyReactionsHint;

  /// No description provided for @profileStudyBuddy.
  ///
  /// In en, this message translates to:
  /// **'Study buddy'**
  String get profileStudyBuddy;

  /// No description provided for @profileBuddyNamed.
  ///
  /// In en, this message translates to:
  /// **'{name}, your study buddy'**
  String profileBuddyNamed(String name);

  /// No description provided for @aiBuddyHandoff.
  ///
  /// In en, this message translates to:
  /// **'Your buddy can help you start; Kru AI will explain the question.'**
  String get aiBuddyHandoff;

  /// No description provided for @homeProvinceSquadNamed.
  ///
  /// In en, this message translates to:
  /// **'{province} study squad'**
  String homeProvinceSquadNamed(String province);

  /// No description provided for @streakReminderTitle.
  ///
  /// In en, this message translates to:
  /// **'🔥 Keep your learning streak alive!'**
  String get streakReminderTitle;

  /// No description provided for @streakReminderBody.
  ///
  /// In en, this message translates to:
  /// **'Take 5 minutes tonight to practice and protect your streak.'**
  String get streakReminderBody;

  /// No description provided for @drawerGeneral.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get drawerGeneral;

  /// No description provided for @drawerAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get drawerAbout;

  /// No description provided for @drawerUserAgreement.
  ///
  /// In en, this message translates to:
  /// **'User Agreement'**
  String get drawerUserAgreement;

  /// No description provided for @drawerPrivacyCenter.
  ///
  /// In en, this message translates to:
  /// **'Privacy Center'**
  String get drawerPrivacyCenter;

  /// No description provided for @aiCopyAnswer.
  ///
  /// In en, this message translates to:
  /// **'Copy answer'**
  String get aiCopyAnswer;

  /// No description provided for @aiCopiedClipboard.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get aiCopiedClipboard;

  /// No description provided for @aiCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get aiCopy;

  /// No description provided for @aiLoginRequired.
  ///
  /// In en, this message translates to:
  /// **'Please log in to chat with the AI Tutor.'**
  String get aiLoginRequired;
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
