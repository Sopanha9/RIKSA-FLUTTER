import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:riksa_app/core/providers/locale_provider.dart';
import 'package:riksa_app/core/theme/app_theme.dart';
import 'package:riksa_app/features/auth/data/auth_models.dart';
import 'package:riksa_app/features/auth/data/onboarding_models.dart';
import 'package:riksa_app/features/auth/presentation/interactive_onboarding_screen.dart';
import 'package:riksa_app/features/auth/providers/auth_provider.dart';
import 'package:riksa_app/features/auth/providers/onboarding_provider.dart';
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
  _TestAuthNotifier([this._initialState = const Unauthenticated()]);

  final AuthState _initialState;
  int provinceSelectionSaveCount = 0;

  @override
  AuthState build() => _initialState;

  @override
  Future<bool> saveProvinceSelection(String provinceId) async {
    provinceSelectionSaveCount++;
    if (_initialState is Authenticated) return true;
    return super.saveProvinceSelection(provinceId);
  }
}

class _PreparedQuizNotifier extends OnboardingNotifier {
  @override
  OnboardingSetupData build() => const OnboardingSetupData(
    subject: OnboardingSubject.physics,
    quizAnswer1Index: 0,
  );
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
  _TestAuthNotifier Function()? authNotifierFactory,
  bool preparedQuiz = false,
}) {
  return ProviderScope(
    overrides: [
      localeProvider.overrideWith(() => _TestLocaleNotifier(locale)),
      authProvider.overrideWith(authNotifierFactory ?? _TestAuthNotifier.new),
      provinceOptionsProvider.overrideWith((ref) async => _testProvinces),
      if (preparedQuiz)
        onboardingProvider.overrideWith(_PreparedQuizNotifier.new),
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
    GoRoute(
      path: '/auth/login',
      builder: (_, _) => Scaffold(body: Text('Login route')),
    ),
  ],
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets(
    'subject, first question, province, then Start learning opens that subject',
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
      expect(find.text('1/4'), findsOneWidget);
      expect(find.text('Physics'), findsOneWidget);

      await tester.tap(find.text('Physics'));
      await tester.pumpAndSettle();

      // Picking a subject leads straight into one of its questions.
      expect(find.byKey(const ValueKey('first_question_step')), findsOneWidget);
      expect(find.text('2/4'), findsOneWidget);
      final continueButton = find.byKey(const Key('onboarding_continue_btn'));
      expect(tester.widget<FilledButton>(continueButton).onPressed, isNull);

      await tester.tap(find.text('F = m × a'));
      await tester.pumpAndSettle();
      expect(find.text("Yes! That's your first win."), findsWidgets);
      // The buddy's explanation is scrolled up from below the fold.
      final questionList = find.descendant(
        of: find.byKey(const ValueKey('first_question_step')),
        matching: find.byType(Scrollable),
      );
      expect(
        tester.state<ScrollableState>(questionList.first).position.pixels,
        greaterThan(0),
      );

      await tester.tap(continueButton);
      await tester.pumpAndSettle();

      expect(find.text('Which province are you representing?'), findsOneWidget);
      expect(find.text('3/4'), findsOneWidget);
      expect(tester.widget<FilledButton>(continueButton).onPressed, isNull);

      await tester.tap(find.text('Phnom Penh'));
      await tester.pumpAndSettle();
      expect(find.text('Representing Phnom Penh!'), findsOneWidget);

      await tester.tap(continueButton);
      await tester.pumpAndSettle();

      expect(find.text('Your Physics roadmap is ready'), findsOneWidget);
      expect(find.text('4/4'), findsOneWidget);
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

  testWidgets('saved province skips its step and is not overwritten', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    late _TestAuthNotifier authNotifier;
    final router = _onboardingRouter();
    addTearDown(router.dispose);
    await tester.pumpWidget(
      _buildApp(
        router: router,
        preparedQuiz: true,
        authNotifierFactory: () => authNotifier = _TestAuthNotifier(
          const Authenticated(
            AuthUser(
              id: 'returning-user',
              username: 'learner',
              displayName: 'Learner',
              emailVerified: true,
              phoneVerified: false,
              role: 'USER',
              provinceId: 'province-siem-reap',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final continueButton = find.byKey(const Key('onboarding_continue_btn'));
    await tester.tap(continueButton);
    await tester.pumpAndSettle();
    expect(find.text('2/3'), findsOneWidget);

    await tester.tap(continueButton);
    await tester.pumpAndSettle();
    expect(find.text('Which province are you representing?'), findsNothing);
    expect(find.text('Your Physics roadmap is ready'), findsOneWidget);
    expect(find.text('3/3'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('onboarding_start_learning')));
    await tester.pumpAndSettle();

    expect(authNotifier.provinceSelectionSaveCount, 0);
  });

  testWidgets('first onboarding page links returning learners to login', (
    tester,
  ) async {
    final router = _onboardingRouter();
    addTearDown(router.dispose);
    await tester.pumpWidget(_buildApp(router: router));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('onboarding_returning_account')),
    );
    await tester.pumpAndSettle();

    expect(router.routeInformationProvider.value.uri.path, '/auth/login');
    expect(
      router
          .routeInformationProvider
          .value
          .uri
          .queryParameters['onboardingReturning'],
      'true',
    );
  });

  testWidgets(
    'subject, first question and province fit Khmer at 200% text scale',
    (tester) async {
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

      // The returning-account link sits above the subjects, so at 200% text
      // the subject may start below the fold.
      final subject = find.text('រូបវិទ្យា');
      await tester.ensureVisible(subject);
      await tester.pumpAndSettle();
      await tester.tap(subject);
      await tester.pumpAndSettle();
      final answer = find.text('F = m × a');
      await tester.ensureVisible(answer);
      await tester.tap(answer);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final next = find.byKey(const Key('onboarding_continue_btn'));
      await tester.tap(next);
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
    },
  );
}
