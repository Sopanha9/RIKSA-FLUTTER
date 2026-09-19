import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:riksa_app/app/router/app_router.dart';
import 'package:riksa_app/core/theme/app_theme.dart';
import 'package:riksa_app/features/auth/data/auth_models.dart';
import 'package:riksa_app/features/auth/providers/auth_provider.dart';
import 'package:riksa_app/features/userProfile/data/public_profile.dart';
import 'package:riksa_app/features/userProfile/data/public_profile_api.dart';
import 'package:riksa_app/features/userProfile/presentation/public_profile_screen.dart';
import 'package:riksa_app/features/userProfile/presentation/profile_settings_screen.dart';
import 'package:riksa_app/features/userProfile/presentation/user_profile_screen.dart';
import 'package:riksa_app/features/userProfile/providers/public_profile_provider.dart';
import 'package:riksa_app/l10n/gen/app_localizations.dart';

class _AuthenticatedNotifier extends AuthNotifier {
  @override
  AuthState build() => const Authenticated(
    AuthUser(
      id: 'user-1',
      username: 'sophea',
      displayName: 'Sophea',
      emailVerified: true,
      phoneVerified: false,
      role: 'USER',
    ),
  );
}

class _PendingProfiles implements PublicProfileRepository {
  final Completer<PublicProfile> completer = Completer<PublicProfile>();

  @override
  Future<PublicProfile> fetch(String userId) => completer.future;
}

void main() {
  testWidgets('routes another profile and redirects your own id to /profile', (
    tester,
  ) async {
    late GoRouter router;
    late WidgetRef appRef;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith(_AuthenticatedNotifier.new),
          publicProfileRepositoryProvider.overrideWithValue(_PendingProfiles()),
        ],
        child: Consumer(
          builder: (context, ref, _) {
            appRef = ref;
            router = ref.watch(goRouterProvider);
            return MaterialApp.router(
              theme: AppTheme.light,
              routerConfig: router,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: const [Locale('en'), Locale('km')],
            );
          },
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    router.go('/home');
    await tester.pump(const Duration(milliseconds: 500));
    router.push('/profile/a0000000-0000-0000-0000-000000000007');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(tester.takeException(), isNull);
    expect(router.canPop(), isTrue);
    expect(find.byType(PublicProfileScreen), findsOneWidget);
    expect(find.byKey(const ValueKey('public-profile-back')), findsOneWidget);

    appRef.invalidate(goRouterProvider);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.takeException(), isNull);

    router.go('/profile/settings');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(ProfileSettingsScreen), findsOneWidget);
    expect(find.byType(PublicProfileScreen), findsNothing);

    router.go('/home');
    await tester.pump(const Duration(milliseconds: 50));
    router.go('/profile/user-1');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(router.routerDelegate.currentConfiguration.uri.path, '/profile');
    expect(find.byType(UserProfileScreen), findsOneWidget);
    expect(find.byType(PublicProfileScreen), findsNothing);
  });
}
