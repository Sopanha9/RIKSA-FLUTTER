import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:riksa_app/core/providers/locale_provider.dart';
import 'package:riksa_app/core/theme/app_theme.dart';
import 'package:riksa_app/features/auth/data/auth_models.dart';
import 'package:riksa_app/features/auth/presentation/language_select_screen.dart';
import 'package:riksa_app/features/auth/presentation/onboarding_splash_screen.dart';
import 'package:riksa_app/features/auth/presentation/province_select_screen.dart';
import 'package:riksa_app/features/auth/providers/auth_provider.dart';
import 'package:riksa_app/l10n/gen/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _LocaleNotifier extends LocaleNotifier {
  @override
  LocaleState build() => const LocaleState(
    locale: Locale('en'),
    isReady: true,
    hasSelection: true,
  );
}

class _AuthNotifier extends AuthNotifier {
  @override
  AuthState build() => const Unauthenticated();
}

Widget _app(Widget child, {Locale locale = const Locale('en')}) {
  return ProviderScope(
    overrides: [
      localeProvider.overrideWith(_LocaleNotifier.new),
      authProvider.overrideWith(_AuthNotifier.new),
    ],
    child: MaterialApp(
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
}

const _provinces = [
  ProvinceOption(
    id: 'province-phnom-penh',
    nameKhmer: 'ភ្នំពេញ',
    nameLatin: 'Phnom Penh',
  ),
  ProvinceOption(
    id: 'province-siem-reap',
    nameKhmer: 'សៀមរាប',
    nameLatin: 'Siem Reap',
  ),
];

Widget _provinceApp() {
  final router = GoRouter(
    initialLocation: '/province-select',
    routes: [
      GoRoute(
        path: '/province-select',
        builder: (context, state) => const ProvinceSelectScreen(),
      ),
      GoRoute(
        path: '/auth/login',
        builder: (context, state) => const Scaffold(body: Text('Login route')),
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      localeProvider.overrideWith(_LocaleNotifier.new),
      authProvider.overrideWith(_AuthNotifier.new),
      provinceOptionsProvider.overrideWith((ref) async => _provinces),
    ],
    child: MaterialApp.router(
      theme: AppTheme.light,
      locale: const Locale('en'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('km')],
      routerConfig: router,
    ),
  );
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('language selection matches the compact first-run layout', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_app(const LanguageSelectScreen()));
    await tester.pump();

    expect(find.byKey(const Key('language_title')), findsOneWidget);
    expect(find.text('ខ្មែរ'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    expect(find.byKey(const Key('language_continue')), findsOneWidget);
  });

  testWidgets(
    'tells the community, learning and buddy story, then records viewing',
    (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var completed = false;

      await tester.pumpWidget(
        _app(OnboardingSplashScreen(onComplete: () => completed = true)),
      );
      await tester.pump();

      expect(find.byKey(const Key('intro_page_0')), findsOneWidget);
      expect(find.text('Your people are here'), findsOneWidget);
      expect(find.byKey(const Key('onboarding_skip')), findsOneWidget);

      await tester.tap(find.byKey(const Key('onboarding_continue')));
      await tester.pump();
      await tester.pump();
      expect(find.byKey(const Key('intro_page_1')), findsOneWidget);

      await tester.tap(find.byKey(const Key('onboarding_continue')));
      await tester.pump();
      await tester.pump();
      expect(find.byKey(const Key('intro_page_2')), findsOneWidget);
      expect(find.text('Get started'), findsOneWidget);

      await tester.tap(find.byKey(const Key('onboarding_continue')));
      await tester.pump();
      await tester.pump();

      expect(completed, isTrue);
      final preferences = await SharedPreferences.getInstance();
      expect(preferences.getBool('riksa_onboarding_viewed'), isTrue);
      expect(preferences.getBool('riksa_onboarding_completed'), isNot(true));

      // Let the buddies' reactions finish before the test tears down.
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 3));
    },
  );

  testWidgets('swiping the sheet turns the page', (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_app(const OnboardingSplashScreen()));
    await tester.pump();
    await tester.fling(
      find.byKey(const Key('intro_copy_0')),
      const Offset(-300, 0),
      1000,
    );
    await tester.pump();
    await tester.pump();
    expect(find.byKey(const Key('intro_page_1')), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('selected Khmer locale localizes the splash content', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(const OnboardingSplashScreen(), locale: const Locale('km')),
    );
    await tester.pump();

    expect(find.text('មិត្តភក្តិរបស់អ្នកនៅទីនេះ'), findsOneWidget);
    expect(find.textContaining('ចូលរួមសហគមន៍'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('province is queued locally before authentication', (
    tester,
  ) async {
    await tester.pumpWidget(_provinceApp());
    await tester.pumpAndSettle();

    expect(find.text('Select your province'), findsOneWidget);
    expect(find.text('Phnom Penh'), findsOneWidget);
    expect(find.text('ភ្នំពេញ'), findsOneWidget);

    await tester.tap(find.text('Phnom Penh'));
    await tester.pump();
    await tester.tap(find.byKey(const Key('province_continue')));
    await tester.pumpAndSettle();

    expect(find.text('Login route'), findsOneWidget);
    final preferences = await SharedPreferences.getInstance();
    expect(
      preferences.getString('riksa_pending_province_id'),
      'province-phnom-penh',
    );
    expect(preferences.getBool('riksa_onboarding_completed'), isNot(true));
  });
}
