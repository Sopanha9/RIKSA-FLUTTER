import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riksa_app/features/auth/data/auth_api.dart';
import 'package:riksa_app/features/auth/presentation/account_recovery_screen.dart';
import 'package:riksa_app/l10n/gen/app_localizations.dart';

void main() {
  test('password rules match the server pattern', () {
    expect(const PasswordRules('riksa2026', 'riksa2026').strongEnough, isFalse);
    expect(const PasswordRules('Riksa202', 'Riksa202').strongEnough, isTrue);
    expect(const PasswordRules('Riksa2026', 'Riksa2027').matches, isFalse);
  });

  test('server errors are shown in plain words, never raw', () async {
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    String friendly(AuthFailureKind kind, String message, {int step = 2}) =>
        friendlyRecoveryError(
          AuthFailure(message, kind: kind),
          step: step,
          l10n: l10n,
        );

    final password = friendly(
      AuthFailureKind.validation,
      'newPassword: Password must be at least 8 characters with uppercase, '
      'lowercase, and a digit',
    );
    expect(password, isNot(contains('newPassword')));
    expect(password, startsWith('Almost there!'));

    expect(
      friendly(AuthFailureKind.validation, 'Invalid or expired code'),
      contains('ask for a new one'),
    );
    expect(friendly(AuthFailureKind.network, 'timeout'), contains('internet'));
    expect(
      friendly(AuthFailureKind.rateLimited, 'Too many requests'),
      contains('short break'),
    );
  });

  test('what the learner typed is explained in their own language', () async {
    final km = await AppLocalizations.delegate.load(const Locale('km'));
    final message = friendlyRecoveryError(
      const RecoveryValidationException(RecoveryIssue.codeLength),
      step: 1,
      l10n: km,
    );
    expect(message, km.recoveryCodeLength);
    expect(message, isNot(matches(RegExp(r'[A-Za-z]{4,}'))));
  });
}
