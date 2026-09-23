import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../auth/providers/auth_provider.dart';
import '../../mascot/domain/buddy_behavior.dart';
import '../../social/providers/social_feed_provider.dart';
import '../../userProfile/data/profile_models.dart';
import '../../userProfile/providers/profile_provider.dart';
import 'widgets/home_sections.dart';

class HomeDashboardScreen extends ConsumerWidget {
  const HomeDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final auth = ref.watch(authProvider);
    final user = auth is Authenticated ? auth.user : null;
    final name = user?.displayName.trim().isNotEmpty == true
        ? user!.displayName.trim()
        : l10n.riksaLearner;
    final streak = ref.watch(communityStreakProvider).value?.current ?? 0;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(profileRankProvider);
          ref.invalidate(leaderboardProvider(LeaderboardScope.province));
          ref.read(socialFeedProvider.notifier).load();
          await ref.refreshHomeStudy();
        },
        child: CustomScrollView(
          key: const PageStorageKey('home-dashboard-scroll'),
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverSafeArea(
              bottom: false,
              sliver: SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  RiksaSpacing.md,
                  RiksaSpacing.md,
                  RiksaSpacing.md,
                  0,
                ),
                sliver: SliverList.list(
                  children: [
                    HomeIdentityHeader(
                      name: name,
                      streak: streak,
                      reaction: BuddyBehavior.resolve(
                        BuddyEvent.appHomeArrival,
                      ),
                    ),
                    const SizedBox(height: RiksaSpacing.lg),
                    const HomeStudySection(),
                    const SizedBox(height: RiksaSpacing.lg),
                    HomeProvinceSection(user: user),
                    const SizedBox(height: RiksaSpacing.lg),
                    const HomeCommunitiesSection(),
                    const SizedBox(height: RiksaSpacing.md),
                    const HomeUtilityRow(),
                    SizedBox(
                      height:
                          MediaQuery.paddingOf(context).bottom +
                          RiksaSpacing.xl * 3,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
