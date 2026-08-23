import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riksa_app/core/theme/app_theme.dart';
import 'package:riksa_app/features/auth/data/auth_models.dart';
import 'package:riksa_app/features/auth/providers/auth_provider.dart';
import 'package:riksa_app/features/userProfile/data/profile_models.dart';
import 'package:riksa_app/features/userProfile/presentation/user_profile_screen.dart';
import 'package:riksa_app/features/userProfile/providers/profile_provider.dart';
import 'package:riksa_app/l10n/gen/app_localizations.dart';

class _AuthNotifier extends AuthNotifier {
  @override
  AuthState build() => Authenticated(
    AuthUser(
      id: 'user-1',
      username: 'sophea',
      displayName: 'Sok Sophea',
      bio: 'Learning mathematics and computer science every day.',
      email: 'sophea@example.com',
      emailVerified: true,
      phoneVerified: false,
      role: 'USER',
      createdAt: DateTime.utc(2026),
    ),
  );
}

const _dashboard = ProfileDashboardData(
  gamification: GamificationProfile(
    totalXp: 1520,
    currentStreak: 14,
    highestStreak: 14,
    currentTier: 'GOLD',
    nextTier: 'PLATINUM',
    xpToNext: 480,
  ),
  achievements: [
    ProfileAchievement(
      id: 'ach-1',
      name: 'Week Warrior',
      description: 'Maintain a seven-day streak',
      earned: true,
      progress: 7,
      progressMax: 7,
      progressPercent: 1,
      rarity: 'RARE',
      xpReward: 50,
    ),
  ],
  activities: [
    XpActivity(
      id: 'tx-1',
      amount: 30,
      sourceType: 'LESSON_COMPLETION',
      runningBalance: 1520,
      createdAt: null,
    ),
  ],
);

void main() {
  testWidgets('renders real profile and gamification data without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith(_AuthNotifier.new),
          profileDashboardProvider.overrideWith((ref) async => _dashboard),
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
          home: const UserProfileScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Sok Sophea'), findsOneWidget);
    expect(find.text('@sophea'), findsOneWidget);
    expect(find.byKey(const ValueKey('profile-total-xp')), findsOneWidget);
    expect(find.byKey(const ValueKey('profile-streak')), findsOneWidget);
    expect(find.text('Gold'), findsOneWidget);
    expect(find.text('Week Warrior'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Lesson completed'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('+30 XP'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
