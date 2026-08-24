import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:riksa_app/app/router/app_router.dart';
import 'package:riksa_app/core/providers/locale_provider.dart';
import 'package:riksa_app/core/theme/app_theme.dart';
import 'package:riksa_app/core/widgets/language_toggle.dart';
import 'package:riksa_app/features/auth/presentation/login_screen.dart';
import 'package:riksa_app/features/auth/presentation/register_screen.dart';
import 'package:riksa_app/features/auth/presentation/auth_switcher_screen.dart';
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

  test('authenticated destinations live in one five-branch shell', () {
    final container = ProviderContainer(
      overrides: [authProvider.overrideWith(_AuthenticatedAuthNotifier.new)],
    );
    addTearDown(container.dispose);

    final router = container.read(goRouterProvider);
    final shell = router.configuration.routes
        .whereType<StatefulShellRoute>()
        .single;

    expect(shell.branches, hasLength(5));
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

  testWidgets('auth top bar does not repeat language selection', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp(const LoginScreen()));
    await tester.pump();

    expect(find.byType(LanguageToggle), findsNothing);
  });

  testWidgets('login card is vertically centered when it fits', (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(_testApp(const LoginScreen()));
    await tester.pump();

    expect(tester.getCenter(find.byType(AuthPanel)).dy, closeTo(600, 1));
  });

  testWidgets('auth submission shows a dedicated loading process', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp(const LoginScreen()));
    final container = ProviderScope.containerOf(
      tester.element(find.byType(AuthSwitcherScreen)),
    );

    (container.read(authProvider.notifier) as _TestAuthNotifier).emit(
      const AuthLoading(),
    );
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byKey(const Key('auth_loading_overlay')), findsOneWidget);
    expect(find.text('Preparing your space'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsWidgets);
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

  testWidgets('registration renders all four requested fields', (tester) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(_testApp(const RegisterScreen()));

    expect(find.byKey(const Key('register_username')), findsOneWidget);
    expect(find.byKey(const Key('register_email')), findsOneWidget);
    expect(find.byKey(const Key('register_password')), findsOneWidget);
    expect(find.byKey(const Key('register_confirm_password')), findsOneWidget);
    expect(find.byKey(const Key('register_submit')), findsOneWidget);
  });

  testWidgets('registration shows password requirements as inline error', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(_testApp(const RegisterScreen()));

    await tester.enterText(find.byKey(const Key('register_password')), 'weak');
    await tester.pump();

    expect(
      find.text('Password must be 8+ chars with upper, lower, and digit'),
      findsOneWidget,
    );

    await tester.enterText(
      find.byKey(const Key('register_password')),
      'StrongPass1',
    );
    await tester.pump();

    expect(
      find.text('Password must be 8+ chars with upper, lower, and digit'),
      findsNothing,
    );
  });

  testWidgets('auth switcher preserves each form values', (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(_testApp(const AuthSwitcherScreen()));

    await tester.enterText(
      find.byKey(const Key('login_username')),
      'sophea@example.com',
    );
    await tester.tap(find.byKey(const Key('register_toggle')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('register_username')),
      'sophea',
    );
    await tester.tap(find.byKey(const Key('login_toggle')));
    await tester.pumpAndSettle();

    expect(find.text('sophea@example.com'), findsOneWidget);

    await tester.tap(find.byKey(const Key('register_toggle')));
    await tester.pumpAndSettle();
    expect(find.text('sophea'), findsOneWidget);
  });

  testWidgets('auth switcher ignores rapid second toggle tap', (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(_testApp(const AuthSwitcherScreen()));

    await tester.tap(find.byKey(const Key('register_toggle')));
    await tester.tap(find.byKey(const Key('login_toggle')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('register_username')), findsOneWidget);
    expect(find.byKey(const Key('login_username')), findsNothing);
  });
}
