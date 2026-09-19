import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:riksa_app/app/router/app_shell.dart';
import 'package:riksa_app/core/theme/app_theme.dart';
import 'package:riksa_app/features/auth/providers/auth_provider.dart';
import 'package:riksa_app/features/social/data/social_models.dart';
import 'package:riksa_app/features/social/presentation/social_feed_screen.dart';
import 'package:riksa_app/features/social/providers/social_feed_provider.dart';
import 'package:riksa_app/l10n/gen/app_localizations.dart';

const _category = SocialCategory(
  id: 'biology',
  name: 'Biology',
  slug: 'biology',
  memberCount: 12,
  joined: true,
);

final _post = SocialPost(
  id: 'post-1',
  title: 'How to solve this?',
  content: 'A question from the feed.',
  reactionCount: 0,
  commentCount: 0,
  shareCount: 0,
  author: const SocialAuthor(
    id: 'official',
    username: 'admin.riksa',
    displayName: 'Riksa Platform Admin',
    avatarUrl: '',
  ),
  category: _category,
  createdAt: DateTime.utc(2026, 9, 8),
  updatedAt: DateTime.utc(2026, 9, 8),
);

class _StubFeedNotifier extends SocialFeedNotifier {
  @override
  SocialFeedState build() => SocialFeedLoaded(
    categories: const [_category],
    posts: [_post],
    hasNextPage: false,
  );
}

void main() {
  testWidgets('opening a post from the feed takes the tab bar with it', (
    tester,
  ) async {
    // The feed used to open the detail with a raw Navigator push. The screen
    // arrived, but go_router never heard about it, so the shell went on
    // believing the feed was on top and left the tab bar sitting over the
    // comment composer.
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
                  builder: (context, state) => const SocialFeedScreen(),
                ),
                GoRoute(
                  path: '/community/posts/:id',
                  builder: (context, state) => const Scaffold(
                    body: Text('post detail'),
                    bottomNavigationBar: SizedBox(
                      height: 70,
                      child: Text('Add to the discussion'),
                    ),
                  ),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/learn',
                  builder: (context, state) =>
                      const Scaffold(body: Text('learn')),
                ),
              ],
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserIdProvider.overrideWithValue(null),
          socialFeedProvider.overrideWith(_StubFeedNotifier.new),
          communityStreakProvider.overrideWith(
            (ref) async => const CommunityStreak(current: 1, highest: 1),
          ),
        ],
        child: MaterialApp.router(
          debugShowCheckedModeBanner: false,
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

    final tabs = find.byKey(const ValueKey('persistent-bottom-navigation'));
    expect(tabs, findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('post-post-1')));
    await tester.pumpAndSettle();

    expect(find.text('post detail'), findsOneWidget);
    expect(find.text('Add to the discussion'), findsOneWidget);
    // The composer is the screen's own bottom bar. Nothing else belongs there.
    expect(tabs, findsNothing);
  });
}
