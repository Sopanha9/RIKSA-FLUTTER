import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import 'package:riksa_app/app/router/app_shell.dart';
import 'package:riksa_app/core/theme/app_theme.dart';
import 'package:riksa_app/features/auth/data/auth_models.dart';
import 'package:riksa_app/features/auth/providers/auth_provider.dart';
import 'package:riksa_app/features/userProfile/data/profile_models.dart';
import 'package:riksa_app/features/userProfile/presentation/widgets/riksa_profile_drawer.dart';
import 'package:riksa_app/features/userProfile/providers/profile_provider.dart';
import 'package:riksa_app/features/blog/data/blog_models.dart';
import 'package:riksa_app/features/blog/providers/blog_provider.dart';
import 'package:riksa_app/features/social/data/social_models.dart';
import 'package:riksa_app/features/social/presentation/social_feed_screen.dart';
import 'package:riksa_app/features/social/providers/social_feed_provider.dart';
import 'package:riksa_app/l10n/gen/app_localizations.dart';

const _category = SocialCategory(
  id: 'category-1',
  name: 'Study Skills',
  slug: 'study-skills',
  description: 'Learn how to learn.',
  memberCount: 148,
  joined: false,
);

final _post = SocialPost(
  id: 'post-1',
  title: 'The two-minute recall habit',
  content: 'Close your notes and explain the idea in your own words.',
  reactionCount: 18,
  commentCount: 5,
  shareCount: 3,
  author: const SocialAuthor(
    id: 'user-2',
    username: 'dara.learns',
    displayName: 'Dara Chhay',
    avatarUrl: '',
  ),
  category: _category,
  createdAt: DateTime.utc(2026, 8, 22),
  updatedAt: DateTime.utc(2026, 8, 22),
);

final _blogPost = BlogPost(
  id: 'blog-1',
  authorId: 'user-2',
  title: 'How curiosity improves learning',
  content: 'A practical field note from the RIKSA learning community.',
  status: BlogStatus.approved,
  viewCount: 34,
  likeCount: 7,
  categoryId: 'category-1',
  liked: false,
  createdAt: DateTime.utc(2026, 8, 22),
  updatedAt: DateTime.utc(2026, 8, 22),
);

class _FeedNotifier extends SocialFeedNotifier {
  int loadCalls = 0;

  @override
  SocialFeedState build() => SocialFeedLoaded(
    categories: const [_category],
    posts: [_post],
    hasNextPage: false,
  );

  @override
  Future<void> load({String? categoryId}) async {
    loadCalls += 1;
    state = SocialFeedLoaded(
      categories: const [_category],
      posts: [_post],
      hasNextPage: false,
      selectedCategoryId: categoryId,
    );
  }
}

class _SignedInAuth extends AuthNotifier {
  @override
  AuthState build() => const Authenticated(
    AuthUser(
      id: 'user-1',
      username: 'sokha',
      displayName: 'Sokha Chan',
      emailVerified: true,
      phoneVerified: true,
      role: 'STUDENT',
    ),
  );
}

final _dashboard = ProfileDashboardData(
  gamification: const GamificationProfile(
    totalXp: 5630,
    currentStreak: 7,
    highestStreak: 12,
    xpToNext: 370,
  ),
  achievements: const [],
  activities: const [],
);

class _BlogNotifier extends BlogFeedNotifier {
  @override
  BlogFeedState build() =>
      BlogFeedLoaded(posts: [_blogPost], page: 0, totalPages: 1);
}

void main() {
  testWidgets('renders the editorial social shell at phone width', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          socialFeedProvider.overrideWith(_FeedNotifier.new),
          blogFeedProvider.overrideWith(_BlogNotifier.new),
          communityStreakProvider.overrideWith(
            (ref) async => const CommunityStreak(current: 7, highest: 12),
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
          home: const SocialFeedScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
      AppColors.editorialNeutralCanvas,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('my-feed-tab')),
        matching: find.text('Community'),
      ),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('bottom-nav-morph')), findsNothing);
    // No hamburger, and no drawer of this screen's own: the account menu hangs
    // off the shell's Scaffold so it covers the floating bottom bar, and it is
    // opened by the avatar in the header.
    expect(find.byKey(const ValueKey('community-drawer-button')), findsNothing);
    expect(find.byType(Drawer), findsNothing);
    expect(find.byKey(const ValueKey('streak-pill')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('create-community-button')),
      findsOneWidget,
    );
    expect(find.byTooltip('What are your doubts?'), findsOneWidget);
    expect(find.text('7'), findsOneWidget);
    expect(find.byKey(const ValueKey('my-feed-tab')), findsOneWidget);
    expect(find.text('Blog'), findsOneWidget);
    expect(find.text('The two-minute recall habit'), findsOneWidget);
    expect(find.byKey(const ValueKey('react-post-1')), findsOneWidget);

    expect(find.byKey(const ValueKey('home-header-search-button')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('home-header-search-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('community-search-sheet')), findsOneWidget);
    final communitySearchField = find.descendant(
      of: find.byKey(const ValueKey('community-search-sheet')),
      matching: find.byType(TextField),
    );

    await tester.enterText(communitySearchField, 'missing topic');
    await tester.pump();
    expect(find.text('The two-minute recall habit'), findsNothing);
    expect(find.text('No matching results'), findsOneWidget);

    await tester.enterText(communitySearchField, 'recall');
    await tester.pump();
    expect(find.text('The two-minute recall habit'), findsOneWidget);

    await tester.enterText(communitySearchField, '');
    await tester.pump();
    Navigator.of(tester.element(communitySearchField)).pop();
    await tester.pumpAndSettle();

    final feedTab = find.byKey(const ValueKey('my-feed-tab'));
    final blogTab = find.byKey(const ValueKey('blog-tab'));
    expect(
      tester
          .getTopLeft(find.byKey(const ValueKey('create-community-button')))
          .dy,
      greaterThan(tester.getBottomLeft(feedTab).dy),
    );
    bool isTabSelected(Finder tab) =>
        tester
            .widget<Semantics>(
              find.ancestor(of: tab, matching: find.byType(Semantics)).first,
            )
            .properties
            .selected ??
        false;

    expect(isTabSelected(feedTab), isTrue);
    expect(isTabSelected(blogTab), isFalse);
    await tester.tap(find.byKey(const ValueKey('blog-tab')));
    await tester.pumpAndSettle();
    expect(isTabSelected(blogTab), isTrue);
    expect(isTabSelected(feedTab), isFalse);
    expect(find.text('How curiosity improves learning'), findsOneWidget);
    expect(find.text('The two-minute recall habit'), findsNothing);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -260));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('create-community-button')));
    await tester.pumpAndSettle();
    expect(find.text('Create in Community'), findsOneWidget);
    expect(find.text('Create a post'), findsOneWidget);
    expect(find.text('Ask the community'), findsOneWidget);
    expect(find.text('Write an article'), findsOneWidget);
  });

  testWidgets('opens profiles from post author identity', (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (_, _) => const SocialFeedScreen()),
        GoRoute(
          path: '/profile/:userId',
          builder: (_, state) =>
              Scaffold(body: Text('profile-${state.pathParameters['userId']}')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          socialFeedProvider.overrideWith(_FeedNotifier.new),
          blogFeedProvider.overrideWith(_BlogNotifier.new),
          communityStreakProvider.overrideWith(
            (ref) async => const CommunityStreak(current: 7, highest: 12),
          ),
        ],
        child: MaterialApp.router(
          theme: AppTheme.light,
          routerConfig: router,
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

    await tester.tap(find.byKey(const ValueKey('author-avatar-user-2')));
    await tester.pumpAndSettle();
    expect(find.text('profile-user-2'), findsOneWidget);
    expect(router.canPop(), isTrue);
  });

  testWidgets('the create menu routes an article to the blog composer', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (_, _) => const SocialFeedScreen()),
        GoRoute(
          path: '/blog/create',
          builder: (_, _) => const Scaffold(body: Text('blog-composer')),
        ),
        GoRoute(
          path: '/community/create',
          builder: (_, _) => const Scaffold(body: Text('community-composer')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          socialFeedProvider.overrideWith(_FeedNotifier.new),
          blogFeedProvider.overrideWith(_BlogNotifier.new),
          communityStreakProvider.overrideWith(
            (ref) async => const CommunityStreak(current: 7, highest: 12),
          ),
        ],
        child: MaterialApp.router(
          theme: AppTheme.light,
          routerConfig: router,
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

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -260));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('create-community-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('create-article-option')));
    await tester.pumpAndSettle();

    expect(find.text('blog-composer'), findsOneWidget);
    expect(find.text('community-composer'), findsNothing);
  });

  testWidgets(
    'the scroll pencil opens the community create sheet in the shell',
    (tester) async {
      tester.view.physicalSize = const Size(430, 932);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final router = GoRouter(
        initialLocation: '/home',
        routes: [
          StatefulShellRoute.indexedStack(
            builder: (context, state, navigationShell) =>
                AppShell(navigationShell: navigationShell),
            branches: [
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/home',
                    builder: (_, _) => const SocialFeedScreen(),
                  ),
                  GoRoute(
                    path: '/community/create',
                    builder: (_, _) =>
                        const Scaffold(body: Text('community-composer')),
                  ),
                  GoRoute(
                    path: '/blog/create',
                    builder: (_, _) =>
                        const Scaffold(body: Text('blog-composer')),
                  ),
                ],
              ),
              _stubBranch('/learn', 'learn'),
              _stubBranch('/ai', 'ai'),
              _stubBranch('/leaderboard', 'leaderboard'),
              _stubBranch('/profile', 'profile'),
            ],
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith(_SignedInAuth.new),
            socialFeedProvider.overrideWith(_FeedNotifier.new),
            blogFeedProvider.overrideWith(_BlogNotifier.new),
            communityStreakProvider.overrideWith(
              (ref) async => const CommunityStreak(current: 7, highest: 12),
            ),
          ],
          child: MaterialApp.router(
            theme: AppTheme.light,
            routerConfig: router,
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

      await tester.drag(find.byType(CustomScrollView), const Offset(0, -260));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('create-community-button')));
      await tester.pumpAndSettle();

      expect(find.text('Create in Community'), findsOneWidget);
    },
  );

  testWidgets('the blog tab points authors at their own articles', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (_, _) => const SocialFeedScreen()),
        GoRoute(
          path: '/blog/my-posts',
          builder: (_, _) => const Scaffold(body: Text('my-posts')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          socialFeedProvider.overrideWith(_FeedNotifier.new),
          blogFeedProvider.overrideWith(_BlogNotifier.new),
          pendingBlogPostCountProvider.overrideWith((ref) async => 2),
          communityStreakProvider.overrideWith(
            (ref) async => const CommunityStreak(current: 7, highest: 12),
          ),
        ],
        child: MaterialApp.router(
          theme: AppTheme.light,
          routerConfig: router,
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

    // The link belongs to the blog tab, not the community feed.
    expect(find.byKey(const ValueKey('your-articles-link')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('blog-tab')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('your-articles-link')), findsOneWidget);
    // A post in review is absent from the feed, so the count says where it is.
    expect(find.text('2 in review'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('your-articles-link')));
    await tester.pumpAndSettle();
    expect(find.text('my-posts'), findsOneWidget);
  });

  testWidgets('no badge appears when nothing is waiting on review', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          socialFeedProvider.overrideWith(_FeedNotifier.new),
          blogFeedProvider.overrideWith(_BlogNotifier.new),
          pendingBlogPostCountProvider.overrideWith((ref) async => 0),
          communityStreakProvider.overrideWith(
            (ref) async => const CommunityStreak(current: 7, highest: 12),
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
          home: const SocialFeedScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('blog-tab')));
    await tester.pumpAndSettle();

    expect(find.text('Your articles'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('articles-in-review-badge')),
      findsNothing,
    );
  });
  testWidgets('the header avatar opens the account menu, not a hamburger', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith(_SignedInAuth.new),
          socialFeedProvider.overrideWith(_FeedNotifier.new),
          blogFeedProvider.overrideWith(_BlogNotifier.new),
          communityStreakProvider.overrideWith(
            (ref) async => const CommunityStreak(current: 7, highest: 12),
          ),
          profileDashboardProvider.overrideWith((ref) async => _dashboard),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          // Mirrors the real shell: the drawer belongs to the outer Scaffold,
          // and the screen reaches it through the scope rather than owning one.
          home: Builder(
            builder: (context) => Scaffold(
              drawer: const RiksaProfileDrawer(),
              body: Builder(
                builder: (inner) => AppShellScope(
                  openDrawer: Scaffold.of(inner).openDrawer,
                  child: const SocialFeedScreen(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('home-sidebar-menu-button')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('home-sidebar-menu-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('profile-drawer')), findsOneWidget);
    expect(find.text('Sokha Chan'), findsOneWidget);
  });
}

StatefulShellBranch _stubBranch(String path, String label) {
  return StatefulShellBranch(
    routes: [
      GoRoute(
        path: path,
        builder: (_, _) => Scaffold(body: Text(label)),
      ),
    ],
  );
}
