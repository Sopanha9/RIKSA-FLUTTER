import 'package:flutter_test/flutter_test.dart';
import 'package:riksa_app/features/userProfile/presentation/public_profile_navigation.dart';

void main() {
  test('builds a public profile route only for a usable author id', () {
    expect(publicProfilePath(null), isNull);
    expect(publicProfilePath(''), isNull);
    expect(publicProfilePath('   '), isNull);
    expect(publicProfilePath('settings'), isNull);
    expect(publicProfilePath('user-2'), '/profile/user-2');
  });
}
