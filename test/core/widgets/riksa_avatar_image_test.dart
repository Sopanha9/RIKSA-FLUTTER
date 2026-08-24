import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riksa_app/core/widgets/riksa_avatar_image.dart';

void main() {
  test('maps stored Humation avatar values to bundled assets', () {
    expect(humationAvatarValue(0), '/avatars/humation/avatar-01.svg');
    expect(
      humationAvatarAssetPath('/avatars/humation/avatar-24.svg'),
      'assets/images/avatars/humation/avatar-24.svg',
    );
    expect(humationAvatarAssetPath('/avatars/humation/avatar-25.svg'), isNull);
    expect(() => humationAvatarValue(24), throwsRangeError);
  });

  testWidgets('renders a bundled Humation avatar without a network image', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: RiksaAvatarImage(
            value: '/avatars/humation/avatar-01.svg',
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
