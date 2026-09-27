import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riksa_app/core/theme/app_theme.dart';
import 'package:riksa_app/features/social/data/social_models.dart';
import 'package:riksa_app/features/social/presentation/widgets/social_post_media_grid.dart';
import 'package:riksa_app/l10n/gen/app_localizations.dart';

void main() {
  for (final dark in [false, true]) {
    for (var count = 1; count <= 4; count++) {
      testWidgets(
        '$count-photo layout matches the ${dark ? 'dark' : 'light'} golden',
        (tester) async {
          await _pumpGrid(tester, count, dark: dark);
          if (count == 1) {
            expect(
              find.byKey(ValueKey('media-grid-post-$count')),
              findsOneWidget,
            );
          }
          for (var index = 0; index < count; index++) {
            final key = count == 1
                ? ValueKey('media-grid-post-$count')
                : ValueKey('media-grid-post-$count-$index');
            expect(find.byKey(key), findsOneWidget);
          }
          expect(tester.takeException(), isNull);
          await expectLater(
            find.byType(MaterialApp),
            matchesGoldenFile(
              '../../../../visuals/goldens/social_post_media_${count}_${dark ? 'dark' : 'light'}.png',
            ),
          );
        },
      );
    }
  }

  testWidgets('tapping photo three opens the viewer on page three', (
    tester,
  ) async {
    await _pumpGrid(tester, 4, dark: false, keyPrefix: 'post-feed-photo');

    await tester.tap(find.byKey(const ValueKey('post-feed-photo-post-4-2')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('photo-viewer-page-indicator')),
      findsOneWidget,
    );
    expect(find.text('3 / 4'), findsOneWidget);
    final viewer = tester.widget<InteractiveViewer>(
      find.byType(InteractiveViewer).last,
    );
    final zoomTarget = find.byType(InteractiveViewer).last;
    await tester.tap(zoomTarget);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(zoomTarget);
    await tester.pump();
    expect(
      viewer.transformationController!.value.getMaxScaleOnAxis(),
      greaterThan(1),
    );

    await tester.fling(find.byType(PageView), const Offset(-320, 0), 700);
    await tester.pumpAndSettle();
    expect(find.text('4 / 4'), findsOneWidget);
    final nextPage = tester.widget<InteractiveViewer>(
      find.byType(InteractiveViewer).last,
    );
    expect(nextPage.transformationController!.value.getMaxScaleOnAxis(), 1);
  });
}

Future<void> _pumpGrid(
  WidgetTester tester,
  int count, {
  required bool dark,
  String keyPrefix = 'media-grid',
}) async {
  tester.view.physicalSize = const Size(400, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      theme: dark ? AppTheme.dark : AppTheme.light,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('km')],
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 360,
            child: SocialPostMediaGrid(
              postId: 'post-$count',
              media: [
                for (var index = 0; index < count; index++)
                  SocialPostMedia(
                    url: 'https://example.org/photo-$index.png',
                    width: index == 0 ? 600 : null,
                    height: index == 0 ? 800 : null,
                  ),
              ],
              keyPrefix: keyPrefix,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}
