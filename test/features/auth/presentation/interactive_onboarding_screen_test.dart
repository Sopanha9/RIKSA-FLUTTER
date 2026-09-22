import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:riksa_app/core/providers/locale_provider.dart';
import 'package:riksa_app/core/theme/app_theme.dart';
import 'package:riksa_app/features/auth/data/auth_models.dart';
import 'package:riksa_app/features/auth/presentation/interactive_onboarding_screen.dart';
import 'package:riksa_app/features/auth/presentation/auth_switcher_screen.dart';
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

Widget _buildInteractiveOnboardingApp({
  Locale locale = const Locale('en'),
  VoidCallback? onComplete,
}) {
  return ProviderScope(
    overrides: [
      localeProvider.overrideWith(() => _TestLocaleNotifier(locale)),
      authProvider.overrideWith(_TestAuthNotifier.new),
      provinceOptionsProvider.overrideWith((ref) async => _testProvinces),
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
      home: InteractiveOnboardingScreen(onComplete: onComplete),
    ),
  );
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('Sign up with Email opens the registration form', (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final router = GoRouter(
      initialLocation: '/onboarding/setup',
      routes: [
        GoRoute(
          path: '/onboarding/setup',
          builder: (_, _) => const InteractiveOnboardingScreen(),
        ),
        GoRoute(
          path: '/auth/login',
          builder: (_, _) => const AuthSwitcherScreen(),
        ),
        GoRoute(
          path: '/auth/register',
          builder: (_, _) =>
              const AuthSwitcherScreen(initialPage: PageState.register),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localeProvider.overrideWith(() => _TestLocaleNotifier()),
          authProvider.overrideWith(_TestAuthNotifier.new),
          provinceOptionsProvider.overrideWith((ref) async => _testProvinces),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          theme: AppTheme.light,
          locale: const Locale('en'),
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
        ),
      ),
    );
    await tester.pumpAndSettle();

    Future<void> next() async {
      await tester.tap(find.byKey(const Key('onboarding_continue_btn')));
      await tester.pumpAndSettle();
    }

    await tester.tap(find.text('BacII National Exam Prep'));
    await tester.pumpAndSettle();
    await next();
    await tester.tap(find.text('Mathematics'));
    await tester.pumpAndSettle();
    await next();
    await tester.tap(find.text('Phnom Penh'));
    await tester.pumpAndSettle();
    await next();
    await tester.tap(find.text('Regular'));
    await tester.pumpAndSettle();
    await next();
    await tester.tap(find.text('3'));
    await tester.pumpAndSettle();
    await next();
    await tester.tap(find.text('7'));
    await tester.pumpAndSettle();
    await next();

    await tester.ensureVisible(find.byKey(const Key('onboarding_save_email')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('onboarding_save_email')));
    await tester.pumpAndSettle();

    expect(router.routeInformationProvider.value.uri.path, '/auth/register');
    expect(find.byKey(const Key('register_email')), findsOneWidget);
  });

  testWidgets(
    'renders Step 1 (Goal) and disables continue until an option is selected',
    (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_buildInteractiveOnboardingApp());
      await tester.pumpAndSettle();

      expect(find.text('What is your learning goal?'), findsOneWidget);
      expect(find.text('BacII National Exam Prep'), findsOneWidget);
      expect(find.text('High School STEM Mastery'), findsOneWidget);
      expect(find.text('1/7'), findsOneWidget);

      final continueBtn = tester.widget<FilledButton>(
        find.byKey(const Key('onboarding_continue_btn')),
      );
      expect(continueBtn.onPressed, isNull);

      // Select BacII
      await tester.tap(find.text('BacII National Exam Prep'));
      await tester.pumpAndSettle();

      final continueBtnEnabled = tester.widget<FilledButton>(
        find.byKey(const Key('onboarding_continue_btn')),
      );
      expect(continueBtnEnabled.onPressed, isNotNull);
    },
  );

  testWidgets(
    'progresses through all 7 steps: setup, challenges, payoff & Telegram conversion',
    (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      var completed = false;
      await tester.pumpWidget(
        _buildInteractiveOnboardingApp(onComplete: () => completed = true),
      );
      await tester.pumpAndSettle();

      // Step 1: Select Goal
      await tester.tap(find.text('BacII National Exam Prep'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('onboarding_continue_btn')));
      await tester.pumpAndSettle();

      // Step 2: Select Subject
      expect(find.text('Pick your starting subject'), findsOneWidget);
      expect(find.text('Mathematics'), findsOneWidget);
      expect(find.text('2/7'), findsOneWidget);

      await tester.tap(find.text('Mathematics'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('onboarding_continue_btn')));
      await tester.pumpAndSettle();

      // Step 3: Select Province
      expect(find.text('Which province are you representing?'), findsOneWidget);
      expect(find.text('3/7'), findsOneWidget);
      expect(find.text('Phnom Penh'), findsOneWidget);

      await tester.tap(find.text('Phnom Penh'));
      await tester.pumpAndSettle();
      expect(find.text('Representing Phnom Penh!'), findsOneWidget);

      await tester.tap(find.byKey(const Key('onboarding_continue_btn')));
      await tester.pumpAndSettle();

      // Step 4: Select Daily Pace
      expect(find.text('Set your daily study pace'), findsOneWidget);
      expect(find.text('4/7'), findsOneWidget);
      expect(find.text('Regular'), findsOneWidget);

      await tester.tap(find.text('Regular'));
      await tester.pumpAndSettle();
      expect(find.text('Start Challenge'), findsOneWidget);
      await tester.tap(find.byKey(const Key('onboarding_continue_btn')));
      await tester.pumpAndSettle();

      // Step 5: Challenge Question 1
      expect(find.text('Mathematics · Challenge 1 of 2'), findsOneWidget);
      expect(find.text('5/7'), findsOneWidget);
      expect(
        find.text('What is the slope of the line given by y = 3x + 5?'),
        findsOneWidget,
      );
      expect(find.text('+10 XP'), findsOneWidget);

      // Tap correct answer '3'
      await tester.tap(find.text('3'));
      await tester.pumpAndSettle();

      // The buddy explains the answer
      expect(find.text('Croco'), findsOneWidget);
      expect(find.textContaining('Spot on! In y = mx + b'), findsOneWidget);
      expect(find.text('Next Challenge'), findsOneWidget);

      await tester.tap(find.byKey(const Key('onboarding_continue_btn')));
      await tester.pumpAndSettle();

      // Step 6: Challenge Question 2
      expect(find.text('Mathematics · Challenge 2 of 2'), findsOneWidget);
      expect(find.text('6/7'), findsOneWidget);
      expect(
        find.text('If 2x - 4 = 10, what is the value of x?'),
        findsOneWidget,
      );

      // Tap correct answer '7'
      await tester.tap(find.text('7'));
      await tester.pumpAndSettle();

      expect(find.text('Croco'), findsOneWidget);
      expect(find.textContaining('Brilliant algebra!'), findsOneWidget);
      expect(find.text('Claim Reward'), findsOneWidget);

      await tester.tap(find.byKey(const Key('onboarding_continue_btn')));
      await tester.pumpAndSettle();

      // Step 7: Payoff & Conversion Screen
      expect(find.text('Day 1 streak started!'), findsOneWidget);
      expect(find.text('+20'), findsOneWidget);
      expect(find.text('Phnom Penh'), findsOneWidget);
      expect(find.text('Save your streak & progress'), findsOneWidget);
      expect(find.byKey(const Key('onboarding_save_telegram')), findsOneWidget);
      expect(find.byKey(const Key('onboarding_save_google')), findsOneWidget);
      expect(find.byKey(const Key('onboarding_save_email')), findsOneWidget);
      // The test font is much larger than the app's, so the last link sits
      // below the fold here.
      await tester.scrollUntilVisible(
        find.byKey(const Key('onboarding_login_link')),
        100,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.byKey(const Key('onboarding_login_link')), findsOneWidget);

      // Tap Save with Telegram
      await tester.ensureVisible(
        find.byKey(const Key('onboarding_save_telegram')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('onboarding_save_telegram')));
      await tester.pumpAndSettle();

      expect(completed, isTrue);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('riksa_onboarding_goal'), 'BAC_II');
      expect(prefs.getString('riksa_onboarding_subject'), 'MATHEMATICS');
      expect(prefs.getInt('riksa_onboarding_pace'), 10);
      expect(prefs.getInt('riksa_onboarding_earned_xp'), 20);
      expect(
        prefs.getString('riksa_pending_province_id'),
        'province-phnom-penh',
      );
    },
  );

  testWidgets('warm-up questions follow the chosen subject', (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_buildInteractiveOnboardingApp());
    await tester.pumpAndSettle();
    Future<void> next() async {
      await tester.tap(find.byKey(const Key('onboarding_continue_btn')));
      await tester.pumpAndSettle();
    }

    await tester.tap(find.text('BacII National Exam Prep'));
    await tester.pumpAndSettle();
    await next();
    await tester.tap(find.text('Physics'));
    await tester.pumpAndSettle();
    await next();
    await tester.tap(find.text('Phnom Penh'));
    await tester.pumpAndSettle();
    await next();
    await tester.tap(find.text('Regular'));
    await tester.pumpAndSettle();
    await next();

    expect(find.text('Physics · Challenge 1 of 2'), findsOneWidget);
    expect(find.textContaining("Newton's Second Law"), findsOneWidget);

    // Answer, then go back and switch to Chemistry: its questions start fresh.
    await tester.tap(find.text('F = m / a'));
    await tester.pumpAndSettle();
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text('Chemistry'));
    await tester.pumpAndSettle();
    await next();
    await next();
    await next();

    expect(find.text('Chemistry · Challenge 1 of 2'), findsOneWidget);
    expect(
      find.text('What is the chemical formula for water?'),
      findsOneWidget,
    );
    expect(find.text('Croco'), findsNothing);
    final continueBtn = tester.widget<FilledButton>(
      find.byKey(const Key('onboarding_continue_btn')),
    );
    expect(continueBtn.onPressed, isNull);
  });

  testWidgets('Khmer locale properly localizes all questions and cards', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _buildInteractiveOnboardingApp(locale: const Locale('km')),
    );
    await tester.pumpAndSettle();

    expect(find.text('តើអ្នកចង់សម្រេចគោលដៅអ្វី?'), findsOneWidget);
    expect(find.text('ត្រៀមប្រឡងបាក់ឌុប (ថ្នាក់ទី១២)'), findsOneWidget);
    expect(find.text('បន្ត'), findsOneWidget);
  });
}
