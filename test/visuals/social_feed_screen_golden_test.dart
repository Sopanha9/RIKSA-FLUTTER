import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riksa_app/core/network/dio_client.dart';
import 'package:riksa_app/core/storage/session_store.dart';
import 'package:riksa_app/core/theme/app_theme.dart';
import 'package:riksa_app/features/auth/providers/auth_provider.dart';
import 'package:riksa_app/core/widgets/riksa_bottom_navigation_bar.dart';
import 'package:riksa_app/features/social/data/social_api.dart';
import 'package:riksa_app/features/social/data/social_models.dart';
import 'package:riksa_app/features/social/presentation/social_feed_screen.dart';
import 'package:riksa_app/features/social/presentation/social_post_detail_screen.dart';
import 'package:riksa_app/features/social/providers/social_feed_provider.dart';
import 'package:riksa_app/features/auth/data/auth_models.dart';
import 'package:riksa_app/features/learning/data/learning_models.dart';
import 'package:riksa_app/features/learning/providers/learning_home_provider.dart';
import 'package:riksa_app/l10n/gen/app_localizations.dart';

Future<void> _loadFonts() async {
  final poppins = FontLoader(RiksaTypography.latinFamily);
  for (final name in [
    'Light',
    'Regular',
    'Medium',
    'SemiBold',
    'Bold',
    'ExtraBold',
    'Black',
  ]) {
    poppins.addFont(rootBundle.load('assets/fonts/Poppins-$name.ttf'));
  }

  final configuredRoot = Platform.environment['FLUTTER_ROOT'];
  final flutterRoot =
      configuredRoot ??
      File(Platform.resolvedExecutable).parent.parent.parent.parent.parent.path;
  final materialIcons = FontLoader('MaterialIcons')
    ..addFont(
      File(
        '$flutterRoot/bin/cache/artifacts/material_fonts/'
        'MaterialIcons-Regular.otf',
      ).readAsBytes().then(ByteData.sublistView),
    );
  final khmerBody = FontLoader('Kantumruy Pro')
    ..addFont(rootBundle.load('assets/fonts/KantumruyPro-Variable.ttf'));
  final khmerDisplay = FontLoader('Koulen')
    ..addFont(rootBundle.load('assets/fonts/Koulen-Regular.ttf'));
  final khmerFallback = FontLoader(RiksaTypography.khmerFamily)
    ..addFont(rootBundle.load('assets/fonts/NotoSansKhmer-Variable.ttf'));
  await Future.wait([
    poppins.load(),
    materialIcons.load(),
    khmerBody.load(),
    khmerDisplay.load(),
    khmerFallback.load(),
  ]);
}

const _category = SocialCategory(
  id: 'computer-science',
  name: 'Computer Science',
  slug: 'computer-science',
  memberCount: 420,
  joined: true,
);

final _posts = [
  SocialPost(
    id: 'official-post',
    title: 'How to learn code?',
    content:
        'I have been learning coding for a while and found a simpler way to practice every day.',
    reactionCount: 20,
    commentCount: 4,
    shareCount: 2,
    myReaction: SocialReaction.upvote,
    author: const SocialAuthor(
      id: 'official',
      username: 'riksa.admin',
      displayName: 'Riksa Platform Admin',
      avatarUrl: '',
    ),
    category: _category,
    createdAt: DateTime.utc(2026, 8, 23),
    updatedAt: DateTime.utc(2026, 8, 23),
  ),
  SocialPost(
    id: 'learner-post',
    title: 'A small mathematics habit that works',
    content:
        'Write one example from memory, check it, then explain why each step is valid.',
    reactionCount: 16,
    commentCount: 6,
    shareCount: 1,
    author: const SocialAuthor(
      id: 'sokha',
      username: 'sokha.learns',
      displayName: 'Sokha Chan',
      avatarUrl: '',
    ),
    category: const SocialCategory(
      id: 'mathematics',
      name: 'Mathematics',
      slug: 'mathematics',
      memberCount: 520,
      joined: true,
    ),
    createdAt: DateTime.utc(2026, 8, 22),
    updatedAt: DateTime.utc(2026, 8, 22),
  ),
];

class _PreviewFeedNotifier extends SocialFeedNotifier {
  @override
  SocialFeedState build() => SocialFeedLoaded(
    categories: const [_category],
    posts: _posts,
    hasNextPage: false,
  );
}

final _detailComment = SocialComment(
  id: 'comment-1',
  content:
      'Start with one tiny project, then explain every decision in your own words.',
  author: const SocialAuthor(
    id: 'bopha',
    username: 'bopha.learns',
    displayName: 'Bopha Pich',
    avatarUrl: '',
  ),
  postId: 'official-post',
  createdAt: DateTime.utc(2026, 8, 24),
  updatedAt: DateTime.utc(2026, 8, 24),
);

class _PreviewSocialApi extends SocialApi {
  _PreviewSocialApi(super.client);

  @override
  Future<SocialPost> post(String id) async => _posts.first;

  @override
  Future<SocialCommentPage> comments({
    required String postId,
    String? cursor,
    int limit = 20,
  }) async => SocialCommentPage(comments: [_detailComment], hasNextPage: false);
}

class _PreviewAuth extends AuthNotifier {
  @override
  AuthState build() => const Authenticated(
    AuthUser(
      id: 'user-1',
      username: 'sopheak',
      displayName: 'Sopheak Phan',
      emailVerified: true,
      phoneVerified: false,
      role: 'STUDENT',
    ),
  );
}

final _biology = SubjectProgress(
  category: const LearningCategory(id: 'bio', name: 'Biology'),
  completed: 3,
  total: 5,
  lessons: [
    LessonSummary(
      id: 'cell-structure',
      title: 'Cell Structure',
      description: '',
      difficulty: null,
      baseXp: 15,
      categoryId: 'bio',
      categoryName: 'Biology',
      exerciseCount: 4,
      completed: false,
      createdAt: null,
      progress: .6,
    ),
  ],
);

void main() {
  setUpAll(_loadFonts);

  testWidgets('social feed editorial palette light', (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // Signed-out reading view: no owner controls in the golden.
          currentUserIdProvider.overrideWithValue(null),
          authProvider.overrideWith(_PreviewAuth.new),
          learningHomeProvider.overrideWith(
            (ref) async => LearningHomeData(
              subjects: [_biology],
              resumeSubject: _biology,
              resumeLesson: _biology.lessons.first,
            ),
          ),
          socialFeedProvider.overrideWith(_PreviewFeedNotifier.new),
          communityStreakProvider.overrideWith(
            (ref) async => const CommunityStreak(current: 20, highest: 24),
          ),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en'), Locale('km')],
          home: Scaffold(
            extendBody: false,
            body: const SocialFeedScreen(),
            bottomNavigationBar: RiksaBottomNavigationBar(
              currentIndex: 0,
              onSelected: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(
      tester
          .state<ScrollableState>(find.byType(Scrollable).first)
          .position
          .pixels,
      0,
    );
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/social_feed_editorial_en_light.png'),
    );
  });

  testWidgets('social post detail editorial palette light', (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    FlutterSecureStorage.setMockInitialValues({});
    final client = DioClient(
      SessionStore(const FlutterSecureStorage()),
      baseUrl: 'http://riksa.test/api/v1',
    );
    addTearDown(client.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserIdProvider.overrideWithValue(null),
          socialApiProvider.overrideWithValue(_PreviewSocialApi(client)),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en'), Locale('km')],
          home: const SocialPostDetailScreen(postId: 'official-post'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    await expectLater(
      find.byType(SocialPostDetailScreen),
      matchesGoldenFile('goldens/social_post_detail_editorial_en_light.png'),
    );
  });
}
