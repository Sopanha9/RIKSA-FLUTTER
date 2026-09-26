import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riksa_app/core/theme/app_theme.dart';
import 'package:riksa_app/core/widgets/riksa_bottom_navigation_bar.dart';
import 'package:riksa_app/l10n/gen/app_localizations.dart';

import 'golden_fonts.dart';

void main() {
  setUpAll(loadRiksaGoldenFonts);
  for (final language in ['en', 'km']) {
    for (final dark in [false, true]) {
      for (final scale in [1.0, 2.0]) {
        final mode = dark ? 'dark' : 'light';
        final name = 'bottom_navigation_${language}_${mode}_$scale';
        testWidgets(name, (tester) async {
          tester.view.physicalSize = const Size(360, 400);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          await tester.pumpWidget(
            MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: dark ? AppTheme.dark : AppTheme.light,
              locale: Locale(language),
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: const [Locale('en'), Locale('km')],
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(scale),
                  disableAnimations: true,
                ),
                child: child!,
              ),
              home: Scaffold(
                bottomNavigationBar: RiksaBottomNavigationBar(
                  currentIndex: 3,
                  onSelected: (_) {},
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await expectLater(
            find.byType(RiksaBottomNavigationBar),
            matchesGoldenFile('goldens/$name.png'),
          );
        });
      }
    }
  }
}
