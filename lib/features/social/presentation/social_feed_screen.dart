
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/router/app_shell.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/pixel_fire_icon.dart';
import '../../../core/widgets/riksa_avatar_image.dart';
import '../../../core/widgets/riksa_logo.dart';
import '../../../core/widgets/riksa_search_bar.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../auth/providers/auth_provider.dart';
import '../../blog/data/blog_models.dart';
import '../../blog/presentation/widgets/blog_ui.dart';
import '../../blog/providers/blog_provider.dart';
import '../../dashboard/presentation/widgets/home_study_banner.dart';
import '../../learning/providers/learning_home_provider.dart';
import '../../userProfile/data/public_profile.dart';
import '../../userProfile/presentation/public_profile_navigation.dart';
import '../../userProfile/providers/profile_provider.dart';
import '../../userProfile/providers/public_profile_provider.dart';
import '../data/social_models.dart';
import '../providers/social_feed_provider.dart';
import 'widgets/social_create_menu.dart';
import 'widgets/social_owner_menu.dart';
import 'widgets/social_palette.dart';
import 'widgets/social_post_card.dart';
import 'widgets/streak_details_sheet.dart';

/// For you is everything; communities is only the ones you joined, the
/// closest RIKSA has to X's Following until people can be followed.
enum _SocialSection { feed, communities, blog }

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
      if (_section == _SocialSection.blog) {
        ref.read(blogFeedProvider.notifier).loadMore();
      } else {
        ref.read(socialFeedProvider.notifier).loadMore();
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
    final l10n = AppLocalizations.of(context)!;
    final palette = context.riksa;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: palette.canvas,
      // Always there, as on X: posting is the second most common thing done
      // here, and a button that hides until you scroll is one people miss.
      floatingActionButton: FloatingActionButton(
        key: const ValueKey('create-community-button'),
        // Every tab stays mounted in the shell, so each button needs its own
        // hero tag or switching tabs throws.
        heroTag: 'timeline-compose',
        tooltip: l10n.communityComposerPrompt,
        onPressed: _showCreateMenu,
        backgroundColor: isDark ? palette.brand : palette.brandStrong,
        foregroundColor: palette.onBrand,
        elevation: 3,
        shape: const CircleBorder(),
        child: const Icon(Icons.add_rounded, size: 30),
      ),
      body: RefreshIndicator(
        color: palette.brand,
        onRefresh: () async {
          if (_section == _SocialSection.blog) {
            await ref.read(blogFeedProvider.notifier).load();
            return;
          }
          ref.invalidate(learningHomeProvider);
          await ref.read(socialFeedProvider.notifier).load();
        },
        child: CustomScrollView(
          key: PageStorageKey('social-${_section.name}-scroll'),
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            _TimelineHeader(
              selected: _section,
              onSelected: _selectSection,
              searchQuery: _searchQuery,
              onSearchChanged: (value) =>
                  setState(() => _searchQuery = value.trim().toLowerCase()),
              onFilter: _showContentFilter,
            ),
            if (_section == _SocialSection.feed && _searchQuery.isEmpty)
              const SliverToBoxAdapter(child: HomeStudyBanner()),
            if (_section == _SocialSection.blog)
              SliverToBoxAdapter(child: _YourArticlesLink(onTap: _openMyPosts)),
            if (_section == _SocialSection.blog)
              ..._blogSlivers(blogState!)
            else
              ..._contentSlivers(state),
            // Room for the last post to scroll clear of the post button.
            const SliverToBoxAdapter(child: SizedBox(height: 96)),
          ],
        ),
      ),
    );
  }

  String _t(String en, String km) =>
      Localizations.localeOf(context).languageCode == 'km' ? km : en;

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
      SocialFeedLoaded(:final posts, :final categories) => [
        ...() {
          final joined = {
            for (final category in categories)
              if (category.joined) category.id,
          };
          final scoped = _section == _SocialSection.communities
              ? posts.where((post) => joined.contains(post.category.id))
              : posts;
          final filteredPosts = scoped.where(_matchesPostSearch).toList();
          return <Widget>[
            if (filteredPosts.isEmpty &&
                _section == _SocialSection.communities &&
                _searchQuery.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _FeedMessage(
                  icon: Icons.groups_2_outlined,
                  title: joined.isEmpty
                      ? _t('Join a community', 'ចូលរួមសហគមន៍')
                      : _t('Nothing new yet', 'មិនទាន់មានអ្វីថ្មី'),
                  message: joined.isEmpty
                      ? _t(
                          'Posts from the communities you join show up here.',
                          'ការបង្ហោះពីសហគមន៍ដែលអ្នកចូលរួម នឹងបង្ហាញនៅទីនេះ។',
                        )
                      : _t(
                          'Your communities have been quiet. Start something!',
                          'សហគមន៍របស់អ្នកនៅស្ងាត់។ ចាប់ផ្ដើមអ្វីមួយ!',
                        ),
                  buttonLabel: l10n.communitiesMenu,
                  onPressed: () => context.push('/communities'),
                ),
              )
            else if (filteredPosts.isEmpty)
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
                  return SocialPostCard(
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
                padding: EdgeInsets.zero,
                sliver: SliverList.builder(
                  itemCount: filteredPosts.length,
                  itemBuilder: (context, index) => _GlassBlogCard(
                    post: filteredPosts[index],
                    onLike: () => ref
                        .read(blogFeedProvider.notifier)
                        .toggleLike(filteredPosts[index].id),
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

/// The timeline's top bar, on the X layout: your avatar (the sidebar) on the
/// left, the wordmark in the middle, streak and search on the right, and the
/// feed tabs underneath. It slides away as you read down and comes back the
/// moment you scroll up.
class _TimelineHeader extends ConsumerWidget {
  const _TimelineHeader({
    required this.selected,
    required this.onSelected,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.onFilter,
  });

  final _SocialSection selected;
  final ValueChanged<_SocialSection> onSelected;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onFilter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.riksa;
    return SliverAppBar(
      floating: true,
      snap: true,
      backgroundColor: palette.canvas,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      toolbarHeight: 56,
      leadingWidth: 60,
      leading: const Padding(
        padding: EdgeInsetsDirectional.only(start: 14),
        child: Center(child: _HeaderAvatarButton()),
      ),
      centerTitle: true,
      title: const RiksaLogo(fontSize: 22),
      actions: [
        _StreakPill(
          key: const ValueKey('streak-pill'),
          streak: ref.watch(communityStreakProvider),
        ),
        _HeaderSearchButton(
          searchQuery: searchQuery,
          onSearchChanged: onSearchChanged,
          onFilter: onFilter,
        ),
        const SizedBox(width: 4),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(49),
        child: _TimelineTabs(selected: selected, onSelected: onSelected),
      ),
    );
  }
}

/// Your own avatar, which opens the sidebar: the same corner and the same
/// meaning on every tab.
class _HeaderAvatarButton extends ConsumerWidget {
  const _HeaderAvatarButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final palette = context.riksa;
    final auth = ref.watch(authProvider);
    final user = auth is Authenticated ? auth.user : null;
    final name = user == null
        ? ''
        : (user.displayName.trim().isEmpty
              ? user.username
              : user.displayName.trim());
    final open = AppShellScope.maybeOf(context)?.openDrawer;
    return Tooltip(
      message: l10n.openProfileMenu,
      child: Semantics(
        button: true,
        label: l10n.openProfileMenu,
        excludeSemantics: true,
        child: InkWell(
          key: const ValueKey('home-sidebar-menu-button'),
          customBorder: const CircleBorder(),
          onTap: open ?? () => context.push('/profile'),
          child: RiksaAvatarImage(
            value: user?.avatarUrl,
            label: name.isEmpty ? '?' : name,
            size: 34,
            backgroundColor: palette.brandSoft,
            foregroundColor: palette.brandStrong,
            frameTier: ref
                .watch(profileDashboardProvider)
                .value
                ?.gamification
                .currentTier,
          ),
        ),
      ),
    );
  }
}

/// For you, your communities, and articles, with X's underline under the
/// selected one.
class _TimelineTabs extends StatelessWidget {
  const _TimelineTabs({required this.selected, required this.onSelected});

  final _SocialSection selected;
  final ValueChanged<_SocialSection> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tabs = [
      (_SocialSection.feed, l10n.forYou, 'my-feed-tab'),
      (
        _SocialSection.communities,
        l10n.communitiesMenu,
        'communities-feed-tab',
      ),
      (_SocialSection.blog, l10n.blog, 'blog-tab'),
    ];
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: context.riksa.outline)),
      ),
      child: SizedBox(
        height: 48,
        child: Row(
          children: [
            for (final (section, label, key) in tabs)
              Expanded(
                child: _TimelineTab(
                  key: ValueKey(key),
                  label: label,
                  selected: section == selected,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onSelected(section);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TimelineTab extends StatelessWidget {
  const _TimelineTab({
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
    final palette = context.riksa;
    final style = Theme.of(context).textTheme.titleSmall?.copyWith(
      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
      color: selected ? palette.ink : palette.inkMuted,
    );
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: RiksaTypography.titleStyleFor(label, style),
              ),
            ),
            Positioned(
              bottom: 0,
              child: AnimatedContainer(
                duration: RiksaMotion.resolve(context, RiksaMotion.standard),
                curve: RiksaMotion.standardCurve,
                width: selected ? 56 : 0,
                height: 4,
                decoration: BoxDecoration(
                  color: palette.brand,
                  borderRadius: AppRadii.fullBorder,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderSearchButton extends StatelessWidget {
  const _HeaderSearchButton({
    required this.searchQuery,
    required this.onSearchChanged,
    required this.onFilter,
  });

  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onFilter;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return IconButton(
      key: const ValueKey('home-header-search-button'),
      tooltip: l10n.homeSearchHint,
      // A bare icon, as on X: the theme's default gives icon buttons a
      // filled disc, which reads as a second avatar in this bar.
      style: IconButton.styleFrom(backgroundColor: Colors.transparent),
      onPressed: () => _showSearchSheet(context),
      icon: Icon(
        searchQuery.isEmpty
            ? Icons.search_rounded
            : Icons.manage_search_rounded,
        color: context.riksa.ink,
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
          child: _CommunitySearchSheet(
            initialQuery: searchQuery,
            hintText: l10n.homeSearchHint,
            onChanged: onSearchChanged,
            onFilter: onFilter,
          ),
        ),
      ),
    );
  }
}

class _CommunitySearchSheet extends StatefulWidget {
  const _CommunitySearchSheet({
    required this.initialQuery,
    required this.hintText,
    required this.onChanged,
    required this.onFilter,
  });

  final String initialQuery;
  final String hintText;
  final ValueChanged<String> onChanged;
  final VoidCallback onFilter;

  @override
  State<_CommunitySearchSheet> createState() => _CommunitySearchSheetState();
}

class _CommunitySearchSheetState extends State<_CommunitySearchSheet> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RiksaSearchBar(
    key: const ValueKey('community-search-sheet'),
    controller: _controller,
    hintText: widget.hintText,
    onChanged: widget.onChanged,
    onFilter: widget.onFilter,
  );
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

/// The streak in the top bar: a flame and a number, opening the streak sheet.
class _StreakPill extends StatelessWidget {
  const _StreakPill({super.key, required this.streak});

  final AsyncValue<CommunityStreak> streak;

  @override
  Widget build(BuildContext context) {
    final palette = context.riksa;
    final theme = Theme.of(context);
    final value = streak.value;
    return Semantics(
      button: value != null,
      label: AppLocalizations.of(context)!.streakDays(value?.current ?? 0),
      excludeSemantics: true,
      child: InkWell(
        borderRadius: AppRadii.fullBorder,
        onTap: value == null
            ? null
            : () => showStreakDetailsSheet(context, value),
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: palette.features.rewardSoft,
            borderRadius: AppRadii.fullBorder,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const PixelFireIcon(size: 18),
              const SizedBox(width: 4),
              if (streak.isLoading)
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Text(
                  '${value?.current ?? 0}',
                  style: theme.textTheme.labelLarge?.copyWith(
                    // Dark ink suits the pale lime; on the dark theme's olive
                    // fill it would vanish, so the lime itself carries it.
                    color: theme.brightness == Brightness.dark
                        ? palette.features.reward
                        : palette.features.onReward,
                    fontWeight: FontWeight.w800,
                  ),
                ),
            ],
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
    final authorState = ref.watch(publicProfileProvider(post.authorId));
    final profile = authorState.profile;

    final authorName = profile != null && profile.preferredName.isNotEmpty
        ? profile.preferredName
        : (post.author != null && post.author!.displayName.isNotEmpty
              ? post.author!.displayName
              : 'Unknown Author');
    final username = profile != null && profile.username.isNotEmpty
        ? profile.username
        : (post.author != null ? post.author!.username : 'user');

    final date = DateFormat.MMMd(
      Localizations.localeOf(context).languageCode,
    ).format(post.createdAt.toLocal());

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: context.riksa.outline)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 12, 14),
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
                              errorBuilder: (_, _, _) =>
                                  const SizedBox.shrink(),
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
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
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
                                                    : Icons
                                                          .favorite_border_rounded,
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
