import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riksa_app/core/theme/app_theme.dart';
import 'package:riksa_app/features/auth/presentation/onboarding_splash_screen.dart';
import 'package:riksa_app/features/auth/presentation/auth_switcher_screen.dart';
import 'package:riksa_app/features/auth/providers/auth_provider.dart';
import 'package:riksa_app/l10n/gen/app_localizations.dart';

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

  testWidgets('onboarding illustration sequence', (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_previewApp(const OnboardingSplashScreen()));
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
