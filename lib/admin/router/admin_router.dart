import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../layout/admin_layout.dart';
import '../pages/dashboard_page.dart';
import '../pages/users_page.dart';
import '../pages/lessons_page.dart';
import '../pages/exercises_page.dart';
import '../pages/blog_posts_page.dart';
import '../pages/settings_page.dart';

final adminRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/admin/dashboard',
    routes: [
      ShellRoute(
        builder: (context, state, child) => AdminLayout(child: child),
        routes: [
          GoRoute(
            path: '/admin/dashboard',
            builder: (context, state) => const DashboardPage(),
          ),
          GoRoute(
            path: '/admin/users',
            builder: (context, state) => const UsersPage(),
          ),
          GoRoute(
            path: '/admin/lessons',
            builder: (context, state) => const LessonsPage(),
          ),
          GoRoute(
            path: '/admin/exercises',
            builder: (context, state) => const ExercisesPage(),
          ),
          GoRoute(
            path: '/admin/blog-posts',
            builder: (context, state) => const BlogPostsPage(),
          ),
          GoRoute(
            path: '/admin/settings',
            builder: (context, state) => const SettingsPage(),
          ),
        ],
      ),
    ],
  );
});
