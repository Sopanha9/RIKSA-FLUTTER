import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/ai/presentation/ai_tutor_screen.dart';
import '../../features/ai/presentation/ai_chat_screen.dart';
import '../../features/auth/presentation/auth_switcher_screen.dart';
import '../../features/auth/presentation/account_recovery_screen.dart';
import '../../features/auth/presentation/splash_animation_screen.dart';
import '../../features/mascot/presentation/mascot_select_screen.dart';
import '../../features/auth/presentation/language_select_screen.dart';
import '../../features/auth/presentation/onboarding_splash_screen.dart';
import '../../features/auth/presentation/interactive_onboarding_screen.dart';
import '../../features/auth/presentation/province_select_screen.dart';
import '../../features/auth/presentation/telegram_auth_screen.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/blog/data/blog_models.dart';
import '../../features/blog/presentation/blog_composer_screen.dart';
import '../../features/blog/presentation/blog_detail_screen.dart';
import '../../features/blog/presentation/blog_feed_screen.dart';
import '../../features/blog/presentation/my_posts_screen.dart';
import '../../features/learning/presentation/lesson_catalog_screen.dart';
import '../../features/learning/presentation/lesson_experience_screen.dart';
import '../../features/learning/presentation/subject_roadmap_screen.dart';
import '../../features/learning/presentation/learning_result_screens.dart';
import '../../features/learning/presentation/saved_lessons_screen.dart';
import '../../features/learning/data/learning_models.dart';
import '../../features/social/presentation/social_feed_screen.dart';
import '../../features/social/presentation/communities_screen.dart';
import '../../features/social/presentation/community_detail_screen.dart';
import '../../features/social/presentation/create_community_screen.dart';
import '../../features/social/data/social_models.dart';
import '../../features/social/presentation/compose_community_post_screen.dart';
import '../../features/social/presentation/social_post_detail_screen.dart';
import '../../features/userProfile/presentation/profile_setup_overview_screen.dart';
import '../../features/userProfile/presentation/profile_settings_screen.dart';
import '../../features/userProfile/presentation/edit_profile_screen.dart';
import '../../features/leaderBoard/presentation/leaderboard_screen.dart';
import '../../features/userProfile/presentation/public_profile_screen.dart';
import '../../features/userProfile/presentation/user_profile_screen.dart';
import '../../features/userProfile/presentation/progress_history_screen.dart';
import 'app_shell.dart';

final _authRouterRefreshProvider = Provider<ValueNotifier<AuthState>>((ref) {
  final refresh = ValueNotifier<AuthState>(ref.read(authProvider));
  ref.listen<AuthState>(authProvider, (previous, next) {
    refresh.value = next;
  });
  ref.onDispose(refresh.dispose);
  return refresh;
});

final goRouterProvider = Provider<GoRouter>((ref) {
  final authRefresh = ref.watch(_authRouterRefreshProvider);

  final router = GoRouter(
    initialLocation: '/splash',
    refreshListenable: authRefresh,
    redirect: (context, state) {
      final authState = authRefresh.value;
      final isLoggedIn = authState is Authenticated;
      final isAuthRoute = state.matchedLocation.startsWith('/auth');
      final isSplash = state.matchedLocation == '/splash';
      final isLanguage = state.matchedLocation == '/language-select';
      final isMascot = state.matchedLocation == '/mascot-select';
      final isOnboarding = state.matchedLocation.startsWith('/onboarding');
      final isProvince = state.matchedLocation == '/province-select';
      final isPublicRoute =
          isSplash ||
          isMascot ||
          isLanguage ||
          isOnboarding ||
          isProvince ||
          isAuthRoute;

      if ((authState is AuthInitial || authState is AuthUnavailable) &&
          !isSplash) {
        return '/splash';
      }

      if (!isLoggedIn && !isAuthRoute && !isPublicRoute) return '/auth/login';
      if (isLoggedIn && (isAuthRoute || isLanguage)) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/', redirect: (context, state) => '/home'),
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashAnimationScreen(),
      ),
      GoRoute(
        path: '/mascot-select',
        builder: (context, state) => const MascotSelectScreen(),
      ),
      GoRoute(
        path: '/language-select',
        builder: (context, state) => const LanguageSelectScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingSplashScreen(),
      ),
      GoRoute(
        path: '/onboarding/setup',
        builder: (context, state) => const InteractiveOnboardingScreen(),
      ),
      GoRoute(
        path: '/province-select',
        builder: (context, state) => const ProvinceSelectScreen(),
      ),
      GoRoute(
        path: '/auth/login',
        builder: (context, state) => AuthSwitcherScreen(
          onForgotPassword: () => context.push('/auth/recover'),
        ),
      ),
      GoRoute(
        path: '/auth/recover',
        builder: (context, state) => const AccountRecoveryScreen(),
      ),
      GoRoute(
        path: '/auth/verify-email',
        builder: (context, state) => EmailVerificationScreen(
          token: state.uri.queryParameters['token'] ?? '',
        ),
      ),
      GoRoute(
        path: '/auth/register',
        builder: (context, state) =>
            const AuthSwitcherScreen(initialPage: PageState.register),
      ),
      GoRoute(
        path: '/auth/telegram',
        builder: (context, state) => const TelegramAuthScreen(),
      ),
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
                path: '/dashboard',
                redirect: (context, state) => '/home',
              ),
              GoRoute(
                path: '/community',
                builder: (context, state) =>
                    const SocialFeedScreen(startInCommunities: true),
              ),
              GoRoute(
                path: '/communities',
                builder: (context, state) => const CommunitiesScreen(),
              ),
              // Listed before '/communities/:id' so "create" is not read as an id.
              GoRoute(
                path: '/communities/create',
                builder: (context, state) => const CreateCommunityScreen(),
              ),
              GoRoute(
                path: '/communities/:id',
                builder: (context, state) => CommunityDetailScreen(
                  communityId: state.pathParameters['id']!,
                  community: state.extra as SocialCategory?,
                ),
              ),
              GoRoute(
                path: '/progress',
                builder: (context, state) => const ProgressHistoryScreen(),
              ),
              GoRoute(
                path: '/community/create',
                builder: (context, state) => ComposeCommunityPostScreen(
                  isQuestion: state.uri.queryParameters['type'] == 'question',
                  communityId: state.uri.queryParameters['community'],
                ),
              ),
              GoRoute(
                path: '/community/posts/:id/edit',
                builder: (context, state) => SocialPostEditScreen(
                  id: state.pathParameters['id']!,
                  post: state.extra as SocialPost?,
                ),
              ),
              GoRoute(
                path: '/community/posts/:id',
                builder: (context, state) =>
                    SocialPostDetailScreen(postId: state.pathParameters['id']!),
              ),
              GoRoute(
                path: '/blog',
                builder: (context, state) => const BlogFeedScreen(),
              ),
              GoRoute(
                path: '/blog/create',
                builder: (context, state) => const BlogComposerScreen(),
              ),
              GoRoute(
                path: '/blog/my-posts',
                builder: (context, state) => const MyPostsScreen(),
              ),
              GoRoute(
                path: '/blog/:id/edit',
                builder: (context, state) => BlogPostEditScreen(
                  id: state.pathParameters['id']!,
                  post: state.extra as BlogPost?,
                ),
              ),
              GoRoute(
                path: '/blog/:id',
                builder: (context, state) =>
                    BlogDetailScreen(id: state.pathParameters['id']!),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/learn',
                builder: (context, state) => const LessonCatalogScreen(),
                routes: [
                  GoRoute(
                    path: 'resume',
                    redirect: (context, state) => '/learn',
                  ),
                  GoRoute(
                    path: 'saved',
                    builder: (context, state) => const SavedLessonsScreen(),
                  ),
                  GoRoute(
                    path: 'completion',
                    builder: (context, state) {
                      final extra = state.extra;
                      final int xp;
                      final String? lessonTitle;
                      final String? categoryName;
                      final int? totalExercises;
                      if (extra is int) {
                        xp = extra;
                        lessonTitle = null;
                        categoryName = null;
                        totalExercises = null;
                      } else if (extra is Map) {
                        xp = (extra['xpEarned'] as num?)?.toInt() ?? 0;
                        lessonTitle = extra['lessonTitle'] as String?;
                        categoryName = extra['categoryName'] as String?;
                        totalExercises = (extra['totalExercises'] as num?)
                            ?.toInt();
                      } else {
                        xp = 0;
                        lessonTitle = null;
                        categoryName = null;
                        totalExercises = null;
                      }
                      return LessonCompletionScreen(
                        xpEarned: xp,
                        roadmapCategoryId:
                            state.uri.queryParameters['roadmapCategoryId'],
                        lessonTitle: lessonTitle,
                        categoryName: categoryName,
                        totalExercises: totalExercises,
                        reflection: extra is Map
                            ? extra['reflection'] as String?
                            : null,
                        needsReview:
                            extra is Map && extra['needsReview'] == true,
                        lessonId: extra is Map
                            ? extra['lessonId'] as String?
                            : null,
                      );
                    },
                  ),
                  GoRoute(
                    path: 'roadmap/:categoryId',
                    builder: (context, state) => LearningRoadmapScreen(
                      categoryId: state.pathParameters['categoryId']!,
                    ),
                  ),
                  GoRoute(
                    path: ':id',
                    builder: (context, state) => LessonExperienceScreen(
                      lessonId: state.pathParameters['id']!,
                      lesson: state.extra is LessonSummary
                          ? state.extra! as LessonSummary
                          : null,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/ai',
                builder: (context, state) => const AiTutorScreen(),
                routes: [
                  GoRoute(
                    path: 'chat/:id',
                    builder: (context, state) {
                      final id = state.pathParameters['id'];
                      final query = state.uri.queryParameters;
                      return AiChatScreen(
                        sessionId: id == 'new' ? null : id,
                        lessonTitle: query['lesson'],
                        learningContext:
                            query['context'] ??
                            (state.extra is String
                                ? state.extra as String
                                : null),
                        initialPrompt: query['prompt'],
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/leaderboard',
                builder: (context, state) => const LeaderboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const UserProfileScreen(),
              ),
              GoRoute(
                path: '/profile/settings',
                builder: (context, state) => const ProfileSettingsScreen(),
              ),
              GoRoute(
                path: '/profile/edit',
                builder: (context, state) => const EditProfileScreen(),
              ),
              GoRoute(
                path: '/profile/setup',
                builder: (context, state) => ProfileSetupOverviewScreen(
                  onSetUpProfile: () => context.go('/profile/edit'),
                ),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/profile/:userId',
        redirect: (context, state) {
          final authState = authRefresh.value;
          final userId = state.pathParameters['userId'];
          if (authState is Authenticated && userId == authState.userId) {
            return '/profile';
          }
          return null;
        },
        builder: (context, state) =>
            PublicProfileScreen(userId: state.pathParameters['userId']!),
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
