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
  String get registerTitle => 'Create Account';

  @override
  String get registerSubtitle => 'Join Riksa and start learning today';

  @override
  String get username => 'Username';

  @override
  String get usernameHint => 'Enter your username';

  @override
  String get password => 'Password';

  @override
  String get passwordHint => 'Enter your password';

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
  String get orContinueWith => 'or continue with';

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
  String get requiredField => 'This field is required';

  @override
  String get invalidUsername => 'Username must be at least 3 characters';

  @override
  String get invalidEmail => 'Enter a valid email address';

  @override
  String get weakPassword =>
      'Password must be 8+ chars with upper, lower, and digit';

  @override
  String get loginFailed => 'Login failed. Check your credentials.';

  @override
  String get registerFailed => 'Registration failed. Please try again.';

  @override
  String get googleFailed => 'Google sign-in failed';

  @override
  String get otpSendFailed => 'Failed to send OTP code';

  @override
  String get otpVerifyFailed => 'Invalid or expired code';

  @override
  String get otpSendSuccess => 'Code sent to your Telegram';

  @override
  String get languageEn => 'English';

  @override
  String get languageKm => 'ខ្មែរ';

  @override
  String get home => 'Home';

  @override
  String get logout => 'Log Out';

  @override
  String get loading => 'Loading...';
}
