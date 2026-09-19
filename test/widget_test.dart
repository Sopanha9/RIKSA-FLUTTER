import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:riksa_app/app/router/app_router.dart';
import 'package:riksa_app/core/providers/locale_provider.dart';
import 'package:riksa_app/core/theme/app_theme.dart';
import 'package:riksa_app/features/auth/presentation/login_screen.dart';
import 'package:riksa_app/features/auth/presentation/register_screen.dart';
import 'package:riksa_app/features/auth/presentation/splash_animation_screen.dart';
import 'package:riksa_app/features/auth/data/auth_models.dart';
import 'package:riksa_app/features/auth/providers/auth_provider.dart';
import 'package:riksa_app/features/auth/widgets/auth_scaffold.dart';
import 'package:riksa_app/l10n/gen/app_localizations.dart';

class _TestAuthNotifier extends AuthNotifier {
  @override
  AuthState build() => const Unauthenticated();

  void emit(AuthState next) => state = next;
}

class _TestLocaleNotifier extends LocaleNotifier {
  @override
  LocaleState build() => const LocaleState(
    locale: Locale('en'),
    isReady: true,
    hasSelection: true,
  );
}

class _UnavailableAuthNotifier extends AuthNotifier {
  @override
  AuthState build() => const AuthUnavailable('Service unavailable');
}

class _AuthenticatedAuthNotifier extends AuthNotifier {
  @override
  AuthState build() => Authenticated(
    AuthUser(
      id: 'user-1',
      username: 'sophea',
      displayName: 'Sok Sophea',
      email: 'sophea@example.com',
      emailVerified: true,
      phoneVerified: false,
      role: 'USER',
      createdAt: DateTime.utc(2026),
    ),
  );
}

Widget _testApp(Widget child) {
  return ProviderScope(
    overrides: [
      authProvider.overrideWith(_TestAuthNotifier.new),
      localeProvider.overrideWith(_TestLocaleNotifier.new),
    ],
    child: MaterialApp(
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

void main() {
  for (final height in [844.0, 800.0]) {
    testWidgets('registration error fits a 390 x $height phone', (
      tester,
    ) async {
      tester.view.physicalSize = Size(390, height);
      tester.view.devicePixelRatio = 1;
      tester.view.padding = const FakeViewPadding(top: 24, bottom: 34);
      tester.view.viewPadding = const FakeViewPadding(top: 24, bottom: 34);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPadding);
      addTearDown(tester.view.resetViewPadding);
      await tester.pumpWidget(_testApp(const RegisterScreen()));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('register_username')),
        'sophea',
      );
      await tester.enterText(
        find.byKey(const Key('register_display_name')),
        'Sok Sophea',
      );
      await tester.enterText(
        find.byKey(const Key('register_email')),
        'sophea@example.com',
      );
      await tester.tap(find.byKey(const Key('register_continue')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('register_password')),
        'Example123',
      );
      await tester.enterText(
        find.byKey(const Key('register_confirm_password')),
        'Example123',
      );
      FocusManager.instance.primaryFocus?.unfocus();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(RegisterScreen)),
      );
      (container.read(authProvider.notifier) as _TestAuthNotifier).emit(
        const AuthError('Email is already taken'),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      final error = find.descendant(
        of: find.byType(AuthErrorText),
        matching: find.byType(Text),
      );
      expect(tester.widget<Text>(error).style!.color, const Color(0xFFB3261E));
      expect(
        find.descendant(
          of: find.byType(AuthErrorText),
          matching: find.byType(Container),
        ),
        findsNothing,
      );
      for (final key in [
        'register_submit',
        'google_auth_button',
        'telegram_auth_button',
      ]) {
        final control = find.byKey(Key(key));
        expect(control.hitTestable(), findsOneWidget);
        expect(tester.getRect(control).bottom, lessThanOrEqualTo(height - 34));
      }
      expect(
        tester.getRect(find.text('Sign in')).bottom,
        lessThanOrEqualTo(height - 34),
      );
      expect(find.byType(FittedBox), findsNothing);
      expect(find.byType(SingleChildScrollView), findsNothing);
    });
  }

  for (final registration in [false, true]) {
    testWidgets(
      'browser keyboard resize preserves ${registration ? 'registration' : 'login'} geometry',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          _testApp(registration ? const RegisterScreen() : const LoginScreen()),
        );
        await tester.pumpAndSettle();
        final username = find.byKey(
          Key(registration ? 'register_username' : 'login_username'),
        );
        final google = find.byKey(const Key('google_auth_button'));
        final fieldBefore = tester.getRect(username);
        final socialBefore = tester.getRect(google);
        await tester.tap(username);
        await tester.pumpAndSettle();

        // Firefox/mobile emulators can reduce the actual viewport with zero
        // viewInsets. This is different from the native keyboard inset test.
        tester.view.physicalSize = const Size(390, 500);
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(tester.getRect(username), fieldBefore);
        expect(tester.getRect(google), socialBefore);
        expect(find.byType(FittedBox), findsNothing);
        expect(find.byType(SingleChildScrollView), findsNothing);

        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        tester.view.physicalSize = const Size(390, 844);
        await tester.pumpAndSettle();
        expect(tester.getRect(username), fieldBefore);
        expect(tester.getRect(google), socialBefore);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('keyboard does not scale or hide the login layout', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);

    await tester.pumpWidget(_testApp(const LoginScreen()));
    await tester.pumpAndSettle();
    final username = find.byKey(const Key('login_username'));
    final before = tester.getRect(username);

    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    await tester.pumpAndSettle();

    expect(tester.getRect(username), before);
    expect(find.byType(FittedBox), findsNothing);
    expect(find.byType(SingleChildScrollView), findsNothing);
    expect(find.text('Riksa'), findsOneWidget);
    expect(find.byKey(const Key('google_auth_button')), findsOneWidget);
    expect(find.byKey(const Key('telegram_auth_button')), findsOneWidget);
    expect(find.text("Don't have an account?"), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('router instance stays stable across auth state changes', () {
    final container = ProviderContainer(
      overrides: [authProvider.overrideWith(_TestAuthNotifier.new)],
    );
    addTearDown(container.dispose);

    final first = container.read(goRouterProvider);
    (container.read(authProvider.notifier) as _TestAuthNotifier).emit(
      const AuthLoading(),
    );
    final second = container.read(goRouterProvider);

    expect(identical(first, second), isTrue);
  });

  test('root path has a safe redirect route', () {
    final container = ProviderContainer(
      overrides: [authProvider.overrideWith(_AuthenticatedAuthNotifier.new)],
    );
    addTearDown(container.dispose);

    final router = container.read(goRouterProvider);
    final rootRoute = router.configuration.routes
        .whereType<GoRoute>()
        .singleWhere((route) => route.path == '/');

    expect(rootRoute.redirect, isNotNull);
  });

  testWidgets('login renders stable inline validation errors', (tester) async {
    await tester.pumpWidget(_testApp(const LoginScreen()));
    await tester.ensureVisible(find.byKey(const Key('login_submit')));
    await tester.tap(find.byKey(const Key('login_submit')));
    await tester.pump();

    expect(find.text('This field is required'), findsNWidgets(2));
  });

  testWidgets('login exposes Google and Telegram fast auth', (tester) async {
    await tester.pumpWidget(_testApp(const LoginScreen()));
    await tester.pump();

    expect(find.byKey(const Key('google_auth_button')), findsOneWidget);
    expect(find.byKey(const Key('telegram_auth_button')), findsOneWidget);
  });

  testWidgets('splash offline actions have finite button constraints', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith(_UnavailableAuthNotifier.new),
          localeProvider.overrideWith(_TestLocaleNotifier.new),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en'), Locale('km')],
          home: const SplashAnimationScreen(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 1500));

    expect(tester.takeException(), isNull);
    expect(find.byType(FilledButton), findsOneWidget);
  });

  testWidgets('registration moves from basics to password step', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(_testApp(const RegisterScreen()));
    await tester.enterText(
      find.byKey(const Key('register_username')),
      'sophea',
    );
    await tester.enterText(
      find.byKey(const Key('register_display_name')),
      'Sok Sophea',
    );
    await tester.enterText(
      find.byKey(const Key('register_email')),
      'sophea@example.com',
    );
    await tester.ensureVisible(find.byKey(const Key('register_continue')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('register_continue')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('register_password')), findsOneWidget);
    expect(find.byKey(const Key('register_confirm_password')), findsOneWidget);
    expect(find.text('Step 2 of 2'), findsOneWidget);
  });
}
