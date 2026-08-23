import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/riksa_bottom_navigation_bar.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../auth/data/auth_api.dart';
import '../../auth/data/auth_models.dart';
import '../../auth/providers/auth_provider.dart';
import '../../social/data/social_api.dart';
import '../../social/data/social_models.dart';
import '../../social/presentation/widgets/social_post_card.dart';
import '../../social/providers/social_feed_provider.dart';
import '../data/profile_models.dart';
import '../providers/profile_provider.dart';
import 'widgets/profile_ui.dart';

enum _ProfileTab { posts, achievements, rank }

class UserProfileScreen extends ConsumerStatefulWidget {
  const UserProfileScreen({super.key});

  @override
  ConsumerState<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends ConsumerState<UserProfileScreen> {
  final _scrollController = ScrollController();
  _ProfileTab _tab = _ProfileTab.posts;
  bool _navigationCollapsed = false;
  double _directionTravel = 0;
  double? _lastOffset;
  ScrollDirection? _trackedDirection;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    final current = position.pixels;
    final delta = current - (_lastOffset ?? current);
    _lastOffset = current;
    final direction = position.userScrollDirection;
    final down = direction == ScrollDirection.reverse && delta > 0;
    final up = direction == ScrollDirection.forward && delta < 0;
    if ((!down && !up) || delta.abs() < .1) return;
    if (_trackedDirection != direction) {
      _trackedDirection = direction;
      _directionTravel = 0;
    }
    _directionTravel += delta.abs();
    if (_directionTravel < 18) return;
    _directionTravel = 0;
    if (_navigationCollapsed != down) {
      setState(() => _navigationCollapsed = down);
    }
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final user = auth is Authenticated ? auth.user : null;
    final dashboard = ref.watch(profileDashboardProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: ProfilePalette.canvas(context),
      extendBody: true,
      bottomNavigationBar: RiksaBottomNavigationBar(
        currentIndex: 4,
        collapsed: _navigationCollapsed,
        onSelected: (index) {
          if (index == 0) {
            ref.invalidate(socialFeedProvider);
            context.go('/home');
          }
          if (index == 1) context.go('/learn');
          if (index == 2) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(l10n.aiTutorComingSoon)));
          }
        },
        onCollapsedTap: () {
          ref.invalidate(socialFeedProvider);
          context.go('/home');
        },
      ),
      body: RefreshIndicator(
        color: ProfilePalette.green,
        onRefresh: () async {
          ref
            ..invalidate(profileDashboardProvider)
            ..invalidate(profileRankProvider);
          if (user != null) ref.invalidate(userPostsProvider(user.id));
          await ref.read(profileDashboardProvider.future);
        },
        child: CustomScrollView(
          key: const PageStorageKey('user-profile-scroll'),
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              pinned: true,
              backgroundColor: ProfilePalette.canvas(
                context,
              ).withValues(alpha: .96),
              title: Text(
                l10n.profile,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              actions: [
                IconButton(
                  key: const ValueKey('profile-settings'),
                  tooltip: l10n.settings,
                  onPressed: () => context.push('/profile/settings'),
                  icon: const Icon(Icons.settings_outlined),
                ),
                const SizedBox(width: 10),
              ],
            ),
            SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 680),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
                    child: Column(
                      children: [
                        if (user != null)
                          _ProfileHeader(user: user, dashboard: dashboard)
                        else
                          const _ProfileLoading(),
                        const SizedBox(height: 22),
                        _ProfileTabs(
                          selected: _tab,
                          onSelected: (tab) => setState(() => _tab = tab),
                        ),
                        const SizedBox(height: 18),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 180),
                          child: user == null
                              ? const _ProfileLoading()
                              : switch (_tab) {
                                  _ProfileTab.posts => _PostsTab(user: user),
                                  _ProfileTab.achievements => _AchievementsTab(
                                    dashboard: dashboard,
                                  ),
                                  _ProfileTab.rank => const _RankTab(),
                                },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 118)),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.user, required this.dashboard});

  final AuthUser user;
  final AsyncValue<ProfileDashboardData> dashboard;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final game = dashboard.asData?.value.gamification;
    final name = user.displayName.trim().isEmpty
        ? user.username
        : user.displayName.trim();
    final tier = readableProfileName(game?.currentTier ?? l10n.startingTier);

    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            RiksaProfileAvatar(user: user, radius: 49),
            PositionedDirectional(
              end: -25,
              top: 3,
              child: Container(
                key: const ValueKey('profile-streak'),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: ProfilePalette.panelSoft(context),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: ProfilePalette.border(context)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.local_fire_department_rounded,
                      color: ProfilePalette.streak,
                      size: 17,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '${game?.currentStreak ?? 0}',
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              user.emailVerified
                  ? Icons.verified_rounded
                  : Icons.workspace_premium_rounded,
              color: ProfilePalette.green,
              size: 20,
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          '@${user.username}',
          style: TextStyle(color: ProfilePalette.muted(context)),
        ),
        if (user.bio?.trim().isNotEmpty == true) ...[
          const SizedBox(height: 10),
          Text(
            user.bio!.trim(),
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Color(0xFFC6CDC7), height: 1.45),
          ),
        ],
        const SizedBox(height: 22),
        ProfilePanel(
          padding: const EdgeInsets.symmetric(vertical: 17, horizontal: 8),
          child: Row(
            children: [
              _HeaderStat(
                key: const ValueKey('profile-tier'),
                value: tier,
                label: l10n.currentRank,
                color: ProfilePalette.green,
              ),
              const _StatDivider(),
              _HeaderStat(
                key: const ValueKey('profile-total-xp'),
                value: NumberFormat.compact().format(game?.totalXp ?? 0),
                label: l10n.totalXp,
                color: ProfilePalette.xp,
              ),
              const _StatDivider(),
              _HeaderStat(
                value: '${game?.currentStreak ?? 0}',
                label: l10n.currentStreak,
                color: ProfilePalette.streak,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeaderStat extends StatelessWidget {
  const _HeaderStat({
    super.key,
    required this.value,
    required this.label,
    required this.color,
  });

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: color,
            fontSize: 17,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: ProfilePalette.muted(context),
            fontSize: 10.5,
          ),
        ),
      ],
    ),
  );
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 34,
    child: VerticalDivider(color: ProfilePalette.border(context), width: 1),
  );
}

class _ProfileTabs extends StatelessWidget {
  const _ProfileTabs({required this.selected, required this.onSelected});

  final _ProfileTab selected;
  final ValueChanged<_ProfileTab> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        _TabButton(
          key: const ValueKey('profile-posts-tab'),
          label: l10n.myPosts,
          selected: selected == _ProfileTab.posts,
          onTap: () => onSelected(_ProfileTab.posts),
        ),
        const SizedBox(width: 8),
        _TabButton(
          key: const ValueKey('profile-achievements-tab'),
          label: l10n.achievements,
          selected: selected == _ProfileTab.achievements,
          onTap: () => onSelected(_ProfileTab.achievements),
        ),
        const SizedBox(width: 8),
        _TabButton(
          key: const ValueKey('profile-rank-tab'),
          label: l10n.leaderboardRank,
          selected: selected == _ProfileTab.rank,
          onTap: () => onSelected(_ProfileTab.rank),
        ),
      ],
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Expanded(
    child: InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? ProfilePalette.greenSoft(context)
              : ProfilePalette.panel(context),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? ProfilePalette.green
                : ProfilePalette.border(context),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: selected
                ? ProfilePalette.green
                : ProfilePalette.muted(context),
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    ),
  );
}

class _PostsTab extends ConsumerWidget {
  const _PostsTab({required this.user});

  final AuthUser user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final posts = ref.watch(userPostsProvider(user.id));
    final l10n = AppLocalizations.of(context)!;
    return posts.when(
      loading: () => const _ProfileLoading(key: ValueKey('posts-loading')),
      error: (error, _) => _ErrorPanel(
        message: _errorMessage(error, l10n),
        onRetry: () => ref.invalidate(userPostsProvider(user.id)),
      ),
      data: (page) {
        if (page.posts.isEmpty) {
          return _EmptyPanel(
            icon: Icons.forum_outlined,
            message: l10n.noPostsYet,
          );
        }
        return Column(
          key: const ValueKey('profile-posts'),
          children: [
            for (final post in page.posts)
              SocialPostCard(
                post: post,
                onTap: () => context.push('/community/posts/${post.id}'),
                onReact: () async {
                  await ref
                      .read(socialApiProvider)
                      .react(postId: post.id, reaction: SocialReaction.upvote);
                  ref.invalidate(userPostsProvider(user.id));
                },
                onShare: () async {
                  await ref.read(socialApiProvider).share(post.id);
                  ref.invalidate(userPostsProvider(user.id));
                },
              ),
          ],
        );
      },
    );
  }
}

class _AchievementsTab extends StatelessWidget {
  const _AchievementsTab({required this.dashboard});

  final AsyncValue<ProfileDashboardData> dashboard;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return dashboard.when(
      loading: () =>
          const _ProfileLoading(key: ValueKey('achievements-loading')),
      error: (error, _) => _EmptyPanel(
        icon: Icons.cloud_off_rounded,
        message: _errorMessage(error, l10n),
      ),
      data: (data) {
        final earned = data.achievements.where((item) => item.earned).toList();
        if (earned.isEmpty) {
          return _EmptyPanel(
            icon: Icons.workspace_premium_outlined,
            message: l10n.noAchievements,
          );
        }
        return GridView.builder(
          key: const ValueKey('profile-achievements-grid'),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.08,
          ),
          itemCount: earned.length,
          itemBuilder: (context, index) =>
              _AchievementTile(achievement: earned[index]),
        );
      },
    );
  }
}

class _AchievementTile extends StatelessWidget {
  const _AchievementTile({required this.achievement});

  final ProfileAchievement achievement;

  @override
  Widget build(BuildContext context) => ProfilePanel(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: ProfilePalette.greenSoft(context),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.workspace_premium_rounded,
                color: ProfilePalette.green,
              ),
            ),
            const Spacer(),
            Text(
              '+${achievement.xpReward} XP',
              style: const TextStyle(
                color: ProfilePalette.xp,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const Spacer(),
        Text(
          achievement.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w900, height: 1.2),
        ),
        const SizedBox(height: 5),
        Text(
          achievement.description,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: ProfilePalette.muted(context),
            fontSize: 11,
            height: 1.3,
          ),
        ),
      ],
    ),
  );
}

class _RankTab extends ConsumerWidget {
  const _RankTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rank = ref.watch(profileRankProvider);
    final l10n = AppLocalizations.of(context)!;
    return rank.when(
      loading: () => const _ProfileLoading(key: ValueKey('rank-loading')),
      error: (error, _) => _ErrorPanel(
        message: _errorMessage(error, l10n),
        onRetry: () => ref.invalidate(profileRankProvider),
      ),
      data: (data) => Column(
        key: const ValueKey('profile-rank'),
        children: [
          _RankCard(
            icon: Icons.public_rounded,
            label: l10n.countryRank,
            rank: data.countryRank,
            score: data.countryScore,
            tier: data.countryTier,
          ),
          const SizedBox(height: 12),
          _RankCard(
            icon: Icons.location_on_outlined,
            label: l10n.provinceRank,
            rank: data.provinceRank ?? 0,
            score: data.provinceScore ?? 0,
            tier: data.provinceTier,
          ),
        ],
      ),
    );
  }
}

class _RankCard extends StatelessWidget {
  const _RankCard({
    required this.icon,
    required this.label,
    required this.rank,
    required this.score,
    this.tier,
  });

  final IconData icon;
  final String label;
  final int rank;
  final int score;
  final String? tier;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ProfilePanel(
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: ProfilePalette.greenSoft(context),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: ProfilePalette.green),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: ProfilePalette.muted(context),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  rank > 0 ? '#$rank' : l10n.unranked,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$score XP',
                style: const TextStyle(
                  color: ProfilePalette.xp,
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (tier != null)
                Text(
                  readableProfileName(tier!),
                  style: const TextStyle(
                    color: ProfilePalette.green,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfileLoading extends StatelessWidget {
  const _ProfileLoading({super.key});

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 36),
    child: Center(
      child: CircularProgressIndicator(color: ProfilePalette.green),
    ),
  );
}

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) => ProfilePanel(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          Icon(icon, color: ProfilePalette.green, size: 34),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: ProfilePalette.muted(context)),
          ),
        ],
      ),
    ),
  );
}

class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => ProfilePanel(
    child: Column(
      children: [
        Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(color: ProfilePalette.muted(context)),
        ),
        const SizedBox(height: 12),
        FilledButton.tonal(
          onPressed: onRetry,
          child: Text(AppLocalizations.of(context)!.tryAgain),
        ),
      ],
    ),
  );
}

String _errorMessage(Object error, AppLocalizations l10n) {
  if (error is DioException) return dioErrorMessage(error);
  if (error is SocialApiException) return error.message;
  return l10n.profileLoadFailed;
}
