import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
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
import '../../features/social/presentation/social_feed_screen.dart';
import '../../features/social/presentation/compose_community_post_screen.dart';
import '../../features/social/presentation/social_post_detail_screen.dart';
import '../../features/userProfile/presentation/profile_setup_overview_screen.dart';
import '../../features/userProfile/presentation/profile_settings_screen.dart';
import '../../features/userProfile/presentation/edit_profile_screen.dart';
import '../../features/userProfile/presentation/user_profile_screen.dart';

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
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/auth/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/auth/telegram',
        builder: (context, state) => TelegramOtpScreen(
          isRegistration: state.uri.queryParameters['register'] == 'true',
        ),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const SocialFeedScreen(),
      ),
      GoRoute(
        path: '/learn',
        builder: (context, state) => const LessonCatalogScreen(),
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
          // The following avatar form is a separate Figma frame and is not yet
          // implemented. Keep navigation safe until that screen lands.
          onSetUpProfile: () => context.go('/home'),
        ),
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
  );
  ref.onDispose(router.dispose);
  return router;
});
