import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riksa_app/core/theme/app_theme.dart';
import 'package:riksa_app/features/social/presentation/widgets/post_photo.dart';

void main() {
  test('photo aspect ratios stay between portrait and landscape bounds', () {
    expect(clampPostPhotoAspectRatio(2 / 3), 4 / 5);
    expect(clampPostPhotoAspectRatio(1), 1);
    expect(clampPostPhotoAspectRatio(2.2), 16 / 9);
  });

  testWidgets('portrait photos use a portrait placeholder, not 16:9', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 320,
              child: const PostPhoto(
                url: 'https://example.org/portrait.png',
                aspectRatio: 2 / 3,
              ),
            ),
          ),
        ),
      ),
    );

    final photo = tester.getSize(
      find.byKey(const ValueKey('post-photo-https://example.org/portrait.png')),
    );
    expect(photo.width / photo.height, closeTo(4 / 5, .001));
    expect(tester.takeException(), isNull);
  });
}
