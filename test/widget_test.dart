import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riksa_app/app/router/app_router.dart';
import 'package:riksa_app/core/providers/locale_provider.dart';
import 'package:riksa_app/features/auth/presentation/login_screen.dart';
import 'package:riksa_app/features/auth/presentation/register_screen.dart';
import 'package:riksa_app/features/auth/providers/auth_provider.dart';
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

  testWidgets('login renders stable inline validation errors', (tester) async {
    await tester.pumpWidget(_testApp(const LoginScreen()));
    await tester.ensureVisible(find.byKey(const Key('login_submit')));
    await tester.tap(find.byKey(const Key('login_submit')));
    await tester.pump();

    expect(find.text('This field is required'), findsNWidgets(2));
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
