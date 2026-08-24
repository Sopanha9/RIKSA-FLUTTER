import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/riksa_components.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../auth/data/auth_api.dart';
import '../../auth/data/auth_models.dart';
import '../../auth/providers/auth_provider.dart';
import '../../social/data/social_api.dart';
import '../../social/data/social_models.dart';
import '../../social/presentation/widgets/social_post_card.dart';
import '../../social/providers/social_feed_provider.dart';
import '../data/profile_models.dart';
import '../providers/profile_cover_provider.dart';
import '../providers/profile_provider.dart';
import 'widgets/profile_cover.dart';
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

  @override
  void dispose() {
    _scrollController.dispose();
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
      body: RefreshIndicator(
        color: ProfilePalette.green(context),
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
            SliverToBoxAdapter(
              child: RiksaPageHeader(
                title: l10n.profile,
                subtitle: l10n.learningHeaderSubtitle,
                trailing: IconButton.filledTonal(
                  key: const ValueKey('profile-settings'),
                  tooltip: l10n.settings,
                  onPressed: () => context.push('/profile/settings'),
                  icon: const Icon(Icons.settings_outlined),
                ),
              ),
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
                          duration: RiksaMotion.resolve(
                            context,
                            RiksaMotion.standard,
                          ),
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
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeader extends ConsumerWidget {
  const _ProfileHeader({required this.user, required this.dashboard});

  final AuthUser user;
  final AsyncValue<ProfileDashboardData> dashboard;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final game = dashboard.asData?.value.gamification;
    final name = user.displayName.trim().isEmpty
        ? user.username
        : user.displayName.trim();
    final tier = readableProfileName(game?.currentTier ?? l10n.startingTier);
    final coverId = ref.watch(profileCoverProvider);

    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            ProfileCover(
              key: const ValueKey('profile-cover'),
              coverId: coverId,
            ),
            PositionedDirectional(
              start: 0,
              end: 0,
              bottom: -49,
              child: Center(child: RiksaProfileAvatar(user: user, radius: 49)),
            ),
          ],
        ),
        const SizedBox(height: 61),
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
              color: ProfilePalette.green(context),
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
        const SizedBox(height: 18),
        Semantics(
          label:
              '$tier, ${NumberFormat.compact().format(game?.totalXp ?? 0)} ${l10n.totalXp}',
          child: ProfilePanel(
            padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 14),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: ProfilePalette.greenSoft(context),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.workspace_premium_outlined,
                    color: ProfilePalette.green(context),
                    size: 19,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ClipRRect(
                    borderRadius: AppRadii.fullBorder,
                    child: LinearProgressIndicator(
                      key: const ValueKey('profile-level-progress'),
                      value: game?.nextTierProgress ?? 0,
                      minHeight: 7,
                      backgroundColor: ProfilePalette.greenSoft(context),
                      valueColor: AlwaysStoppedAnimation(
                        ProfilePalette.green(context),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  key: const ValueKey('profile-total-xp'),
                  '${NumberFormat.compact().format(game?.totalXp ?? 0)} XP',
                  style: TextStyle(
                    color: ProfilePalette.text(context),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
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
      borderRadius: AppRadii.smallBorder,
      onTap: onTap,
      child: AnimatedContainer(
        duration: RiksaMotion.resolve(context, RiksaMotion.standard),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? ProfilePalette.greenSoft(context)
              : ProfilePalette.panel(context),
          borderRadius: AppRadii.smallBorder,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: selected
                ? ProfilePalette.green(context)
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
                color: AppColors.gamificationOrangeSoft,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.workspace_premium_rounded,
                color: context.riksa.saffron,
              ),
            ),
            const Spacer(),
            Text(
              '+${achievement.xpReward} XP',
              style: TextStyle(
                color: ProfilePalette.xp(context),
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
            child: Icon(icon, color: ProfilePalette.green(context)),
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
                style: TextStyle(
                  color: ProfilePalette.xp(context),
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (tier != null)
                Text(
                  readableProfileName(tier!),
                  style: TextStyle(
                    color: ProfilePalette.green(context),
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
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 36),
    child: Center(
      child: CircularProgressIndicator(color: ProfilePalette.green(context)),
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
          Icon(icon, color: ProfilePalette.green(context), size: 34),
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
