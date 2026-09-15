import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riksa_app/core/providers/locale_provider.dart';
import 'package:riksa_app/core/theme/app_theme.dart';
import 'package:riksa_app/features/auth/presentation/language_select_screen.dart';
import 'package:riksa_app/features/auth/presentation/onboarding_splash_screen.dart';
import 'package:riksa_app/features/auth/presentation/splash_animation_screen.dart';
import 'package:riksa_app/features/auth/providers/auth_provider.dart';
import 'package:riksa_app/l10n/gen/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'golden_fonts.dart';

class _NewLearnerLocale extends LocaleNotifier {
  @override
  LocaleState build() =>
      const LocaleState(
        locale: Locale('en'),
        isReady: true,
        hasSelection: false,
      );
}

class _SignedOut extends AuthNotifier {
  @override
  AuthState build() => const Unauthenticated();
}

Widget _app(Widget child, {Locale locale = const Locale('en')}) =>
    ProviderScope(
      overrides: [
        localeProvider.overrideWith(_NewLearnerLocale.new),
        authProvider.overrideWith(_SignedOut.new),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        locale: locale,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child!,
        ),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en'), Locale('km')],
        home: child,
      ),
    );

void main() {
  setUpAll(loadRiksaGoldenFonts);
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> phone(WidgetTester tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  testWidgets('welcome splash', (tester) async {
    await phone(tester);
    await tester.pumpWidget(_app(const SplashAnimationScreen()));
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(seconds: 1));
    expect(find.byKey(const Key('splash_get_started')), findsOneWidget);
    await expectLater(
      find.byType(SplashAnimationScreen),
      matchesGoldenFile('goldens/first_run_splash_en_light.png'),
    );
  });

  for (final locale in ['en', 'km']) {
    testWidgets('onboarding $locale', (tester) async {
      await phone(tester);
      await tester.pumpWidget(
        _app(const OnboardingSplashScreen(), locale: Locale(locale)),
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(OnboardingSplashScreen),
        matchesGoldenFile('goldens/first_run_onboarding_${locale}_light.png'),
      );
    });
  }

  testWidgets('language select', (tester) async {
    await phone(tester);
    await tester.pumpWidget(_app(const LanguageSelectScreen()));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(LanguageSelectScreen),
      matchesGoldenFile('goldens/first_run_language_en_light.png'),
    );
  });
}
