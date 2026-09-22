import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/router/app_shell.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/pixel_fire_icon.dart';
import '../../../core/widgets/riksa_components.dart';
import '../../../core/widgets/riksa_search_bar.dart';
import '../../../core/widgets/riksa_segmented_tabs.dart';
import '../../dashboard/presentation/widgets/home_sections.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../auth/providers/auth_provider.dart';
import '../../blog/data/blog_models.dart';
import '../../blog/presentation/widgets/blog_ui.dart';
import '../../blog/providers/blog_provider.dart';
import '../../userProfile/data/public_profile.dart';
import '../../userProfile/presentation/public_profile_navigation.dart';
import '../../userProfile/providers/public_profile_provider.dart';
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
  bool _showFab = false;

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
      backgroundColor: context.riksa.canvas,
      floatingActionButton: AnimatedSlide(
        duration: const Duration(milliseconds: 230),
        curve: Curves.easeInOutCubic,
        offset: _showFab ? Offset.zero : const Offset(0, 2),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 230),
          curve: Curves.easeInOutCubic,
          opacity: _showFab ? 1.0 : 0.0,
          child: IgnorePointer(
            ignoring: !_showFab,
            child: Semantics(
              button: true,
              label: AppLocalizations.of(context)!.communityComposerPrompt,
              child: Tooltip(
                message: AppLocalizations.of(context)!.communityComposerPrompt,
                child: GestureDetector(
                  key: const ValueKey('create-community-button'),
                  behavior: HitTestBehavior.opaque,
                  onTap: _showCreateMenu,
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: ShapeDecoration(
                      shape: CircleBorder(
                        side: BorderSide(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white.withValues(alpha: 0.12)
                              : Colors.white.withValues(alpha: 0.72),
                        ),
                      ),
                      shadows: [
                        BoxShadow(
                          color: context.riksa.ink.withValues(
                            alpha:
                                Theme.of(context).brightness == Brightness.dark
                                ? .18
                                : .08,
                          ),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                      color: Theme.of(context).brightness == Brightness.dark
                          ? context.riksa.surface.withValues(alpha: 0.46)
                          : Colors.white.withValues(alpha: 0.58),
                    ),
                    child: ClipOval(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : Colors.white.withValues(alpha: 0.54),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.36),
                              ),
                            ),
                            child: Icon(
                              Icons.edit_rounded,
                              size: 24,
                              color: context.riksa.brand,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      body: NotificationListener<UserScrollNotification>(
        onNotification: (notification) {
          if (notification.direction == ScrollDirection.reverse) {
            if (!_showFab) setState(() => _showFab = true);
          } else if (notification.direction == ScrollDirection.forward) {
            if (_showFab) setState(() => _showFab = false);
          }
          return false;
        },
        child: RefreshIndicator(
          color: context.riksa.brand,
          onRefresh: () => _section == _SocialSection.feed
              ? ref.read(socialFeedProvider.notifier).load()
              : ref.read(blogFeedProvider.notifier).load(),
          child: CustomScrollView(
            key: PageStorageKey('social-${_section.name}-scroll'),
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              _HomeHeader(
                onSearchChanged: (value) =>
                    setState(() => _searchQuery = value.trim().toLowerCase()),
                onFilter: _showContentFilter,
              ),
              const SliverToBoxAdapter(child: HomeQuickActions()),
              SliverToBoxAdapter(
                child: HomeSectionHeader(
                  title: 'Feeds',
                  padding: const EdgeInsets.fromLTRB(16, 12, 12, 4),
                ),
              ),
              SliverToBoxAdapter(
                child: _FeedSectionTabs(
                  selected: _section,
                  onSelected: _selectSection,
                ),
              ),
              if (_section == _SocialSection.blog)
                SliverToBoxAdapter(
                  child: _YourArticlesLink(onTap: _openMyPosts),
                ),
              if (_section == _SocialSection.feed)
                ..._contentSlivers(state)
              else
                ..._blogSlivers(blogState!),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
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
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
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

/// Greeting, streak, account avatar and the search field.
class _HomeHeader extends ConsumerWidget {
  const _HomeHeader({required this.onSearchChanged, required this.onFilter});

  final ValueChanged<String> onSearchChanged;
  final VoidCallback onFilter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final auth = ref.watch(authProvider);
    final name = auth is Authenticated
        ? auth.user.displayName.trim().split(RegExp(r'\s+')).first
        : '';
    // Without a name the greeting drops the gap it would have filled.
    final greeting = name.isEmpty
        ? l10n.homeGreeting('').replaceFirst(RegExp(r',?\s*!'), '!')
        : l10n.homeGreeting(name);

    return SliverToBoxAdapter(
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const _SidebarMenuButton(),
                  const SizedBox(width: RiksaSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          greeting,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: RiksaTypography.titleStyleFor(
                            greeting,
                            theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: RiksaSpacing.sm),
                  _StreakPill(
                    key: const ValueKey('streak-pill'),
                    streak: ref.watch(communityStreakProvider),
                  ),
                  const SizedBox(width: RiksaSpacing.xs),
                  _HeaderSearchButton(
                    onSearchChanged: onSearchChanged,
                    onFilter: onFilter,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SidebarMenuButton extends StatelessWidget {
  const _SidebarMenuButton();

  @override
  Widget build(BuildContext context) {
    final open = AppShellScope.maybeOf(context)?.openDrawer;
    if (open == null) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;
    return Tooltip(
      message: l10n.openProfileMenu,
      child: Semantics(
        button: true,
        label: l10n.openProfileMenu,
        child: _HeaderGlassIconButton(
          key: const ValueKey('home-sidebar-menu-button'),
          icon: Icons.menu_rounded,
          onTap: open,
        ),
      ),
    );
  }
}

class _HeaderSearchButton extends StatelessWidget {
  const _HeaderSearchButton({
    required this.onSearchChanged,
    required this.onFilter,
  });

  final ValueChanged<String> onSearchChanged;
  final VoidCallback onFilter;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Tooltip(
      message: l10n.homeSearchHint,
      child: Semantics(
        button: true,
        label: l10n.homeSearchHint,
        child: _HeaderGlassIconButton(
          key: const ValueKey('home-header-search-button'),
          icon: Icons.search_rounded,
          onTap: () => _showSearchSheet(context),
        ),
      ),
    );
  }

  void _showSearchSheet(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.riksa.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            16 + MediaQuery.viewInsetsOf(sheetContext).bottom,
          ),
          child: RiksaSearchBar(
            key: const ValueKey('community-search-sheet'),
            hintText: l10n.homeSearchHint,
            onChanged: onSearchChanged,
            onFilter: onFilter,
          ),
        ),
      ),
    );
  }
}

class _HeaderGlassIconButton extends StatelessWidget {
  const _HeaderGlassIconButton({
    super.key,
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.riksa;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fill = isDark
        ? palette.surface.withValues(alpha: 0.46)
        : Colors.white.withValues(alpha: 0.58);
    final border = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.white.withValues(alpha: 0.72);

    return SizedBox.square(
      dimension: 48,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Center(
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: palette.ink.withValues(alpha: isDark ? 0.18 : 0.08),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Material(
                color: fill,
                shape: CircleBorder(side: BorderSide(color: border)),
                clipBehavior: Clip.antiAlias,
                child: SizedBox.square(
                  dimension: 42,
                  child: Icon(icon, size: 22, color: palette.ink),
                ),
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
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
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
                  color: context.riksa.inkMuted,
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.yourArticles,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: context.riksa.ink,
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
                      color: context.riksa.brandSoft,
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
                  color: context.riksa.inkMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Filter chips over the feed: everything, or articles only.
class _FeedSectionTabs extends StatelessWidget {
  const _FeedSectionTabs({required this.selected, required this.onSelected});

  final _SocialSection selected;
  final ValueChanged<_SocialSection> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
      child: RiksaSegmentedTabs<_SocialSection>(
        height: 46,
        segments: [
          (
            value: _SocialSection.feed,
            label: l10n.community,
            semanticKey: 'my-feed-tab',
          ),
          (
            value: _SocialSection.blog,
            label: l10n.blog,
            semanticKey: 'blog-tab',
          ),
        ],
        selected: selected,
        onChanged: (section) {
          HapticFeedback.selectionClick();
          onSelected(section);
        },
      ),
    );
  }
}

class _StreakPill extends StatelessWidget {
  const _StreakPill({super.key, required this.streak});

  final AsyncValue<CommunityStreak> streak;

  @override
  Widget build(BuildContext context) {
    final palette = context.riksa;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final fill = isDark
        ? palette.surface.withValues(alpha: 0.46)
        : Colors.white.withValues(alpha: 0.58);
    final border = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.white.withValues(alpha: 0.72);
    final value = streak.value;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: AppRadii.fullBorder,
        boxShadow: [
          BoxShadow(
            color: palette.ink.withValues(alpha: isDark ? 0.18 : 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: fill,
        borderRadius: AppRadii.fullBorder,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          borderRadius: AppRadii.fullBorder,
          onTap: value == null
              ? null
              : () => showStreakDetailsSheet(context, value),
          child: Container(
            height: 38,
            constraints: const BoxConstraints(minWidth: 56),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              borderRadius: AppRadii.fullBorder,
              border: Border.all(color: border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const PixelFireIcon(size: 20),
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
                      color: palette.ink,
                      fontWeight: FontWeight.w700,
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

class _GlassBlogCard extends ConsumerWidget {
  const _GlassBlogCard({required this.post, required this.onLike});

  final BlogPost post;
  final VoidCallback onLike;

  void _openProfile(BuildContext context, PublicProfile? profile) {
    final path = publicProfilePath(profile?.id ?? post.authorId);
    if (path != null) context.push(path);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isOwner = ref.watch(currentUserIdProvider) == post.authorId;
    final authorState = ref.watch(publicProfileProvider(post.authorId));
    final profile = authorState.profile;

    final authorName = profile != null && profile.preferredName.isNotEmpty
        ? profile.preferredName
        : (post.author != null && post.author!.displayName.isNotEmpty ? post.author!.displayName : 'Unknown Author');
    final username = profile != null && profile.username.isNotEmpty
        ? profile.username
        : (post.author != null ? post.author!.username : 'user');

    final date = DateFormat.MMMd(Localizations.localeOf(context).languageCode).format(post.createdAt.toLocal());

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BlogAvatar(
            profile: profile,
            size: BlogMetrics.rowAvatar,
            onTap: () => _openProfile(context, profile),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => _openProfile(context, profile),
                        child: Text(
                          authorName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: context.riksa.ink,
                          ),
                        ),
                      ),
                    ),
                    if (profile?.isVerified == true) ...[
                      const SizedBox(width: 4),
                      const BlogVerifiedBadge(),
                    ],
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        '· @$username · $date',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: context.riksa.inkMuted,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Material(
                  color: context.riksa.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadii.largeBorder,
                    side: BorderSide(color: context.riksa.outline),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => context.push('/blog/${post.id}'),
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
                                style: RiksaTypography.bodyStyleFor(
                                  post.title,
                                  theme.textTheme.titleLarge?.copyWith(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    height: 1.35,
                                    letterSpacing: 0,
                                    color: context.riksa.ink,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 9),
                              Text(
                                post.content,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: RiksaTypography.bodyStyleFor(
                                  post.content,
                                  theme.textTheme.bodyMedium?.copyWith(
                                    fontSize: 15,
                                    color: context.riksa.inkMuted,
                                    height: 1.42,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  Text(
                                    DateFormat.yMMMd().format(post.createdAt),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: context.riksa.inkMuted,
                                    ),
                                  ),
                                  const Spacer(),
                                  Material(
                                    color: context.riksa.surface,
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
                                                  ? Colors.red
                                                  : context.riksa.inkMuted,
                                            ),
                                            const SizedBox(width: 5),
                                            Text(
                                              '${post.likeCount}',
                                              style: TextStyle(
                                                color: post.liked
                                                    ? Colors.red
                                                    : context.riksa.inkMuted,
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
              ],
            ),
          ),
        ],
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
                color: context.riksa.brandSoft,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: SocialPalette.pink(context), size: 29),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: context.riksa.ink,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: context.riksa.inkMuted,
                height: 1.45,
              ),
            ),
            if (onPressed != null && buttonLabel != null) ...[
              const SizedBox(height: 18),
              SizedBox(
                width: 160,
                child: FilledButton(
                  onPressed: onPressed,
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
    final color = context.riksa.surfaceRaised;
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
