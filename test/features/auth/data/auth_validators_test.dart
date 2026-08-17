import 'package:flutter_test/flutter_test.dart';
import 'package:riksa_app/features/auth/data/auth_validators.dart';

void main() {
  group('registration validation mirrors the backend', () {
    test('username boundaries are 3 and 50 characters', () {
      expect(AuthValidators.isRegistrationUsername('ab'), isFalse);
      expect(AuthValidators.isRegistrationUsername('abc'), isTrue);
      expect(AuthValidators.isRegistrationUsername('a' * 50), isTrue);
      expect(AuthValidators.isRegistrationUsername('a' * 51), isFalse);
    });

    test('password requires upper, lower, digit, and eight characters', () {
      expect(AuthValidators.isStrongPassword('Password1'), isTrue);
      expect(AuthValidators.isStrongPassword('password1'), isFalse);
      expect(AuthValidators.isStrongPassword('PASSWORD1'), isFalse);
      expect(AuthValidators.isStrongPassword('Password'), isFalse);
      expect(AuthValidators.isStrongPassword('Pass1'), isFalse);
    });

    test('display name and email validate client boundaries', () {
      expect(AuthValidators.isDisplayName('Sok Sophea'), isTrue);
      expect(AuthValidators.isDisplayName(' '), isFalse);
      expect(AuthValidators.isDisplayName('a' * 101), isFalse);
      expect(AuthValidators.isEmail('sophea@example.com'), isTrue);
      expect(AuthValidators.isEmail('not-an-email'), isFalse);
    });
  });
}
