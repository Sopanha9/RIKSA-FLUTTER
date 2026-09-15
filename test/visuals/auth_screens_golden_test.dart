import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riksa_app/core/theme/app_theme.dart';
import 'package:riksa_app/features/auth/data/auth_api.dart';
import 'package:riksa_app/features/auth/presentation/account_recovery_screen.dart';
import 'package:riksa_app/features/auth/presentation/onboarding_splash_screen.dart';
import 'package:riksa_app/features/auth/presentation/auth_switcher_screen.dart';
import 'package:riksa_app/features/auth/providers/auth_provider.dart';
import 'package:riksa_app/l10n/gen/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _loadFonts() async {
  final poppins = FontLoader(RiksaTypography.latinFamily);
  for (final name in [
    'Light',
    'Regular',
    'Medium',
    'SemiBold',
    'Bold',
    'ExtraBold',
    'Black',
  ]) {
    poppins.addFont(rootBundle.load('assets/fonts/Poppins-$name.ttf'));
  }
  final khmer = FontLoader(RiksaTypography.khmerFamily)
    ..addFont(rootBundle.load('assets/fonts/NotoSansKhmer-Variable.ttf'));
  final configuredRoot = Platform.environment['FLUTTER_ROOT'];
  final flutterRoot =
      configuredRoot ??
      File(Platform.resolvedExecutable).parent.parent.parent.parent.parent.path;
  final materialIcons = FontLoader('MaterialIcons')
    ..addFont(
      File(
        '$flutterRoot/bin/cache/artifacts/material_fonts/'
        'MaterialIcons-Regular.otf',
      ).readAsBytes().then(ByteData.sublistView),
    );
  await Future.wait([poppins.load(), khmer.load(), materialIcons.load()]);
}

class _PreviewAuthNotifier extends AuthNotifier {
  @override
  AuthState build() => const Unauthenticated();
}

/// Sends the code, then turns the new password down the way the server does.
class _RejectingAuthApi extends Fake implements AuthApi {
  @override
  Future<String> forgotPassword(String identifier) async => 'sent';

  @override
  Future<String> resetPassword({
    required String identifier,
    required String code,
    required String newPassword,
  }) async => throw AuthFailure(
    'newPassword: Password must be at least 8 characters with uppercase, '
    'lowercase, and a digit',
    statusCode: 400,
    kind: AuthFailureKind.validation,
  );
}

Widget _previewApp(
  Widget home, {
  ThemeData? theme,
  Locale locale = const Locale('en'),
}) => ProviderScope(
  overrides: [authProvider.overrideWith(_PreviewAuthNotifier.new)],
  child: MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: theme ?? AppTheme.light,
    locale: locale,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const [Locale('en'), Locale('km')],
    home: home,
  ),
);

void main() {
  setUpAll(_loadFonts);
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('compact login design', (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_previewApp(const AuthSwitcherScreen()));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle(const Duration(milliseconds: 50));

    expect(find.byKey(const Key('auth_supporting_panel')), findsNothing);
    await expectLater(
      find.byType(AuthSwitcherScreen),
      matchesGoldenFile('goldens/auth_login_compact_en_light.png'),
    );
  });

  testWidgets('wide registration design', (tester) async {
    tester.view.physicalSize = const Size(1366, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _previewApp(const AuthSwitcherScreen(initialPage: PageState.register)),
    );
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle(const Duration(milliseconds: 50));

    expect(find.byKey(const Key('auth_supporting_panel')), findsNothing);
    await expectLater(
      find.byType(AuthSwitcherScreen),
      matchesGoldenFile('goldens/auth_register_wide_en_light.png'),
    );
  });

  testWidgets('compact Khmer login in dark mode', (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _previewApp(
        const AuthSwitcherScreen(),
        theme: AppTheme.dark,
        locale: const Locale('km'),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle(const Duration(milliseconds: 50));

    expect(tester.takeException(), isNull);
    await expectLater(
      find.byType(AuthSwitcherScreen),
      matchesGoldenFile('goldens/auth_login_compact_km_dark.png'),
    );
  });

  for (final dark in [false, true]) {
    final mode = dark ? 'dark' : 'light';
    testWidgets('password reset step with a friendly error ($mode)', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(405, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith(_PreviewAuthNotifier.new),
            authApiProvider.overrideWithValue(_RejectingAuthApi()),
          ],
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: dark ? AppTheme.dark : AppTheme.light,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: true),
              child: child!,
            ),
            home: const AccountRecoveryScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('recovery-identifier')),
        'sopheak',
      );
      await tester.tap(find.byKey(const ValueKey('recovery-continue')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('recovery-code')),
        '123456',
      );
      await tester.tap(find.byKey(const ValueKey('recovery-continue')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('recovery-password')),
        'riksa2026',
      );
      await tester.enterText(
        find.byKey(const ValueKey('recovery-confirm')),
        'riksa2026',
      );
      await tester.tap(find.byKey(const ValueKey('recovery-continue')));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      // Missing a capital letter: caught before the server, in plain words.
      expect(find.textContaining('AuthFailure'), findsNothing);
      expect(find.byKey(const ValueKey('recovery-error')), findsOneWidget);
      await expectLater(
        find.byType(AccountRecoveryScreen),
        matchesGoldenFile('goldens/account_recovery_password_$mode.png'),
      );
    });
  }

  testWidgets('onboarding illustration sequence', (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // The subject bubbles float forever; still them so the frame settles.
    await tester.pumpWidget(
      _previewApp(
        Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: const OnboardingSplashScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    await expectLater(
      find.byType(OnboardingSplashScreen),
      matchesGoldenFile('goldens/onboarding_learning_en_light.png'),
    );

    await tester.drag(
      find.byKey(const Key('onboarding_pages')),
      const Offset(-360, 0),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(OnboardingSplashScreen),
      matchesGoldenFile('goldens/onboarding_achievement_en_light.png'),
    );

    await tester.drag(
      find.byKey(const Key('onboarding_pages')),
      const Offset(-360, 0),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(OnboardingSplashScreen),
      matchesGoldenFile('goldens/onboarding_community_en_light.png'),
    );
  });
}
