import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/router/app_shell.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/riksa_components.dart';
import '../../../core/widgets/riksa_search_bar.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../auth/providers/auth_provider.dart';
import '../../blog/data/blog_models.dart';
import '../../blog/providers/blog_provider.dart';
import '../../userProfile/presentation/public_profile_navigation.dart';
import '../../userProfile/presentation/widgets/profile_ui.dart';
import '../../userProfile/providers/profile_cover_provider.dart';
import '../data/social_models.dart';
import '../providers/social_feed_provider.dart';
import 'widgets/social_create_menu.dart';
import 'widgets/social_owner_menu.dart';
import 'widgets/social_palette.dart';
import 'widgets/social_post_card.dart';
import 'widgets/streak_details_sheet.dart';

enum _SocialSection { feed, blog }

class SocialFeedScreen extends ConsumerStatefulWidget {
  const SocialFeedScreen({super.key});

  @override
  ConsumerState<SocialFeedScreen> createState() => _SocialFeedScreenState();
}

class _SocialFeedScreenState extends ConsumerState<SocialFeedScreen> {
  late final ScrollController _scrollController;
  _SocialSection _section = _SocialSection.feed;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_loadMoreNearEdge);
  }

  void _loadMoreNearEdge() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.extentAfter < 520) {
      if (_section == _SocialSection.feed) {
        ref.read(socialFeedProvider.notifier).loadMore();
      } else {
        ref.read(blogFeedProvider.notifier).loadMore();
      }
    }
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_loadMoreNearEdge)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(socialFeedProvider);
    final blogState = _section == _SocialSection.blog
        ? ref.watch(blogFeedProvider)
        : null;
    return Scaffold(
      backgroundColor: SocialPalette.canvas(context),
      body: RefreshIndicator(
        color: SocialPalette.green(context),
        onRefresh: () => _section == _SocialSection.feed
            ? ref.read(socialFeedProvider.notifier).load()
            : ref.read(blogFeedProvider.notifier).load(),
        child: CustomScrollView(
          key: PageStorageKey('social-${_section.name}-scroll'),
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            _CommunityAppBar(
              onSearchChanged: (value) =>
                  setState(() => _searchQuery = value.trim().toLowerCase()),
              onFilter: _showContentFilter,
            ),
            SliverToBoxAdapter(
              child: _FeedSectionTabs(
                selected: _section,
                onSelected: _selectSection,
              ),
            ),
            SliverToBoxAdapter(
              child: _CommunityComposerPrompt(onTap: _showCreateMenu),
            ),
            if (_section == _SocialSection.blog)
              SliverToBoxAdapter(child: _YourArticlesLink(onTap: _openMyPosts)),
            if (_section == _SocialSection.feed)
              ..._contentSlivers(state)
            else
              ..._blogSlivers(blogState!),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }

  List<Widget> _contentSlivers(SocialFeedState state) {
    final l10n = AppLocalizations.of(context)!;
    final currentUserId = ref.watch(currentUserIdProvider);
    return switch (state) {
      SocialFeedLoading() => [const SliverToBoxAdapter(child: _FeedSkeleton())],
      SocialFeedFailure(:final message) => [
        SliverFillRemaining(
          hasScrollBody: false,
          child: _FeedMessage(
            icon: Icons.wifi_off_rounded,
            title: l10n.feedErrorTitle,
            message: message,
            buttonLabel: l10n.tryAgain,
            onPressed: () => ref.read(socialFeedProvider.notifier).load(),
          ),
        ),
      ],
      SocialFeedLoaded(:final posts) => [
        ...() {
          final filteredPosts = posts.where(_matchesPostSearch).toList();
          return <Widget>[
            if (filteredPosts.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _FeedMessage(
                  icon: Icons.forum_outlined,
                  title: _searchQuery.isEmpty
                      ? l10n.feedEmptyTitle
                      : l10n.noSearchResults,
                  message: _searchQuery.isEmpty
                      ? l10n.feedEmptyMessage
                      : l10n.searchCommunityHint,
                ),
              )
            else
              SliverList.builder(
                itemCount: filteredPosts.length,
                itemBuilder: (context, index) {
                  final post = filteredPosts[index];
                  return RiksaEntrance(
                    index: index,
                    child: SocialPostCard(
                      post: post,
                      // Through the router, not Navigator: a raw push leaves
                      // go_router still believing the feed is on screen, and
                      // the shell reads it to decide whether the tab bar
                      // belongs over this screen.
                      onTap: () => context.push('/community/posts/${post.id}'),
                      onAuthorTap: publicProfilePath(post.author.id) == null
                          ? null
                          : () => _openProfile(post.author.id),
                      onReact: () => _react(post.id),
                      onShare: () => _share(post.id),
                      onEdit: post.author.id == currentUserId
                          ? () => _editPost(post)
                          : null,
                      onDelete: post.author.id == currentUserId
                          ? () => _deletePost(post)
                          : null,
                    ),
                  );
                },
              ),
            if (state.isLoadingMore)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
          ];
        }(),
      ],
    };
  }

  List<Widget> _blogSlivers(BlogFeedState state) {
    final l10n = AppLocalizations.of(context)!;
    return switch (state) {
      BlogFeedLoading() => [const SliverToBoxAdapter(child: _FeedSkeleton())],
      BlogFeedError(:final message) => [
        SliverFillRemaining(
          hasScrollBody: false,
          child: _FeedMessage(
            icon: Icons.auto_stories_outlined,
            title: l10n.blog,
            message: message,
            buttonLabel: l10n.tryAgain,
            onPressed: () => ref.read(blogFeedProvider.notifier).load(),
          ),
        ),
      ],
      BlogFeedLoaded(:final posts, :final isLoadingMore) => [
        ...() {
          final filteredPosts = posts.where(_matchesBlogSearch).toList();
          return <Widget>[
            if (filteredPosts.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _FeedMessage(
                  icon: Icons.menu_book_rounded,
                  title: l10n.blog,
                  message: _searchQuery.isEmpty
                      ? l10n.blogEmptyMessage
                      : l10n.noSearchResults,
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                sliver: SliverList.builder(
                  itemCount: filteredPosts.length,
                  itemBuilder: (context, index) => RiksaEntrance(
                    index: index,
                    child: _GlassBlogCard(
                      post: filteredPosts[index],
                      onLike: () => ref
                          .read(blogFeedProvider.notifier)
                          .toggleLike(filteredPosts[index].id),
                    ),
                  ),
                ),
              ),
            if (isLoadingMore)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
          ];
        }(),
      ],
    };
  }

  Future<void> _react(String postId) async {
    final success = await ref
        .read(socialFeedProvider.notifier)
        .toggleReaction(postId);
    if (!success && mounted) _showFailure();
  }

  Future<void> _share(String postId) async {
    final success = await ref
        .read(socialFeedProvider.notifier)
        .sharePost(postId);
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    if (!success) {
      _showFailure();
      return;
    }
    await Clipboard.setData(
      ClipboardData(text: 'https://riksa.app/community/posts/$postId'),
    );
    if (mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.copiedLink)));
    }
  }

  Future<void> _editPost(SocialPost post) async {
    final saved = await context.push<bool>(
      '/community/posts/${post.id}/edit',
      extra: post,
    );
    if (saved == true && mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.postUpdated)),
        );
    }
  }

  Future<void> _deletePost(SocialPost post) async {
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
  }

  void _openProfile(String userId) {
    final path = publicProfilePath(userId);
    if (path != null) context.push(path);
  }

  void _showFailure() {
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l10n.actionFailed)));
  }

  void _selectSection(_SocialSection section) {
    if (_section == section) return;
    setState(() => _section = section);
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
    // Moderation happens elsewhere, so an article approved since the last
    // fetch is only ever seen by asking again on the way in.
    if (section == _SocialSection.blog) {
      ref.read(blogFeedProvider.notifier).refreshIfStale();
      ref.invalidate(pendingBlogPostCountProvider);
    }
  }

  Future<void> _showContentFilter() async {
    final l10n = AppLocalizations.of(context)!;
    final selected = await showModalBottomSheet<_SocialSection>(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.filters, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadii.mediumBorder,
                ),
                selected: _section == _SocialSection.feed,
                leading: const Icon(Icons.forum_outlined),
                title: Text(l10n.forYou),
                onTap: () => Navigator.pop(context, _SocialSection.feed),
              ),
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadii.mediumBorder,
                ),
                selected: _section == _SocialSection.blog,
                leading: const Icon(Icons.auto_stories_outlined),
                title: Text(l10n.blog),
                onTap: () => Navigator.pop(context, _SocialSection.blog),
              ),
            ],
          ),
        ),
      ),
    );
    if (selected != null && mounted) _selectSection(selected);
  }

  bool _matchesPostSearch(SocialPost post) {
    if (_searchQuery.isEmpty) return true;
    return [
      post.title,
      post.content,
      post.author.displayName,
      post.author.username,
      post.category.name,
    ].any((value) => value.toLowerCase().contains(_searchQuery));
  }

  bool _matchesBlogSearch(BlogPost post) {
    if (_searchQuery.isEmpty) return true;
    return post.title.toLowerCase().contains(_searchQuery) ||
        post.content.toLowerCase().contains(_searchQuery);
  }

  Future<void> _showCreateMenu() async {
    final action = await showSocialCreateMenu(context);
    if (!mounted || action == null) return;
    final created = await context.push<bool>(socialCreateRoute(action));
    if (created != true || !mounted) return;
    // An article lands in the blog tab, where it waits for moderation.
    if (action == SocialCreateAction.article) {
      _selectSection(_SocialSection.blog);
      ref.invalidate(pendingBlogPostCountProvider);
      await ref.read(blogFeedProvider.notifier).load();
    } else {
      _selectSection(_SocialSection.feed);
    }
  }

  /// The author's own articles, moderation status included. A pending post
  /// shows up nowhere else, so this is the only way back to it.
  Future<void> _openMyPosts() async {
    await context.push<void>('/blog/my-posts');
    if (!mounted) return;
    ref.invalidate(pendingBlogPostCountProvider);
  }
}

class _CommunityAppBar extends ConsumerWidget {
  const _CommunityAppBar({
    required this.onSearchChanged,
    required this.onFilter,
  });

  final ValueChanged<String> onSearchChanged;
  final VoidCallback onFilter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return SliverToBoxAdapter(
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(20, 16, 20, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const _AccountAvatarButton(),
                  const SizedBox(width: RiksaSpacing.sm),
                  Expanded(
                    child: Text(
                      l10n.community,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            color: SocialPalette.text(context),
                            fontWeight: FontWeight.w700,
                            letterSpacing: -.6,
                          ),
                    ),
                  ),
                  _StreakPill(
                    key: const ValueKey('streak-pill'),
                    streak: ref.watch(communityStreakProvider),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              RiksaSearchBar(
                key: const ValueKey('community-search'),
                hintText: l10n.searchCommunity,
                onChanged: onSearchChanged,
                onFilter: onFilter,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The way into the account menu. An avatar, never a hamburger: the learner's
/// own face is a clearer promise of "this is your stuff" than three lines, and
/// it doubles as the signed-in indicator the header otherwise lacked.
class _AccountAvatarButton extends ConsumerWidget {
  const _AccountAvatarButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Checked before auth is read: outside the shell there is no drawer to
    // open, so the header should not pull the session in just to hide a button.
    final open = AppShellScope.maybeOf(context)?.openDrawer;
    if (open == null) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;
    final auth = ref.watch(authProvider);
    if (auth is! Authenticated) return const SizedBox.shrink();
    final user = auth.user;

    return Semantics(
      button: true,
      label: l10n.openProfileMenu,
      child: Tooltip(
        message: l10n.openProfileMenu,
        child: InkWell(
          key: const ValueKey('account-avatar-button'),
          onTap: open,
          customBorder: const CircleBorder(),
          child: RiksaProfileAvatar(
            user: user,
            radius: 19,
            avatarPath: ref.watch(profileAvatarProvider),
          ),
        ),
      ),
    );
  }
}

class _CommunityComposerPrompt extends StatelessWidget {
  const _CommunityComposerPrompt({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Semantics(
        button: true,
        label: l10n.communityComposerPrompt,
        child: Material(
          color: Theme.of(context).brightness == Brightness.dark
              ? context.riksa.surfaceRaised
              : AppColors.editorialField,
          borderRadius: AppRadii.fullBorder,
          child: InkWell(
            key: const ValueKey('create-community-button'),
            onTap: onTap,
            borderRadius: AppRadii.fullBorder,
            child: Container(
              constraints: const BoxConstraints(minHeight: 52),
              padding: const EdgeInsets.fromLTRB(9, 7, 9, 7),
              decoration: const BoxDecoration(
                borderRadius: AppRadii.fullBorder,
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: SocialPalette.pinkSoft(
                        context,
                      ).withValues(alpha: .55),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.help_outline_rounded,
                      size: 19,
                      color: SocialPalette.pink(context).withValues(alpha: .7),
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Text(
                      l10n.communityComposerPrompt,
                      style: TextStyle(
                        color: SocialPalette.muted(
                          context,
                        ).withValues(alpha: .72),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: SocialPalette.aubergine(context),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.add_rounded,
                      size: 20,
                      color: SocialPalette.onAubergine(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Doorway to the author's own articles, sitting at the top of the blog
/// list.
///
/// A post in review is absent from the feed below, so the count carries the
/// reassurance: the writing is somewhere, and this is where.
class _YourArticlesLink extends ConsumerWidget {
  const _YourArticlesLink({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final pending = ref.watch(pendingBlogPostCountProvider).value ?? 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Material(
        color: Colors.transparent,
        borderRadius: AppRadii.fullBorder,
        child: InkWell(
          key: const ValueKey('your-articles-link'),
          onTap: onTap,
          borderRadius: AppRadii.fullBorder,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Row(
              children: [
                Icon(
                  Icons.drafts_outlined,
                  size: 18,
                  color: SocialPalette.muted(context),
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.yourArticles,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: SocialPalette.text(context),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (pending > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    key: const ValueKey('articles-in-review-badge'),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: SocialPalette.pinkSoft(context),
                      borderRadius: AppRadii.fullBorder,
                    ),
                    child: Text(
                      l10n.articlesInReview(pending),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: SocialPalette.pink(context),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: SocialPalette.muted(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FeedSectionTabs extends StatelessWidget {
  const _FeedSectionTabs({required this.selected, required this.onSelected});

  final _SocialSection selected;
  final ValueChanged<_SocialSection> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = context.riksa;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: palette.outline.withValues(alpha: isDark ? 0.35 : 0.6),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ModernSectionTabItem(
              key: const ValueKey('my-feed-tab'),
              label: l10n.forYou,
              selected: selected == _SocialSection.feed,
              onTap: () {
                HapticFeedback.selectionClick();
                onSelected(_SocialSection.feed);
              },
            ),
          ),
          Expanded(
            child: _ModernSectionTabItem(
              key: const ValueKey('blog-tab'),
              label: l10n.blog,
              selected: selected == _SocialSection.blog,
              onTap: () {
                HapticFeedback.selectionClick();
                onSelected(_SocialSection.blog);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ModernSectionTabItem extends StatelessWidget {
  const _ModernSectionTabItem({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = isDark
        ? AppColors.editorialPink
        : SocialPalette.aubergine(context);
    final inactiveColor = SocialPalette.muted(context);

    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected ? activeColor : inactiveColor,
                  fontSize: 15,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 8),
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                height: 3,
                width: selected ? 48 : 0,
                decoration: BoxDecoration(
                  color: selected ? activeColor : Colors.transparent,
                  borderRadius: AppRadii.fullBorder,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StreakPill extends StatelessWidget {
  const _StreakPill({super.key, required this.streak});

  final AsyncValue<CommunityStreak> streak;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final value = streak.value;
    return Material(
      color: theme.brightness == Brightness.dark
          ? AppColors.editorialAubergineRaised
          : SocialPalette.pinkSoft(context),
      borderRadius: AppRadii.fullBorder,
      child: InkWell(
        borderRadius: AppRadii.fullBorder,
        onTap: value == null
            ? null
            : () => showStreakDetailsSheet(context, value),
        child: Container(
          height: 40,
          constraints: const BoxConstraints(minWidth: 60),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: const BoxDecoration(borderRadius: AppRadii.fullBorder),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.local_fire_department_rounded,
                color: SocialPalette.pink(context),
                size: 20,
              ),
              const SizedBox(width: 4),
              if (streak.isLoading)
                const SizedBox(
                  width: 13,
                  height: 13,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Text(
                  '${value?.current ?? 0}',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: SocialPalette.aubergine(context),
                    fontWeight: FontWeight.w900,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlassBlogCard extends StatelessWidget {
  const _GlassBlogCard({required this.post, required this.onLike});

  final BlogPost post;
  final VoidCallback onLike;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: SocialPalette.surface(context),
        borderRadius: AppRadii.largeBorder,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push('/blog/${post.id}'),
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(
                color: SocialPalette.border(context).withValues(alpha: .35),
              ),
              borderRadius: AppRadii.largeBorder,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (post.hasCover)
                  Image.network(
                    post.coverUrl!,
                    height: 176,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const SizedBox.shrink(),
                  ),
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          color: SocialPalette.text(context),
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        post.content,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: SocialPalette.muted(context),
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Text(
                            DateFormat.yMMMd().format(post.createdAt),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: SocialPalette.muted(context),
                            ),
                          ),
                          const Spacer(),
                          Material(
                            color: post.liked
                                ? SocialPalette.pinkSoft(context)
                                : SocialPalette.editorialSurface(context),
                            borderRadius: AppRadii.fullBorder,
                            child: InkWell(
                              borderRadius: AppRadii.fullBorder,
                              onTap: onLike,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      post.liked
                                          ? Icons.favorite_rounded
                                          : Icons.favorite_border_rounded,
                                      size: 16,
                                      color: post.liked
                                          ? SocialPalette.pink(context)
                                          : SocialPalette.muted(context),
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      '${post.likeCount}',
                                      style: TextStyle(
                                        color: post.liked
                                            ? SocialPalette.aubergine(context)
                                            : SocialPalette.muted(context),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FeedMessage extends StatelessWidget {
  const _FeedMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.buttonLabel,
    this.onPressed,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? buttonLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: SocialPalette.pinkSoft(context),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: SocialPalette.pink(context), size: 29),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: SocialPalette.text(context),
              ),
            ),
            const SizedBox(height: 7),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: SocialPalette.muted(context),
                height: 1.45,
              ),
            ),
            if (onPressed != null && buttonLabel != null) ...[
              const SizedBox(height: 18),
              SizedBox(
                width: 160,
                child: FilledButton(
                  onPressed: onPressed,
                  style: FilledButton.styleFrom(
                    backgroundColor: SocialPalette.aubergine(context),
                    foregroundColor: SocialPalette.onAubergine(context),
                    shape: const RoundedRectangleBorder(
                      borderRadius: AppRadii.fullBorder,
                    ),
                  ),
                  child: Text(buttonLabel!),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FeedSkeleton extends StatelessWidget {
  const _FeedSkeleton();

  @override
  Widget build(BuildContext context) {
    final color = SocialPalette.surfaceRaised(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: List.generate(
          3,
          (index) => Container(
            height: index == 0 ? 188 : 244,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: color,
              borderRadius: AppRadii.mediumBorder,
            ),
          ),
        ),
      ),
    );
  }
}
