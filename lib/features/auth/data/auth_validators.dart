class AuthValidators {
  AuthValidators._();

  static bool isRegistrationUsername(String value) {
    final length = value.trim().length;
    return length >= 3 && length <= 50;
  }

  static bool isDisplayName(String value) {
    final length = value.trim().length;
    return length > 0 && length <= 100;
  }

  static bool isEmail(String value) {
    return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value.trim());
  }

  static bool isStrongPassword(String value) {
    return value.length >= 8 &&
        RegExp('[a-z]').hasMatch(value) &&
        RegExp('[A-Z]').hasMatch(value) &&
        RegExp(r'\d').hasMatch(value);
  }
}
