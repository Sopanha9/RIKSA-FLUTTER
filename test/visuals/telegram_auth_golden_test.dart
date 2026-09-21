import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riksa_app/features/auth/presentation/telegram_auth_screen.dart';

import '../features/auth/presentation/auth_journey_test.dart' as journey;

void main() {
  setUpAll(() async {
    final flutterRoot =
        Platform.environment['FLUTTER_ROOT'] ??
        File(
          Platform.resolvedExecutable,
        ).parent.parent.parent.parent.parent.path;
    await (FontLoader('MaterialIcons')..addFont(
          File(
            '$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
          ).readAsBytes().then(ByteData.sublistView),
        ))
        .load();
    for (final entry in {
      'Reddit Sans': 'assets/fonts/RedditSans-Variable.ttf',
      'Kantumruy Pro': 'assets/fonts/KantumruyPro-Variable.ttf',
      'Noto Sans Khmer': 'assets/fonts/NotoSansKhmer-Variable.ttf',
      'Koulen': 'assets/fonts/Koulen-Regular.ttf',
    }.entries) {
      await (FontLoader(
        entry.key,
      )..addFont(rootBundle.load(entry.value))).load();
    }
  });

  Future<void> mount(WidgetTester tester, String locale) async {
    tester.view.physicalSize = const Size(430, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await journey.mountAuth(
      tester,
      journey.AuthServer()
        ..statuses = [
          journey.pending,
          journey.pending,
          journey.profileRequired,
        ],
      locale: Locale(locale),
    );
    await tester.runAsync(() async {
      await precacheImage(
        const AssetImage('assets/images/logos/tglogo.png'),
        tester.element(find.byType(TelegramAuthScreen)),
      );
    });
    await tester.pumpAndSettle();
  }

  Future<void> expectGolden(WidgetTester tester, String name) => expectLater(
    find.byType(TelegramAuthScreen),
    matchesGoldenFile('goldens/$name.png'),
  );

  for (final locale in ['en', 'km']) {
    testWidgets('Telegram authorization steps $locale', (tester) async {
      await mount(tester, locale);
      await expectGolden(tester, 'telegram_auth_intro_${locale}_light');

      await journey.authorize(tester);
      await journey.pumpFor(tester, const Duration(milliseconds: 1200));
      await expectGolden(tester, 'telegram_auth_waiting_${locale}_light');

      await journey.pumpFor(tester, const Duration(seconds: 3));
      await tester.pumpAndSettle();
      await expectGolden(tester, 'telegram_auth_profile_${locale}_light');
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('Telegram code sign-in $locale', (tester) async {
      await mount(tester, locale);
      await journey.openCodeStep(tester);
      await tester.enterText(
        find.byKey(const Key('telegram_code_input')),
        'VE9BLZ8J',
      );
      await tester.pumpAndSettle();
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await expectGolden(tester, 'telegram_auth_code_${locale}_light');
    });
  }
}
