import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/providers/locale_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/riksa_avatar_image.dart';
import '../../../core/widgets/riksa_components.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../auth/providers/auth_provider.dart';
import '../../blog/data/blog_models.dart';
import '../../blog/providers/blog_provider.dart';
import '../../userProfile/presentation/public_profile_navigation.dart';
import '../data/social_models.dart';
import '../providers/social_feed_provider.dart';
import 'social_post_detail_screen.dart';
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
    final selectedCategory = state is SocialFeedLoaded
        ? state.selectedCategoryId
        : null;
    final categories = state is SocialFeedLoaded
        ? state.categories
        : const <SocialCategory>[];

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAF7),
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
            _CommunityAppBar(onCreate: _showCreateMenu),
            SliverToBoxAdapter(
              child: _FeedSectionTabs(
                selected: _section,
                onSelected: _selectSection,
              ),
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
      SocialFeedLoaded(:final categories, :final posts) => [
        const SliverToBoxAdapter(child: _CommunityGreeting()),
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
              onLearnerTap: _openProfile,
            ),
          ),
        SliverToBoxAdapter(child: _CreatePostPrompt(onTap: _showCreateMenu)),
        const SliverToBoxAdapter(child: SizedBox(height: 14)),
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
                onAuthorTap: publicProfilePath(post.author.id) == null
                    ? null
                    : () => _openProfile(post.author.id),
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

  void _openProfile(String userId) {
    final path = publicProfilePath(userId);
    if (path != null) context.push(path);
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
  const _CommunityAppBar({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return SliverToBoxAdapter(
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          child: Row(
            children: [
              Builder(
                builder: (context) => _GlassIconButton(
                  key: const ValueKey('community-drawer-button'),
                  icon: Icons.menu_rounded,
                  tooltip: MaterialLocalizations.of(
                    context,
                  ).openAppDrawerTooltip,
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: const Color(0xFF20211F),
                      fontWeight: FontWeight.w900,
                      letterSpacing: -.5,
                    ),
                    children: [
                      const TextSpan(text: 'RIKSA'),
                      TextSpan(
                        text: ' / ${l10n.community}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              _StreakPill(
                key: const ValueKey('streak-pill'),
                streak: ref.watch(communityStreakProvider),
              ),
              const SizedBox(width: 10),
              _GlassIconButton(
                key: const ValueKey('create-community-button'),
                icon: Icons.add_rounded,
                tooltip: l10n.createCommunityContent,
                isPrimary: true,
                onPressed: onCreate,
              ),
            ],
          ),
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
    return Tooltip(
      message: tooltip,
      child: Material(
        color: isPrimary ? const Color(0xFF20211F) : Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 42,
            height: 42,
            child: Icon(
              icon,
              color: isPrimary ? Colors.white : const Color(0xFF20211F),
            ),
          ),
        ),
      ),
    );
  }
}

class _CommunityGreeting extends ConsumerWidget {
  const _CommunityGreeting();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final state = ref.watch(authProvider);
    final name =
        state is Authenticated && state.user.displayName.trim().isNotEmpty
        ? state.user.displayName.trim().split(' ').first
        : 'Learner';
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 30, 20, 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 520),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) => Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 16 * (1 - value)),
                  child: child,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Good afternoon,',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      letterSpacing: -.6,
                    ),
                  ),
                  Text(
                    '$name.',
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontSize: 38,
                      height: .98,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'What are you curious about today?',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const _CuriosityOrb(),
        ],
      ),
    );
  }
}

class _CuriosityOrb extends StatelessWidget {
  const _CuriosityOrb();

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: .85, end: 1),
    duration: const Duration(milliseconds: 620),
    curve: Curves.easeOutBack,
    builder: (context, value, _) => Transform.scale(
      scale: value,
      child: Container(
        width: 142,
        height: 142,
        decoration: BoxDecoration(
          color: const Color(0xFFE9E4FA),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF8E7CC3).withValues(alpha: .18),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: const Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              Icons.auto_awesome_rounded,
              color: Color(0xFF625284),
              size: 51,
            ),
            Positioned(
              right: 25,
              top: 26,
              child: Icon(Icons.circle, color: Color(0xFFFFC978), size: 15),
            ),
          ],
        ),
      ),
    ),
  );
}

class _FeedSectionTabs extends StatefulWidget {
  const _FeedSectionTabs({required this.selected, required this.onSelected});

  final _SocialSection selected;
  final ValueChanged<_SocialSection> onSelected;

  @override
  State<_FeedSectionTabs> createState() => _FeedSectionTabsState();
}

class _FeedSectionTabsState extends State<_FeedSectionTabs> {
  _SocialSection? _pressedSection;
  _SocialSection? _visualSelected;

  _SocialSection get _effectiveVisualSelected =>
      _visualSelected ?? widget.selected;

  @override
  void initState() {
    super.initState();
    _visualSelected = widget.selected;
  }

  @override
  void didUpdateWidget(covariant _FeedSectionTabs oldWidget) {
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
      setState(() => _visualSelected = section);
      widget.onSelected(section);
    }
    Future<void>.delayed(RiksaMotion.resolve(context, RiksaMotion.fast), () {
      if (mounted && _pressedSection == section) {
        setState(() => _pressedSection = null);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final visualSelected = _effectiveVisualSelected;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 2),
      child: Row(
        key: const ValueKey('feed-section-tabs'),
        children: [
          _SectionTab(
            key: const ValueKey('my-feed-tab'),
            label: 'Feed',
            selected: visualSelected == _SocialSection.feed,
            pressed: _pressedSection == _SocialSection.feed,
            onPressChanged: (pressed) =>
                _setPressed(_SocialSection.feed, pressed),
            onTap: () => _activate(_SocialSection.feed),
          ),
          const SizedBox(width: 28),
          _SectionTab(
            key: const ValueKey('blog-tab'),
            label: l10n.blog,
            selected: visualSelected == _SocialSection.blog,
            pressed: _pressedSection == _SocialSection.blog,
            onPressChanged: (pressed) =>
                _setPressed(_SocialSection.blog, pressed),
            onTap: () => _activate(_SocialSection.blog),
          ),
        ],
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
      duration: RiksaMotion.resolve(context, RiksaMotion.fast),
      curve: pressed ? Curves.easeOutCubic : Curves.easeOutBack,
      child: child,
    );
  }
}

class _SectionTab extends StatelessWidget {
  const _SectionTab({
    super.key,
    required this.label,
    required this.selected,
    required this.pressed,
    required this.onPressChanged,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool pressed;
  final ValueChanged<bool> onPressChanged;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final foreground = selected
        ? AppColors.brandPrimaryPressed
        : colors.onSurfaceVariant.withValues(alpha: .75);
    return Semantics(
      button: true,
      selected: selected,
      child: _PressScale(
        pressed: pressed,
        child: SizedBox(
          height: 44,
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.zero,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              borderRadius: AppRadii.smallBorder,
              onTapDown: (_) => onPressChanged(true),
              onTapCancel: () => onPressChanged(false),
              onTap: onTap,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedDefaultTextStyle(
                    duration: RiksaMotion.resolve(
                      context,
                      RiksaMotion.standard,
                    ),
                    curve: Curves.easeOutCubic,
                    style: theme.textTheme.labelMedium!.copyWith(
                      color: foreground,
                      fontSize: 15,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    ),
                    child: Text(label, maxLines: 1),
                  ),
                  const SizedBox(height: 6),
                  AnimatedContainer(
                    duration: RiksaMotion.resolve(
                      context,
                      RiksaMotion.standard,
                    ),
                    curve: Curves.easeOutCubic,
                    height: 2.5,
                    width: selected ? 30 : 0,
                    decoration: BoxDecoration(
                      color: const Color(0xFF625284),
                      borderRadius: AppRadii.fullBorder,
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
        color: AppColors.gamificationOrangeSoft,
        borderRadius: AppRadii.fullBorder,
        child: InkWell(
          borderRadius: AppRadii.fullBorder,
          onTap: value == null
              ? null
              : () => showStreakDetailsSheet(context, value),
          child: Container(
            height: 44,
            constraints: const BoxConstraints(minWidth: 62),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              borderRadius: AppRadii.fullBorder,
              border: Border.all(
                color: AppColors.gamificationOrange.withValues(alpha: .28),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.local_fire_department_rounded,
                  color: AppColors.gamificationOrange,
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
                      color: AppColors.gamificationOrangePressed,
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

    return Drawer(
      width: MediaQuery.sizeOf(context).width.clamp(180, 270).toDouble(),
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: ClipRRect(
        borderRadius: const BorderRadiusDirectional.only(
          topEnd: Radius.circular(AppRadii.large),
          bottomEnd: Radius.circular(AppRadii.large),
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
                    key: const ValueKey('drawer-profile-hero'),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFE8F8F1), Color(0xFFEAF4FC)],
                      ),
                      borderRadius: AppRadii.largeBorder,
                      border: Border.all(color: const Color(0xFFD7E7E0)),
                    ),
                    child: Row(
                      children: [
                        RiksaAvatarImage(
                          value: user?.avatarUrl,
                          label: displayName,
                          size: 50,
                          backgroundColor: AppColors.brandPrimary,
                          foregroundColor: Colors.white,
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
                    key: const ValueKey('drawer-feed-row'),
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
                    key: const ValueKey('drawer-blog-row'),
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
                    key: const ValueKey('drawer-profile-row'),
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
        key: ValueKey('drawer-nav-$label'),
        color: selected
            ? AppColors.brandPrimary.withValues(alpha: .12)
            : Colors.transparent,
        borderRadius: AppRadii.mediumBorder,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          borderRadius: AppRadii.mediumBorder,
          onTap: onTap,
          child: SizedBox(
            height: 50,
            child: Row(
              children: [
                AnimatedContainer(
                  key: ValueKey('drawer-accent-$label'),
                  duration: RiksaMotion.resolve(context, RiksaMotion.standard),
                  curve: Curves.easeInOut,
                  width: 4,
                  height: selected ? 28 : 0,
                  decoration: BoxDecoration(
                    color: AppColors.brandPrimaryPressed,
                    borderRadius: AppRadii.smallBorder,
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
                  duration: RiksaMotion.resolve(context, RiksaMotion.standard),
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
    super.key,
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
            duration: RiksaMotion.resolve(context, RiksaMotion.standard),
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
            duration: RiksaMotion.resolve(context, RiksaMotion.standard),
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
        borderRadius: AppRadii.smallBorder,
        child: InkWell(
          borderRadius: AppRadii.smallBorder,
          onTap: onTap,
          child: SizedBox(
            height: 42,
            child: Row(
              children: [
                AnimatedContainer(
                  duration: RiksaMotion.resolve(context, RiksaMotion.standard),
                  curve: Curves.easeInOut,
                  width: 3,
                  height: selected ? 24 : 0,
                  decoration: BoxDecoration(
                    color: AppColors.brandPrimaryPressed,
                    borderRadius: AppRadii.smallBorder,
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
      shape: const RoundedRectangleBorder(borderRadius: AppRadii.mediumBorder),
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
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(AppRadii.large),
      ),
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
                    color: theme.colorScheme.outlineVariant,
                    borderRadius: AppRadii.fullBorder,
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
                  color: color.withValues(alpha: .12),
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
        borderRadius: AppRadii.mediumBorder,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push('/blog/${post.id}'),
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withValues(alpha: .62),
              ),
              borderRadius: AppRadii.mediumBorder,
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
  const _TopLearnersSpotlight({
    required this.posts,
    required this.onViewAll,
    required this.onLearnerTap,
  });

  final List<SocialPost> posts;
  final VoidCallback onViewAll;
  final ValueChanged<String> onLearnerTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final learners = _SpotlightLearner.fromPosts(posts).take(8).toList();
    final spotlightOrder = learners.length >= 3
        ? [learners[1], learners[0], learners[2], ...learners.skip(3)]
        : learners;

    return Container(
      key: const ValueKey('top-learners-spotlight'),
      margin: const EdgeInsets.fromLTRB(20, 26, 20, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.topLearnersThisWeek,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -.6,
                  ),
                ),
              ),
              TextButton.icon(
                key: const ValueKey('top-learners-view-all'),
                onPressed: onViewAll,
                iconAlignment: IconAlignment.end,
                icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                label: Text(l10n.viewAll),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 126,
            child: ListView.separated(
              padding: const EdgeInsets.only(right: 44),
              scrollDirection: Axis.horizontal,
              itemCount: spotlightOrder.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, index) => _SpotlightLearnerCard(
                learner: spotlightOrder[index],
                rank: learners.indexOf(spotlightOrder[index]) + 1,
                onTap: spotlightOrder[index].id.isEmpty
                    ? null
                    : () => onLearnerTap(spotlightOrder[index].id),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SpotlightLearnerCard extends StatelessWidget {
  const _SpotlightLearnerCard({
    required this.learner,
    required this.rank,
    this.onTap,
  });

  final _SpotlightLearner learner;
  final int rank;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rankBadges = ['①', '②', '③', '④', '⑤', '⑥', '⑦', '⑧'];
    final rankBadgeStr = rank <= rankBadges.length
        ? rankBadges[rank - 1]
        : '#$rank';

    final rankColor = switch (rank) {
      1 => const Color(0xFFE9E4FA),
      2 => const Color(0xFFDDEBFA),
      3 => const Color(0xFFFFE8C7),
      _ => const Color(0xFFDFF0E4),
    };

    return InkWell(
      onTap: onTap,
      borderRadius: AppRadii.mediumBorder,
      child: Container(
        width: rank == 1 ? 108 : 98,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: rankColor,
          borderRadius: AppRadii.mediumBorder,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: .8),
                      width: 2,
                    ),
                  ),
                  padding: const EdgeInsets.all(2),
                  child: SocialAuthorAvatar(
                    imageUrl: learner.avatarUrl,
                    label: learner.name,
                    seed: learner.username.isEmpty
                        ? learner.id
                        : learner.username,
                    size: rank == 1 ? 52 : 44,
                  ),
                ),
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF20211F),
                      borderRadius: AppRadii.fullBorder,
                    ),
                    child: Text(
                      rankBadgeStr,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              learner.name.split(' ').first,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: theme.textTheme.labelMedium?.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${learner.score}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF393A37),
                  ),
                ),
                const Icon(
                  Icons.arrow_upward_rounded,
                  size: 11,
                  color: const Color(0xFF393A37),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: AppRadii.fullBorder,
              child: LinearProgressIndicator(
                value: (learner.score.clamp(1, 100) as int) / 100,
                minHeight: 3,
                backgroundColor: Colors.white.withValues(alpha: .55),
                valueColor: const AlwaysStoppedAnimation(Color(0xFF393A37)),
              ),
            ),
          ],
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
                      borderRadius: AppRadii.mediumBorder,
                    ),
                    tileColor: theme.colorScheme.surfaceContainerLow,
                    leading: SocialAuthorAvatar(
                      imageUrl: learner.avatarUrl,
                      label: learner.name,
                      seed: learner.username.isEmpty
                          ? learner.id
                          : learner.username,
                      size: 48,
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

class _CreatePostPrompt extends StatelessWidget {
  const _CreatePostPrompt({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Semantics(
      button: true,
      label: l10n.startConversation,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
        child: Material(
          color: Colors.white,
          elevation: 0,
          borderRadius: AppRadii.mediumBorder,
          child: InkWell(
            key: const ValueKey('community-start-conversation'),
            onTap: onTap,
            borderRadius: AppRadii.mediumBorder,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE9E4FA),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person_rounded,
                      color: Color(0xFF625284),
                      size: 19,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l10n.startConversationHint,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: Color(0xFF20211F),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.edit_rounded,
                      color: Colors.white,
                      size: 17,
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
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 1),
      child: SizedBox(
        height: 40,
        child: ListView(
          padding: const EdgeInsets.only(right: 40),
          scrollDirection: Axis.horizontal,
          children: [
            _CategoryFilterPill(
              key: const ValueKey('category-filter-for-you'),
              label: l10n.forYou,
              icon: Icons.auto_awesome_rounded,
              selected: selectedCategoryId == null,
              onTap: () => onSelected(null),
            ),
            for (final category in categories) ...[
              const SizedBox(width: 6),
              _CategoryFilterPill(
                key: ValueKey('category-filter-${category.id}'),
                label: category.name,
                icon: _categoryIcon(category),
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
    return Material(
      color: selected ? const Color(0xFFE9E4FA) : Colors.transparent,
      borderRadius: AppRadii.fullBorder,
      child: InkWell(
        borderRadius: AppRadii.fullBorder,
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(borderRadius: AppRadii.fullBorder),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected) ...[
                Icon(icon, size: 15, color: const Color(0xFF625284)),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: selected
                      ? const Color(0xFF393A37)
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

IconData _categoryIcon(SocialCategory category) {
  final value = '${category.name} ${category.slug}'.toLowerCase();
  if (value.contains('biology')) return Icons.biotech_rounded;
  if (value.contains('chem')) return Icons.science_rounded;
  if (value.contains('math')) return Icons.calculate_rounded;
  if (value.contains('computer') || value.contains('tech')) {
    return Icons.code_rounded;
  }
  if (value.contains('physics') || value.contains('astronomy')) {
    return Icons.public_rounded;
  }
  if (value.contains('language') || value.contains('english')) {
    return Icons.translate_rounded;
  }
  return Icons.local_library_rounded;
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
              borderRadius: AppRadii.mediumBorder,
            ),
          ),
        ),
      ),
    );
  }
}
