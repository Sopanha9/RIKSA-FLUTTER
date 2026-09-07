import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riksa_app/features/auth/presentation/telegram_otp_screen.dart';

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
      'Poppins': 'assets/fonts/Poppins-Regular.ttf',
      'Kantumruy Pro': 'assets/fonts/KantumruyPro-Variable.ttf',
      'Noto Sans Khmer': 'assets/fonts/NotoSansKhmer-Variable.ttf',
      'Koulen': 'assets/fonts/Koulen-Regular.ttf',
    }.entries) {
      await (FontLoader(
        entry.key,
      )..addFont(rootBundle.load(entry.value))).load();
    }
  });

  for (final locale in ['en', 'km']) {
    testWidgets('Telegram verification $locale', (tester) async {
      tester.view.physicalSize = const Size(430, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await journey.mountAuth(
        tester,
        journey.AuthServer(),
        locale: Locale(locale),
      );
      await tester.runAsync(() async {
        await precacheImage(
          const AssetImage('assets/images/logos/tglogo.png'),
          tester.element(find.byType(TelegramOtpScreen)),
        );
      });
      await journey.sendCode(tester);
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(TelegramOtpScreen),
        matchesGoldenFile('goldens/telegram_otp_${locale}_light.png'),
      );
      await tester.pumpWidget(const SizedBox());
    });
  }
}
