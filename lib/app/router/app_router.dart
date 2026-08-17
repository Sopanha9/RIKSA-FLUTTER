import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/presentation/splash_animation_screen.dart';
import '../../features/auth/presentation/language_select_screen.dart';
import '../../features/auth/presentation/telegram_otp_screen.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/blog/presentation/blog_detail_screen.dart';
import '../../features/blog/presentation/blog_feed_screen.dart';
import '../../features/blog/presentation/create_blog_post_screen.dart';
import '../../features/blog/presentation/my_posts_screen.dart';

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
      final isPublicRoute = isSplash || isLanguage || isAuthRoute;

      if ((authState is AuthInitial || authState is AuthUnavailable) &&
          !isSplash) {
        return '/splash';
      }

      if (!isLoggedIn && !isAuthRoute && !isPublicRoute) return '/auth/login';
      if (isLoggedIn && (isAuthRoute || isLanguage)) return '/home';
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashAnimationScreen(),
      ),
      GoRoute(
        path: '/language-select',
        builder: (context, state) => const LanguageSelectScreen(),
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
      GoRoute(path: '/home', builder: (context, state) => const HomeShell()),
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

/// Temporary home shell — will be replaced by the full app shell later.
class HomeShell extends ConsumerWidget {
  const HomeShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final username = authState is Authenticated ? authState.username : '';

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            onPressed: () => ref.read(authProvider.notifier).logout(),
            icon: const Icon(Icons.logout),
            tooltip: 'Log Out',
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Riksa',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text('Welcome, $username'),
            const SizedBox(height: 24),
            const Text(
              'App shell coming soon',
              style: TextStyle(color: Color(0xFF8A8A8A)),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => context.push('/blog'),
              icon: const Icon(Icons.article_outlined),
              label: const Text('Blog'),
            ),
          ],
        ),
      ),
    );
  }
}
