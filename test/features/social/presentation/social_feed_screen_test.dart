import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:riksa_app/core/theme/app_theme.dart';
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
    expect(find.text('Community'), findsOneWidget);
    expect(find.byKey(const ValueKey('bottom-nav-morph')), findsNothing);
    expect(find.byKey(const ValueKey('community-drawer-button')), findsNothing);
    expect(find.byType(Drawer), findsNothing);
    expect(find.byKey(const ValueKey('community-search')), findsOneWidget);
    final communitySearchField = find.descendant(
      of: find.byKey(const ValueKey('community-search')),
      matching: find.byType(TextField),
    );
    expect(
      tester.widget<TextField>(communitySearchField).decoration?.border,
      InputBorder.none,
    );
    expect(find.byKey(const ValueKey('streak-pill')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('create-community-button')),
      findsOneWidget,
    );
    expect(find.text('What are your doubts?'), findsOneWidget);
    expect(find.text('7'), findsOneWidget);
    expect(find.byKey(const ValueKey('my-feed-tab')), findsOneWidget);
    expect(find.text('Blog'), findsOneWidget);
    expect(find.text('The two-minute recall habit'), findsOneWidget);
    expect(find.byKey(const ValueKey('react-post-1')), findsOneWidget);

    await tester.enterText(communitySearchField, 'missing topic');
    await tester.pump();
    expect(find.text('The two-minute recall habit'), findsNothing);
    expect(find.text('No matching results'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('community-search')),
      'recall',
    );
    await tester.pump();
    expect(find.text('The two-minute recall habit'), findsOneWidget);

    await tester.enterText(find.byKey(const ValueKey('community-search')), '');
    await tester.pump();

    BoxDecoration tabDecoration(Finder tab) {
      final container = tester.widget<AnimatedContainer>(
        find.descendant(of: tab, matching: find.byType(AnimatedContainer)),
      );
      return container.decoration! as BoxDecoration;
    }

    final feedTab = find.byKey(const ValueKey('my-feed-tab'));
    final blogTab = find.byKey(const ValueKey('blog-tab'));
    expect(
      tester
          .getTopLeft(find.byKey(const ValueKey('create-community-button')))
          .dy,
      greaterThan(tester.getBottomLeft(feedTab).dy),
    );
    expect(tabDecoration(feedTab).color, AppColors.editorialAubergine);
    expect(tabDecoration(blogTab).color, Colors.transparent);
    await tester.tap(find.byKey(const ValueKey('blog-tab')));
    await tester.pumpAndSettle();
    expect(tabDecoration(blogTab).color, AppColors.editorialAubergine);
    expect(tabDecoration(feedTab).color, Colors.transparent);
    expect(find.text('How curiosity improves learning'), findsOneWidget);
    expect(find.text('The two-minute recall habit'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('create-community-button')));
    await tester.pumpAndSettle();
    expect(find.text('Create in Community'), findsOneWidget);
    expect(find.text('Create a post'), findsOneWidget);
    expect(find.text('Ask the community'), findsOneWidget);
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
}
