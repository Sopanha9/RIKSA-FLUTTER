import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/providers/locale_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../auth/providers/auth_provider.dart';
import '../../blog/data/blog_models.dart';
import '../../blog/providers/blog_provider.dart';
import '../data/social_models.dart';
import '../providers/social_feed_provider.dart';
import 'social_post_detail_screen.dart';
import 'widgets/social_post_card.dart';

enum _SocialSection { feed, blog }

class SocialFeedScreen extends ConsumerStatefulWidget {
  const SocialFeedScreen({super.key});

  @override
  ConsumerState<SocialFeedScreen> createState() => _SocialFeedScreenState();
}

class _SocialFeedScreenState extends ConsumerState<SocialFeedScreen> {
  late final ScrollController _scrollController;
  _SocialSection _section = _SocialSection.feed;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_loadMoreNearEdge);
  }

  void _loadMoreNearEdge() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.extentAfter < 520) {
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
    final selectedCategory = state is SocialFeedLoaded
        ? state.selectedCategoryId
        : null;
    final categories = state is SocialFeedLoaded
        ? state.categories
        : const <SocialCategory>[];

    return Scaffold(
      drawer: _CommunityDrawer(
        categories: categories,
        selectedSection: _section,
        onSectionSelected: _selectSection,
        onMembershipTap: _toggleMembership,
      ),
      body: RefreshIndicator(
        color: AppColors.brandPrimary,
        onRefresh: () => _section == _SocialSection.feed
            ? ref
                  .read(socialFeedProvider.notifier)
                  .load(categoryId: selectedCategory)
            : ref.read(blogFeedProvider.notifier).load(),
        child: CustomScrollView(
          key: PageStorageKey('social-${_section.name}-scroll'),
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            _CommunityAppBar(
              selectedSection: _section,
              onSectionSelected: _selectSection,
              onCreate: _showCreateMenu,
            ),
            if (_section == _SocialSection.feed)
              ..._contentSlivers(state)
            else
              ..._blogSlivers(blogState!),
            const SliverToBoxAdapter(child: SizedBox(height: 40)),
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
      SocialFeedLoaded(:final categories, :final posts) => [
        SliverToBoxAdapter(
          child: _CategoryFilters(
            categories: categories,
            selectedCategoryId: state.selectedCategoryId,
            onSelected: (id) =>
                ref.read(socialFeedProvider.notifier).selectCategory(id),
          ),
        ),
        if (posts.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: _FeedMessage(
              icon: Icons.forum_outlined,
              title: l10n.feedEmptyTitle,
              message: l10n.feedEmptyMessage,
            ),
          )
        else
          SliverList.builder(
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
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
        if (posts.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: _FeedMessage(
              icon: Icons.menu_book_rounded,
              title: l10n.blog,
              message: l10n.blogEmptyMessage,
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            sliver: SliverList.builder(
              itemCount: posts.length,
              itemBuilder: (context, index) => _GlassBlogCard(
                post: posts[index],
                onLike: () => ref
                    .read(blogFeedProvider.notifier)
                    .toggleLike(posts[index].id),
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

  Future<void> _toggleMembership(String categoryId) async {
    final success = await ref
        .read(socialFeedProvider.notifier)
        .toggleCategoryMembership(categoryId);
    if (!success && mounted) _showFailure();
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
  const _CommunityAppBar({
    required this.selectedSection,
    required this.onSectionSelected,
    required this.onCreate,
  });

  final _SocialSection selectedSection;
  final ValueChanged<_SocialSection> onSectionSelected;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return SliverAppBar(
      pinned: true,
      toolbarHeight: 72,
      titleSpacing: 2,
      leadingWidth: 64,
      automaticallyImplyLeading: false,
      backgroundColor: theme.colorScheme.surface.withValues(alpha: .82),
      surfaceTintColor: Colors.transparent,
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: const SizedBox.expand(),
        ),
      ),
      leading: Builder(
        builder: (context) => Padding(
          padding: const EdgeInsetsDirectional.only(start: 14),
          child: _GlassIconButton(
            key: const ValueKey('community-drawer-button'),
            icon: Icons.menu_rounded,
            tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'RIKSA',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
          Text(
            l10n.community,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      actions: [
        _StreakPill(
          key: const ValueKey('streak-pill'),
          streak: ref.watch(communityStreakProvider),
        ),
        const SizedBox(width: 8),
        Padding(
          padding: const EdgeInsetsDirectional.only(end: 14),
          child: _GlassIconButton(
            key: const ValueKey('create-community-button'),
            icon: Icons.add_rounded,
            tooltip: l10n.createCommunityContent,
            isPrimary: true,
            onPressed: onCreate,
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: _GlassSectionTabs(
          selected: selectedSection,
          onSelected: onSectionSelected,
        ),
      ),
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  const _GlassIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.isPrimary = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Tooltip(
      message: tooltip,
      child: Material(
        color: isPrimary
            ? AppColors.brandPrimary
            : theme.colorScheme.surfaceContainer.withValues(alpha: .72),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: BorderSide(
            color: isPrimary
                ? AppColors.brandPrimary
                : theme.colorScheme.outlineVariant.withValues(alpha: .65),
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: onPressed,
          child: SizedBox(
            width: 42,
            height: 42,
            child: Icon(
              icon,
              size: 23,
              color: isPrimary ? Colors.white : theme.colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassSectionTabs extends StatelessWidget {
  const _GlassSectionTabs({required this.selected, required this.onSelected});

  final _SocialSection selected;
  final ValueChanged<_SocialSection> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            height: 48,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainer.withValues(alpha: .68),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withValues(alpha: .6),
              ),
            ),
            child: Row(
              children: [
                _SectionTab(
                  key: const ValueKey('my-feed-tab'),
                  label: l10n.myFeed,
                  icon: Icons.dynamic_feed_outlined,
                  selected: selected == _SocialSection.feed,
                  onTap: () => onSelected(_SocialSection.feed),
                ),
                const SizedBox(width: 4),
                _SectionTab(
                  key: const ValueKey('blog-tab'),
                  label: l10n.blog,
                  icon: Icons.auto_stories_outlined,
                  selected: selected == _SocialSection.blog,
                  onTap: () => onSelected(_SocialSection.blog),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionTab extends StatelessWidget {
  const _SectionTab({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Material(
        color: selected ? theme.colorScheme.surface : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected
                    ? AppColors.brandPrimaryPressed
                    : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: selected
                      ? theme.colorScheme.onSurface
                      : theme.colorScheme.onSurfaceVariant,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
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
      color: const Color(0xFFFFF1E8),
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: value == null ? null : () => _showDetails(context, value),
        child: Container(
          height: 42,
          constraints: const BoxConstraints(minWidth: 58),
          padding: const EdgeInsets.symmetric(horizontal: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: const Color(0xFFFFD7BC)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.local_fire_department_rounded,
                color: Color(0xFFF26B2D),
                size: 21,
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
                    color: const Color(0xFF9B3D12),
                    fontWeight: FontWeight.w900,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetails(BuildContext context, CommunityStreak value) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 6, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.local_fire_department_rounded,
              size: 48,
              color: Color(0xFFF26B2D),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.streakDays(value.current),
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(
              value.nextMilestoneName == null
                  ? l10n.communitySubtitle
                  : '${value.daysToNext} • ${value.nextMilestoneName}',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommunityDrawer extends ConsumerWidget {
  const _CommunityDrawer({
    required this.categories,
    required this.selectedSection,
    required this.onSectionSelected,
    required this.onMembershipTap,
  });

  final List<SocialCategory> categories;
  final _SocialSection selectedSection;
  final ValueChanged<_SocialSection> onSectionSelected;
  final ValueChanged<String> onMembershipTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final auth = ref.watch(authProvider);
    final user = auth is Authenticated ? auth.user : null;
    final displayName = user?.displayName.trim().isNotEmpty == true
        ? user!.displayName
        : user?.username ?? 'RIKSA Learner';
    final initial = displayName.isEmpty ? 'R' : displayName[0].toUpperCase();

    return Drawer(
      width: MediaQuery.sizeOf(context).width.clamp(280, 344).toDouble(),
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: ClipRRect(
        borderRadius: const BorderRadiusDirectional.only(
          topEnd: Radius.circular(28),
          bottomEnd: Radius.circular(28),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Material(
            color: theme.colorScheme.surface.withValues(alpha: .92),
            child: SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFE8F8F1), Color(0xFFEAF4FC)],
                      ),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: const Color(0xFFD7E7E0)),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 25,
                          backgroundColor: AppColors.brandPrimary,
                          foregroundImage:
                              user?.avatarUrl?.trim().isNotEmpty == true
                              ? NetworkImage(user!.avatarUrl!)
                              : null,
                          child: Text(
                            initial,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                displayName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  color: AppColors.lightTextPrimary,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Text(
                                '@${user?.username ?? 'learner'}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppColors.lightTextSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _DrawerTile(
                    icon: Icons.dynamic_feed_outlined,
                    label: l10n.myFeed,
                    selected: selectedSection == _SocialSection.feed,
                    onTap: () {
                      Navigator.pop(context);
                      onSectionSelected(_SocialSection.feed);
                    },
                  ),
                  _DrawerTile(
                    icon: Icons.auto_stories_outlined,
                    label: l10n.blog,
                    selected: selectedSection == _SocialSection.blog,
                    onTap: () {
                      Navigator.pop(context);
                      onSectionSelected(_SocialSection.blog);
                    },
                  ),
                  _DrawerTile(
                    icon: Icons.person_outline_rounded,
                    label: l10n.setUpProfile,
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/profile/setup');
                    },
                  ),
                  if (categories.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        l10n.community,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    for (final category in categories.take(6))
                      ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                        ),
                        leading: CircleAvatar(
                          radius: 16,
                          backgroundColor: theme.colorScheme.primaryContainer,
                          child: Text(
                            category.name.isEmpty
                                ? '#'
                                : category.name[0].toUpperCase(),
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                        title: Text(
                          category.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Icon(
                          category.joined
                              ? Icons.check_circle_rounded
                              : Icons.add_circle_outline_rounded,
                          color: category.joined
                              ? AppColors.brandPrimaryPressed
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                        onTap: () => onMembershipTap(category.id),
                      ),
                  ],
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(),
                  ),
                  _DrawerTile(
                    icon: Icons.translate_rounded,
                    label: ref.watch(localeProvider).locale.languageCode == 'en'
                        ? l10n.languageKm
                        : l10n.languageEn,
                    onTap: () => ref.read(localeProvider.notifier).toggle(),
                  ),
                  _DrawerTile(
                    icon: Icons.logout_rounded,
                    label: l10n.logout,
                    foregroundColor: theme.colorScheme.error,
                    onTap: () {
                      Navigator.pop(context);
                      ref.read(authProvider.notifier).logout();
                    },
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

class _DrawerTile extends StatelessWidget {
  const _DrawerTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
    this.foregroundColor,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = foregroundColor ?? theme.colorScheme.onSurface;
    return ListTile(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      selected: selected,
      selectedTileColor: theme.colorScheme.primaryContainer,
      leading: Icon(icon, color: color),
      title: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w700),
      ),
      onTap: onTap,
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
      borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          padding: EdgeInsets.fromLTRB(
            18,
            12,
            18,
            24 + MediaQuery.paddingOf(context).bottom,
          ),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(alpha: .94),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
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
                    color: theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                l10n.createCommunityContent,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 14),
              _CreateOption(
                icon: Icons.edit_note_rounded,
                title: l10n.createPost,
                subtitle: l10n.createPostSubtitle,
                color: AppColors.brandPrimary,
                onTap: () => Navigator.pop(context, _CreateAction.post),
              ),
              const SizedBox(height: 10),
              _CreateOption(
                icon: Icons.help_outline_rounded,
                title: l10n.askCommunity,
                subtitle: l10n.askCommunitySubtitle,
                color: AppColors.brandAccent,
                onTap: () => Navigator.pop(context, _CreateAction.question),
              ),
            ],
          ),
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
      color: theme.colorScheme.surfaceContainer.withValues(alpha: .72),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(15),
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
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
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
        color: theme.colorScheme.surfaceContainer.withValues(alpha: .64),
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push('/blog/${post.id}'),
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withValues(alpha: .62),
              ),
              borderRadius: BorderRadius.circular(24),
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
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        post.content,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Text(
                            DateFormat.yMMMd().format(post.createdAt),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            onPressed: onLike,
                            icon: Icon(
                              post.liked
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              color: post.liked
                                  ? AppColors.error
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          Text('${post.likeCount}'),
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

class _CategoryFilters extends StatelessWidget {
  const _CategoryFilters({
    required this.categories,
    required this.selectedCategoryId,
    required this.onSelected,
  });

  final List<SocialCategory> categories;
  final String? selectedCategoryId;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainer.withValues(alpha: .58),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withValues(alpha: .55),
              ),
            ),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                ChoiceChip(
                  label: Text(l10n.forYou),
                  selected: selectedCategoryId == null,
                  showCheckmark: false,
                  onSelected: (_) => onSelected(null),
                ),
                for (final category in categories) ...[
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: Text(category.name),
                    selected: selectedCategoryId == category.id,
                    showCheckmark: false,
                    onSelected: (_) => onSelected(category.id),
                  ),
                ],
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
                color: theme.colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: theme.colorScheme.onPrimaryContainer,
                size: 29,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
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
                    backgroundColor: AppColors.lightTextPrimary,
                    foregroundColor: const Color(0xFFFFFFFF),
                    side: const BorderSide(color: AppColors.lightTextPrimary),
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
    final color = Theme.of(context).colorScheme.surfaceContainer;
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
              borderRadius: BorderRadius.circular(22),
            ),
          ),
        ),
      ),
    );
  }
}
