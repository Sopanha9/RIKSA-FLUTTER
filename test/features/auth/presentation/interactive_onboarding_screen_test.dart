import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:riksa_app/core/providers/locale_provider.dart';
import 'package:riksa_app/core/theme/app_theme.dart';
import 'package:riksa_app/features/auth/data/auth_models.dart';
import 'package:riksa_app/features/auth/presentation/interactive_onboarding_screen.dart';
import 'package:riksa_app/features/auth/providers/auth_provider.dart';
import 'package:riksa_app/l10n/gen/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _TestLocaleNotifier extends LocaleNotifier {
  _TestLocaleNotifier([this._initialLocale = const Locale('en')]);
  final Locale _initialLocale;

  @override
  LocaleState build() =>
      LocaleState(locale: _initialLocale, isReady: true, hasSelection: true);
}

class _TestAuthNotifier extends AuthNotifier {
  @override
  AuthState build() => const Unauthenticated();
}

const _testProvinces = [
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

Widget _buildApp({
  Locale locale = const Locale('en'),
  double textScale = 1,
  required GoRouter router,
}) {
  return ProviderScope(
    overrides: [
      localeProvider.overrideWith(() => _TestLocaleNotifier(locale)),
      authProvider.overrideWith(_TestAuthNotifier.new),
      provinceOptionsProvider.overrideWith((ref) async => _testProvinces),
    ],
    child: MaterialApp.router(
      routerConfig: router,
      theme: AppTheme.light,
      locale: locale,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          disableAnimations: true,
          textScaler: TextScaler.linear(textScale),
        ),
        child: child!,
      ),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('km')],
    ),
  );
}

GoRouter _onboardingRouter() => GoRouter(
  initialLocation: '/onboarding/setup',
  routes: [
    GoRoute(
      path: '/onboarding/setup',
      builder: (_, _) => const InteractiveOnboardingScreen(),
    ),
    GoRoute(
      path: '/learn',
      builder: (_, _) => const Scaffold(body: Text('Learn destination')),
      routes: [
        GoRoute(
          path: 'subject/:subjectId',
          builder: (_, state) => Scaffold(
            body: Text('Subject ${state.pathParameters['subjectId']}'),
          ),
        ),
      ],
    ),
  ],
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets(
    'subject, then province, then Start learning opens that subject',
    (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final router = _onboardingRouter();
      addTearDown(router.dispose);
      await tester.pumpWidget(_buildApp(router: router));
      await tester.pumpAndSettle();

      expect(find.text('Pick your starting subject'), findsOneWidget);
      expect(find.text('1/3'), findsOneWidget);
      expect(find.text('Physics'), findsOneWidget);

      await tester.tap(find.text('Physics'));
      await tester.pumpAndSettle();

      expect(find.text('Which province are you representing?'), findsOneWidget);
      expect(find.text('2/3'), findsOneWidget);
      final continueButton = find.byKey(const Key('onboarding_continue_btn'));
      expect(tester.widget<FilledButton>(continueButton).onPressed, isNull);

      await tester.tap(find.text('Phnom Penh'));
      await tester.pumpAndSettle();
      expect(find.text('Representing Phnom Penh!'), findsOneWidget);

      await tester.tap(continueButton);
      await tester.pumpAndSettle();

      expect(find.text('Your Physics roadmap is ready'), findsOneWidget);
      expect(find.text('3/3'), findsOneWidget);
      expect(find.text('Start learning'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('onboarding_start_learning')));
      await tester.pumpAndSettle();

      expect(
        router.routeInformationProvider.value.uri.path,
        '/learn/subject/PHYSICS',
      );
      expect(find.text('Subject PHYSICS'), findsOneWidget);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('riksa_onboarding_subject'), 'PHYSICS');
      expect(prefs.getBool('riksa_onboarding_viewed'), isTrue);
      // A guest's squad waits for sign-in to reach their profile.
      expect(
        prefs.getString('riksa_pending_province_id'),
        'province-phnom-penh',
      );
      expect(prefs.getInt('riksa_onboarding_earned_xp'), isNull);
    },
  );

  testWidgets('subject and province fit Khmer at 200% text scale', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final router = _onboardingRouter();
    addTearDown(router.dispose);
    await tester.pumpWidget(
      _buildApp(router: router, locale: const Locale('km'), textScale: 2),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('រូបវិទ្យា'));
    await tester.pumpAndSettle();
    final province = find.text('ភ្នំពេញ');
    await tester.scrollUntilVisible(
      province,
      80,
      // At 200% the province list starts below the fold in the step's own
      // scroll view.
      scrollable: find
          .descendant(
            of: find.byType(CustomScrollView).last,
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(tester.takeException(), isNull);

    await tester.tap(province);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
