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
        selectedCategoryId: selectedCategory,
        onSectionSelected: _selectDrawerSection,
        onCategorySelected: _selectDrawerCategory,
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
        if (posts.isNotEmpty)
          SliverToBoxAdapter(
            child: _TopLearnersSpotlight(
              posts: posts,
              onViewAll: () => _showTopLearners(posts),
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

  void _showTopLearners(List<SocialPost> posts) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) =>
          _TopLearnersSheet(learners: _SpotlightLearner.fromPosts(posts)),
    );
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

  void _selectDrawerSection(_SocialSection section) {
    _selectSection(section);
    if (section == _SocialSection.feed) {
      ref.read(socialFeedProvider.notifier).selectCategory(null);
    }
  }

  void _selectDrawerCategory(String categoryId) {
    _selectSection(_SocialSection.feed);
    ref.read(socialFeedProvider.notifier).selectCategory(categoryId);
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
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.shadow.withValues(alpha: .12),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Material(
          color: isPrimary
              ? AppColors.brandPrimary
              : theme.colorScheme.surface.withValues(alpha: .94),
          shape: CircleBorder(
            side: BorderSide(
              color: isPrimary
                  ? AppColors.brandPrimary
                  : theme.colorScheme.outlineVariant.withValues(alpha: .52),
            ),
          ),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onPressed,
            child: SizedBox(
              width: 44,
              height: 44,
              child: Icon(
                icon,
                size: 23,
                color: isPrimary ? Colors.white : theme.colorScheme.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassSectionTabs extends StatefulWidget {
  const _GlassSectionTabs({required this.selected, required this.onSelected});

  final _SocialSection selected;
  final ValueChanged<_SocialSection> onSelected;

  @override
  State<_GlassSectionTabs> createState() => _GlassSectionTabsState();
}

class _GlassSectionTabsState extends State<_GlassSectionTabs> {
  static const _gap = 12.0;
  _SocialSection? _pressedSection;
  _SocialSection? _visualSelected;
  int _selectionChange = 0;

  _SocialSection get _effectiveVisualSelected =>
      _visualSelected ?? widget.selected;

  @override
  void initState() {
    super.initState();
    _visualSelected = widget.selected;
  }

  @override
  void didUpdateWidget(covariant _GlassSectionTabs oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selected != oldWidget.selected &&
        widget.selected != _effectiveVisualSelected) {
      _visualSelected = widget.selected;
    }
  }

  void _setPressed(_SocialSection section, bool pressed) {
    final next = pressed ? section : null;
    if (_pressedSection == next) return;
    setState(() => _pressedSection = next);
  }

  void _activate(_SocialSection section) {
    if (_effectiveVisualSelected != section) {
      final change = ++_selectionChange;
      setState(() => _visualSelected = section);
      Future<void>.delayed(const Duration(milliseconds: 280), () {
        if (mounted &&
            change == _selectionChange &&
            widget.selected != section) {
          widget.onSelected(section);
        }
      });
    }
    Future<void>.delayed(const Duration(milliseconds: 70), () {
      if (mounted && _pressedSection == section) {
        setState(() => _pressedSection = null);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final inactiveColor = theme.brightness == Brightness.dark
        ? colors.surfaceContainer
        : colors.surface.withValues(alpha: .96);
    final visualSelected = _effectiveVisualSelected;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: SizedBox(
        height: 48,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final pillWidth = (constraints.maxWidth - _gap) / 2;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: Row(
                    children: [
                      Expanded(
                        child: _PressScale(
                          pressed: _pressedSection == _SocialSection.feed,
                          child: _InactiveTabSurface(
                            backgroundColor: inactiveColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: _gap),
                      Expanded(
                        child: _PressScale(
                          pressed: _pressedSection == _SocialSection.blog,
                          child: _InactiveTabSurface(
                            backgroundColor: inactiveColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                AnimatedPositioned(
                  key: const ValueKey('active-section-pill'),
                  duration: const Duration(milliseconds: 280),
                  curve: const Cubic(.18, 1.32, .32, 1),
                  top: 0,
                  bottom: 0,
                  left: visualSelected == _SocialSection.feed
                      ? 0
                      : pillWidth + _gap,
                  width: pillWidth,
                  child: IgnorePointer(
                    child: _PressScale(
                      pressed: _pressedSection == visualSelected,
                      child: const _ActiveTabSurface(),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Row(
                    children: [
                      _SectionTab(
                        key: const ValueKey('my-feed-tab'),
                        label: l10n.myFeed,
                        icon: Icons.dynamic_feed_outlined,
                        selected: visualSelected == _SocialSection.feed,
                        pressed: _pressedSection == _SocialSection.feed,
                        onPressChanged: (pressed) =>
                            _setPressed(_SocialSection.feed, pressed),
                        onTap: () => _activate(_SocialSection.feed),
                      ),
                      const SizedBox(width: _gap),
                      _SectionTab(
                        key: const ValueKey('blog-tab'),
                        label: l10n.blog,
                        icon: Icons.auto_stories_outlined,
                        selected: visualSelected == _SocialSection.blog,
                        pressed: _pressedSection == _SocialSection.blog,
                        onPressChanged: (pressed) =>
                            _setPressed(_SocialSection.blog, pressed),
                        onTap: () => _activate(_SocialSection.blog),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _InactiveTabSurface extends StatelessWidget {
  const _InactiveTabSurface({required this.backgroundColor});

  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: .34)),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: .055),
            blurRadius: 9,
            offset: const Offset(0, 3),
          ),
        ],
      ),
    );
  }
}

class _ActiveTabSurface extends StatelessWidget {
  const _ActiveTabSurface();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.lerp(Colors.white, AppColors.brandPrimaryHover, .68)!,
            Color.lerp(
              AppColors.brandPrimaryHover,
              AppColors.brandPrimaryPressed,
              .28,
            )!,
          ],
        ),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: .24)),
        boxShadow: [
          BoxShadow(
            color: AppColors.brandPrimaryPressed.withValues(alpha: .16),
            blurRadius: 13,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Align(
        alignment: Alignment.topCenter,
        child: FractionallySizedBox(
          widthFactor: .78,
          child: Container(
            margin: const EdgeInsets.only(top: 2),
            height: 1.5,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              gradient: LinearGradient(
                colors: [
                  Colors.white.withValues(alpha: 0),
                  Colors.white.withValues(alpha: .72),
                  Colors.white.withValues(alpha: 0),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PressScale extends StatelessWidget {
  const _PressScale({required this.pressed, required this.child});

  final bool pressed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: pressed ? .95 : 1,
      duration: Duration(milliseconds: pressed ? 110 : 150),
      curve: pressed ? Curves.easeOutCubic : Curves.easeOutBack,
      child: child,
    );
  }
}

class _SectionTab extends StatelessWidget {
  const _SectionTab({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.pressed,
    required this.onPressChanged,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final bool pressed;
  final ValueChanged<bool> onPressChanged;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final foreground = selected ? Colors.white : colors.onSurfaceVariant;

    return Expanded(
      child: _PressScale(
        pressed: pressed,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            borderRadius: BorderRadius.circular(999),
            onTapDown: (_) => onPressChanged(true),
            onTapCancel: () => onPressChanged(false),
            onTap: onTap,
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TweenAnimationBuilder<Color?>(
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeOutCubic,
                    tween: ColorTween(end: foreground),
                    builder: (context, color, _) =>
                        Icon(icon, size: 18, color: color),
                  ),
                  const SizedBox(width: 8),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeOutCubic,
                    style: theme.textTheme.labelLarge!.copyWith(
                      color: foreground,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    ),
                    child: Text(label),
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

class _StreakPill extends StatelessWidget {
  const _StreakPill({super.key, required this.streak});

  final AsyncValue<CommunityStreak> streak;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final value = streak.value;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: .1),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: const Color(0xFFFFF1E8),
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: value == null ? null : () => _showDetails(context, value),
          child: Container(
            height: 44,
            constraints: const BoxConstraints(minWidth: 62),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
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

enum _DrawerAccordionSection { feed, blog, profile, community }

class _CommunityDrawer extends ConsumerStatefulWidget {
  const _CommunityDrawer({
    required this.categories,
    required this.selectedSection,
    required this.selectedCategoryId,
    required this.onSectionSelected,
    required this.onCategorySelected,
  });

  final List<SocialCategory> categories;
  final _SocialSection selectedSection;
  final String? selectedCategoryId;
  final ValueChanged<_SocialSection> onSectionSelected;
  final ValueChanged<String> onCategorySelected;

  @override
  ConsumerState<_CommunityDrawer> createState() => _CommunityDrawerState();
}

class _CommunityDrawerState extends ConsumerState<_CommunityDrawer> {
  _DrawerAccordionSection? _expandedSection;

  void _toggleSection(_DrawerAccordionSection section) {
    setState(() {
      _expandedSection = _expandedSection == section ? null : section;
    });
  }

  @override
  Widget build(BuildContext context) {
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
                  _SingleDestinationAccordion(
                    icon: Icons.dynamic_feed_outlined,
                    label: l10n.myFeed,
                    destinationLabel: l10n.forYou,
                    expanded: _expandedSection == _DrawerAccordionSection.feed,
                    parentSelected:
                        _expandedSection == null &&
                        widget.selectedSection == _SocialSection.feed &&
                        widget.selectedCategoryId == null,
                    destinationSelected:
                        widget.selectedSection == _SocialSection.feed &&
                        widget.selectedCategoryId == null,
                    onToggle: () =>
                        _toggleSection(_DrawerAccordionSection.feed),
                    onDestinationTap: () {
                      Navigator.pop(context);
                      widget.onSectionSelected(_SocialSection.feed);
                    },
                  ),
                  const SizedBox(height: 4),
                  _SingleDestinationAccordion(
                    icon: Icons.auto_stories_outlined,
                    label: l10n.blog,
                    destinationLabel: l10n.viewAll,
                    expanded: _expandedSection == _DrawerAccordionSection.blog,
                    parentSelected:
                        _expandedSection == null &&
                        widget.selectedSection == _SocialSection.blog,
                    destinationSelected:
                        widget.selectedSection == _SocialSection.blog,
                    onToggle: () =>
                        _toggleSection(_DrawerAccordionSection.blog),
                    onDestinationTap: () {
                      Navigator.pop(context);
                      widget.onSectionSelected(_SocialSection.blog);
                    },
                  ),
                  const SizedBox(height: 4),
                  _SingleDestinationAccordion(
                    icon: Icons.person_outline_rounded,
                    label: l10n.setUpProfile,
                    destinationLabel: l10n.profile,
                    expanded:
                        _expandedSection == _DrawerAccordionSection.profile,
                    parentSelected: false,
                    destinationSelected: false,
                    onToggle: () =>
                        _toggleSection(_DrawerAccordionSection.profile),
                    onDestinationTap: () {
                      Navigator.pop(context);
                      context.push('/profile/setup');
                    },
                  ),
                  const SizedBox(height: 4),
                  _CommunityAccordion(
                    expanded:
                        _expandedSection == _DrawerAccordionSection.community,
                    parentSelected:
                        _expandedSection == null &&
                        widget.selectedCategoryId != null,
                    categories: widget.categories.take(6).toList(),
                    selectedCategoryId: widget.selectedCategoryId,
                    onToggle: () =>
                        _toggleSection(_DrawerAccordionSection.community),
                    onCategorySelected: (categoryId) {
                      Navigator.pop(context);
                      widget.onCategorySelected(categoryId);
                    },
                  ),
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

class _DrawerNavigationTile extends StatelessWidget {
  const _DrawerNavigationTile({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
    this.expanded = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final foreground = selected
        ? AppColors.brandPrimaryPressed
        : colors.onSurface;
    return Semantics(
      button: true,
      expanded: expanded,
      selected: selected,
      child: Material(
        color: selected
            ? AppColors.brandPrimary.withValues(alpha: .12)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(999),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onTap,
          child: SizedBox(
            height: 50,
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeInOut,
                  width: 4,
                  height: selected ? 28 : 0,
                  decoration: BoxDecoration(
                    color: AppColors.brandPrimaryPressed,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(width: 12),
                Icon(icon, size: 22, color: foreground),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: foreground,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
                    ),
                  ),
                ),
                AnimatedRotation(
                  turns: expanded ? .5 : 0,
                  duration: const Duration(milliseconds: 230),
                  curve: Curves.easeInOut,
                  child: Icon(
                    Icons.expand_more_rounded,
                    size: 22,
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 13),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SingleDestinationAccordion extends StatelessWidget {
  const _SingleDestinationAccordion({
    required this.icon,
    required this.label,
    required this.destinationLabel,
    required this.expanded,
    required this.parentSelected,
    required this.destinationSelected,
    required this.onToggle,
    required this.onDestinationTap,
  });

  final IconData icon;
  final String label;
  final String destinationLabel;
  final bool expanded;
  final bool parentSelected;
  final bool destinationSelected;
  final VoidCallback onToggle;
  final VoidCallback onDestinationTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _DrawerNavigationTile(
          icon: icon,
          label: label,
          expanded: expanded,
          selected: parentSelected,
          onTap: onToggle,
        ),
        ClipRect(
          child: AnimatedSize(
            duration: const Duration(milliseconds: 230),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: expanded
                ? Padding(
                    padding: const EdgeInsets.only(top: 5, bottom: 3),
                    child: Container(
                      margin: const EdgeInsetsDirectional.only(start: 27),
                      decoration: BoxDecoration(
                        border: BorderDirectional(
                          start: BorderSide(
                            color: colors.outlineVariant.withValues(alpha: .7),
                          ),
                        ),
                      ),
                      child: _DrawerCategoryItem(
                        label: destinationLabel,
                        selected: destinationSelected,
                        onTap: onDestinationTap,
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }
}

class _CommunityAccordion extends StatelessWidget {
  const _CommunityAccordion({
    required this.expanded,
    required this.parentSelected,
    required this.categories,
    required this.selectedCategoryId,
    required this.onToggle,
    required this.onCategorySelected,
  });

  final bool expanded;
  final bool parentSelected;
  final List<SocialCategory> categories;
  final String? selectedCategoryId;
  final VoidCallback onToggle;
  final ValueChanged<String> onCategorySelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _DrawerNavigationTile(
          key: const ValueKey('community-accordion'),
          icon: Icons.groups_2_outlined,
          label: l10n.community,
          expanded: expanded,
          selected: parentSelected,
          onTap: onToggle,
        ),
        ClipRect(
          child: AnimatedSize(
            duration: const Duration(milliseconds: 230),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: expanded
                ? Padding(
                    padding: const EdgeInsets.only(top: 5, bottom: 3),
                    child: Container(
                      margin: const EdgeInsetsDirectional.only(start: 27),
                      decoration: BoxDecoration(
                        border: BorderDirectional(
                          start: BorderSide(
                            color: colors.outlineVariant.withValues(alpha: .7),
                          ),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (final category in categories)
                            _DrawerCategoryItem(
                              key: ValueKey('drawer-category-${category.id}'),
                              label: category.name,
                              selected: selectedCategoryId == category.id,
                              onTap: () => onCategorySelected(category.id),
                            ),
                        ],
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }
}

class _DrawerCategoryItem extends StatelessWidget {
  const _DrawerCategoryItem({
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
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final foreground = selected
        ? AppColors.brandPrimaryPressed
        : colors.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 9, end: 2, bottom: 2),
      child: Material(
        color: selected
            ? AppColors.brandPrimary.withValues(alpha: .12)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onTap,
          child: SizedBox(
            height: 42,
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeInOut,
                  width: 3,
                  height: selected ? 24 : 0,
                  decoration: BoxDecoration(
                    color: AppColors.brandPrimaryPressed,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: foreground,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
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
    this.foregroundColor,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = foregroundColor ?? theme.colorScheme.onSurface;
    return ListTile(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
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

class _SpotlightLearner {
  const _SpotlightLearner({
    required this.id,
    required this.name,
    required this.username,
    required this.avatarUrl,
    required this.subject,
    required this.score,
  });

  final String id;
  final String name;
  final String username;
  final String avatarUrl;
  final String subject;
  final int score;

  static List<_SpotlightLearner> fromPosts(List<SocialPost> posts) {
    final byAuthor = <String, _SpotlightLearner>{};
    for (final post in posts) {
      final author = post.author;
      final id = author.id.isEmpty ? author.username : author.id;
      final current = byAuthor[id];
      final displayName = author.displayName.trim().isEmpty
          ? author.username
          : author.displayName;
      byAuthor[id] = _SpotlightLearner(
        id: id,
        name: displayName,
        username: author.username,
        avatarUrl: author.avatarUrl,
        subject: current?.subject ?? post.category.name,
        score: (current?.score ?? 0) + post.reactionCount,
      );
    }
    final learners = byAuthor.values.toList()
      ..sort((a, b) => b.score.compareTo(a.score));
    return learners;
  }
}

class _TopLearnersSpotlight extends StatelessWidget {
  const _TopLearnersSpotlight({required this.posts, required this.onViewAll});

  final List<SocialPost> posts;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final learners = _SpotlightLearner.fromPosts(posts).take(6).toList();

    return Container(
      key: const ValueKey('top-learners-spotlight'),
      margin: const EdgeInsets.fromLTRB(16, 7, 16, 13),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [Color(0xFF102C24), Color(0xFF1D3024)]
              : const [Color(0xFFE5F6EF), Color(0xFFF3F6DC)],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: AppColors.brandPrimary.withValues(alpha: isDark ? .34 : .14),
        ),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: .07),
            blurRadius: 24,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.brandPrimary,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.brandPrimary.withValues(alpha: .2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.emoji_events_rounded,
                  size: 21,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  l10n.topLearnersThisWeek,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: -.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          SizedBox(
            height: 112,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: learners.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, index) =>
                  _SpotlightLearnerCard(learner: learners[index]),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 42,
            child: Material(
              color: AppColors.brandPrimary,
              borderRadius: BorderRadius.circular(999),
              child: InkWell(
                key: const ValueKey('top-learners-view-all'),
                borderRadius: BorderRadius.circular(999),
                onTap: onViewAll,
                child: Center(
                  child: Text(
                    l10n.viewAll,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SpotlightLearnerCard extends StatelessWidget {
  const _SpotlightLearnerCard({required this.learner});

  final _SpotlightLearner learner;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Container(
      width: 218,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: .82),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.surface.withValues(alpha: .72)),
      ),
      child: Row(
        children: [
          _SpotlightAvatar(imageUrl: learner.avatarUrl, label: learner.name),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  learner.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Container(
                  constraints: const BoxConstraints(maxWidth: 122),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.brandPrimary.withValues(alpha: .1),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    learner.subject,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.brandPrimaryPressed,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 7),
                Row(
                  children: [
                    const Icon(
                      Icons.thumb_up_alt_rounded,
                      size: 14,
                      color: AppColors.brandPrimaryPressed,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        l10n.upvotesCount(learner.score),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colors.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
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
    );
  }
}

class _SpotlightAvatar extends StatelessWidget {
  const _SpotlightAvatar({required this.imageUrl, required this.label});

  final String imageUrl;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final initial = label.trim().isEmpty ? 'R' : label.trim()[0].toUpperCase();
    return CircleAvatar(
      radius: 24,
      backgroundColor: colors.primaryContainer,
      foregroundImage: imageUrl.trim().isEmpty ? null : NetworkImage(imageUrl),
      onForegroundImageError: imageUrl.trim().isEmpty
          ? null
          : (exception, stackTrace) {},
      child: Text(
        initial,
        style: TextStyle(
          color: colors.onPrimaryContainer,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _TopLearnersSheet extends StatelessWidget {
  const _TopLearnersSheet({required this.learners});

  final List<_SpotlightLearner> learners;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return FractionallySizedBox(
      heightFactor: .72,
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 8, 22, 14),
              child: Text(
                l10n.topLearnersThisWeek,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
                itemCount: learners.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final learner = learners[index];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    tileColor: theme.colorScheme.surfaceContainerLow,
                    leading: _SpotlightAvatar(
                      imageUrl: learner.avatarUrl,
                      label: learner.name,
                    ),
                    title: Text(
                      learner.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Text(learner.subject),
                    trailing: Text(
                      l10n.upvotesCount(learner.score),
                      style: const TextStyle(
                        color: AppColors.brandPrimaryPressed,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 7),
      child: SizedBox(
        height: 42,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            _CategoryFilterPill(
              label: l10n.forYou,
              selected: selectedCategoryId == null,
              onTap: () => onSelected(null),
            ),
            for (final category in categories) ...[
              const SizedBox(width: 10),
              _CategoryFilterPill(
                label: category.name,
                selected: selectedCategoryId == category.id,
                onTap: () => onSelected(category.id),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CategoryFilterPill extends StatelessWidget {
  const _CategoryFilterPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: selected
          ? AppColors.brandPrimary
          : theme.colorScheme.surfaceContainer.withValues(alpha: .72),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 17),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? AppColors.brandPrimary
                  : theme.colorScheme.outlineVariant.withValues(alpha: .48),
            ),
          ),
          child: Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: selected ? Colors.white : theme.colorScheme.onSurface,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
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
