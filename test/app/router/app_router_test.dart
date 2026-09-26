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
import 'package:riksa_app/features/learning/data/learning_models.dart';
import 'package:riksa_app/features/learning/presentation/lesson_catalog_screen.dart';
import 'package:riksa_app/features/learning/presentation/lesson_experience_screen.dart';
import 'package:riksa_app/features/learning/presentation/subject_roadmap_screen.dart';
import 'package:riksa_app/features/learning/providers/learning_home_provider.dart';
import 'package:riksa_app/features/learning/providers/learning_roadmap_provider.dart';
import 'package:riksa_app/features/userProfile/data/public_profile.dart';
import 'package:riksa_app/features/userProfile/data/public_profile_api.dart';
import 'package:riksa_app/features/userProfile/presentation/public_profile_screen.dart';
import 'package:riksa_app/features/userProfile/presentation/profile_settings_screen.dart';
import 'package:riksa_app/features/userProfile/presentation/user_profile_screen.dart';
import 'package:riksa_app/features/userProfile/providers/public_profile_provider.dart';
import 'package:riksa_app/l10n/gen/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

class _SwitchableAuthNotifier extends AuthNotifier {
  @override
  AuthState build() => const Unauthenticated();

  void authenticate() => state = const Authenticated(
    AuthUser(
      id: 'user-1',
      username: 'sophea',
      displayName: 'Sophea',
      emailVerified: true,
      phoneVerified: false,
      role: 'USER',
    ),
  );

  void becomeGuest() => state = const Unauthenticated();
}

class _PendingProfiles implements PublicProfileRepository {
  final Completer<PublicProfile> completer = Completer<PublicProfile>();

  @override
  Future<PublicProfile> fetch(String userId) => completer.future;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

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

  testWidgets(
    'guest learning routes are readable and account routes defer auth',
    (tester) async {
      late GoRouter router;
      late WidgetRef appRef;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith(_SwitchableAuthNotifier.new),
            learningHomeProvider.overrideWith(
              (ref) async => const LearningHomeData(
                subjects: [],
                resumeSubject: null,
                resumeLesson: null,
              ),
            ),
            learningRoadmapProvider('roadmap-1').overrideWith(
              (ref) async => const LearningRoadmap(
                categoryId: 'roadmap-1',
                categoryName: 'Mathematics',
                completedLessons: 0,
                totalLessons: 0,
                progress: 0,
                currentLessonId: null,
                activeDates: [],
                units: [],
              ),
            ),
            lessonDetailProvider('lesson-1').overrideWith(
              (ref) async => const LessonDetail(
                id: 'lesson-1',
                title: 'Lesson one',
                description: '# Lesson one\n\nRead this lesson.',
                difficulty: LessonDifficulty.easy,
                baseXp: 0,
                categoryId: 'roadmap-1',
                categoryName: 'Mathematics',
                reflectionPrompt: '',
                exercises: [],
              ),
            ),
          ],
          child: Consumer(
            builder: (context, ref, _) {
              appRef = ref;
              router = ref.watch(goRouterProvider);
              return MaterialApp.router(
                theme: AppTheme.light,
                routerConfig: router,
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(disableAnimations: true),
                  child: child!,
                ),
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
      await tester.pump();

      router.go('/learn');
      await tester.pumpAndSettle();
      expect(router.routerDelegate.currentConfiguration.uri.path, '/learn');
      expect(find.byType(LessonCatalogScreen), findsOneWidget);

      router.go('/learn/roadmap/roadmap-1');
      await tester.pumpAndSettle();
      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        '/learn/roadmap/roadmap-1',
      );
      expect(find.byType(LearningRoadmapScreen), findsOneWidget);

      router.go('/learn/lesson-1');
      await tester.pumpAndSettle();
      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        '/learn/lesson-1',
      );
      await tester.pump(const Duration(milliseconds: 1000));
      expect(find.byType(LessonExperienceScreen), findsOneWidget);

      for (final location in ['/home', '/profile', '/learn/saved']) {
        router.go(location);
        await tester.pump(const Duration(milliseconds: 500));
        expect(
          router.routerDelegate.currentConfiguration.uri.path,
          '/auth/login',
        );
        expect(
          router
              .routerDelegate
              .currentConfiguration
              .uri
              .queryParameters['from'],
          location,
        );
      }

      router.go('/auth/login?from=%2Flearn%2Flesson-1');
      await tester.pump(const Duration(milliseconds: 500));
      (appRef.read(authProvider.notifier) as _SwitchableAuthNotifier)
          .authenticate();
      await tester.pump(const Duration(milliseconds: 500));
      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        '/learn/lesson-1',
      );

      router.go('/auth/login');
      await tester.pump(const Duration(milliseconds: 500));
      expect(router.routerDelegate.currentConfiguration.uri.path, '/learn');
      router.go('/');
      await tester.pump(const Duration(milliseconds: 500));
      expect(router.routerDelegate.currentConfiguration.uri.path, '/learn');

      (appRef.read(authProvider.notifier) as _SwitchableAuthNotifier)
          .becomeGuest();
      router.go('/auth/login?from=%2F%2Fevil.com');
      await tester.pump(const Duration(milliseconds: 500));
      (appRef.read(authProvider.notifier) as _SwitchableAuthNotifier)
          .authenticate();
      await tester.pump(const Duration(milliseconds: 500));
      expect(router.routerDelegate.currentConfiguration.uri.path, '/learn');
      await tester.pump(const Duration(milliseconds: 1000));
      expect(tester.takeException(), isNull);
    },
  );
}
