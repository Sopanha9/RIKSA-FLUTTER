import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/riksa_avatar_image.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../auth/providers/auth_provider.dart';
import '../../social/data/social_models.dart';
import '../../social/presentation/widgets/social_owner_menu.dart';
import '../../social/presentation/widgets/social_post_card.dart';
import '../../social/providers/social_feed_provider.dart';
import '../data/public_profile.dart';
import '../providers/public_profile_provider.dart';
import 'public_profile_navigation.dart';
import 'widgets/profile_ui.dart';

class PublicProfileScreen extends ConsumerStatefulWidget {
  const PublicProfileScreen({super.key, required this.userId});

  final String userId;

  @override
  ConsumerState<PublicProfileScreen> createState() =>
      _PublicProfileScreenState();
}

class _PublicProfileScreenState extends ConsumerState<PublicProfileScreen> {
  ProfileTab _tab = ProfileTab.posts;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(publicProfileProvider(widget.userId));
    final l10n = AppLocalizations.of(context)!;

    return ProfilePaletteScope.editorial(
      context: context,
      child: Builder(
        builder: (context) => Scaffold(
          key: const ValueKey('public-profile-scaffold'),
          backgroundColor: ProfilePalette.canvas(context),
          appBar: AppBar(
            backgroundColor: ProfilePalette.canvas(context),
            foregroundColor: ProfilePalette.text(context),
            leading: IconButton(
              key: const ValueKey('public-profile-back'),
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              style: IconButton.styleFrom(
                backgroundColor: ProfilePalette.panel(context),
                foregroundColor: ProfilePalette.aubergine(context),
                side: BorderSide(color: ProfilePalette.border(context)),
              ),
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }
              },
            ),
            title: Text(
              l10n.publicProfile,
              style: TextStyle(
                color: ProfilePalette.aubergine(context),
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          body: switch (state.status) {
            PublicProfileStatus.loading => const ProfileLoadingState(
              key: ValueKey('public-profile-loading'),
            ),
            PublicProfileStatus.unavailable => _UnavailableProfile(
              onRetry: () => ref
                  .read(publicProfileProvider(widget.userId).notifier)
                  .refresh(),
            ),
            PublicProfileStatus.failure => Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: ProfileErrorPanel(
                    key: const ValueKey('public-profile-error'),
                    retryButtonKey: const ValueKey('public-profile-retry'),
                    message: l10n.publicProfileLoadFailed,
                    retryLabel: l10n.tryAgain,
                    onRetry: () => ref
                        .read(publicProfileProvider(widget.userId).notifier)
                        .refresh(),
                  ),
                ),
              ),
            ),
            PublicProfileStatus.ready => _buildReady(context, state),
          },
        ),
      ),
    );
  }

  Widget _buildReady(BuildContext context, PublicProfileState state) {
    final profile = state.profile!;
    final l10n = AppLocalizations.of(context)!;
    final controller = ref.read(publicProfileProvider(widget.userId).notifier);
    SocialAuthor? postAuthor;
    for (final post in state.posts) {
      if (post.author.id == widget.userId || post.author.id == profile.id) {
        postAuthor = post.author;
        break;
      }
    }
    final postAuthorName = postAuthor?.displayName.trim().isNotEmpty == true
        ? postAuthor!.displayName.trim()
        : postAuthor?.username.trim() ?? '';
    final displayName = profile.preferredName.isNotEmpty
        ? profile.preferredName
        : postAuthorName.isNotEmpty
        ? postAuthorName
        : l10n.riksaLearner;
    final username = profile.username.trim().isNotEmpty
        ? profile.username.trim()
        : postAuthor?.username.trim() ?? '';
    final avatarUrl = profile.avatarUrl?.trim().isNotEmpty == true
        ? profile.avatarUrl
        : postAuthor?.avatarUrl;

    return RefreshIndicator(
      color: ProfilePalette.green(context),
      onRefresh: controller.refresh,
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification.metrics.extentAfter < 320) {
            controller.loadMorePosts();
          }
          return false;
        },
        child: CustomScrollView(
          key: PageStorageKey('public-profile-${widget.userId}'),
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 680),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
                    child: Column(
                      children: [
                        ProfileIdentityHeader(
                          cover: _PublicCover(url: profile.coverUrl),
                          avatar: _PublicAvatar(
                            value: avatarUrl,
                            label: displayName,
                          ),
                          displayName: displayName,
                          username: username,
                          bio: profile.bio,
                          isVerified: profile.isVerified,
                          tier: profile.currentTier,
                          totalXpLabel:
                              '${NumberFormat.compact(locale: Localizations.localeOf(context).languageCode).format(profile.totalXp)} XP',
                        ),
                        const SizedBox(height: 22),
                        ProfileTabs(
                          selected: _tab,
                          postsLabel: l10n.posts,
                          achievementsLabel: l10n.achievements,
                          rankLabel: l10n.leaderboardRank,
                          onSelected: (tab) => setState(() => _tab = tab),
                        ),
                        const SizedBox(height: 18),
                        AnimatedSwitcher(
                          duration: RiksaMotion.resolve(
                            context,
                            RiksaMotion.standard,
                          ),
                          child: switch (_tab) {
                            ProfileTab.posts => _PublicPosts(
                              state: state,
                              onRetry: controller.refresh,
                              onLoadMore: controller.loadMorePosts,
                              onReact: controller.react,
                              onShare: (postId) => _share(postId, controller),
                              currentUserId: ref.watch(currentUserIdProvider),
                              onEditPost: (post) => _editPost(post, controller),
                              onDeletePost: (post) =>
                                  _deletePost(post, controller),
                            ),
                            ProfileTab.achievements => _PublicAchievements(
                              achievements: profile.achievements,
                            ),
                            ProfileTab.rank => _PublicRank(rank: profile.rank),
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 30)),
          ],
        ),
      ),
    );
  }

  Future<void> _editPost(
    SocialPost post,
    PublicProfileController controller,
  ) async {
    final saved = await context.push<bool>(
      '/community/posts/${post.id}/edit',
      extra: post,
    );
    if (saved != true || !mounted) return;
    await controller.refresh();
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.postUpdated)),
      );
  }

  Future<void> _deletePost(
    SocialPost post,
    PublicProfileController controller,
  ) async {
    if (!await confirmSocialPostDeletion(context)) return;
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final failure = await ref
        .read(socialFeedProvider.notifier)
        .deletePost(post.id);
    if (!mounted) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(failure ?? l10n.postDeleted)));
    if (failure == null) await controller.refresh();
  }

  Future<void> _share(String postId, PublicProfileController controller) async {
    final shared = await controller.share(postId);
    if (!shared || !mounted) return;
    await Clipboard.setData(
      ClipboardData(text: 'https://riksa.app/community/posts/$postId'),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.copiedLink)),
      );
  }
}

class _PublicCover extends StatelessWidget {
  const _PublicCover({this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      key: const ValueKey('public-profile-default-cover'),
      color: ProfilePalette.greenSoft(context),
    );
    return ClipRRect(
      borderRadius: AppRadii.largeBorder,
      child: SizedBox(
        height: 170,
        width: double.infinity,
        child: url?.trim().isNotEmpty == true
            ? Image.network(
                url!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => fallback,
              )
            : fallback,
      ),
    );
  }
}

class _PublicAvatar extends StatelessWidget {
  const _PublicAvatar({required this.value, required this.label});

  final String? value;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey('public-profile-avatar-ring'),
    width: 98,
    height: 98,
    padding: const EdgeInsets.all(3),
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: ProfilePalette.greenSoft(context),
      border: Border.all(color: ProfilePalette.green(context), width: 2),
    ),
    child: RiksaAvatarImage(
      value: value,
      label: label,
      size: 92,
      backgroundColor: ProfilePalette.panelSoft(context),
      foregroundColor: ProfilePalette.text(context),
    ),
  );
}

class _PublicPosts extends StatelessWidget {
  const _PublicPosts({
    required this.state,
    required this.onRetry,
    required this.onLoadMore,
    required this.onReact,
    required this.onShare,
    required this.currentUserId,
    required this.onEditPost,
    required this.onDeletePost,
  });

  final PublicProfileState state;
  final Future<void> Function() onRetry;
  final Future<void> Function() onLoadMore;
  final Future<bool> Function(String) onReact;
  final Future<void> Function(String) onShare;

  /// Set when the reader is looking at their own public profile.
  final String? currentUserId;
  final void Function(SocialPost) onEditPost;
  final void Function(SocialPost) onDeletePost;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (state.isLoadingPosts && state.posts.isEmpty) {
      return const ProfileLoadingState(key: ValueKey('public-posts-loading'));
    }
    if (state.postsErrorMessage != null && state.posts.isEmpty) {
      return ProfileErrorPanel(
        key: const ValueKey('public-posts-error'),
        message: l10n.publicPostsLoadFailed,
        retryLabel: l10n.tryAgain,
        onRetry: onRetry,
      );
    }
    if (state.posts.isEmpty) {
      return ProfileEmptyPanel(
        key: const ValueKey('public-profile-posts-empty'),
        icon: Icons.forum_outlined,
        message: l10n.noPublicPosts,
      );
    }
    return Column(
      key: const ValueKey('public-profile-posts'),
      children: [
        for (final post in state.posts)
          SocialPostCard(
            post: post,
            onTap: () => context.push('/community/posts/${post.id}'),
            onAuthorTap: publicProfilePath(post.author.id) == null
                ? null
                : () => context.push(publicProfilePath(post.author.id)!),
            onReact: () => onReact(post.id),
            onShare: () => onShare(post.id),
            onEdit: post.author.id == currentUserId
                ? () => onEditPost(post)
                : null,
            onDelete: post.author.id == currentUserId
                ? () => onDeletePost(post)
                : null,
          ),
        if (state.isLoadingMore)
          const ProfileLoadingState(key: ValueKey('public-posts-loading-more')),
        if (state.paginationErrorMessage != null)
          ProfileErrorPanel(
            key: const ValueKey('public-posts-pagination-error'),
            message: l10n.publicPostsLoadFailed,
            retryLabel: l10n.tryAgain,
            onRetry: onLoadMore,
          ),
      ],
    );
  }
}

class _PublicAchievements extends StatelessWidget {
  const _PublicAchievements({required this.achievements});

  final List<PublicProfileAchievement> achievements;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (achievements.isEmpty) {
      return ProfileEmptyPanel(
        key: const ValueKey('public-profile-achievements-empty'),
        icon: Icons.workspace_premium_outlined,
        message: l10n.noPublicAchievements,
      );
    }
    return GridView.builder(
      key: const ValueKey('public-profile-achievements'),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.08,
      ),
      itemCount: achievements.length,
      itemBuilder: (context, index) {
        final achievement = achievements[index];
        return ProfileAchievementTile(
          name: achievement.name,
          description: achievement.description,
          iconUrl: achievement.iconUrl,
          trailingLabel: readableProfileName(achievement.rarity),
        );
      },
    );
  }
}

class _PublicRank extends StatelessWidget {
  const _PublicRank({required this.rank});

  final PublicProfileRank? rank;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (rank == null || !rank!.hasRank) {
      return ProfileEmptyPanel(
        key: const ValueKey('public-profile-rank-empty'),
        icon: Icons.leaderboard_outlined,
        message: l10n.noPublicRank,
      );
    }
    return Column(
      key: const ValueKey('public-profile-rank'),
      children: [
        if (rank!.countryRank != null)
          ProfileRankCard(
            icon: Icons.public_rounded,
            label: l10n.countryRank,
            rank: rank!.countryRank,
            unrankedLabel: l10n.unranked,
          ),
        if (rank!.countryRank != null && rank!.provinceRank != null)
          const SizedBox(height: 12),
        if (rank!.provinceRank != null)
          ProfileRankCard(
            icon: Icons.location_on_outlined,
            label: l10n.provinceRank,
            rank: rank!.provinceRank,
            unrankedLabel: l10n.unranked,
          ),
      ],
    );
  }
}

class _UnavailableProfile extends StatelessWidget {
  const _UnavailableProfile({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: ProfileErrorPanel(
            key: const ValueKey('public-profile-unavailable'),
            icon: Icons.person_off_outlined,
            message:
                '${l10n.publicProfileUnavailable}\n\n${l10n.publicProfileUnavailableMessage}',
            retryLabel: l10n.tryAgain,
            onRetry: onRetry,
          ),
        ),
      ),
    );
  }
}
