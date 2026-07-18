import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/presentation/telegram_otp_screen.dart';
import '../../features/auth/presentation/splash_animation_screen.dart';
import '../../features/auth/presentation/language_select_screen.dart';
import '../../features/auth/providers/auth_provider.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final isLoggedIn = authState is Authenticated;
      final isAuthRoute = state.matchedLocation.startsWith('/auth');
      final isPublicRoute = state.matchedLocation == '/splash' ||
          state.matchedLocation == '/language-select';

      if (!isLoggedIn && !isAuthRoute && !isPublicRoute) return '/auth/login';
      if (isLoggedIn && isAuthRoute) return '/home';
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
        path: '/auth/telegram-otp',
        builder: (context, state) => const TelegramOtpScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeShell(),
      ),
    ],
  );
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
            const Text('Riksa', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text('Welcome, $username'),
            const SizedBox(height: 24),
            const Text(
              'App shell coming soon',
              style: TextStyle(color: Color(0xFF8A8A8A)),
            ),
          ],
        ),
      ),
    );
  }
}