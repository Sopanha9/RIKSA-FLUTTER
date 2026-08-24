import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riksa_app/core/widgets/riksa_avatar_image.dart';
import 'package:riksa_app/features/auth/data/auth_models.dart';
import 'package:riksa_app/features/userProfile/data/profile_media_storage.dart';

void main() {
  test('maps stored Humation avatar values to bundled assets', () {
    expect(humationAvatarValue(0), '/avatars/avatar-1.png');
    expect(
      humationAvatarAssetPath('/avatars/avatar-24.png'),
      'assets/images/avatars/humation/avatar-24.svg',
    );
    expect(
      humationAvatarAssetPath('/avatars/humation/avatar-01.svg'),
      'assets/images/avatars/humation/avatar-01.svg',
    );
    expect(humationAvatarAssetPath('/avatars/avatar-25.png'), isNull);
    expect(() => humationAvatarValue(24), throwsRangeError);
  });

  test('serializes picked avatars using the backend catalog path', () {
    final request = UpdateProfileRequest(avatarUrl: humationAvatarValue(0));

    expect(request.toJson()['avatarUrl'], '/avatars/avatar-1.png');
  });

  test('round-trips local profile media paths', () {
    const path = '/documents/riksa-profile-media/user/avatar.jpg';

    expect(localProfileMediaPath(localProfileMediaValue(path)), path);
    expect(localProfileMediaPath('/avatars/avatar-1.png'), isNull);
  });

  testWidgets('renders a bundled Humation avatar without a network image', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: RiksaAvatarImage(
            value: '/avatars/avatar-1.png',
            label: 'Sophea',
            size: 72,
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('humation-avatar-avatar-01.svg')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
