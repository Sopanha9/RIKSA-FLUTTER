import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riksa_app/core/theme/app_theme.dart';
import 'package:riksa_app/features/auth/data/auth_models.dart';
import 'package:riksa_app/features/auth/providers/auth_provider.dart';
import 'package:riksa_app/features/social/data/social_models.dart';
import 'package:riksa_app/features/social/providers/social_feed_provider.dart';
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

final _post = SocialPost(
  id: 'post-1',
  title: 'A simple way to remember quadratic formulas',
  content: 'Connect each term to the shape of the graph.',
  reactionCount: 12,
  commentCount: 3,
  shareCount: 1,
  author: const SocialAuthor(
    id: 'user-1',
    username: 'sophea',
    displayName: 'Sok Sophea',
    avatarUrl: '',
  ),
  category: const SocialCategory(
    id: 'math',
    name: 'Mathematics',
    slug: 'mathematics',
    memberCount: 100,
    joined: true,
  ),
  createdAt: DateTime.utc(2026, 8, 23),
  updatedAt: DateTime.utc(2026, 8, 23),
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
          userPostsProvider.overrideWith(
            (ref, userId) async =>
                SocialFeedPage(posts: [_post], hasNextPage: false),
          ),
          profileRankProvider.overrideWith(
            (ref) async => const LeaderboardRank(
              countryRank: 12,
              countryScore: 1520,
              countryTier: 'GOLD',
              provinceRank: 3,
              provinceScore: 1520,
              provinceTier: 'GOLD',
            ),
          ),
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
    final scaffold = tester.widget<Scaffold>(
      find.byKey(const ValueKey('personal-profile-scaffold')),
    );
    expect(scaffold.backgroundColor, AppColors.editorialNeutralCanvas);
    expect(
      tester.widget<RefreshIndicator>(find.byType(RefreshIndicator)).color,
      AppColors.editorialPink,
    );
    expect(find.text('Sok Sophea'), findsNWidgets(2));
    expect(find.text('@sophea'), findsOneWidget);
    expect(find.byKey(const ValueKey('profile-cover')), findsOneWidget);
    expect(find.byKey(const ValueKey('profile-hero-avatar')), findsOneWidget);
    final verificationBadge = tester.widget<Container>(
      find.byKey(const ValueKey('profile-verification-badge')),
    );
    expect(
      (verificationBadge.decoration! as BoxDecoration).color,
      AppColors.editorialPink,
    );
    expect(
      tester.getCenter(find.byKey(const ValueKey('profile-hero-avatar'))).dx,
      tester.getCenter(find.byKey(const ValueKey('profile-cover'))).dx,
    );
    expect(find.byKey(const ValueKey('profile-share')), findsOneWidget);
    expect(find.byKey(const ValueKey('profile-settings')), findsOneWidget);
    expect(find.byKey(const ValueKey('profile-edit')), findsNothing);
    expect(find.byKey(const ValueKey('profile-stats')), findsOneWidget);
    expect(find.byKey(const ValueKey('profile-learning-card')), findsOneWidget);
    expect(find.byKey(const ValueKey('profile-total-xp')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('profile-level-progress')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('profile-streak')), findsOneWidget);
    expect(find.text('Gold'), findsOneWidget);
    expect(find.text('My Posts'), findsOneWidget);
    expect(
      find.text('A simple way to remember quadratic formulas'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('profile-achievements-tab')));
    await tester.pumpAndSettle();
    expect(find.text('Week Warrior'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('profile-rank-tab')));
    await tester.pumpAndSettle();
    expect(find.text('#12'), findsOneWidget);
    expect(find.text('#3'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
