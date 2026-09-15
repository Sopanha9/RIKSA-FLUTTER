import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:riksa_app/core/theme/app_theme.dart';
import 'package:riksa_app/core/widgets/riksa_achievement_image.dart';
import 'package:riksa_app/features/auth/data/auth_models.dart';
import 'package:riksa_app/features/auth/providers/auth_provider.dart';
import 'package:riksa_app/features/social/data/social_models.dart';
import 'package:riksa_app/features/social/providers/social_feed_provider.dart';
import 'package:riksa_app/features/userProfile/data/profile_models.dart';
import 'package:riksa_app/features/userProfile/presentation/user_profile_screen.dart';
import 'package:riksa_app/features/userProfile/providers/profile_provider.dart';
import 'package:riksa_app/l10n/gen/app_localizations.dart';
import '../../../visuals/achievement_preview.dart';

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
    currentTierMinXp: 500,
    nextTierMinXp: 2000,
    xpToNext: 480,
  ),
  achievements: [
    ProfileAchievement(
      id: 'ach-1',
      name: 'Week Warrior',
      iconUrl: '/icons/ach-streak-7.png',
      description: 'Maintain a seven-day streak',
      earned: true,
      progress: 7,
      progressMax: 7,
      progressPercent: 1,
      rarity: 'RARE',
      xpReward: 50,
    ),
    ProfileAchievement(
      id: 'locked',
      name: 'Not earned yet',
      description: 'Still in progress',
      iconUrl: '/icons/ach-century.png',
      earned: false,
      progress: 1,
      progressMax: 100,
      progressPercent: .01,
      rarity: 'EPIC',
      xpReward: 1000,
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
  setUpAll(loadAchievementPreviewFonts);
  setUp(() => SharedPreferences.setMockInitialValues({}));
  for (final dark in [false, true]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'signed-in achievement tab at 360px dark=$dark scale=$scale',
        (tester) async {
          tester.view.physicalSize = const Size(360, 2200);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          await tester.pumpWidget(
            _app(
              posts: const [],
              theme: dark ? AppTheme.dark : AppTheme.light,
              textScale: scale,
            ),
          );
          await tester.pumpAndSettle();
          final tab = find.byKey(const ValueKey('profile-achievements-tab'));
          await tester.ensureVisible(tab);
          await tester.tap(tab);
          await tester.pumpAndSettle();
          await tester.ensureVisible(find.byType(RiksaAchievementImage));
          await tester.runAsync(
            () => precacheImage(
              const AssetImage('assets/images/achievements/ach-streak-7.png'),
              tester.element(find.byType(RiksaAchievementImage)),
            ),
          );
          await tester.pumpAndSettle();
          expect(find.text('Week Warrior'), findsOneWidget);
          expect(find.text('Not earned yet'), findsNothing);
          expect(tester.takeException(), isNull);
          await exportAchievementPreview(
            tester,
            find.byKey(const ValueKey('personal-achievement-preview')),
            'signed_in_${dark ? 'dark' : 'light'}_${scale.toInt()}x',
          );
        },
      );
    }
  }

  testWidgets('renders real profile and gamification data without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 1500);
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
    expect(find.byKey(const ValueKey('avatar-frame-gold')), findsWidgets);
    final verificationBadge = tester.widget<Icon>(
      find.byKey(const ValueKey('profile-verification-badge')),
    );
    expect(verificationBadge.color, AppColors.editorialPink);
    // The avatar hangs off the leading edge of the banner, X-style, rather
    // than sitting centred on it.
    final avatarRect = tester.getRect(
      find.byKey(const ValueKey('profile-hero-avatar')),
    );
    final coverRect = tester.getRect(
      find.byKey(const ValueKey('profile-cover')),
    );
    expect(avatarRect.left, closeTo(coverRect.left + 14, 4));
    expect(avatarRect.bottom, greaterThan(coverRect.bottom));
    expect(find.byKey(const ValueKey('profile-share')), findsOneWidget);
    expect(find.byKey(const ValueKey('profile-settings')), findsOneWidget);
    expect(find.byKey(const ValueKey('profile-edit')), findsOneWidget);
    expect(find.byKey(const ValueKey('profile-stats')), findsOneWidget);
    expect(find.byKey(const ValueKey('profile-learning-card')), findsOneWidget);
    // Progress is measured through the current tier, not from zero XP:
    // 1,520 sits 1,020 into the 1,500 band from Gold to Platinum.
    expect(find.text('1,020 / 1,500 XP'), findsOneWidget);
    final bar = tester.widget<LinearProgressIndicator>(
      find.byKey(const ValueKey('profile-level-progress')),
    );
    expect(bar.value, closeTo(1020 / 1500, 0.001));
    // The card no longer restates the totals the counts line already carries.
    expect(find.text('1,520 XP'), findsNothing);
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
    expect(find.text('Not earned yet'), findsNothing);
    expect(
      tester
          .widget<RiksaAchievementImage>(find.byType(RiksaAchievementImage))
          .iconUrl,
      '/icons/ach-streak-7.png',
    );

    await tester.tap(find.byKey(const ValueKey('profile-rank-tab')));
    await tester.pumpAndSettle();
    expect(find.text('#12'), findsOneWidget);
    expect(find.text('#3'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('posts tab carries the composer, the count and post actions', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 1500);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_app(posts: [_post]));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('profile-create-post')), findsOneWidget);
    expect(find.text('1 post'), findsOneWidget);

    // Long-pressing a post the author wrote offers the same edit and delete
    // the card's overflow menu carries, with larger targets.
    final postTitle = find.text('A simple way to remember quadratic formulas');
    await tester.ensureVisible(postTitle);
    await tester.pumpAndSettle();
    await tester.longPress(postTitle);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('profile-post-action-edit')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('profile-post-action-delete')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('empty posts tab offers writing a first post', (tester) async {
    tester.view.physicalSize = const Size(430, 1500);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_app(posts: const []));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('profile-posts-empty')), findsOneWidget);
    final createButton = find.byKey(
      const ValueKey('profile-empty-create-post'),
    );
    await tester.ensureVisible(createButton);
    await tester.pumpAndSettle();
    await tester.tap(createButton);
    await tester.pumpAndSettle();

    // The composer sheet is the community's, so the profile offers the same
    // three kinds of writing the feed does.
    expect(find.text('Create a post'), findsOneWidget);
    expect(find.text('Ask the community'), findsOneWidget);
    expect(find.byKey(const ValueKey('create-article-option')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('renders the tier card from a server without tier floors', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 1500);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // Exactly what /gamification/me sends before the tier floors ship.
    final legacy = GamificationProfile.fromJson(const {
      'userId': 'user-1',
      'totalXp': 4050,
      'currentStreak': 20,
      'highestStreak': 20,
      'currentTier': 'DIAMOND',
      'currentTierIcon': '/icons/rank-diamond.png',
      'nextTier': 'LEGEND',
      'xpToNext': 950,
    });

    await tester.pumpWidget(_appWithGamification(legacy));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byKey(const ValueKey('profile-learning-card')), findsOneWidget);
    // No floors means no honest band, so the card omits the band figure
    // rather than printing a wrong one.
    expect(find.byKey(const ValueKey('profile-tier-band')), findsNothing);
    expect(find.text('Diamond'), findsOneWidget);
  });

  testWidgets('renders the top of the ladder without a progress bar', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 1500);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final legend = GamificationProfile.fromJson(const {
      'totalXp': 6200,
      'currentTier': 'LEGEND',
      'currentTierMinXp': 5000,
      'nextTierMinXp': 0,
      'xpToNext': 0,
    });

    await tester.pumpWidget(_appWithGamification(legend));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byKey(const ValueKey('profile-level-progress')), findsNothing);
  });
}

/// The app may run against an API that predates the tier floors. The card has
/// to render from what that server does send rather than crash on the gap.
Widget _appWithGamification(GamificationProfile game) => ProviderScope(
  overrides: [
    authProvider.overrideWith(_AuthNotifier.new),
    profileDashboardProvider.overrideWith(
      (ref) async => ProfileDashboardData(
        gamification: game,
        achievements: const [],
        activities: const [],
      ),
    ),
    userPostsProvider.overrideWith(
      (ref, userId) async =>
          const SocialFeedPage(posts: [], hasNextPage: false),
    ),
    profileRankProvider.overrideWith(
      (ref) async => const LeaderboardRank(
        countryRank: 12,
        countryScore: 1520,
        countryTier: 'GOLD',
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
);

Widget _app({
  required List<SocialPost> posts,
  ThemeData? theme,
  double textScale = 1,
}) => ProviderScope(
  overrides: [
    authProvider.overrideWith(_AuthNotifier.new),
    profileDashboardProvider.overrideWith((ref) async => _dashboard),
    userPostsProvider.overrideWith(
      (ref, userId) async => SocialFeedPage(posts: posts, hasNextPage: false),
    ),
    profileRankProvider.overrideWith(
      (ref) async => const LeaderboardRank(
        countryRank: 12,
        countryScore: 1520,
        countryTier: 'GOLD',
      ),
    ),
  ],
  child: MaterialApp(
    theme: theme ?? AppTheme.light,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(textScale)),
      child: child!,
    ),
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const [Locale('en'), Locale('km')],
    home: const RepaintBoundary(
      key: ValueKey('personal-achievement-preview'),
      child: UserProfileScreen(),
    ),
  ),
);
