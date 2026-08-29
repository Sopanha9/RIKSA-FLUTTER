import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/ai/presentation/ai_tutor_screen.dart';
import '../../features/auth/presentation/auth_switcher_screen.dart';
import '../../features/auth/presentation/splash_animation_screen.dart';
import '../../features/auth/presentation/language_select_screen.dart';
import '../../features/auth/presentation/onboarding_splash_screen.dart';
import '../../features/auth/presentation/province_select_screen.dart';
import '../../features/auth/presentation/telegram_otp_screen.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/blog/presentation/blog_detail_screen.dart';
import '../../features/blog/presentation/blog_feed_screen.dart';
import '../../features/blog/presentation/create_blog_post_screen.dart';
import '../../features/blog/presentation/my_posts_screen.dart';
import '../../features/learning/presentation/lesson_catalog_screen.dart';
import '../../features/learning/presentation/lesson_experience_screen.dart';
import '../../features/learning/presentation/mathematics_roadmap_screen.dart';
import '../../features/learning/data/learning_models.dart';
import '../../features/social/presentation/social_feed_screen.dart';
import '../../features/social/presentation/compose_community_post_screen.dart';
import '../../features/social/presentation/social_post_detail_screen.dart';
import '../../features/userProfile/presentation/profile_setup_overview_screen.dart';
import '../../features/userProfile/presentation/profile_settings_screen.dart';
import '../../features/userProfile/presentation/edit_profile_screen.dart';
import '../../features/leaderBoard/presentation/leaderboard_screen.dart';
import '../../features/userProfile/presentation/public_profile_screen.dart';
import '../../features/userProfile/presentation/user_profile_screen.dart';
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
    redirect: (context, state) {
      final authState = authRefresh.value;
      final isLoggedIn = authState is Authenticated;
      final isAuthRoute = state.matchedLocation.startsWith('/auth');
      final isSplash = state.matchedLocation == '/splash';
      final isLanguage = state.matchedLocation == '/language-select';
      final isOnboarding = state.matchedLocation == '/onboarding';
      final isProvince = state.matchedLocation == '/province-select';
      final isPublicRoute =
          isSplash || isLanguage || isOnboarding || isProvince || isAuthRoute;

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
        path: '/language-select',
        builder: (context, state) => const LanguageSelectScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingSplashScreen(),
      ),
      GoRoute(
        path: '/province-select',
        builder: (context, state) => const ProvinceSelectScreen(),
      ),
      GoRoute(
        path: '/auth/login',
        builder: (context, state) => const AuthSwitcherScreen(),
      ),
      GoRoute(
        path: '/auth/register',
        builder: (context, state) =>
            const AuthSwitcherScreen(initialPage: PageState.register),
      ),
      GoRoute(
        path: '/auth/telegram',
        builder: (context, state) => TelegramOtpScreen(
          isRegistration: state.uri.queryParameters['register'] == 'true',
        ),
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
                path: '/community/create',
                builder: (context, state) => ComposeCommunityPostScreen(
                  isQuestion: state.uri.queryParameters['type'] == 'question',
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
                builder: (context, state) => const CreateBlogPostScreen(),
              ),
              GoRoute(
                path: '/blog/my-posts',
                builder: (context, state) => const MyPostsScreen(),
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
                    path: 'roadmap/:categoryId',
                    builder: (context, state) => LearningRoadmapScreen(
                      categoryId: state.pathParameters['categoryId']!,
                      currentLesson: state.extra is LessonSummary
                          ? state.extra! as LessonSummary
                          : null,
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
                  onSetUpProfile: () => context.go('/home'),
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
