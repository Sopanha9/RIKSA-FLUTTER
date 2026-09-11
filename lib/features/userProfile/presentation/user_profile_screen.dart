import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/riksa_rank_badge.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../auth/data/auth_api.dart';
import '../../auth/data/auth_models.dart';
import '../../auth/providers/auth_provider.dart';
import '../../social/data/social_api.dart';
import '../../social/data/social_models.dart';
import '../../social/presentation/widgets/social_create_menu.dart';
import '../../social/presentation/widgets/social_owner_menu.dart';
import '../../social/presentation/widgets/social_post_card.dart';
import '../../social/providers/social_feed_provider.dart';
import '../data/profile_models.dart';
import '../providers/profile_cover_provider.dart';
import '../providers/profile_provider.dart';
import 'widgets/profile_cover.dart';
import 'widgets/profile_post_actions.dart';
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
                    child: centeredProfileColumn(
                      Padding(
                        padding: const EdgeInsets.fromLTRB(18, 4, 18, 8),
                        child: _ProfileTopBar(
                          shareLabel: l10n.shareProfile,
                          settingsLabel: l10n.settings,
                          editLabel: l10n.editProfile,
                          onShare: user == null ? null : () => _share(user),
                          onSettings: () => context.push('/profile/settings'),
                          onEdit: () => context.push('/profile/edit'),
                        ),
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: centeredProfileColumn(
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
                      child: user == null
                          ? const _ProfileLoading()
                          : _ProfileHeader(user: user, dashboard: dashboard),
                    ),
                  ),
                ),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: ProfileTabsHeaderDelegate(
                    extent: ProfileTabs.heightFor(context),
                    color: ProfilePalette.canvas(context),
                    tabs: ProfileTabs(
                      selected: _tab,
                      postsLabel: l10n.myPosts,
                      achievementsLabel: l10n.achievements,
                      rankLabel: l10n.currentRank,
                      onSelected: (tab) => setState(() => _tab = tab),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: centeredProfileColumn(
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
                      child: AnimatedSwitcher(
                        duration: RiksaMotion.resolve(
                          context,
                          RiksaMotion.standard,
                        ),
                        child: user == null
                            ? const _ProfileLoading()
                            : switch (_tab) {
                                ProfileTab.posts => _PostsTab(user: user),
                                ProfileTab.achievements => _AchievementsTab(
                                  dashboard: dashboard,
                                ),
                                ProfileTab.rank => const _RankTab(),
                              },
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

/// The screen's action row.
///
/// It carries no "Profile" title: the bottom navigation already labels this
/// tab, and repeating it here spent a full row on a word the user can see.
/// Utilities sit leading, the one primary action trailing.
class _ProfileTopBar extends StatelessWidget {
  const _ProfileTopBar({
    required this.shareLabel,
    required this.settingsLabel,
    required this.editLabel,
    required this.onShare,
    required this.onSettings,
    required this.onEdit,
  });

  final String shareLabel;
  final String settingsLabel;
  final String editLabel;
  final VoidCallback? onShare;
  final VoidCallback onSettings;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 44,
    child: Row(
      children: [
        ProfileIconAction(
          key: const ValueKey('profile-share'),
          tooltip: shareLabel,
          icon: Icons.ios_share_rounded,
          onPressed: onShare ?? () {},
        ),
        const SizedBox(width: 8),
        ProfileIconAction(
          key: const ValueKey('profile-settings'),
          tooltip: settingsLabel,
          icon: Icons.settings_outlined,
          onPressed: onSettings,
        ),
        // Expanded, not Spacer plus Flexible: those two compete for the free
        // space and truncate a long Khmer label while room is still going
        // spare. Here the button takes all of it and aligns itself trailing.
        Expanded(
          child: Align(
            alignment: AlignmentDirectional.centerEnd,
            child: _ProfileEditButton(
              key: const ValueKey('profile-edit'),
              label: editLabel,
              onPressed: onEdit,
            ),
          ),
        ),
      ],
    ),
  );
}

/// The primary action on the signed-in user's own profile, matching the
/// position X gives its edit control.
class _ProfileEditButton extends StatelessWidget {
  const _ProfileEditButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => OutlinedButton(
    onPressed: onPressed,
    style: OutlinedButton.styleFrom(
      minimumSize: const Size(0, 44),
      padding: const EdgeInsets.symmetric(horizontal: 18),
      foregroundColor: ProfilePalette.text(context),
      side: BorderSide(color: ProfilePalette.border(context)),
      shape: const RoundedRectangleBorder(borderRadius: AppRadii.fullBorder),
    ),
    // Styled on the child so the label keeps the theme's font family.
    child: Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800),
    ),
  );
}

class _ProfileHeader extends ConsumerWidget {
  const _ProfileHeader({required this.user, required this.dashboard});

  final AuthUser user;
  final AsyncValue<ProfileDashboardData> dashboard;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final game = dashboard.asData?.value.gamification;
    final achievements = dashboard.asData?.value.achievements ?? const [];
    final earnedAchievements = achievements.where((item) => item.earned).length;
    final name = user.displayName.trim().isEmpty
        ? user.username
        : user.displayName.trim();
    final tier = readableProfileName(game?.currentTier ?? l10n.startingTier);
    final coverId = ref.watch(profileCoverProvider);
    final localAvatar = ref.watch(profileAvatarProvider);
    final decimal = NumberFormat.decimalPattern(locale);

    return ProfileIdentityHeader(
      cover: ProfileCover(
        key: const ValueKey('profile-cover'),
        coverId: coverId,
        height: ProfileIdentityHeader.coverHeight,
        borderRadius: AppRadii.largeBorder,
      ),
      avatar: RiksaProfileAvatar(
        key: const ValueKey('profile-hero-avatar'),
        user: user,
        radius: 44,
        avatarPath: localAvatar,
        frameTier: game?.currentTier,
        // A ring in the page ground separates the avatar from the banner.
        borderColor: ProfilePalette.canvas(context),
        ringColor: ProfilePalette.canvas(context),
      ),
      displayName: name,
      username: user.username,
      bio: user.bio?.trim().isNotEmpty == true
          ? user.bio
          : l10n.learningHeaderSubtitle,
      isVerified: user.emailVerified,
      verifiedKey: const ValueKey('profile-verification-badge'),
      metadata: [
        ?_provinceMeta(ref, locale),
        if (user.createdAt != null)
          ProfileMetaItem(
            icon: Icons.calendar_today_outlined,
            label:
                '${l10n.joined} ${DateFormat.yMMMM(locale).format(user.createdAt!.toLocal())}',
          ),
      ],
      countsKey: const ValueKey('profile-stats'),
      counts: [
        ProfileCountItem(
          value: decimal.format(game?.totalXp ?? 0),
          label: l10n.totalXp,
        ),
        ProfileCountItem(
          itemKey: const ValueKey('profile-streak'),
          value: decimal.format(game?.currentStreak ?? 0),
          label: l10n.currentStreak,
        ),
        ProfileCountItem(
          value: decimal.format(earnedAchievements),
          label: l10n.achievements,
        ),
      ],
      footer: _ProfileLearningCard(
        tier: tier,
        gamification: game,
        highestRankLabel: l10n.highestRankReached,
      ),
    );
  }

  /// The user's province, when the options list has already resolved. Absent
  /// while it loads rather than showing a raw province id.
  ProfileMetaItem? _provinceMeta(WidgetRef ref, String locale) {
    final provinceId = user.provinceId;
    if (provinceId == null || provinceId.isEmpty) return null;
    final options = ref.watch(provinceOptionsProvider).asData?.value;
    if (options == null) return null;
    for (final option in options) {
      if (option.id != provinceId) continue;
      final label = locale == 'km' ? option.nameKhmer : option.nameLatin;
      if (label.trim().isEmpty) return null;
      return ProfileMetaItem(
        icon: Icons.location_on_outlined,
        label: label.trim(),
      );
    }
    return null;
  }
}

/// Where the learner sits on the rank ladder, and how far the end is.
///
/// It deliberately shows neither total XP nor the streak: the counts line
/// directly above already carries both, and XP is a consequence of studying,
/// not the headline.
class _ProfileLearningCard extends StatelessWidget {
  const _ProfileLearningCard({
    required this.tier,
    required this.gamification,
    required this.highestRankLabel,
  });

  final String tier;
  final GamificationProfile? gamification;
  final String highestRankLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final decimal = NumberFormat.decimalPattern(locale);
    final game = gamification;

    final currentTier = game?.currentTier;
    final ladderIndex = currentTier == null
        ? -1
        : profileTierLadder.indexOf(currentTier.toUpperCase());
    final nextTier = game?.nextTier;
    final isFinalStep =
        nextTier != null &&
        profileTierLadder.indexOf(nextTier.toUpperCase()) ==
            profileTierLadder.length - 1;

    final progressLabel = nextTier == null
        ? highestRankLabel
        : isFinalStep
        ? l10n.xpUntilFinalRank(
            game?.xpToNext ?? 0,
            readableProfileName(nextTier),
          )
        : l10n.xpUntilNextRank(
            game?.xpToNext ?? 0,
            readableProfileName(nextTier),
          );

    final band = game != null && game.tierBandXp > 0
        ? l10n.tierBandProgress(
            decimal.format(game.xpIntoTier),
            decimal.format(game.tierBandXp),
          )
        : null;

    return Semantics(
      label: ladderIndex < 0
          ? tier
          : '$tier, ${l10n.tierPosition(ladderIndex + 1, profileTierLadder.length)}',
      child: Container(
        key: const ValueKey('profile-learning-card'),
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
        decoration: BoxDecoration(
          color: ProfilePalette.pinkSoft(context),
          borderRadius: AppRadii.extraLargeBorder,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Absent when the server reports a tier this build does not know,
            // rather than drawing a rail with nothing marked on it.
            if (ladderIndex >= 0) ...[
              ProfileTierRail(
                key: const ValueKey('profile-tier-rail'),
                tiers: profileTierLadder,
                currentIndex: ladderIndex,
                // The end label is dropped when the learner is standing on
                // it: the heading below already names that tier.
                startLabel: ladderIndex == 0
                    ? ''
                    : readableProfileName(profileTierLadder.first),
                endLabel: ladderIndex == profileTierLadder.length - 1
                    ? ''
                    : readableProfileName(profileTierLadder.last),
              ),
              const SizedBox(height: 18),
            ],
            Row(
              children: [
                RiksaRankBadge(tier: currentTier, size: 48),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    tier,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: ProfilePalette.text(context),
                      fontSize: 21,
                      letterSpacing: -.2,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (band != null) ...[
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      key: const ValueKey('profile-tier-band'),
                      band,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                      style: TextStyle(
                        color: ProfilePalette.muted(context),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            // At the top of the ladder there is nothing left to fill, and a
            // permanently full bar is decoration.
            if (nextTier != null) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: AppRadii.fullBorder,
                child: TweenAnimationBuilder<double>(
                  // Fills towards the next tier on arrival, so the gap left to
                  // close is what the learner sees rather than a static bar.
                  tween: Tween<double>(
                    begin: 0,
                    end: (game?.nextTierProgress ?? 0).clamp(0, 1).toDouble(),
                  ),
                  duration: RiksaMotion.resolve(
                    context,
                    RiksaMotion.emphasisLong,
                  ),
                  curve: RiksaMotion.standardCurve,
                  builder: (context, animated, _) => LinearProgressIndicator(
                    key: const ValueKey('profile-level-progress'),
                    value: animated,
                    minHeight: 8,
                    backgroundColor: AppColors.editorialAubergine.withValues(
                      alpha: .14,
                    ),
                    valueColor: const AlwaysStoppedAnimation(
                      AppColors.editorialPink,
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 9),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                progressLabel,
                style: TextStyle(
                  color: ProfilePalette.muted(context),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The author's own posts, with the whole lifecycle in one place: the
/// composer at the top, then each post carrying its own edit and delete.
class _PostsTab extends ConsumerStatefulWidget {
  const _PostsTab({required this.user});

  final AuthUser user;

  @override
  ConsumerState<_PostsTab> createState() => _PostsTabState();
}

class _PostsTabState extends ConsumerState<_PostsTab> {
  @override
  Widget build(BuildContext context) {
    final posts = ref.watch(userPostsProvider(widget.user.id));
    final l10n = AppLocalizations.of(context)!;
    return Column(
      key: const ValueKey('profile-posts-tab'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ProfileComposerPrompt(
          user: widget.user,
          avatarPath: ref.watch(profileAvatarProvider),
          frameTier: ref
              .watch(profileDashboardProvider)
              .value
              ?.gamification
              .currentTier,
          onTap: _create,
        ),
        const SizedBox(height: 14),
        posts.when(
          loading: () => const _ProfileLoading(key: ValueKey('posts-loading')),
          error: (error, _) => _ErrorPanel(
            message: _errorMessage(error, l10n),
            onRetry: () => ref.invalidate(userPostsProvider(widget.user.id)),
          ),
          data: (page) => page.posts.isEmpty
              ? ProfilePostsEmpty(onCreate: _create)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ProfilePostsSummary(count: page.posts.length),
                    const SizedBox(height: 10),
                    Column(
                      key: const ValueKey('profile-posts'),
                      children: [
                        for (final post in page.posts)
                          GestureDetector(
                            behavior: HitTestBehavior.deferToChild,
                            onLongPress: () => _manage(post),
                            child: SocialPostCard(
                              post: post,
                              onTap: () =>
                                  context.push('/community/posts/${post.id}'),
                              onAuthorTap:
                                  publicProfilePath(post.author.id) == null
                                  ? null
                                  : () => context.push(
                                      publicProfilePath(post.author.id)!,
                                    ),
                              onReact: () async {
                                await ref
                                    .read(socialApiProvider)
                                    .react(
                                      postId: post.id,
                                      reaction: SocialReaction.upvote,
                                    );
                                _refresh();
                              },
                              onShare: () async {
                                await ref
                                    .read(socialApiProvider)
                                    .share(post.id);
                                _refresh();
                              },
                              // This tab only ever lists the signed-in user's
                              // own posts, so every card is editable.
                              onEdit: () => _edit(post),
                              onDelete: () => _delete(post),
                              // The author already owns this screen, so an
                              // official tint here would only make their own
                              // posts look unlike the ones readers see.
                              highlightOfficial: false,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  void _refresh() => ref.invalidate(userPostsProvider(widget.user.id));

  /// Writes a new post, question or article. An article never lands in this
  /// tab — it waits for moderation — so the author is taken to the one list
  /// that shows it.
  Future<void> _create() async {
    final action = await showSocialCreateMenu(context);
    if (!mounted || action == null) return;
    final created = await context.push<bool>(socialCreateRoute(action));
    if (created != true || !mounted) return;
    if (action == SocialCreateAction.article) {
      await context.push<void>('/blog/my-posts');
      return;
    }
    _refresh();
  }

  Future<void> _manage(SocialPost post) async {
    final action = await showProfilePostActions(context, title: post.title);
    if (!mounted || action == null) return;
    switch (action) {
      case ProfilePostAction.edit:
        await _edit(post);
      case ProfilePostAction.delete:
        await _delete(post);
    }
  }

  Future<void> _edit(SocialPost post) async {
    final saved = await context.push<bool>(
      '/community/posts/${post.id}/edit',
      extra: post,
    );
    if (saved != true || !mounted) return;
    _refresh();
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l10n.postUpdated)));
  }

  Future<void> _delete(SocialPost post) async {
    if (!await confirmSocialPostDeletion(context)) return;
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final failure = await ref
        .read(socialFeedProvider.notifier)
        .deletePost(post.id);
    _refresh();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(failure ?? l10n.postDeleted)));
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
        return ProfileAchievementGrid(
          key: const ValueKey('profile-achievements-grid'),
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
    iconUrl: achievement.iconUrl,
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
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                RiksaRankBadge(tier: tier, size: 28),
                const SizedBox(width: 4),
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
