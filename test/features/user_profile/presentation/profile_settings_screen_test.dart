import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riksa_app/core/providers/locale_provider.dart';
import 'package:riksa_app/core/providers/theme_mode_provider.dart';
import 'package:riksa_app/core/theme/app_theme.dart';
import 'package:riksa_app/features/auth/data/auth_models.dart';
import 'package:riksa_app/features/auth/providers/auth_provider.dart';
import 'package:riksa_app/features/userProfile/presentation/edit_profile_screen.dart';
import 'package:riksa_app/features/userProfile/presentation/profile_settings_screen.dart';
import 'package:riksa_app/l10n/gen/app_localizations.dart';

class _AuthNotifier extends AuthNotifier {
  @override
  AuthState build() => const Authenticated(
    AuthUser(
      id: 'user-1',
      username: 'sophea',
      displayName: 'Sok Sophea',
      email: 'sophea@example.com',
      phoneNumber: '012345678',
      emailVerified: true,
      phoneVerified: false,
      role: 'USER',
    ),
  );
}

class _LocaleNotifier extends LocaleNotifier {
  @override
  LocaleState build() => const LocaleState(
    locale: Locale('en'),
    isReady: true,
    hasSelection: true,
  );
}

class _ThemeNotifier extends ThemeModeNotifier {
  @override
  ThemeMode build() => ThemeMode.dark;
}

Widget _app(Widget home, {ThemeMode themeMode = ThemeMode.dark}) =>
    ProviderScope(
      overrides: [
        authProvider.overrideWith(_AuthNotifier.new),
        localeProvider.overrideWith(_LocaleNotifier.new),
        themeModeProvider.overrideWith(_ThemeNotifier.new),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: themeMode,
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
  testWidgets('profile settings follows the application light and dark mode', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(const ProfileSettingsScreen(), themeMode: ThemeMode.light),
    );
    await tester.pumpAndSettle();
    expect(
      tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
      AppColors.lightCanvas,
    );

    await tester.pumpWidget(
      _app(const ProfileSettingsScreen(), themeMode: ThemeMode.dark),
    );
    await tester.pumpAndSettle();
    expect(
      tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
      AppColors.darkCanvas,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'settings presents account, preferences, legal, and logout groups',
    (tester) async {
      await tester.pumpWidget(_app(const ProfileSettingsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Sok Sophea'), findsOneWidget);
      expect(find.text('Notification preferences'), findsOneWidget);
      expect(find.text('Dark mode'), findsOneWidget);
      expect(find.text('Language'), findsOneWidget);
      expect(find.text('FAQ'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('settings-logout')),
        260,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.byKey(const ValueKey('settings-logout')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('edit profile exposes writable schema and confirms deletion', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_app(const EditProfileScreen()));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('edit-display-name')), findsOneWidget);
    expect(find.text('@sophea'), findsOneWidget);
    expect(find.text('sophea@example.com'), findsOneWidget);
    expect(find.text('012345678'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('edit-avatar')));
    await tester.pumpAndSettle();
    expect(find.text('Humation'), findsOneWidget);
    expect(find.byKey(const ValueKey('humation-avatar-grid')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('humation-avatar-option-0')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('humation-avatar-option-0')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('humation-avatar-avatar-01.svg')),
      findsOneWidget,
    );

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('delete-account')),
      320,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -100));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('delete-account')));
    await tester.pumpAndSettle();
    expect(find.text('Delete your RIKSA account?'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
