import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../auth/data/auth_api.dart';
import '../../auth/data/auth_models.dart';
import '../../auth/providers/auth_provider.dart';
import '../../social/data/social_api.dart';
import '../../social/data/social_models.dart';
import '../../social/presentation/widgets/social_owner_menu.dart';
import '../../social/presentation/widgets/social_post_card.dart';
import '../../social/providers/social_feed_provider.dart';
import '../data/profile_models.dart';
import '../providers/profile_cover_provider.dart';
import '../providers/profile_provider.dart';
import 'widgets/profile_cover.dart';
import 'widgets/profile_ui.dart';
import 'public_profile_navigation.dart';

class UserProfileScreen extends ConsumerStatefulWidget {
  const UserProfileScreen({super.key});

  @override
  ConsumerState<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends ConsumerState<UserProfileScreen> {
  final _scrollController = ScrollController();
  ProfileTab _tab = ProfileTab.posts;

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

    return ProfilePaletteScope.editorial(
      context: context,
      child: Builder(
        builder: (context) => Scaffold(
          key: const ValueKey('personal-profile-scaffold'),
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
                SliverSafeArea(
                  bottom: false,
                  sliver: SliverToBoxAdapter(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 680),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
                          child: _ProfileTopBar(
                            title: l10n.profile,
                            shareLabel: l10n.shareProfile,
                            settingsLabel: l10n.settings,
                            onShare: user == null ? null : () => _share(user),
                            onSettings: () => context.push('/profile/settings'),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 680),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
                        child: Column(
                          children: [
                            if (user != null)
                              _ProfileHeader(user: user, dashboard: dashboard)
                            else
                              const _ProfileLoading(),
                            const SizedBox(height: 22),
                            ProfileTabs(
                              selected: _tab,
                              postsLabel: l10n.myPosts,
                              achievementsLabel: l10n.achievements,
                              rankLabel: l10n.currentRank,
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
                                      ProfileTab.posts => _PostsTab(user: user),
                                      ProfileTab.achievements =>
                                        _AchievementsTab(dashboard: dashboard),
                                      ProfileTab.rank => const _RankTab(),
                                    },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 112)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _share(AuthUser user) async {
    await Clipboard.setData(ClipboardData(text: '/profile/${user.id}'));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.profileLinkCopied),
        ),
      );
  }
}

class _ProfileTopBar extends StatelessWidget {
  const _ProfileTopBar({
    required this.title,
    required this.shareLabel,
    required this.settingsLabel,
    required this.onShare,
    required this.onSettings,
  });

  final String title;
  final String shareLabel;
  final String settingsLabel;
  final VoidCallback? onShare;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Expanded(
        child: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: ProfilePalette.text(context),
            fontSize: 32,
            letterSpacing: -0.5,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      _ProfileHeaderAction(
        key: const ValueKey('profile-share'),
        tooltip: shareLabel,
        icon: Icons.ios_share_rounded,
        onPressed: onShare,
      ),
      const SizedBox(width: 10),
      _ProfileHeaderAction(
        key: const ValueKey('profile-settings'),
        tooltip: settingsLabel,
        icon: Icons.settings_outlined,
        backgroundColor: ProfilePalette.pink(context),
        onPressed: onSettings,
      ),
    ],
  );
}

class _ProfileHeaderAction extends StatelessWidget {
  const _ProfileHeaderAction({
    super.key,
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.backgroundColor,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: tooltip,
    onPressed: onPressed,
    style: IconButton.styleFrom(
      minimumSize: const Size.square(46),
      backgroundColor:
          backgroundColor ?? ProfilePalette.editorialSurface(context),
      foregroundColor: AppColors.editorialAubergine,
    ),
    icon: Icon(icon, size: 20),
  );
}

class _ProfileHeader extends ConsumerWidget {
  const _ProfileHeader({required this.user, required this.dashboard});

  final AuthUser user;
  final AsyncValue<ProfileDashboardData> dashboard;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final game = dashboard.asData?.value.gamification;
    final achievements = dashboard.asData?.value.achievements ?? const [];
    final earnedAchievements = achievements.where((item) => item.earned).length;
    final name = user.displayName.trim().isEmpty
        ? user.username
        : user.displayName.trim();
    final tier = readableProfileName(game?.currentTier ?? l10n.startingTier);
    final coverId = ref.watch(profileCoverProvider);
    final localAvatar = ref.watch(profileAvatarProvider);

    return Column(
      children: [
        _ProfileHeroCard(
          user: user,
          displayName: name,
          coverId: coverId,
          avatarPath: localAvatar,
          verifiedLabel: l10n.verified,
          fallbackBio: l10n.learningHeaderSubtitle,
        ),
        const SizedBox(height: 14),
        _ProfileStatsCard(
          totalXp: game?.totalXp ?? 0,
          currentStreak: game?.currentStreak ?? 0,
          earnedAchievements: earnedAchievements,
        ),
        const SizedBox(height: 14),
        _ProfileLearningCard(
          tier: tier,
          gamification: game,
          totalXpLabel: l10n.totalXp,
          currentStreakLabel: l10n.currentStreak,
          highestRankLabel: l10n.highestRankReached,
          xpUntilNextRank: l10n.xpUntilNextRank,
        ),
      ],
    );
  }
}

class _ProfileHeroCard extends StatelessWidget {
  const _ProfileHeroCard({
    required this.user,
    required this.displayName,
    required this.coverId,
    required this.avatarPath,
    required this.verifiedLabel,
    required this.fallbackBio,
  });

  final AuthUser user;
  final String displayName;
  final String coverId;
  final String? avatarPath;
  final String verifiedLabel;
  final String fallbackBio;

  @override
  Widget build(BuildContext context) {
    const height = 318.0;
    return SizedBox(
      height: height,
      child: Stack(
        children: [
          Positioned.fill(
            child: ProfileCover(
              key: const ValueKey('profile-cover'),
              coverId: coverId,
              height: height,
              borderRadius: AppRadii.extraLargeBorder,
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: AppRadii.extraLargeBorder,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.editorialAubergine.withValues(alpha: .94),
                    AppColors.editorialAubergineRaised.withValues(alpha: .8),
                  ],
                ),
              ),
            ),
          ),
          PositionedDirectional(
            start: -38,
            bottom: -68,
            child: _ProfileBlob(
              width: 210,
              height: 172,
              color: ProfilePalette.pink(context).withValues(alpha: .92),
            ),
          ),
          PositionedDirectional(
            start: 102,
            bottom: -84,
            child: _ProfileBlob(
              width: 145,
              height: 168,
              color: ProfilePalette.pink(context).withValues(alpha: .58),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                RiksaProfileAvatar(
                  key: const ValueKey('profile-hero-avatar'),
                  user: user,
                  radius: 52,
                  avatarPath: avatarPath,
                  borderColor: Colors.white,
                  ringColor: ProfilePalette.pink(context),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: _ProfileHeroIdentity(
                    user: user,
                    displayName: displayName,
                    verifiedLabel: verifiedLabel,
                    fallbackBio: fallbackBio,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileBlob extends StatelessWidget {
  const _ProfileBlob({
    required this.width,
    required this.height,
    required this.color,
  });

  final double width;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) => Transform.rotate(
    angle: -.24,
    child: Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(80),
      ),
    ),
  );
}

class _ProfileHeroIdentity extends StatelessWidget {
  const _ProfileHeroIdentity({
    required this.user,
    required this.displayName,
    required this.verifiedLabel,
    required this.fallbackBio,
  });

  final AuthUser user;
  final String displayName;
  final String verifiedLabel;
  final String fallbackBio;

  @override
  Widget build(BuildContext context) {
    final bio = user.bio?.trim().isNotEmpty == true
        ? user.bio!.trim()
        : fallbackBio;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          displayName,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: ProfilePalette.onAubergine(context),
            fontSize: 25,
            height: 1.05,
            letterSpacing: -.5,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          '@${user.username}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: ProfilePalette.onAubergine(context).withValues(alpha: .82),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        if (user.emailVerified) ...[
          _ProfileVerificationBadge(label: verifiedLabel),
          const SizedBox(height: 12),
        ] else
          const SizedBox(height: 10),
        Text(
          bio,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: ProfilePalette.onAubergine(context).withValues(alpha: .88),
            fontSize: 13,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

class _ProfileVerificationBadge extends StatelessWidget {
  const _ProfileVerificationBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey('profile-verification-badge'),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: ProfilePalette.pink(context),
      borderRadius: AppRadii.fullBorder,
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.verified_rounded,
          size: 15,
          color: ProfilePalette.aubergine(context),
        ),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: ProfilePalette.aubergine(context),
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    ),
  );
}

class _ProfileStatsCard extends StatelessWidget {
  const _ProfileStatsCard({
    required this.totalXp,
    required this.currentStreak,
    required this.earnedAchievements,
  });

  final int totalXp;
  final int currentStreak;
  final int earnedAchievements;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    return Container(
      key: const ValueKey('profile-stats'),
      padding: const EdgeInsets.symmetric(vertical: 17, horizontal: 8),
      decoration: BoxDecoration(
        color: ProfilePalette.editorialSurface(context),
        borderRadius: AppRadii.extraLargeBorder,
        border: Border.all(
          color: ProfilePalette.border(context).withValues(alpha: .45),
        ),
      ),
      child: Row(
        children: [
          _ProfileStat(
            value: NumberFormat.compact(locale: locale).format(totalXp),
            label: l10n.totalXp,
          ),
          const _ProfileStatDivider(),
          _ProfileStat(
            key: const ValueKey('profile-streak'),
            value: NumberFormat.decimalPattern(locale).format(currentStreak),
            label: l10n.currentStreak,
          ),
          const _ProfileStatDivider(),
          _ProfileStat(
            value: NumberFormat.decimalPattern(
              locale,
            ).format(earnedAchievements),
            label: l10n.achievements,
          ),
        ],
      ),
    );
  }
}

class _ProfileStat extends StatelessWidget {
  const _ProfileStat({super.key, required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        Text(
          value,
          maxLines: 1,
          style: TextStyle(
            color: ProfilePalette.text(context),
            fontSize: 23,
            height: 1,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: ProfilePalette.muted(context),
            fontSize: 11,
            height: 1.15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

class _ProfileStatDivider extends StatelessWidget {
  const _ProfileStatDivider();

  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 38, color: ProfilePalette.border(context));
}

class _ProfileLearningCard extends StatelessWidget {
  const _ProfileLearningCard({
    required this.tier,
    required this.gamification,
    required this.totalXpLabel,
    required this.currentStreakLabel,
    required this.highestRankLabel,
    required this.xpUntilNextRank,
  });

  final String tier;
  final GamificationProfile? gamification;
  final String totalXpLabel;
  final String currentStreakLabel;
  final String highestRankLabel;
  final String Function(int xp, String tier) xpUntilNextRank;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final totalXp = gamification?.totalXp ?? 0;
    final streak = gamification?.currentStreak ?? 0;
    final nextTier = gamification?.nextTier;
    final progress = gamification?.nextTierProgress ?? 0;
    final progressLabel = nextTier == null
        ? highestRankLabel
        : xpUntilNextRank(
            gamification?.xpToNext ?? 0,
            readableProfileName(nextTier),
          );
    return Semantics(
      label: '$tier, $totalXp $totalXpLabel, $streak $currentStreakLabel',
      child: Container(
        key: const ValueKey('profile-learning-card'),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: ProfilePalette.pinkSoft(context),
          borderRadius: AppRadii.extraLargeBorder,
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: const BoxDecoration(
                    color: AppColors.editorialAubergine,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: AppColors.editorialPink,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tier,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: ProfilePalette.text(context),
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        key: const ValueKey('profile-total-xp'),
                        '${NumberFormat.decimalPattern(locale).format(totalXp)} XP',
                        style: const TextStyle(
                          color: AppColors.editorialPink,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: ProfilePalette.editorialSurface(context),
                    borderRadius: AppRadii.fullBorder,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        NumberFormat.decimalPattern(locale).format(streak),
                        style: TextStyle(
                          color: ProfilePalette.text(context),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(width: 5),
                      const Icon(
                        Icons.local_fire_department_rounded,
                        color: AppColors.achievementSaffron,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 17),
            ClipRRect(
              borderRadius: AppRadii.fullBorder,
              child: LinearProgressIndicator(
                key: const ValueKey('profile-level-progress'),
                value: progress,
                minHeight: 10,
                backgroundColor: AppColors.editorialAubergine.withValues(
                  alpha: .14,
                ),
                valueColor: const AlwaysStoppedAnimation(
                  AppColors.editorialPink,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                progressLabel,
                style: TextStyle(
                  color: ProfilePalette.muted(context),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
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
                onAuthorTap: publicProfilePath(post.author.id) == null
                    ? null
                    : () => context.push(publicProfilePath(post.author.id)!),
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
                // This tab only ever lists the signed-in user's own posts.
                onEdit: () async {
                  final saved = await context.push<bool>(
                    '/community/posts/${post.id}/edit',
                    extra: post,
                  );
                  if (saved == true) ref.invalidate(userPostsProvider(user.id));
                },
                onDelete: () async {
                  if (!await confirmSocialPostDeletion(context)) return;
                  if (!context.mounted) return;
                  final l10n = AppLocalizations.of(context)!;
                  final messenger = ScaffoldMessenger.of(context);
                  final failure = await ref
                      .read(socialFeedProvider.notifier)
                      .deletePost(post.id);
                  ref.invalidate(userPostsProvider(user.id));
                  messenger
                    ..hideCurrentSnackBar()
                    ..showSnackBar(
                      SnackBar(content: Text(failure ?? l10n.postDeleted)),
                    );
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
  Widget build(BuildContext context) => ProfileAchievementTile(
    name: achievement.name,
    description: achievement.description,
    trailingLabel: '+${achievement.xpReward} XP',
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
    return ProfileRankCard(
      icon: icon,
      label: label,
      rank: rank,
      unrankedLabel: l10n.unranked,
      trailing: Column(
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
    );
  }
}

class _ProfileLoading extends StatelessWidget {
  const _ProfileLoading({super.key});

  @override
  Widget build(BuildContext context) => ProfileLoadingState(key: key);
}

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) =>
      ProfileEmptyPanel(icon: icon, message: message);
}

class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => ProfileErrorPanel(
    message: message,
    retryLabel: AppLocalizations.of(context)!.tryAgain,
    onRetry: onRetry,
  );
}

String _errorMessage(Object error, AppLocalizations l10n) {
  if (error is DioException) return dioErrorMessage(error);
  if (error is SocialApiException) return error.message;
  return l10n.profileLoadFailed;
}
