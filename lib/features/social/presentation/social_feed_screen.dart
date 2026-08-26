import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../blog/data/blog_models.dart';
import '../../blog/providers/blog_provider.dart';
import '../../userProfile/presentation/public_profile_navigation.dart';
import '../data/social_models.dart';
import '../providers/social_feed_provider.dart';
import 'social_post_detail_screen.dart';
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
                  return SocialPostCard(
                    post: post,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (context) =>
                            SocialPostDetailScreen(postId: post.id),
                        settings: RouteSettings(
                          name: '/community/posts/${post.id}',
                        ),
                      ),
                    ),
                    onAuthorTap: publicProfilePath(post.author.id) == null
                        ? null
                        : () => _openProfile(post.author.id),
                    onReact: () => _react(post.id),
                    onShare: () => _share(post.id),
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
    final action = await showModalBottomSheet<_CreateAction>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const _CreateMenuSheet(),
    );
    if (!mounted || action == null) return;
    final created = await context.push<bool>(
      action == _CreateAction.question
          ? '/community/create?type=question'
          : '/community/create',
    );
    if (created == true) {
      _selectSection(_SocialSection.feed);
    }
  }
}

class _CommunityAppBar extends ConsumerWidget {
  const _CommunityAppBar({required this.onSearchChanged});

  final ValueChanged<String> onSearchChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return SliverToBoxAdapter(
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 6),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'RIKSA',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: SocialPalette.aubergine(context),
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    l10n.community,
                    style: TextStyle(
                      color: SocialPalette.muted(context),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  key: const ValueKey('community-search'),
                  onChanged: onSearchChanged,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: l10n.searchCommunity,
                    hintStyle: TextStyle(
                      color: SocialPalette.muted(context),
                      fontSize: 14,
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      size: 20,
                      color: SocialPalette.muted(context),
                    ),
                    filled: true,
                    fillColor: SocialPalette.editorialSurface(context),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: AppRadii.fullBorder,
                      borderSide: BorderSide(
                        color: SocialPalette.border(
                          context,
                        ).withValues(alpha: .4),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: AppRadii.fullBorder,
                      borderSide: BorderSide(
                        color: SocialPalette.border(
                          context,
                        ).withValues(alpha: .4),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: AppRadii.fullBorder,
                      borderSide: BorderSide(
                        color: SocialPalette.pink(context),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _StreakPill(
                key: const ValueKey('streak-pill'),
                streak: ref.watch(communityStreakProvider),
              ),
            ],
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
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
      child: Semantics(
        button: true,
        label: l10n.communityComposerPrompt,
        child: Material(
          color: SocialPalette.surface(context),
          borderRadius: AppRadii.fullBorder,
          child: InkWell(
            key: const ValueKey('create-community-button'),
            onTap: onTap,
            borderRadius: AppRadii.fullBorder,
            child: Container(
              constraints: const BoxConstraints(minHeight: 54),
              padding: const EdgeInsets.fromLTRB(9, 7, 9, 7),
              decoration: BoxDecoration(
                borderRadius: AppRadii.fullBorder,
                border: Border.all(color: SocialPalette.outline(context)),
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

class _FeedSectionTabs extends StatefulWidget {
  const _FeedSectionTabs({required this.selected, required this.onSelected});

  final _SocialSection selected;
  final ValueChanged<_SocialSection> onSelected;

  @override
  State<_FeedSectionTabs> createState() => _FeedSectionTabsState();
}

class _FeedSectionTabsState extends State<_FeedSectionTabs> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Container(
        height: 48,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: SocialPalette.surface(context),
          borderRadius: AppRadii.fullBorder,
          border: Border.all(color: SocialPalette.outline(context)),
        ),
        child: Row(
          children: [
            Expanded(
              child: _CapsuleTabItem(
                key: const ValueKey('my-feed-tab'),
                label: l10n.forYou,
                selected: widget.selected == _SocialSection.feed,
                onTap: () => widget.onSelected(_SocialSection.feed),
              ),
            ),
            Expanded(
              child: _CapsuleTabItem(
                key: const ValueKey('blog-tab'),
                label: l10n.blog,
                selected: widget.selected == _SocialSection.blog,
                onTap: () => widget.onSelected(_SocialSection.blog),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CapsuleTabItem extends StatelessWidget {
  const _CapsuleTabItem({
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
    return Semantics(
      button: true,
      selected: selected,
      child: AnimatedContainer(
        duration: RiksaMotion.resolve(context, RiksaMotion.standard),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: selected
              ? (isDark
                    ? AppColors.editorialPink
                    : AppColors.editorialAubergine)
              : Colors.transparent,
          borderRadius: AppRadii.fullBorder,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: AppRadii.fullBorder,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            borderRadius: AppRadii.fullBorder,
            onTap: onTap,
            splashColor: AppColors.editorialPink.withValues(alpha: .16),
            highlightColor: AppColors.editorialPink.withValues(alpha: .1),
            child: Center(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected
                      ? (isDark ? AppColors.editorialAubergine : Colors.white)
                      : SocialPalette.ink(context),
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
                  letterSpacing: -0.1,
                ),
              ),
            ),
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
    return Container(
      decoration: BoxDecoration(
        borderRadius: AppRadii.fullBorder,
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: .1),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: SocialPalette.pinkSoft(context),
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
            decoration: BoxDecoration(
              borderRadius: AppRadii.fullBorder,
              border: Border.all(
                color: SocialPalette.pink(context).withValues(alpha: .28),
              ),
            ),
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
      ),
    );
  }
}

enum _CreateAction { post, question }

class _CreateMenuSheet extends StatelessWidget {
  const _CreateMenuSheet();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(AppRadii.large),
      ),
      child: Container(
        padding: EdgeInsets.fromLTRB(
          18,
          12,
          18,
          24 + MediaQuery.paddingOf(context).bottom,
        ),
        decoration: BoxDecoration(
          color: SocialPalette.panel(context),
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadii.large),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: SocialPalette.border(context),
                  borderRadius: AppRadii.fullBorder,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.createCommunityContent,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: SocialPalette.text(context),
              ),
            ),
            const SizedBox(height: 14),
            _CreateOption(
              icon: Icons.edit_note_rounded,
              title: l10n.createPost,
              subtitle: l10n.createPostSubtitle,
              color: SocialPalette.pink(context),
              onTap: () => Navigator.pop(context, _CreateAction.post),
            ),
            const SizedBox(height: 10),
            _CreateOption(
              icon: Icons.help_outline_rounded,
              title: l10n.askCommunity,
              subtitle: l10n.askCommunitySubtitle,
              color: SocialPalette.aubergine(context),
              onTap: () => Navigator.pop(context, _CreateAction.question),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreateOption extends StatelessWidget {
  const _CreateOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: SocialPalette.editorialSurface(context),
      borderRadius: AppRadii.mediumBorder,
      child: InkWell(
        borderRadius: AppRadii.mediumBorder,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .14),
                  borderRadius: AppRadii.smallBorder,
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: SocialPalette.text(context),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: SocialPalette.muted(context),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: SocialPalette.muted(context),
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
