import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/providers/auth_provider.dart';
import '../../userProfile/providers/profile_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/riksa_components.dart';

class HomeDashboardScreen extends ConsumerWidget {
  const HomeDashboardScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final profile = ref.watch(profileDashboardProvider);
    final name = auth is Authenticated ? auth.user.displayName : 'Learner';
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: RiksaPageHeader(
              title: 'Hello, $name',
              subtitle: 'What will you learn today?',
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
            sliver: SliverList.list(
              children: [
                profile.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (_, _) => const SizedBox.shrink(),
                  data: (data) => RiksaPastelCard(
                    tone: RiksaPastelTone.saffron,
                    child: Row(
                      children: [
                        const Icon(
                          Icons.local_fire_department_rounded,
                          size: 34,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '${data.gamification.currentStreak} day streak • ${data.gamification.totalXp} XP',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.push('/progress'),
                          child: const Text('Details'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _DashboardAction(
                  icon: Icons.play_circle_fill_rounded,
                  color: context.riksa.jade,
                  title: 'Continue learning',
                  subtitle: 'Resume your active lesson',
                  onTap: () => context.push('/learn/resume'),
                ),
                const SizedBox(height: 12),
                _DashboardAction(
                  icon: Icons.school_rounded,
                  color: context.riksa.math,
                  title: 'Explore lessons',
                  subtitle: 'Build your STEM roadmap',
                  onTap: () => context.go('/learn'),
                ),
                const SizedBox(height: 12),
        _DashboardAction(
          icon: Icons.groups_rounded,
          color: context.riksa.jadeStrong,
          title: 'Communities',
          subtitle: 'Find and join learning groups',
          onTap: () => context.push('/communities'),
        ),
        const SizedBox(height: 12),
        _DashboardAction(
          icon: Icons.forum_rounded,
          color: context.riksa.jadeStrong,
          title: 'Community feed',
          subtitle: 'Ask questions and share what you know',
          onTap: () => context.push('/community'),
        ),
                const SizedBox(height: 12),
                _DashboardAction(
                  icon: Icons.auto_awesome_rounded,
                  color: context.riksa.saffron,
                  title: 'Ask AI Tutor',
                  subtitle: 'Get a step-by-step explanation',
                  onTap: () => context.go('/ai'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardAction extends StatelessWidget {
  const _DashboardAction({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => RiksaPastelCard(
    onTap: onTap,
    child: Row(
      children: [
        CircleAvatar(
          backgroundColor: color,
          child: Icon(icon, color: Colors.white),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              Text(subtitle),
            ],
          ),
        ),
        const Icon(Icons.chevron_right_rounded),
      ],
    ),
  );
}
