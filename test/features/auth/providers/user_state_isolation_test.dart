import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riksa_app/core/network/dio_client.dart';
import 'package:riksa_app/core/storage/session_store.dart';
import 'package:riksa_app/features/ai/data/ai_chat_api.dart';
import 'package:riksa_app/features/ai/data/ai_chat_cache.dart';
import 'package:riksa_app/features/ai/data/ai_chat_models.dart';
import 'package:riksa_app/features/ai/providers/ai_chat_provider.dart';
import 'package:riksa_app/features/auth/data/auth_models.dart';
import 'package:riksa_app/features/auth/providers/auth_provider.dart';
import 'package:riksa_app/features/blog/data/blog_api.dart';
import 'package:riksa_app/features/blog/data/blog_models.dart';
import 'package:riksa_app/features/blog/providers/blog_provider.dart';
import 'package:riksa_app/features/learning/providers/saved_lessons_provider.dart';
import 'package:riksa_app/features/mascot/domain/mascot.dart';
import 'package:riksa_app/features/mascot/providers/mascot_provider.dart';
import 'package:riksa_app/features/quests/data/quest_models.dart';
import 'package:riksa_app/features/quests/data/quests_api.dart';
import 'package:riksa_app/features/quests/providers/today_quests_provider.dart';
import 'package:riksa_app/features/resources/data/resource_models.dart';
import 'package:riksa_app/features/resources/data/resources_api.dart';
import 'package:riksa_app/features/resources/providers/lesson_resources_provider.dart';
import 'package:riksa_app/features/social/data/social_api.dart';
import 'package:riksa_app/features/social/data/social_models.dart';
import 'package:riksa_app/features/social/providers/social_feed_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _SwitchableAuthNotifier extends AuthNotifier {
  @override
  AuthState build() => const Unauthenticated();

  void signIn(String id, {String? displayName}) {
    state = Authenticated(
      AuthUser(
        id: id,
        username: id,
        displayName: displayName ?? id,
        emailVerified: true,
        phoneVerified: false,
        role: 'USER',
      ),
    );
  }

  void signOut() => state = const Unauthenticated();
}

class _UserQuestsRepository implements QuestsRepository {
  _UserQuestsRepository(this.currentUser);

  final String Function() currentUser;

  @override
  Future<TodayQuests> today() async => TodayQuests(
    date: DateTime(2026, 9, 27),
    allClaimedBonusXp: 10,
    quests: [
      DailyQuest(
        id: 'same-id',
        type: DailyQuestType.completeLesson,
        title: currentUser(),
        titleKm: '',
        target: 1,
        progress: 0,
        xpReward: 10,
        completed: false,
        claimed: false,
      ),
    ],
  );

  @override
  Future<DailyQuest> claim(String id) => throw UnimplementedError();
}

class _UserSocialApi extends SocialApi {
  _UserSocialApi(this.currentUser)
    : super(DioClient(SessionStore(const FlutterSecureStorage())));

  final String Function() currentUser;

  @override
  Future<List<SocialCategory>> categories() async => [
    SocialCategory(
      id: 'community',
      name: 'Community',
      slug: 'community',
      memberCount: 1,
      joined: currentUser() == 'A',
    ),
  ];

  @override
  Future<SocialFeedPage> feed({
    String? categoryId,
    String? authorId,
    String? cursor,
    int limit = 20,
  }) async {
    final userId = currentUser();
    final category = SocialCategory(
      id: 'community',
      name: 'Community',
      slug: 'community',
      memberCount: 1,
      joined: userId == 'A',
    );
    final post = SocialPost(
      id: 'same-post',
      title: userId,
      content: userId,
      reactionCount: 0,
      commentCount: 0,
      shareCount: 0,
      author: SocialAuthor(
        id: userId,
        username: userId,
        displayName: userId,
        avatarUrl: '',
      ),
      category: category,
      myReaction: userId == 'A' ? SocialReaction.love : null,
      createdAt: DateTime(2026, 9, 27),
      updatedAt: DateTime(2026, 9, 27),
    );
    return SocialFeedPage(posts: [post], hasNextPage: false, endCursor: null);
  }
}

class _UserBlogApi extends BlogApi {
  _UserBlogApi(this.currentUser)
    : super(DioClient(SessionStore(const FlutterSecureStorage())));

  final String Function() currentUser;

  @override
  Future<BlogPage> listPosts({
    String? categoryId,
    int page = 0,
    int size = 20,
  }) async {
    final userId = currentUser();
    return BlogPage(
      content: [
        BlogPost(
          id: 'same-blog',
          authorId: userId,
          title: userId,
          content: userId,
          status: BlogStatus.approved,
          viewCount: 0,
          likeCount: 1,
          categoryId: 'category',
          liked: userId == 'A',
          createdAt: DateTime(2026, 9, 27),
          updatedAt: DateTime(2026, 9, 27),
        ),
      ],
      page: 0,
      size: size,
      totalElements: 1,
      totalPages: 1,
    );
  }
}

class _UserResourcesRepository implements ResourcesRepository {
  _UserResourcesRepository(this.currentUser);

  final String Function() currentUser;

  @override
  Future<LessonResourcePage> list(String lessonId, {String? cursor}) async {
    final saved = currentUser() == 'A';
    return LessonResourcePage(
      edges: [
        LessonResource(
          id: 'resource',
          lessonId: lessonId,
          title: 'Resource',
          url: 'https://example.org/resource',
          kind: LessonResourceKind.link,
          author: const ResourceAuthor(id: 'author', displayName: 'Author'),
          saveCount: saved ? 1 : 0,
          savedByMe: saved,
          createdAt: DateTime(2026, 9, 27),
        ),
      ],
      hasNextPage: false,
    );
  }

  @override
  Future<LessonResource> create(
    String lessonId, {
    required String title,
    required String url,
    required LessonResourceKind kind,
  }) => throw UnimplementedError();

  @override
  Future<LessonResource> save(String id) => throw UnimplementedError();

  @override
  Future<LessonResource> unsave(String id) => throw UnimplementedError();

  @override
  Future<void> delete(String id) => throw UnimplementedError();

  @override
  Future<void> report(String id) => throw UnimplementedError();
}

class _MockAiChatApi extends Mock implements AiChatApi {}

class _FailingDioClient extends DioClient {
  _FailingDioClient()
    : super(_EmptySessionStore(), httpClientAdapter: _FailingHttpAdapter());
}

class _LogoutDioClient extends DioClient {
  _LogoutDioClient({this.failClear = false}) : super(_EmptySessionStore());

  final bool failClear;

  @override
  Future<String?> getRefreshToken() async => null;

  @override
  Future<void> clearSession() async {
    if (failClear) throw StateError('local storage unavailable');
  }
}

class _EmptySessionStore extends SessionStore {
  _EmptySessionStore() : super(const FlutterSecureStorage());

  @override
  Future<String?> readAccessToken() async => null;

  @override
  Future<String?> readRefreshToken() async => null;
}

class _FailingHttpAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    throw DioException(requestOptions: options, message: 'offline');
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('current user id ignores same-account profile changes', () {
    final container = ProviderContainer(
      overrides: [authProvider.overrideWith(_SwitchableAuthNotifier.new)],
    );
    addTearDown(container.dispose);
    var notifications = 0;
    container.listen(currentUserIdProvider, (_, _) => notifications++);
    final auth =
        container.read(authProvider.notifier) as _SwitchableAuthNotifier;

    // Riverpod recomputes a derived provider when it is read, so read after
    // each change to observe every notification.
    auth.signIn('A', displayName: 'Original');
    container.read(currentUserIdProvider);
    auth.signIn('A', displayName: 'Updated profile');
    container.read(currentUserIdProvider);
    auth.signIn('B');

    expect(container.read(currentUserIdProvider), 'B');
    expect(notifications, 2);
  });

  test(
    'quests, social, blog, AI sessions, and saved lessons change accounts',
    () async {
      SharedPreferences.setMockInitialValues({});
      var activeUser = 'guest';
      final quests = _UserQuestsRepository(() => activeUser);
      final social = _UserSocialApi(() => activeUser);
      final blog = _UserBlogApi(() => activeUser);
      final resources = _UserResourcesRepository(() => activeUser);
      final ai = _MockAiChatApi();
      when(() => ai.sessions()).thenAnswer(
        (_) async => [
          AiChatSession(
            id: 'session-$activeUser',
            title: activeUser,
            messages: const [],
          ),
        ],
      );
      when(() => ai.session('shared-session')).thenAnswer(
        (_) async => AiChatSession(
          id: 'shared-session',
          title: activeUser,
          messages: const [],
        ),
      );
      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith(_SwitchableAuthNotifier.new),
          questsRepositoryProvider.overrideWithValue(quests),
          socialApiProvider.overrideWithValue(social),
          blogApiProvider.overrideWithValue(blog),
          resourcesRepositoryProvider.overrideWithValue(resources),
          aiChatApiProvider.overrideWithValue(ai),
        ],
      );
      addTearDown(container.dispose);

      container.listen(todayQuestsProvider, (_, _) {});
      container.listen(socialFeedProvider, (_, _) {});
      container.listen(blogFeedProvider, (_, _) {});
      container.listen(lessonResourcesProvider('lesson-1'), (_, _) {});
      container.listen(aiChatSessionsProvider, (_, _) {});
      container.listen(aiChatSessionProvider('shared-session'), (_, _) {});
      container.listen(savedLessonsProvider, (_, _) {});
      final auth =
          container.read(authProvider.notifier) as _SwitchableAuthNotifier;

      activeUser = 'A';
      auth.signIn('A');
      await _loadUserData(container);
      await container.read(savedLessonsProvider.notifier).add('lesson-A');
      expect(
        container.read(todayQuestsProvider).value!.quests.single.title,
        'A',
      );
      expect(
        (container.read(socialFeedProvider) as SocialFeedLoaded)
            .categories
            .single
            .joined,
        isTrue,
      );
      expect(
        (container.read(socialFeedProvider) as SocialFeedLoaded)
            .posts
            .single
            .myReaction,
        SocialReaction.love,
      );
      expect(
        (container.read(blogFeedProvider) as BlogFeedLoaded).posts.single.title,
        'A',
      );
      expect(
        (await container.read(
          lessonResourcesProvider('lesson-1').future,
        )).resources.single.savedByMe,
        isTrue,
      );
      expect(
        (await container.read(aiChatSessionsProvider.future)).single.title,
        'A',
      );
      expect(
        (await container.read(
          aiChatSessionProvider('shared-session').future,
        )).title,
        'A',
      );

      activeUser = 'guest';
      auth.signOut();
      await _flushAsyncWork();
      activeUser = 'B';
      auth.signIn('B');
      await _loadUserData(container);

      expect(
        container.read(todayQuestsProvider).value!.quests.single.title,
        'B',
      );
      final socialState =
          container.read(socialFeedProvider) as SocialFeedLoaded;
      expect(socialState.categories.single.joined, isFalse);
      expect(socialState.posts.single.myReaction, isNull);
      expect(
        (container.read(blogFeedProvider) as BlogFeedLoaded).posts.single.title,
        'B',
      );
      expect(
        (container.read(blogFeedProvider) as BlogFeedLoaded).posts.single.liked,
        isFalse,
      );
      expect(
        container
            .read(lessonResourcesProvider('lesson-1'))
            .value!
            .resources
            .single
            .savedByMe,
        isFalse,
      );
      expect(
        (await container.read(aiChatSessionsProvider.future)).single.title,
        'B',
      );
      expect(
        (await container.read(
          aiChatSessionProvider('shared-session').future,
        )).title,
        'B',
      );
      expect(container.read(savedLessonsProvider), isEmpty);

      await container.read(savedLessonsProvider.notifier).add('lesson-B');
      activeUser = 'guest';
      auth.signOut();
      await _flushAsyncWork();
      activeUser = 'A';
      auth.signIn('A');
      await container.read(savedLessonsRestoredProvider.future);
      expect(container.read(savedLessonsProvider), {'lesson-A'});
    },
  );

  test('old saved lesson list moves only to the guest bucket', () async {
    SharedPreferences.setMockInitialValues({
      'riksa_saved_lesson_ids': ['legacy-lesson'],
    });
    final container = ProviderContainer(
      overrides: [authProvider.overrideWith(_SwitchableAuthNotifier.new)],
    );
    addTearDown(container.dispose);
    container.listen(savedLessonsProvider, (_, _) {});
    final auth =
        container.read(authProvider.notifier) as _SwitchableAuthNotifier;
    await container.read(savedLessonsRestoredProvider.future);

    auth.signIn('A');
    await container.read(savedLessonsRestoredProvider.future);
    expect(container.read(savedLessonsProvider), isEmpty);

    auth.signOut();
    await container.read(savedLessonsRestoredProvider.future);
    expect(container.read(savedLessonsProvider), {'legacy-lesson'});
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getStringList('riksa_saved_lesson_ids'), isNull);
    expect(preferences.getStringList('riksa_saved_lesson_ids_guest'), [
      'legacy-lesson',
    ]);
  });

  test('the old device-wide buddy choice becomes the guest buddy', () async {
    SharedPreferences.setMockInitialValues({
      'riksa_mascot_species': 'capybara',
      'riksa_mascot_name': 'Old Capy',
    });
    final container = ProviderContainer(
      overrides: [authProvider.overrideWith(_SwitchableAuthNotifier.new)],
    );
    addTearDown(container.dispose);
    container.listen(mascotProvider, (_, _) {});
    await _flushAsyncWork();

    final profile = container.read(mascotProvider).profile;
    expect(profile?.species, MascotSpecies.capybara);
    expect(profile?.name, 'Old Capy');
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString('riksa_mascot_species'), isNull);
    expect(preferences.getString('riksa_mascot_species_guest'), 'capybara');
  });

  test(
    'mascot resets to the guest profile after an account signs out',
    () async {
      SharedPreferences.setMockInitialValues({
        'riksa_mascot_species_A': 'capybara',
        'riksa_mascot_name_A': 'Account A',
        'riksa_mascot_species_guest': 'crocodile',
        'riksa_mascot_name_guest': 'Guest Croco',
      });
      final container = ProviderContainer(
        overrides: [authProvider.overrideWith(_SwitchableAuthNotifier.new)],
      );
      addTearDown(container.dispose);
      container.listen(mascotProvider, (_, _) {});
      final auth =
          container.read(authProvider.notifier) as _SwitchableAuthNotifier;

      auth.signIn('A');
      await _flushAsyncWork();
      expect(container.read(mascotProvider).profile?.name, 'Account A');

      auth.signOut();
      await _flushAsyncWork();
      expect(
        container.read(mascotProvider).profile?.species,
        MascotSpecies.crocodile,
      );
      expect(container.read(mascotProvider).profile?.name, 'Guest Croco');
    },
  );

  test(
    'AI history fallback is isolated by user and disabled for guests',
    () async {
      SharedPreferences.setMockInitialValues({});
      final session = const AiChatSession(
        id: 'session-a',
        title: 'A private chat',
        messages: [],
      );
      final cacheA = AiChatCache('A');
      await cacheA.saveSessions([session]);
      await cacheA.saveSession(session);

      final apiA = AiChatApi(_FailingDioClient(), cacheA);
      expect((await apiA.sessions()).single.title, 'A private chat');
      expect((await apiA.session('session-a')).title, 'A private chat');

      final apiB = AiChatApi(_FailingDioClient(), AiChatCache('B'));
      await expectLater(apiB.sessions(), throwsA(isA<DioException>()));
      await expectLater(
        apiB.session('session-a'),
        throwsA(isA<DioException>()),
      );

      final guestCache = AiChatCache();
      await guestCache.saveSessions([session]);
      expect(await guestCache.loadSessions(), isEmpty);
      final guestApi = AiChatApi(_FailingDioClient(), guestCache);
      await expectLater(guestApi.sessions(), throwsA(isA<DioException>()));
      await expectLater(
        guestApi.session('session-a'),
        throwsA(isA<DioException>()),
      );

      await AiChatCache('B').saveSessions([
        const AiChatSession(id: 'session-b', title: 'B chat', messages: []),
      ]);
      await AiChatCache.clearForUser('A');
      expect(await AiChatCache('A').loadSessions(), isEmpty);
      expect((await AiChatCache('B').loadSessions()).single.title, 'B chat');
    },
  );

  test('AI cache removes the previous global keys on first use', () async {
    SharedPreferences.setMockInitialValues({
      'ai_chat_sessions_cache': '[]',
      'ai_chat_session_old-session': '{}',
    });

    await AiChatCache.clearLegacyKeysOnce();

    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString('ai_chat_sessions_cache'), isNull);
    expect(preferences.getString('ai_chat_session_old-session'), isNull);
    expect(preferences.getBool('ai_chat_legacy_cache_cleared_v1'), isTrue);
  });

  test('logout clears the signed-out user AI cache', () async {
    SharedPreferences.setMockInitialValues({});
    await AiChatCache('A').saveSessions([
      const AiChatSession(id: 'session-a', title: 'Private', messages: []),
    ]);
    final container = ProviderContainer(
      overrides: [
        authProvider.overrideWith(_SwitchableAuthNotifier.new),
        dioClientProvider.overrideWithValue(_LogoutDioClient(failClear: true)),
      ],
    );
    addTearDown(container.dispose);
    final auth =
        container.read(authProvider.notifier) as _SwitchableAuthNotifier;
    auth.signIn('A');

    await auth.logout();

    expect(container.read(authProvider), isA<Unauthenticated>());
    expect(await AiChatCache('A').loadSessions(), isEmpty);
  });
}

Future<void> _loadUserData(ProviderContainer container) async {
  await container.read(todayQuestsProvider.future);
  await container.read(aiChatSessionsProvider.future);
  await container.read(aiChatSessionProvider('shared-session').future);
  await container.read(savedLessonsRestoredProvider.future);
  await _flushAsyncWork();
}

Future<void> _flushAsyncWork() async {
  for (var i = 0; i < 5; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 2));
  }
}
